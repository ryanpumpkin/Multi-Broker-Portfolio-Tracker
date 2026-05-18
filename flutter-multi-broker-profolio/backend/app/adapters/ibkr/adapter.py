"""IBKR Client Portal Gateway adapter.

The adapter talks to a co-located CP Gateway through an injected
`IbkrClient` Protocol. A keep-alive ping loop is exposed because CP
Gateway expires sessions after a few minutes of inactivity (detailed-design
§4.3 / §7.2).
"""

from __future__ import annotations

import asyncio
from collections.abc import AsyncIterator, Awaitable, Callable, Iterable
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

SOURCE_NAME = "ibkr"


class IbkrClient(Protocol):
    """Thin wrapper around the CP Gateway HTTP/WS endpoints."""

    async def tickle(self) -> bool: ...

    async def fetch_positions(self) -> list[dict[str, Any]]: ...

    async def fetch_account_summary(self) -> list[dict[str, Any]]: ...

    async def fetch_executions(
        self, *, since: str | None, limit: int | None
    ) -> list[dict[str, Any]]: ...

    def stream_market_data(self, symbols: list[str]) -> AsyncIterator[dict[str, Any]]: ...


def _dec(v: Any) -> Decimal:
    return Decimal(str(v))


def _opt_dec(v: Any) -> Decimal | None:
    if v is None or v == "":
        return None
    return Decimal(str(v))


def _parse_ts(value: Any) -> datetime:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=UTC)
    if isinstance(value, int | float):
        return datetime.fromtimestamp(float(value), tz=UTC)
    return datetime.fromisoformat(str(value).replace("Z", "+00:00"))


def _map_position(raw: dict[str, Any]) -> Position:
    return Position(
        source=SOURCE_NAME,
        account_id=raw.get("acctId") or raw.get("account_id"),
        symbol=raw["contractDesc"] if "contractDesc" in raw else raw["symbol"],
        exchange=raw.get("listingExchange") or raw.get("exchange"),
        quantity=_dec(raw["position"]),
        avg_cost=_opt_dec(raw.get("avgCost") or raw.get("avg_cost")),
        last_price=_opt_dec(raw.get("mktPrice")),
        currency=raw["currency"],
        market_value=_opt_dec(raw.get("mktValue")),
        unrealized_pnl=_opt_dec(raw.get("unrealizedPnl")),
    )


def _map_balance(raw: dict[str, Any]) -> CashBalance:
    return CashBalance(
        source=SOURCE_NAME,
        account_id=raw.get("acctId") or raw.get("account_id"),
        currency=raw["currency"],
        amount=_dec(raw["cashBalance"] if "cashBalance" in raw else raw["amount"]),
    )


def _map_transaction(raw: dict[str, Any]) -> Transaction:
    side_raw = raw.get("side")
    side = side_raw.lower() if isinstance(side_raw, str) else None
    return Transaction(
        source=SOURCE_NAME,
        account_id=raw.get("acctId") or raw.get("account_id"),
        transaction_id=str(raw.get("execId") or raw["transaction_id"]),
        symbol=raw.get("symbol"),
        side=side,
        quantity=_opt_dec(raw.get("size") or raw.get("quantity")),
        price=_opt_dec(raw.get("price")),
        currency=raw.get("currency"),
        amount=_opt_dec(raw.get("net_amount") or raw.get("amount")),
        timestamp=_parse_ts(raw.get("time") or raw["timestamp"]),
    )


def _map_quote(raw: dict[str, Any]) -> Quote:
    return Quote(
        source=SOURCE_NAME,
        symbol=raw["symbol"],
        price=_dec(raw.get("last") or raw["price"]),
        currency=raw["currency"],
        timestamp=_parse_ts(raw.get("t") or raw["timestamp"]),
    )


class IbkrAdapter(SourceAdapter):
    """IBKR adapter."""

    source = SOURCE_NAME

    def __init__(
        self,
        client: IbkrClient,
        *,
        retry: RetryPolicy | None = None,
        health: HealthTracker | None = None,
        keepalive_interval: float = 60.0,
    ) -> None:
        self._client = client
        self._retry = retry or RetryPolicy()
        self._health = health or HealthTracker(source=SOURCE_NAME)
        self._keepalive_interval = keepalive_interval
        self._keepalive_task: asyncio.Task[None] | None = None

    async def _call(self, func: Callable[[], Awaitable[Any]]) -> Any:
        try:
            result = await retry_async(func, policy=self._retry)
        except Exception as exc:
            self._health.record_failure(str(exc))
            raise
        self._health.record_success()
        return result

    async def list_positions(self) -> list[Position]:
        raw = await self._call(self._client.fetch_positions)
        return [_map_position(item) for item in raw]

    async def list_balances(self) -> list[CashBalance]:
        raw = await self._call(self._client.fetch_account_summary)
        return [_map_balance(item) for item in raw]

    async def list_transactions(
        self,
        *,
        since: str | None = None,
        limit: int | None = None,
    ) -> list[Transaction]:
        async def _do() -> list[dict[str, Any]]:
            return await self._client.fetch_executions(since=since, limit=limit)

        raw = await self._call(_do)
        return [_map_transaction(item) for item in raw]

    async def stream_quotes(self, symbols: Iterable[str]) -> AsyncIterator[Quote]:
        async for raw in self._client.stream_market_data(list(symbols)):
            yield _map_quote(raw)

    async def healthcheck(self) -> SourceHealth:
        try:
            ok = await self._client.tickle()
            if ok:
                self._health.record_success()
            else:
                self._health.record_failure("tickle returned false")
        except Exception as exc:  # noqa: BLE001
            self._health.record_failure(str(exc))
        return self._health.snapshot()

    async def _keepalive_loop(
        self,
        sleep: Callable[[float], Awaitable[None]] = asyncio.sleep,
    ) -> None:
        while True:
            try:
                await self._client.tickle()
            except Exception as exc:  # noqa: BLE001 - keepalive must keep looping
                self._health.record_failure(str(exc))
            await sleep(self._keepalive_interval)

    def start_keepalive(self) -> asyncio.Task[None]:
        """Spawn the CP Gateway tickle loop."""
        if self._keepalive_task is None or self._keepalive_task.done():
            self._keepalive_task = asyncio.create_task(self._keepalive_loop())
        return self._keepalive_task

    async def stop_keepalive(self) -> None:
        task = self._keepalive_task
        if task is None:
            return
        task.cancel()
        try:
            await task
        except (asyncio.CancelledError, Exception):  # noqa: BLE001
            pass
        self._keepalive_task = None
