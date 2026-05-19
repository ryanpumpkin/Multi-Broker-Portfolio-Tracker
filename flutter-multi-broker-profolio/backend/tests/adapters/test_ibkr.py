"""Tests for the IBKR adapter."""

from __future__ import annotations

import asyncio
from collections.abc import AsyncIterator
from decimal import Decimal
from typing import Any

import pytest

from app.adapters._common import PermanentError, RetryPolicy, TransientError
from app.adapters.ibkr import IbkrAdapter
from app.models.domain import SourceHealthStatus


class FakeIbkrClient:
    def __init__(
        self,
        *,
        positions: list[dict[str, Any]] | None = None,
        accounts: list[dict[str, Any]] | None = None,
        executions: list[dict[str, Any]] | None = None,
        quotes: list[dict[str, Any]] | None = None,
        tickle_result: bool = True,
        tickle_raises: Exception | None = None,
        fail_positions: int = 0,
        position_error: Exception | None = None,
    ) -> None:
        self._positions = positions or []
        self._accounts = accounts or []
        self._executions = executions or []
        self._quotes = quotes or []
        self._tickle_result = tickle_result
        self._tickle_raises = tickle_raises
        self._fail_positions = fail_positions
        self._position_error = position_error
        self.tickle_calls = 0
        self.position_calls = 0

    async def tickle(self) -> bool:
        self.tickle_calls += 1
        if self._tickle_raises is not None:
            raise self._tickle_raises
        return self._tickle_result

    async def fetch_positions(self) -> list[dict[str, Any]]:
        self.position_calls += 1
        if self._position_error is not None:
            raise self._position_error
        if self._fail_positions > 0:
            self._fail_positions -= 1
            raise TransientError("rate-limited")
        return self._positions

    async def fetch_account_summary(self) -> list[dict[str, Any]]:
        return self._accounts

    async def fetch_executions(
        self, *, since: str | None, limit: int | None
    ) -> list[dict[str, Any]]:
        return self._executions

    async def stream_market_data(self, symbols: list[str]) -> AsyncIterator[dict[str, Any]]:
        for q in self._quotes:
            yield q


def _no_jitter() -> RetryPolicy:
    return RetryPolicy(max_attempts=3, initial_delay=0.0, jitter=0.0)


@pytest.mark.asyncio
async def test_positions_and_balances_mapping() -> None:
    client = FakeIbkrClient(
        positions=[
            {
                "acctId": "U1",
                "contractDesc": "AAPL",
                "listingExchange": "NASDAQ",
                "position": "10",
                "avgCost": "150",
                "mktPrice": "170",
                "mktValue": "1700",
                "unrealizedPnl": "200",
                "currency": "USD",
            }
        ],
        accounts=[{"acctId": "U1", "currency": "USD", "cashBalance": "1000"}],
    )
    adapter = IbkrAdapter(client, retry=_no_jitter())
    positions = await adapter.list_positions()
    assert positions[0].symbol == "AAPL"
    assert positions[0].market_value == Decimal("1700")

    balances = await adapter.list_balances()
    assert balances[0].amount == Decimal("1000")


@pytest.mark.asyncio
async def test_list_positions_calls_tickle_first() -> None:
    """tickle() must be called before fetch_positions() on every request."""
    client = FakeIbkrClient(
        positions=[
            {
                "acctId": "U1",
                "contractDesc": "AAPL",
                "position": "5",
                "currency": "USD",
                "secType": "STK",
            }
        ]
    )
    adapter = IbkrAdapter(client, retry=_no_jitter())
    await adapter.list_positions()
    assert client.tickle_calls == 1


@pytest.mark.asyncio
async def test_list_balances_calls_tickle_first() -> None:
    """tickle() must be called before fetch_account_summary() on every request."""
    client = FakeIbkrClient(
        accounts=[{"acctId": "U1", "currency": "USD", "cashBalance": "500"}]
    )
    adapter = IbkrAdapter(client, retry=_no_jitter())
    await adapter.list_balances()
    assert client.tickle_calls == 1


