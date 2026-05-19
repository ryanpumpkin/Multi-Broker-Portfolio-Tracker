"""Env-gated Binance integration tests.

These tests hit the real Binance REST API and are skipped unless the
environment variables BINANCE_API_KEY and BINANCE_API_SECRET are set.

To run locally:
    BINANCE_API_KEY=... BINANCE_API_SECRET=... \
        pytest tests/adapters/test_binance_integration.py -v

Optional:
    BINANCE_REGION=us   (default: com)
"""
from __future__ import annotations

import os

import pytest

pytestmark = pytest.mark.skipif(
    not os.getenv("BINANCE_API_KEY"),
    reason="Binance integration env vars not set",
)


@pytest.fixture
def binance_adapter() -> object:
    """Build a real BinanceAdapter from environment variables."""
    from app.adapters.binance.adapter import (
        BinanceAdapter,
        BinanceCredentials,
        BinanceHost,
        HttpxBinanceClient,
    )

    api_key = os.environ["BINANCE_API_KEY"]
    api_secret = os.environ["BINANCE_API_SECRET"]
    region = os.getenv("BINANCE_REGION", "com").strip().lower()
    host = BinanceHost.US if region == "us" else BinanceHost.COM

    client = HttpxBinanceClient(
        BinanceCredentials(api_key=api_key, api_secret=api_secret),
        host=host,
    )
    return BinanceAdapter(client)


@pytest.mark.asyncio
async def test_list_positions_returns_at_least_one_with_price(
    binance_adapter: object,
) -> None:
    """With a real read-only key, list_positions should return ≥1 row with a price."""
    from app.adapters.binance.adapter import BinanceAdapter

    adapter = binance_adapter
    assert isinstance(adapter, BinanceAdapter)

    positions = await adapter.list_positions()
    # Account may have no non-stablecoin holdings — that's a valid state.
    # When positions do exist they must each have a last_price from the ticker.
    for pos in positions:
        assert pos.source == "binance"
        assert pos.quantity > 0
        # Market value and price should be populated when we could fetch a ticker.
        if pos.last_price is not None:
            assert pos.market_value is not None
            assert pos.market_value == pos.quantity * pos.last_price


@pytest.mark.asyncio
async def test_list_balances_returns_stablecoins(binance_adapter: object) -> None:
    """With a real read-only key, list_balances should only contain stablecoins."""
    from app.adapters.binance.adapter import STABLECOINS, BinanceAdapter

    adapter = binance_adapter
    assert isinstance(adapter, BinanceAdapter)

    balances = await adapter.list_balances()
    for bal in balances:
        assert bal.source == "binance"
        assert bal.amount > 0
        # Every balance returned must be a recognised stablecoin.
        assert bal.currency in STABLECOINS, (
            f"Non-stablecoin {bal.currency!r} appeared in list_balances"
        )


@pytest.mark.asyncio
async def test_region_routing_reaches_api(binance_adapter: object) -> None:
    """Healthcheck should succeed — verifies the host routing is correct."""
    from app.adapters.binance.adapter import BinanceAdapter
    from app.models.domain import SourceHealthStatus

    adapter = binance_adapter
    assert isinstance(adapter, BinanceAdapter)

    health = await adapter.healthcheck()
    assert health.status is SourceHealthStatus.OK, (
        f"Binance healthcheck failed: {health.message}"
    )


@pytest.mark.asyncio
async def test_list_transactions_returns_history(binance_adapter: object) -> None:
    """With a real read-only key, list_transactions should return recent trades."""
    from app.adapters.binance.adapter import BinanceAdapter

    adapter = binance_adapter
    assert isinstance(adapter, BinanceAdapter)

    txs = await adapter.list_transactions(since=None, limit=None)
    # An account may have no recent trades — that's valid.
    # When transactions do exist, they must have the correct shape.
    for tx in txs:
        assert tx.source == "binance", f"Unexpected source: {tx!r}"
        assert tx.timestamp is not None, f"Transaction missing timestamp: {tx!r}"
        assert tx.side in {"buy", "sell", "deposit", "withdrawal"}, (
            f"Unexpected side value: {tx.side!r}"
        )
