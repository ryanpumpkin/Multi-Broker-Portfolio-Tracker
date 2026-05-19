"""Env-gated integration tests for the IBKR adapter.

These tests require a running IBKR Client Portal Gateway and are skipped
unless the ``IBKR_GATEWAY_HOST`` environment variable is set.

To run them locally:

    IBKR_GATEWAY_HOST=ibkr-gateway \
    IBKR_GATEWAY_PORT=7497 \
    IBKR_ACCOUNT_ID=U1234567 \
    pytest tests/adapters/test_ibkr_integration.py -v
"""

from __future__ import annotations

import os

import pytest

from app.adapters.ibkr import IbkrAdapter, IBKRClient

pytestmark = pytest.mark.skipif(
    not os.getenv("IBKR_GATEWAY_HOST"),
    reason="IBKR gateway env vars not set",
)


@pytest.mark.asyncio
async def test_list_positions_returns_at_least_one_stk_position() -> None:
    """With a running gateway, list_positions should return >= 1 STK position."""
    host = os.environ["IBKR_GATEWAY_HOST"]
    port = int(os.getenv("IBKR_GATEWAY_PORT", "7497"))
    account_id = os.getenv("IBKR_ACCOUNT_ID") or None

    client = IBKRClient(host=host, port=port, account_id=account_id)
    adapter = IbkrAdapter(client)

    positions = await adapter.list_positions()

    assert len(positions) >= 1, (
        "Expected at least one STK position from the IBKR gateway"
    )
    # All returned positions must be equities (secType filter applied upstream
    # in fetch_positions — the adapter enforces STK-only for v1 scope).
    for pos in positions:
        assert pos.symbol, f"Position missing symbol: {pos!r}"
        assert pos.quantity is not None
        assert pos.currency


@pytest.mark.asyncio
async def test_list_balances_returns_cash_balances() -> None:
    """With a running gateway, list_balances should return >= 1 cash balance."""
    host = os.environ["IBKR_GATEWAY_HOST"]
    port = int(os.getenv("IBKR_GATEWAY_PORT", "7497"))
    account_id = os.getenv("IBKR_ACCOUNT_ID") or None

    client = IBKRClient(host=host, port=port, account_id=account_id)
    adapter = IbkrAdapter(client)

    balances = await adapter.list_balances()

    assert len(balances) >= 1, (
        "Expected at least one cash balance from the IBKR gateway"
    )
    for bal in balances:
        assert bal.currency
        assert bal.amount is not None


@pytest.mark.asyncio
async def test_list_transactions_returns_historical_fills() -> None:
    """With a running gateway, list_transactions should return recent fill executions."""
    host = os.environ["IBKR_GATEWAY_HOST"]
    port = int(os.getenv("IBKR_GATEWAY_PORT", "7497"))
    account_id = os.getenv("IBKR_ACCOUNT_ID") or None

    client = IBKRClient(host=host, port=port, account_id=account_id)
    adapter = IbkrAdapter(client)

    txs = await adapter.list_transactions(since=None, limit=None)
    # An account may have no recent fills — that's valid.
    # When transactions exist, verify shape.
    for tx in txs:
        assert tx.source == "ibkr", f"Unexpected source: {tx!r}"
        assert tx.timestamp is not None, f"Transaction missing timestamp: {tx!r}"
        assert tx.side in {"buy", "sell"}, f"Unexpected side value: {tx.side!r}"