@pytest.mark.asyncio
async def test_non_stk_positions_filtered_out() -> None:
    """Only secType == 'STK' positions should be returned (v1 scope)."""
    client = FakeIbkrClient(
        positions=[
            {
                "acctId": "U1",
                "contractDesc": "AAPL",
                "position": "10",
                "avgCost": "150",
                "currency": "USD",
                "secType": "STK",
            },
            {
                "acctId": "U1",
                "contractDesc": "EUR.USD",
                "position": "5000",
                "avgCost": "1.08",
                "currency": "USD",
                "secType": "CASH",
            },
            {
                "acctId": "U1",
                "contractDesc": "AAPL   DEC2026",
                "position": "3",
                "avgCost": "800",
                "currency": "USD",
                "secType": "OPT",
            },
            {
                "acctId": "U1",
                "contractDesc": "ES",
                "position": "1",
                "avgCost": "5100",
                "currency": "USD",
                "secType": "FUT",
            },
        ]
    )
    adapter = IbkrAdapter(client, retry=_no_jitter())
    positions = await adapter.list_positions()
    assert len(positions) == 1
    assert positions[0].symbol == "AAPL"


@pytest.mark.asyncio
async def test_positions_without_sectype_included() -> None:
    """Positions with secType=None (e.g. older rows missing the field) pass through."""
    client = FakeIbkrClient(
        positions=[
            {
                "acctId": "U1",
                "contractDesc": "GOOG",
                "position": "2",
                "currency": "USD",
            }
        ]
    )
    adapter = IbkrAdapter(client, retry=_no_jitter())
    positions = await adapter.list_positions()
    assert len(positions) == 1
    assert positions[0].symbol == "GOOG"


@pytest.mark.asyncio
async def test_market_value_fallback_tiers() -> None:
    """Three-tier fallback: explicit mktValue -> last_price*qty -> avg_cost*qty."""
    # Tier 2: last_price * quantity when mktValue absent.
    client = FakeIbkrClient(
        positions=[
            {
                "acctId": "U1",
                "contractDesc": "MSFT",
                "position": "4",
                "avgCost": "300",
                "mktPrice": "320",
                "currency": "USD",
                "secType": "STK",
            }
        ]
    )
    adapter = IbkrAdapter(client, retry=_no_jitter())
    positions = await adapter.list_positions()
    assert positions[0].market_value == Decimal("4") * Decimal("320")

    # Tier 3: avg_cost * quantity when both mktValue and mktPrice absent.
    client2 = FakeIbkrClient(
        positions=[
            {
                "acctId": "U1",
                "contractDesc": "NVDA",
                "position": "3",
                "avgCost": "200",
                "currency": "USD",
                "secType": "STK",
            }
        ]
    )
    adapter2 = IbkrAdapter(client2, retry=_no_jitter())
    positions2 = await adapter2.list_positions()
    assert positions2[0].market_value == Decimal("3") * Decimal("200")


@pytest.mark.asyncio
async def test_cost_basis_is_avg_cost_per_share() -> None:
    """avgCost is the per-share cost; cost_basis field = avgCost (stored in avg_cost)."""
    client = FakeIbkrClient(
        positions=[
            {
                "acctId": "U1",
                "contractDesc": "TSLA",
                "position": "10",
                "avgCost": "185.50",
                "mktValue": "1950",
                "currency": "USD",
                "secType": "STK",
            }
        ]
    )
    adapter = IbkrAdapter(client, retry=_no_jitter())
    positions = await adapter.list_positions()
    assert positions[0].avg_cost == Decimal("185.50")
    # market_value from explicit mktValue field, not recomputed
    assert positions[0].market_value == Decimal("1950")


@pytest.mark.asyncio
async def test_balances_multiple_currencies() -> None:
    """Multiple currencies appear as separate CashBalance rows."""
    client = FakeIbkrClient(
        accounts=[
            {"acctId": "U1", "currency": "USD", "cashBalance": "12345.67"},
            {"acctId": "U1", "currency": "HKD", "cashBalance": "8000.00"},
        ]
    )
    adapter = IbkrAdapter(client, retry=_no_jitter())
    balances = await adapter.list_balances()
    assert len(balances) == 2
    currencies = {b.currency for b in balances}
    assert currencies == {"USD", "HKD"}


