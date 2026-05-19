"""Tests for the Futu adapter."""

from __future__ import annotations

from collections.abc import AsyncIterator
from decimal import Decimal
from typing import Any

import pytest

from app.adapters._common import PermanentError, RetryPolicy
from app.adapters.futu import FutuAdapter, request_trade_password
from app.models.domain import SourceHealthStatus


class FakeFutuClient:
    def __init__(
        self,
        *,
        positions: list[dict[str, Any]] | None = None,
        accounts: list[dict[str, Any]] | None = None,
        orders: list[dict[str, Any]] | None = None,
        quotes: list[dict[str, Any]] | None = None,
        unlock_raises: Exception | None = None,
        fail_positions: int = 0,
        ping_result: bool = True,
        ping_raises: Exception | None = None,
    ) -> None:
        self._positions = positions or []
        self._accounts = accounts or []
        self._orders = orders or []
        self._quotes = quotes or []
        self._unlock_raises = unlock_raises
        self._fail_positions = fail_positions
        self._ping_result = ping_result
        self._ping_raises = ping_raises
        self.unlock_calls = 0
        self.lock_calls = 0
        self.position_calls = 0

    async def unlock_trade(self, password: str) -> None:
        self.unlock_calls += 1
        if self._unlock_raises is not None:
            raise self._unlock_raises

    async def lock_trade(self) -> None:
        self.lock_calls += 1

    async def fetch_positions(self) -> list[dict[str, Any]]:
        self.position_calls += 1
        if self._fail_positions > 0:
            self._fail_positions -= 1
            raise RuntimeError("rate limit")
        return self._positions

    async def fetch_accounts(self) -> list[dict[str, Any]]:
        return self._accounts

    async def fetch_history_deals(
        self, *, since: str | None, limit: int | None
    ) -> list[dict[str, Any]]:
        return self._orders

    async def subscribe_quotes(self, symbols: list[str]) -> AsyncIterator[dict[str, Any]]:
        for q in self._quotes:
            yield q

    async def ping(self) -> bool:
        if self._ping_raises is not None:
            raise self._ping_raises
        return self._ping_result


def _no_jitter() -> RetryPolicy:
    return RetryPolicy(max_attempts=2, initial_delay=0.0, jitter=0.0)


@pytest.mark.asyncio
async def test_positions_with_unlock_relocks() -> None:
    client = FakeFutuClient(
        positions=[
            {
                "acc_id": 99,
                "code": "HK.00700",
                "trd_market": "HK",
                "qty": "100",
                "cost_price": "300",
                "nominal_price": "350",
                "market_val": "35000",
                "pl_val": "5000",
                "currency": "HKD",
            }
        ]
    )
    adapter = FutuAdapter(client, retry=_no_jitter())
    with request_trade_password("pw"):
        positions = await adapter.list_positions()
    assert positions[0].symbol == "HK.00700"
    assert positions[0].quantity == Decimal("100")
    assert client.unlock_calls == 1
    assert client.lock_calls == 1


@pytest.mark.asyncio
async def test_balances_without_password_does_not_unlock() -> None:
    client = FakeFutuClient(
        accounts=[{"acc_id": 1, "currency": "HKD", "cash": "1000"}]
    )
    adapter = FutuAdapter(client, retry=_no_jitter())
    balances = await adapter.list_balances()
    assert balances[0].amount == Decimal("1000")
    assert client.unlock_calls == 0
    assert client.lock_calls == 0


@pytest.mark.asyncio
async def test_transactions_mapping() -> None:
    client = FakeFutuClient(
        orders=[
            {
                "acc_id": 1,
                "order_id": "o-1",
                "code": "HK.00700",
                "trd_side": "BUY",
                "qty": "100",
                "price": "350",
                "currency": "HKD",
                "dealt_amount": "35000",
                "create_time": "2025-01-02T03:04:05+00:00",
            }
        ]
    )
    adapter = FutuAdapter(client, retry=_no_jitter())
    txs = await adapter.list_transactions()
    assert txs[0].transaction_id == "o-1"
    assert txs[0].side == "buy"


@pytest.mark.asyncio
async def test_retries_rate_limited_call_then_succeeds() -> None:
    client = FakeFutuClient(
        positions=[
            {
                "code": "HK.00700",
                "qty": "1",
                "currency": "HKD",
            }
        ],
        fail_positions=2,
    )
    adapter = FutuAdapter(client, retry=RetryPolicy(max_attempts=5, initial_delay=0.0, jitter=0.0))
    rows = await adapter.list_positions()
    assert client.position_calls == 3
    assert rows[0].symbol == "HK.00700"


