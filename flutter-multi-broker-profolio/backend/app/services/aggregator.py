"""Portfolio aggregation service with resilient fan-out and per-source caching."""

from __future__ import annotations

import asyncio
import time
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any, Protocol, TypeVar, cast

from app.adapters.base import SourceAdapter
from app.models.domain import (
    CashBalance,
    Connection,
    FxRate,
    PartialResult,
    PortfolioSnapshot,
    Position,
    SourceHealth,
    SourceHealthStatus,
    Transaction,
)
from app.services.fx import FxService

T = TypeVar("T")


class ConnectionRepository(Protocol):
    """Loads user connections from storage."""

    async def list_connections(self, user_id: str) -> list[Connection]: ...


class AdapterRegistry(Protocol):
    """Maps a user connection to the adapter instance handling it."""

    def for_connection(self, connection: Connection) -> SourceAdapter | None: ...


@dataclass(slots=True)
class _TtlEntry:
    value: Any
    expires_at: float


@dataclass(slots=True)
class _SourceSlice:
    source_health: SourceHealth
    positions: list[Position]
    balances: list[CashBalance]


class InMemoryConnectionRepository:
    """Simple repository implementation used by tests and local boot."""

    def __init__(self, connections: list[Connection] | None = None) -> None:
        self._connections = connections or []

    async def list_connections(self, user_id: str) -> list[Connection]:
        _ = user_id
        return [c for c in self._connections if c.enabled]


