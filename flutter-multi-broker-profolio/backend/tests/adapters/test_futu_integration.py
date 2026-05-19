"""Env-gated integration tests for the Futu adapter.

These tests require a running Futu OpenD gateway and are skipped unless the
``FUTU_OPEND_HOST`` environment variable is set.

To run them locally:

    FUTU_OPEND_HOST=futu-opend \
    FUTU_OPEND_PORT=11111 \
    FUTU_TRADE_PASSWORD=<your-trade-unlock-password> \
    pytest tests/adapters/test_futu_integration.py -v
"""

from __future__ import annotations

import os

import pytest

pytestmark = pytest.mark.skipif(
    not os.getenv("FUTU_OPEND_HOST"),
    reason="Futu OpenD env vars not set",
)


@pytest.mark.asyncio
async def test_list_positions_returns_at_least_one_row() -> None:
    """With a running OpenD gateway, list_positions returns >= 1 position."""
    from app.adapters.futu import FutuAdapter, request_trade_password
    from app.adapters.futu.client import FutuOpenDClient

    host = os.environ["FUTU_OPEND_HOST"]
    port = int(os.getenv("FUTU_OPEND_PORT", "11111"))
    trade_pw = os.getenv("FUTU_TRADE_PASSWORD")

    client = FutuOpenDClient(host=host, port=port)
    adapter = FutuAdapter(client)

    with request_trade_password(trade_pw):
        positions = await adapter.list_positions()

    assert len(positions) >= 1, (
        "Expected at least one position from the Futu OpenD gateway"
    )
    for pos in positions:
        assert pos.symbol, f"Position missing symbol: {pos!r}"
        assert pos.quantity is not None, f"Position missing quantity: {pos!r}"
        assert pos.currency, f"Position missing currency: {pos!r}"


@pytest.mark.asyncio
async def test_list_balances_returns_at_least_one_row() -> None:
    """With a running OpenD gateway, list_balances returns >= 1 cash balance."""
    from app.adapters.futu import FutuAdapter, request_trade_password
    from app.adapters.futu.client import FutuOpenDClient

    host = os.environ["FUTU_OPEND_HOST"]
    port = int(os.getenv("FUTU_OPEND_PORT", "11111"))
    trade_pw = os.getenv("FUTU_TRADE_PASSWORD")

    client = FutuOpenDClient(host=host, port=port)
    adapter = FutuAdapter(client)

    with request_trade_password(trade_pw):
        balances = await adapter.list_balances()

    assert len(balances) >= 1, (
        "Expected at least one cash balance from the Futu OpenD gateway"
    )
    for bal in balances:
        assert bal.currency, f"Balance missing currency: {bal!r}"
        assert bal.amount is not None, f"Balance missing amount: {bal!r}"


@pytest.mark.asyncio
async def test_list_transactions_returns_at_least_one_row() -> None:
    """With a running OpenD gateway, list_transactions returns >= 1 historical deal."""
    from app.adapters.futu import FutuAdapter, request_trade_password
    from app.adapters.futu.client import FutuOpenDClient

    host = os.environ["FUTU_OPEND_HOST"]
    port = int(os.getenv("FUTU_OPEND_PORT", "11111"))
    trade_pw = os.getenv("FUTU_TRADE_PASSWORD")

    client = FutuOpenDClient(host=host, port=port)
    adapter = FutuAdapter(client)

    with request_trade_password(trade_pw):
        txs = await adapter.list_transactions(since=None, limit=None)

    assert len(txs) >= 1, (
        "Expected at least one historical deal from the Futu OpenD gateway"
    )
    for tx in txs:
        assert tx.source == "futu", f"Transaction has wrong source: {tx!r}"
        assert tx.timestamp is not None, f"Transaction missing timestamp: {tx!r}"