@pytest.mark.asyncio
async def test_stream_quotes_and_health() -> None:
    client = FakeFutuClient(
        quotes=[
            {
                "code": "HK.00700",
                "last_price": "350",
                "currency": "HKD",
                "timestamp": "2025-01-02T00:00:00+00:00",
            }
        ]
    )
    adapter = FutuAdapter(client, retry=_no_jitter())
    quotes = [q async for q in adapter.stream_quotes(["HK.00700"])]
    assert quotes[0].price == Decimal("350")

    snap = await adapter.healthcheck()
    assert snap.status is SourceHealthStatus.OK

    bad = FutuAdapter(
        FakeFutuClient(ping_result=False), retry=_no_jitter()
    )
    snap = await bad.healthcheck()
    assert snap.status is not SourceHealthStatus.OK

    boom = FutuAdapter(
        FakeFutuClient(ping_raises=RuntimeError("opend down")), retry=_no_jitter()
    )
    snap = await boom.healthcheck()
    assert snap.message is not None and "opend down" in snap.message


@pytest.mark.asyncio
async def test_unlock_failure_propagates_and_relocks_skipped() -> None:
    client = FakeFutuClient(unlock_raises=RuntimeError("bad password"))
    adapter = FutuAdapter(client, retry=_no_jitter())
    with pytest.raises(PermanentError):
        with request_trade_password("pw"):
            await adapter.list_positions()
    assert client.unlock_calls >= 1
    # lock_trade is not called because unlock raised before entering the with body.
    assert client.lock_calls == 0


# ---------------------------------------------------------------------------
# Mapping verification against real SDK response shapes (doc/BROKER_INTEGRATION_DETAILS.md §C.4)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_list_positions_sdk_shape_hk_stock() -> None:
    """Verify HK stock position row (market prefix kept for symbol, pl_ratio ignored)."""
    client = FakeFutuClient(
        positions=[
            {
                "position_side": "LONG",
                "code": "HK.00700",
                "stock_name": "騰訊控股",
                "qty": 100,
                "can_sell_qty": 100,
                "currency": "HKD",
                "nominal_price": 500.50,
                "cost_price": 480.30,
                "market_val": 50050.00,
                "pl_val": 2020.00,
                "pl_ratio": 4.21,
            }
        ]
    )
    adapter = FutuAdapter(client, retry=_no_jitter())
    positions = await adapter.list_positions()

    assert len(positions) == 1
    p = positions[0]
    assert p.source == "futu"
    assert p.symbol == "HK.00700"
    assert p.currency == "HKD"
    assert p.quantity == Decimal("100")
    assert p.last_price == Decimal("500.5")
    assert p.avg_cost == Decimal("480.3")
    assert p.market_value == Decimal("50050.00")
    assert p.unrealized_pnl == Decimal("2020.00")
    # pl_ratio is not in the domain model; no error when present in raw row
    assert p.account_id is None


@pytest.mark.asyncio
async def test_list_positions_sdk_shape_us_stock() -> None:
    """Verify US stock position row."""
    client = FakeFutuClient(
        positions=[
            {
                "position_side": "LONG",
                "code": "US.AAPL",
                "stock_name": "Apple Inc",
                "qty": 50,
                "can_sell_qty": 50,
                "currency": "USD",
                "nominal_price": 180.20,
                "cost_price": 175.50,
                "market_val": 9010.00,
                "pl_val": 235.00,
                "pl_ratio": 2.68,
            }
        ]
    )
    adapter = FutuAdapter(client, retry=_no_jitter())
    positions = await adapter.list_positions()

    assert len(positions) == 1
    p = positions[0]
    assert p.symbol == "US.AAPL"
    assert p.currency == "USD"
    assert p.quantity == Decimal("50")
    assert p.last_price == Decimal("180.2")
    assert p.avg_cost == Decimal("175.5")
    assert p.market_value == Decimal("9010.00")
    assert p.unrealized_pnl == Decimal("235.00")


@pytest.mark.asyncio
async def test_list_positions_empty_dataframe_returns_empty_list() -> None:
    """Empty position list (0, N) shape should return [] without error."""
    client = FakeFutuClient(positions=[])
    adapter = FutuAdapter(client, retry=_no_jitter())
    positions = await adapter.list_positions()
    assert positions == []


