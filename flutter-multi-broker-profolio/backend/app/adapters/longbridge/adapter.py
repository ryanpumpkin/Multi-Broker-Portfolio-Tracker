"""LongBridge OpenAPI adapter.

The official `longbridge` Python SDK is intentionally not declared as a
runtime dependency. Callers pass any object that satisfies the
`LongBridgeClient` Protocol — in production a thin wrapper around the SDK;
in tests, a fake. See detailed-design §4.3.
"""

from __future__ import annotations

from collections.abc import AsyncIterator, Iterable
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any, Protocol

from app.adapters._common import (
    HealthTracker,
    RetryPolicy,
    TransientError,
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

SOURCE_NAME = "longbridge"


class LongBridgeClient(Protocol):
    """SDK wrapper boundary. The real impl wraps `longbridge.openapi`."""

    async def fetch_positions(self) -> list[dict[str, Any]]: ...

    async def fetch_balances(self) -> list[dict[str, Any]]: ...

    async def fetch_transactions(
        self, *, since: str | None, limit: int | None
    ) -> list[dict[str, Any]]: ...

    def subscribe_quotes(self, symbols: list[str]) -> AsyncIterator[dict[str, Any]]: ...

    async def refresh_token(self) -> None: ...


def _dec(value: Any) -> Decimal:
    return Decimal(str(value))


def _opt_dec(value: Any) -> Decimal | None:
    if value is None or value == "":
        return None
    return Decimal(str(value))


def _map_position(raw: dict[str, Any]) -> Position:
    qty = _dec(raw["quantity"])
    avg = _opt_dec(raw.get("cost_price"))
    last = _opt_dec(raw.get("last_price"))
    mv = last * qty if last is not None else None
    upl = (last - avg) * qty if last is not None and avg is not None else None
    return Position(
        source=SOURCE_NAME,
        account_id=raw.get("account_no"),
        symbol=raw["symbol"],
        exchange=raw.get("market") or raw.get("exchange"),
        quantity=qty,
        avg_cost=avg,
        last_price=last,
        currency=raw["currency"],
        market_value=mv,
        unrealized_pnl=upl,
    )


def _map_balance(raw: dict[str, Any]) -> CashBalance:
    return CashBalance(
        source=SOURCE_NAME,
        account_id=raw.get("account_no"),
        currency=raw["currency"],
        amount=_dec(raw["total_cash"]),
    )


def _parse_ts(value: Any) -> datetime:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=UTC)
    return datetime.fromisoformat(str(value).replace("Z", "+00:00"))


def _map_transaction(raw: dict[str, Any]) -> Transaction:
    return Transaction(
        source=SOURCE_NAME,
        account_id=raw.get("account_no"),
        transaction_id=str(raw["order_id"]),
        symbol=raw.get("symbol"),
        side=(raw.get("side") or "").lower() or None,
        quantity=_opt_dec(raw.get("quantity")),
        price=_opt_dec(raw.get("price")),
        currency=raw.get("currency"),
        amount=_opt_dec(raw.get("amount")),
        timestamp=_parse_ts(raw["submitted_at"]),
    )


def _map_quote(raw: dict[str, Any]) -> Quote:
    return Quote(
        source=SOURCE_NAME,
        symbol=raw["symbol"],
        price=_dec(raw["last_done"]),
        currency=raw["currency"],
        timestamp=_parse_ts(raw["timestamp"]),
    )


class LongBridgeAdapter(SourceAdapter):
    """LongBridge OpenAPI adapter."""

    source = SOURCE_NAME

    def __init__(
        self,
        client: LongBridgeClient,
        *,
        retry: RetryPolicy | None = None,
        health: HealthTracker | None = None,
    ) -> None:
        self._client = client
        self._retry = retry or RetryPolicy()
        self._health = health or HealthTracker(source=SOURCE_NAME)

    async def _call(self, func: Any) -> Any:
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
        raw = await self._call(self._client.fetch_balances)
        return [_map_balance(item) for item in raw]

    async def list_transactions(
        self,
        *,
        since: str | None = None,
        limit: int | None = None,
    ) -> list[Transaction]:
        async def _do() -> list[dict[str, Any]]:
            return await self._client.fetch_transactions(since=since, limit=limit)

        raw = await self._call(_do)
        return [_map_transaction(item) for item in raw]

    async def stream_quotes(self, symbols: Iterable[str]) -> AsyncIterator[Quote]:
        async for raw in self._client.subscribe_quotes(list(symbols)):
            yield _map_quote(raw)

    async def healthcheck(self) -> SourceHealth:
        try:
            await self._client.refresh_token()
            self._health.record_success()
        except Exception as exc:  # noqa: BLE001 - health probe records and continues
            self._health.record_failure(str(exc))
        return self._health.snapshot()


# Re-export the transient error so adapter callers can raise it inside
# injected SDK wrappers without importing from the private module.
__all__ = ["LongBridgeAdapter", "LongBridgeClient", "TransientError"]
