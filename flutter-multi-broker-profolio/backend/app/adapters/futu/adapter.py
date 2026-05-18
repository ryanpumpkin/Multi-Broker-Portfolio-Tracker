"""Futu OpenD adapter.

The official `futu-api` SDK uses a long-lived TCP connection to a local
OpenD process. This adapter goes through an injected `FutuClient`
Protocol so tests can replace it. The trade context must be unlocked with
the user's trade password per request — it is never persisted.
"""

from __future__ import annotations

from collections.abc import AsyncIterator, Awaitable, Callable, Iterable
from contextlib import asynccontextmanager
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any, Protocol

from app.adapters._common import (
    HealthTracker,
    RetryPolicy,
    retry_async,
)
from app.adapters.base import SourceAdapter
from app.models.domain import (
    CashBalance,
    Position,
    Quote,
    SourceHealth,
    Transaction,
)

SOURCE_NAME = "futu"


class FutuClient(Protocol):
    """OpenD wrapper."""

    async def unlock_trade(self, password: str) -> None: ...

    async def lock_trade(self) -> None: ...

    async def fetch_positions(self) -> list[dict[str, Any]]: ...

    async def fetch_accounts(self) -> list[dict[str, Any]]: ...

    async def fetch_history_orders(
        self, *, since: str | None, limit: int | None
    ) -> list[dict[str, Any]]: ...

    def subscribe_quotes(self, symbols: list[str]) -> AsyncIterator[dict[str, Any]]: ...

    async def ping(self) -> bool: ...


def _dec(v: Any) -> Decimal:
    return Decimal(str(v))


def _opt_dec(v: Any) -> Decimal | None:
    if v is None or v == "":
        return None
    return Decimal(str(v))


def _parse_ts(value: Any) -> datetime:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=UTC)
    return datetime.fromisoformat(str(value).replace("Z", "+00:00"))


def _map_position(raw: dict[str, Any]) -> Position:
    qty = _dec(raw["qty"])
    last = _opt_dec(raw.get("nominal_price"))
    avg = _opt_dec(raw.get("cost_price"))
    return Position(
        source=SOURCE_NAME,
        account_id=str(raw["acc_id"]) if "acc_id" in raw else None,
        symbol=raw["code"],
        exchange=raw.get("trd_market"),
        quantity=qty,
        avg_cost=avg,
        last_price=last,
        currency=raw["currency"],
        market_value=_opt_dec(raw.get("market_val")),
        unrealized_pnl=_opt_dec(raw.get("pl_val")),
    )


def _map_balance(raw: dict[str, Any]) -> CashBalance:
    return CashBalance(
        source=SOURCE_NAME,
        account_id=str(raw["acc_id"]) if "acc_id" in raw else None,
        currency=raw["currency"],
        amount=_dec(raw["cash"]),
    )


def _map_transaction(raw: dict[str, Any]) -> Transaction:
    side_raw = raw.get("trd_side")
    side = side_raw.lower() if isinstance(side_raw, str) else None
    return Transaction(
        source=SOURCE_NAME,
        account_id=str(raw["acc_id"]) if "acc_id" in raw else None,
        transaction_id=str(raw["order_id"]),
        symbol=raw.get("code"),
        side=side,
        quantity=_opt_dec(raw.get("qty")),
        price=_opt_dec(raw.get("price")),
        currency=raw.get("currency"),
        amount=_opt_dec(raw.get("dealt_amount") or raw.get("amount")),
        timestamp=_parse_ts(raw["create_time"]),
    )


def _map_quote(raw: dict[str, Any]) -> Quote:
    return Quote(
        source=SOURCE_NAME,
        symbol=raw["code"],
        price=_dec(raw["last_price"]),
        currency=raw["currency"],
        timestamp=_parse_ts(raw.get("data_date") or raw["timestamp"]),
    )


class FutuAdapter(SourceAdapter):
    """Futu OpenD adapter."""

    source = SOURCE_NAME

    def __init__(
        self,
        client: FutuClient,
        *,
        trade_password: str | None = None,
        retry: RetryPolicy | None = None,
        health: HealthTracker | None = None,
    ) -> None:
        self._client = client
        self._trade_password = trade_password
        self._retry = retry or RetryPolicy()
        self._health = health or HealthTracker(source=SOURCE_NAME)

    @asynccontextmanager
    async def _unlocked(self) -> AsyncIterator[None]:
        if self._trade_password is None:
            yield
            return
        await self._client.unlock_trade(self._trade_password)
        try:
            yield
        finally:
            await self._client.lock_trade()

    async def _call(self, func: Callable[[], Awaitable[Any]]) -> Any:
        try:
            result = await retry_async(func, policy=self._retry)
        except Exception as exc:
            self._health.record_failure(str(exc))
            raise
        self._health.record_success()
        return result

    async def list_positions(self) -> list[Position]:
        async def _do() -> list[dict[str, Any]]:
            async with self._unlocked():
                return await self._client.fetch_positions()

        raw = await self._call(_do)
        return [_map_position(item) for item in raw]

    async def list_balances(self) -> list[CashBalance]:
        async def _do() -> list[dict[str, Any]]:
            async with self._unlocked():
                return await self._client.fetch_accounts()

        raw = await self._call(_do)
        return [_map_balance(item) for item in raw]

    async def list_transactions(
        self,
        *,
        since: str | None = None,
        limit: int | None = None,
    ) -> list[Transaction]:
        async def _do() -> list[dict[str, Any]]:
            async with self._unlocked():
                return await self._client.fetch_history_orders(since=since, limit=limit)

        raw = await self._call(_do)
        return [_map_transaction(item) for item in raw]

    async def stream_quotes(self, symbols: Iterable[str]) -> AsyncIterator[Quote]:
        async for raw in self._client.subscribe_quotes(list(symbols)):
            yield _map_quote(raw)

    async def healthcheck(self) -> SourceHealth:
        try:
            ok = await self._client.ping()
            if ok:
                self._health.record_success()
            else:
                self._health.record_failure("OpenD ping failed")
        except Exception as exc:  # noqa: BLE001
            self._health.record_failure(str(exc))
        return self._health.snapshot()
