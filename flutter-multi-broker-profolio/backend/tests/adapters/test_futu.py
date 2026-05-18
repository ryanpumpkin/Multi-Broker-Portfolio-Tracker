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