class PortfolioAggregator:
    """Aggregates data from all enabled source adapters for a user."""

    def __init__(
        self,
        *,
        connections: ConnectionRepository,
        adapters: AdapterRegistry,
        fx: FxService,
        ttl_seconds: float = 10.0,
    ) -> None:
        self._connections = connections
        self._adapters = adapters
        self._fx = fx
        self._ttl_seconds = ttl_seconds
        self._cache: dict[tuple[str, str, str], _TtlEntry] = {}

    async def get_snapshot(self, user_id: str, *, base_currency: str = "USD") -> PortfolioSnapshot:
        """Get a unified portfolio snapshot for one user."""
        base = base_currency.upper()
        connections = await self._enabled_connections(user_id)

        tasks = [self._collect_source_snapshot(user_id, conn) for conn in connections]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        positions: list[Position] = []
        balances: list[CashBalance] = []
        health: list[SourceHealth] = []

        for conn, result in zip(connections, results, strict=True):
            if isinstance(result, BaseException):
                health.append(
                    SourceHealth(
                        source=conn.source,
                        status=SourceHealthStatus.DOWN,
                        message=str(result),
                    )
                )
                continue
            positions.extend(result.positions)
            balances.extend(result.balances)
            health.append(result.source_health)

        fx_pairs = self._pairs_for_snapshot(base, positions, balances)
        fx_by_pair = await self._fx.get_rates_for(fx_pairs)
        fx_rates = list(fx_by_pair.values())

        total_market_value = self._sum_positions(positions, base, fx_by_pair)
        total_balance_value = self._sum_balances(balances, base, fx_by_pair)
        total_unrealized = self._sum_unrealized(positions, base, fx_by_pair)

        snapshot = PortfolioSnapshot(
            as_of=datetime.now(UTC),
            base_currency=base,
            positions=positions,
            balances=balances,
            fx_rates=fx_rates,
            source_health=health,
            total_market_value=total_market_value + total_balance_value,
            total_unrealized_pnl=total_unrealized,
        )
        return snapshot

    async def get_positions(
        self,
        user_id: str,
        *,
        source: str | None = None,
    ) -> PartialResult[Position]:
        connections = await self._filtered_connections(user_id, source=source)
        tasks = [self._list_positions_for_connection(user_id, conn) for conn in connections]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        items: list[Position] = []
        health: list[SourceHealth] = []
        for conn, result in zip(connections, results, strict=True):
            if isinstance(result, BaseException):
                health.append(
                    SourceHealth(source=conn.source, status=SourceHealthStatus.DOWN, message=str(result))
                )
                continue
            items.extend(result)
            health.append(SourceHealth(source=conn.source, status=SourceHealthStatus.OK))
        return PartialResult(items=items, source_health=health)

    async def get_balances(
        self,
        user_id: str,
        *,
        source: str | None = None,
    ) -> PartialResult[CashBalance]:
        connections = await self._filtered_connections(user_id, source=source)
        tasks = [self._list_balances_for_connection(user_id, conn) for conn in connections]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        items: list[CashBalance] = []
        health: list[SourceHealth] = []
        for conn, result in zip(connections, results, strict=True):
            if isinstance(result, BaseException):
                health.append(
                    SourceHealth(source=conn.source, status=SourceHealthStatus.DOWN, message=str(result))
                )
                continue
            items.extend(result)
            health.append(SourceHealth(source=conn.source, status=SourceHealthStatus.OK))
        return PartialResult(items=items, source_health=health)

    async def get_transactions(
        self,
        user_id: str,
        *,
        source: str | None = None,
        since: str | None = None,
        limit: int | None = None,
    ) -> PartialResult[Transaction]:
        connections = await self._filtered_connections(user_id, source=source)
        tasks = [self._list_transactions_for_connection(conn, since=since, limit=limit) for conn in connections]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        items: list[Transaction] = []
        health: list[SourceHealth] = []
        for conn, result in zip(connections, results, strict=True):
            if isinstance(result, BaseException):
                health.append(
                    SourceHealth(source=conn.source, status=SourceHealthStatus.DOWN, message=str(result))
                )
                continue
            items.extend(result)
            health.append(SourceHealth(source=conn.source, status=SourceHealthStatus.OK))

        items.sort(key=lambda row: row.timestamp, reverse=True)
        if limit is not None:
            items = items[:limit]
        return PartialResult(items=items, source_health=health)

    async def _collect_source_snapshot(self, user_id: str, conn: Connection) -> _SourceSlice:
        adapter = self._adapters.for_connection(conn)
        if adapter is None:
            return _SourceSlice(
                source_health=SourceHealth(
                    source=conn.source,
                    status=SourceHealthStatus.DOWN,
                    message=f"No adapter configured for source '{conn.source}'",
                ),
                positions=[],
                balances=[],
            )

        pos_task = self._list_positions_for_connection(user_id, conn)
        bal_task = self._list_balances_for_connection(user_id, conn)
        pos_result, bal_result = await asyncio.gather(pos_task, bal_task, return_exceptions=True)

        positions: list[Position] = []
        balances: list[CashBalance] = []
        errors: list[str] = []

        if isinstance(pos_result, BaseException):
            errors.append(f"positions: {pos_result}")
        else:
            positions = pos_result

        if isinstance(bal_result, BaseException):
            errors.append(f"balances: {bal_result}")
        else:
            balances = bal_result

        if not errors:
            status = SourceHealthStatus.OK
            message = None
        elif positions or balances:
            status = SourceHealthStatus.DEGRADED
            message = "; ".join(errors)
        else:
            status = SourceHealthStatus.DOWN
            message = "; ".join(errors)

        return _SourceSlice(
            source_health=SourceHealth(
                source=conn.source,
                status=status,
                message=message,
                last_success_at=datetime.now(UTC) if status is SourceHealthStatus.OK else None,
            ),
            positions=positions,
            balances=balances,
        )

    async def _list_positions_for_connection(self, user_id: str, conn: Connection) -> list[Position]:
        adapter = self._require_adapter(conn)
        key = (user_id, conn.connection_id, "positions")
        return await self._cached(key, adapter.list_positions)

    async def _list_balances_for_connection(self, user_id: str, conn: Connection) -> list[CashBalance]:
        adapter = self._require_adapter(conn)
        key = (user_id, conn.connection_id, "balances")
        return await self._cached(key, adapter.list_balances)

    async def _list_transactions_for_connection(
        self,
        conn: Connection,
        *,
        since: str | None,
        limit: int | None,
    ) -> list[Transaction]:
        adapter = self._require_adapter(conn)
        return await adapter.list_transactions(since=since, limit=limit)

    def _require_adapter(self, conn: Connection) -> SourceAdapter:
        adapter = self._adapters.for_connection(conn)
        if adapter is None:
            msg = f"No adapter configured for source '{conn.source}'"
            raise LookupError(msg)
        return adapter

    async def _enabled_connections(self, user_id: str) -> list[Connection]:
        rows = await self._connections.list_connections(user_id)
        return [row for row in rows if row.enabled]

    async def _filtered_connections(self, user_id: str, *, source: str | None) -> list[Connection]:
        rows = await self._enabled_connections(user_id)
        if source is None:
            return rows
        source_l = source.lower()
        return [row for row in rows if row.source.lower() == source_l]

    async def _cached(self, key: tuple[str, str, str], loader: Callable[[], Awaitable[T]]) -> T:
        cached = self._cache.get(key)
        now = time.monotonic()
        if cached is not None and cached.expires_at > now:
            return cast(T, cached.value)

        fresh = await loader()
        self._cache[key] = _TtlEntry(value=fresh, expires_at=now + self._ttl_seconds)
        return fresh

    @staticmethod
    def _pairs_for_snapshot(
        base_currency: str,
        positions: list[Position],
        balances: list[CashBalance],
    ) -> set[tuple[str, str]]:
        pairs: set[tuple[str, str]] = set()
        for pos in positions:
            curr = pos.currency.upper()
            if curr != base_currency:
                pairs.add((curr, base_currency))
        for bal in balances:
            curr = bal.currency.upper()
            if curr != base_currency:
                pairs.add((curr, base_currency))
        return pairs

    @staticmethod
    def _sum_positions(
        positions: list[Position],
        base_currency: str,
        fx_by_pair: dict[tuple[str, str], FxRate],
    ) -> Decimal:
        total = Decimal("0")
        for pos in positions:
            value = pos.market_value
            if value is None and pos.last_price is not None:
                value = pos.last_price * pos.quantity
            if value is None:
                continue
            total += PortfolioAggregator._to_base(value, pos.currency, base_currency, fx_by_pair)
        return total

    @staticmethod
    def _sum_balances(
        balances: list[CashBalance],
        base_currency: str,
        fx_by_pair: dict[tuple[str, str], FxRate],
    ) -> Decimal:
        total = Decimal("0")
        for bal in balances:
            total += PortfolioAggregator._to_base(bal.amount, bal.currency, base_currency, fx_by_pair)
        return total

    @staticmethod
    def _sum_unrealized(
        positions: list[Position],
        base_currency: str,
        fx_by_pair: dict[tuple[str, str], FxRate],
    ) -> Decimal:
        total = Decimal("0")
        for pos in positions:
            if pos.unrealized_pnl is None:
                continue
            total += PortfolioAggregator._to_base(
                pos.unrealized_pnl,
                pos.currency,
                base_currency,
                fx_by_pair,
            )
        return total

    @staticmethod
    def _to_base(
        amount: Decimal,
        currency: str,
        base_currency: str,
        fx_by_pair: dict[tuple[str, str], FxRate],
    ) -> Decimal:
        curr = currency.upper()
        if curr == base_currency:
            return amount
        pair = (curr, base_currency)
        fx = fx_by_pair.get(pair)
        if fx is None:
            return Decimal("0")
        return amount * fx.rate


__all__ = [
    "AdapterRegistry",
    "ConnectionRepository",
    "InMemoryConnectionRepository",
    "PortfolioAggregator",
]