@pytest.mark.asyncio
async def test_list_balances_sdk_shape_uses_available_funds() -> None:
    """accinfo_query row: use available_funds (not cash)."""
    client = FakeFutuClient(
        accounts=[
            {
                "currency": "HKD",
                "cash": 50000.00,
                "total_assets": 51500.00,
                "available_funds": 49500.00,  # should use this, not cash
                "frozen_cash": 500.00,
                "market_val": 1500.00,
                "realized_pl": 0.00,
                "unrealized_pl": 150.00,
            }
        ]
    )
    adapter = FutuAdapter(client, retry=_no_jitter())
    balances = await adapter.list_balances()

    assert len(balances) == 1
    b = balances[0]
    assert b.source == "futu"
    assert b.currency == "HKD"
    assert b.amount == Decimal("49500.00")


@pytest.mark.asyncio
async def test_list_balances_multiple_currencies() -> None:
    """accinfo_query returns one row per currency; all should be returned."""
    client = FakeFutuClient(
        accounts=[
            {
                "currency": "HKD",
                "cash": 50000.00,
                "available_funds": 50000.00,
            },
            {
                "currency": "USD",
                "cash": 10000.00,
                "available_funds": 9800.00,
            },
        ]
    )
    adapter = FutuAdapter(client, retry=_no_jitter())
    balances = await adapter.list_balances()

    assert len(balances) == 2
    currencies = {b.currency for b in balances}
    assert currencies == {"HKD", "USD"}
    by_currency = {b.currency: b for b in balances}
    assert by_currency["HKD"].amount == Decimal("50000.00")
    assert by_currency["USD"].amount == Decimal("9800.00")


@pytest.mark.asyncio
async def test_list_balances_falls_back_to_cash_when_available_funds_missing() -> None:
    """When available_funds is absent, fall back to cash."""
    client = FakeFutuClient(
        accounts=[{"currency": "SGD", "cash": 8000.00}]
    )
    adapter = FutuAdapter(client, retry=_no_jitter())
    balances = await adapter.list_balances()
    assert balances[0].currency == "SGD"
    assert balances[0].amount == Decimal("8000.00")


@pytest.mark.asyncio
async def test_unlock_lifecycle_calls_lock_after_success() -> None:
    """Verify unlock → query → lock sequence runs exactly once per call."""
    client = FakeFutuClient(
        positions=[
            {
                "code": "HK.00001",
                "qty": "10",
                "currency": "HKD",
                "nominal_price": "10",
                "cost_price": "9",
                "market_val": "100",
                "pl_val": "10",
            }
        ]
    )
    adapter = FutuAdapter(client, retry=_no_jitter())
    with request_trade_password("s3cret"):
        await adapter.list_positions()

    assert client.unlock_calls == 1
    assert client.lock_calls == 1


@pytest.mark.asyncio
async def test_unlock_lifecycle_no_password_skips_unlock_and_lock() -> None:
    """With no trade password in context, unlock/lock must not be called."""
    client = FakeFutuClient(
        accounts=[{"currency": "HKD", "available_funds": "1000"}]
    )
    adapter = FutuAdapter(client, retry=_no_jitter())
    # No request_trade_password context → no unlock
    await adapter.list_balances()
    assert client.unlock_calls == 0
    assert client.lock_calls == 0


@pytest.mark.asyncio
async def test_unlock_password_not_accessible_outside_context() -> None:
    """Trade password context var must be None outside the request_trade_password block."""
    from app.adapters.futu import get_request_trade_password

    # Before setting
    assert get_request_trade_password() is None

    with request_trade_password("pw"):
        assert get_request_trade_password() == "pw"

    # After exiting the context, it must be reset
    assert get_request_trade_password() is None


@pytest.mark.asyncio
async def test_history_deals_sdk_shape() -> None:
    """history_deal_list_query row maps correctly to Transaction."""
    client = FakeFutuClient(
        orders=[
            {
                "trd_side": "BUY",
                "order_id": "20260501000001",
                "deal_id": "20260501999999",
                "code": "HK.00700",
                "stock_name": "騰訊控股",
                "qty": 100,
                "price": 480.30,
                "create_time": "2026-05-01 10:15:20",
                "acc_id": 42,
            }
        ]
    )
    adapter = FutuAdapter(client, retry=_no_jitter())
    txs = await adapter.list_transactions()

    assert len(txs) == 1
    t = txs[0]
    assert t.source == "futu"
    assert t.transaction_id == "20260501000001"
    assert t.symbol == "HK.00700"
    assert t.side == "buy"
    assert t.quantity == Decimal("100")
    assert t.price == Decimal("480.30")
    assert t.account_id == "42"