@pytest.mark.asyncio
async def test_positions_retries_transient_then_succeeds() -> None:
    client = FakeIbkrClient(
        positions=[
            {
                "acctId": "U1",
                "contractDesc": "MSFT",
                "position": "5",
                "currency": "USD",
            }
        ],
        fail_positions=2,
    )
    adapter = IbkrAdapter(client, retry=RetryPolicy(max_attempts=5, initial_delay=0.0, jitter=0.0))
    out = await adapter.list_positions()
    assert out[0].symbol == "MSFT"
    assert client.position_calls == 3


@pytest.mark.asyncio
async def test_positions_credential_error_is_permanent() -> None:
    client = FakeIbkrClient(position_error=PermanentError("invalid credentials"))
    adapter = IbkrAdapter(client, retry=RetryPolicy(max_attempts=5, initial_delay=0.0, jitter=0.0))
    with pytest.raises(PermanentError):
        await adapter.list_positions()
    assert client.position_calls == 1


@pytest.mark.asyncio
async def test_transactions_mapping() -> None:
    client = FakeIbkrClient(
        executions=[
            {
                "execId": "exec-1",
                "symbol": "AAPL",
                "side": "BUY",
                "size": "10",
                "price": "150",
                "currency": "USD",
                "net_amount": "1500",
                "time": 1700000000,
            }
        ]
    )
    adapter = IbkrAdapter(client, retry=_no_jitter())
    txs = await adapter.list_transactions()
    assert txs[0].side == "buy"
    assert txs[0].transaction_id == "exec-1"
    assert txs[0].timestamp.year == 2023


@pytest.mark.asyncio
async def test_stream_quotes() -> None:
    client = FakeIbkrClient(
        quotes=[{"symbol": "AAPL", "last": "170", "currency": "USD", "t": 1700000000}]
    )
    adapter = IbkrAdapter(client, retry=_no_jitter())
    out = [q async for q in adapter.stream_quotes(["AAPL"])]
    assert out[0].price == Decimal("170")


@pytest.mark.asyncio
async def test_healthcheck_paths() -> None:
    adapter = IbkrAdapter(FakeIbkrClient(tickle_result=True), retry=_no_jitter())
    snap = await adapter.healthcheck()
    assert snap.status is SourceHealthStatus.OK

    adapter = IbkrAdapter(FakeIbkrClient(tickle_result=False), retry=_no_jitter())
    snap = await adapter.healthcheck()
    assert snap.status is not SourceHealthStatus.OK

    adapter = IbkrAdapter(
        FakeIbkrClient(tickle_raises=RuntimeError("net down")), retry=_no_jitter()
    )
    snap = await adapter.healthcheck()
    assert snap.message is not None and "net down" in snap.message


@pytest.mark.asyncio
async def test_keepalive_loop_calls_tickle_and_stops() -> None:
    client = FakeIbkrClient(tickle_result=True)
    adapter = IbkrAdapter(client, retry=_no_jitter(), keepalive_interval=0.001)
    task = adapter.start_keepalive()
    # Idempotent — calling again returns the same task.
    assert adapter.start_keepalive() is task
    await asyncio.sleep(0.02)
    await adapter.stop_keepalive()
    assert client.tickle_calls >= 1
    # Calling stop again is a no-op.
    await adapter.stop_keepalive()


@pytest.mark.asyncio
async def test_keepalive_records_failure_and_keeps_looping() -> None:
    client = FakeIbkrClient(tickle_raises=RuntimeError("boom"))
    adapter = IbkrAdapter(client, retry=_no_jitter(), keepalive_interval=0.001)
    adapter.start_keepalive()
    await asyncio.sleep(0.02)
    await adapter.stop_keepalive()
    assert client.tickle_calls >= 1
