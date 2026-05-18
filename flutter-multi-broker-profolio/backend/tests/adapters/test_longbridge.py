"""Tests for the LongBridge adapter using a fake SDK client."""

from __future__ import annotations

from collections.abc import AsyncIterator
from decimal import Decimal
from typing import Any

import pytest

from app.adapters._common import RetryPolicy, TransientError
from app.adapters.longbridge import LongBridgeAdapter
from app.models.domain import SourceHealthStatus


class FakeLBClient:
    def __init__(
        self,
        *,
        positions: list[dict[str, Any]] | None = None,
        balances: list[dict[str, Any]] | None = None,
        transactions: list[dict[str, Any]] | None = None,
        quotes: list[dict[str, Any]] | None = None,
        fail_positions: int = 0,
        refresh_raises: Exception | None = None,
    ) -> None:
        self._positions = positions or []
        self._balances = balances or []
        self._transactions = transactions or []
        self._quotes = quotes or []
        self._fail_positions = fail_positions
        self._refresh_raises = refresh_raises
        self.refresh_calls = 0
        self.position_calls = 0

    async def fetch_positions(self) -> list[dict[str, Any]]:
        self.position_calls += 1
        if self._fail_positions > 0:
            self._fail_positions -= 1
            raise TransientError("rate-limited")
        return self._positions

    async def fetch_balances(self) -> list[dict[str, Any]]:
        return self._balances

    async def fetch_transactions(
        self, *, since: str | None, limit: int | None
    ) -> list[dict[str, Any]]:
        return self._transactions

    async def subscribe_quotes(self, symbols: list[str]) -> AsyncIterator[dict[str, Any]]:
        for q in self._quotes:
            yield q

    async def refresh_token(self) -> None:
        self.refresh_calls += 1
        if self._refresh_raises is not None:
            raise self._refresh_raises


def _no_jitter() -> RetryPolicy:
    return RetryPolicy(max_attempts=5, initial_delay=0.0, jitter=0.0)


@pytest.mark.asyncio
async def test_list_positions_maps_fields() -> None:
    client = FakeLBClient(
        positions=[
            {
                "symbol": "700.HK",
                "market": "HK",
                "quantity": "100",
                "cost_price": "300",
                "last_price": "350",
                "currency": "HKD",
                "account_no": "acc-1",
            }
        ]
    )
    adapter = LongBridgeAdapter(client, retry=_no_jitter())
    positions = await adapter.list_positions()
    assert len(positions) == 1
    p = positions[0]
    assert p.source == "longbridge"
    assert p.symbol == "700.HK"
    assert p.quantity == Decimal("100")
    assert p.market_value == Decimal("35000")
    assert p.unrealized_pnl == Decimal("5000")


@pytest.mark.asyncio
async def test_list_balances_and_transactions() -> None:
    client = FakeLBClient(
        balances=[{"currency": "HKD", "total_cash": "12345.67"}],
        transactions=[
            {
                "order_id": "ord-1",
                "symbol": "AAPL.US",
                "side": "Buy",
                "quantity": "10",
                "price": "150.00",
                "currency": "USD",
                "amount": "1500.00",
                "submitted_at": "2025-01-02T03:04:05Z",
            }
        ],
    )
    adapter = LongBridgeAdapter(client, retry=_no_jitter())
    balances = await adapter.list_balances()
    assert balances[0].amount == Decimal("12345.67")

    txs = await adapter.list_transactions(since=None, limit=10)
    assert txs[0].transaction_id == "ord-1"
    assert txs[0].side == "buy"
    assert txs[0].timestamp.year == 2025


@pytest.mark.asyncio
async def test_retries_transient_then_succeeds() -> None:
    client = FakeLBClient(
        positions=[
            {
                "symbol": "X",
                "quantity": "1",
                "currency": "USD",
            }
        ],
        fail_positions=2,
    )
    adapter = LongBridgeAdapter(client, retry=_no_jitter())
    out = await adapter.list_positions()
    assert client.position_calls == 3
    assert out[0].symbol == "X"


@pytest.mark.asyncio
async def test_stream_quotes() -> None:
    client = FakeLBClient(
        quotes=[
            {
                "symbol": "AAPL.US",
                "last_done": "150.50",
                "currency": "USD",
                "timestamp": "2025-01-02T03:04:05+00:00",
            }
        ]
    )
    adapter = LongBridgeAdapter(client, retry=_no_jitter())
    seen = [q async for q in adapter.stream_quotes(["AAPL.US"])]
    assert seen[0].price == Decimal("150.50")


@pytest.mark.asyncio
async def test_healthcheck_records_success_and_failure() -> None:
    ok_client = FakeLBClient()
    adapter = LongBridgeAdapter(ok_client, retry=_no_jitter())
    snap = await adapter.healthcheck()
    assert snap.status is SourceHealthStatus.OK

    bad_client = FakeLBClient(refresh_raises=RuntimeError("bad token"))
    adapter = LongBridgeAdapter(bad_client, retry=_no_jitter())
    snap = await adapter.healthcheck()
    assert snap.status is not SourceHealthStatus.OK
    assert snap.message is not None and "bad token" in snap.message
