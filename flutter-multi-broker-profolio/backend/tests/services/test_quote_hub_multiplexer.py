"""Tests for QuoteHub multi-source fan-out and WebSocket endpoint integration.

Covers:
- Fan-out from 3 independent sources to a single client queue.
- Clean shutdown on disconnect (unregister_client cancels source tasks).
- WebSocket endpoint accepting two quotes and disconnecting cleanly.
"""

from __future__ import annotations

import asyncio
from collections.abc import AsyncIterator, Iterable
from datetime import UTC, datetime
from decimal import Decimal

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.adapters.base import SourceAdapter
from app.models.domain import (
    CashBalance,
    Position,
    Quote,
    SourceHealth,
    SourceHealthStatus,
    Transaction,
)
from app.services.dependencies import StaticAdapterRegistry, get_quote_hub
from app.services.quote_hub import QuoteHub

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_quote(source: str, symbol: str, price: str = "100") -> Quote:
    return Quote(
        source=source,
        symbol=symbol,
        price=Decimal(price),
        currency="USD",
        timestamp=datetime.now(UTC),
    )


class _SingleQuoteAdapter(SourceAdapter):
    """Yields exactly one quote then blocks indefinitely."""

    def __init__(self, source: str, symbol: str, price: str = "100") -> None:
        self.source = source
        self._symbol = symbol
        self._price = price

    async def list_positions(self) -> list[Position]:
        return []

    async def list_balances(self) -> list[CashBalance]:
        return []

    async def list_transactions(
        self, *, since: str | None = None, limit: int | None = None
    ) -> list[Transaction]:
        _ = (since, limit)
        return []

    async def stream_quotes(self, symbols: Iterable[str]) -> AsyncIterator[Quote]:
        _ = symbols
        yield _make_quote(self.source, self._symbol, self._price)
        # Block so the hub task stays alive until cancelled.
        await asyncio.sleep(3600)

    async def healthcheck(self) -> SourceHealth:
        return SourceHealth(source=self.source, status=SourceHealthStatus.OK)


# ---------------------------------------------------------------------------
# Test: 3-source fan-out interleaved correctly
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_three_source_fan_out_delivers_all_quotes() -> None:
    """All three source adapters contribute one quote each to the client queue."""
    adapters = {
        "longbridge": _SingleQuoteAdapter("longbridge", "AAPL", "180"),
        "binance": _SingleQuoteAdapter("binance", "BTCUSDT", "105000"),
        "futu": _SingleQuoteAdapter("futu", "HK.00700", "500"),
    }
    hub = QuoteHub(
        StaticAdapterRegistry(adapters),
        heartbeat_interval=3600,
        reconnect_delay=0.01,
    )

    queue = await hub.register_client("test-client")
    await hub.subscribe("test-client", source="longbridge", symbols=["AAPL"])
    await hub.subscribe("test-client", source="binance", symbols=["BTCUSDT"])
    await hub.subscribe("test-client", source="futu", symbols=["HK.00700"])

    # Collect the first three messages (one from each source).
    received: list[dict[str, object]] = []
    deadline = asyncio.get_event_loop().time() + 2.0
    while len(received) < 3 and asyncio.get_event_loop().time() < deadline:
        try:
            msg = await asyncio.wait_for(queue.get(), timeout=0.5)
            received.append(msg)
        except TimeoutError:
            break

    assert len(received) == 3, f"Expected 3 quotes, got {len(received)}"

    sources = {m["source"] for m in received}
    assert sources == {"longbridge", "binance", "futu"}

    symbols = {m["symbol"] for m in received}
    assert symbols == {"AAPL", "BTCUSDT", "HK.00700"}

    await hub.aclose()


# ---------------------------------------------------------------------------
# Test: client disconnect cleans up source tasks
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_unregister_client_stops_source_tasks() -> None:
    """After unregister_client the hub has no active source tasks."""
    adapter = _SingleQuoteAdapter("longbridge", "AAPL")
    hub = QuoteHub(
        StaticAdapterRegistry({"longbridge": adapter}),
        heartbeat_interval=3600,
        reconnect_delay=0.01,
    )

    await hub.register_client("c1")
    await hub.subscribe("c1", source="longbridge", symbols=["AAPL"])

    # Give the source task time to start.
    await asyncio.sleep(0.05)
    assert hub.ref_count("longbridge", "AAPL") == 1

    await hub.unregister_client("c1")

    # After unregistering the only client, no symbol is subscribed.
    assert hub.ref_count("longbridge", "AAPL") == 0
    assert hub.active_symbols("longbridge") == set()

    await hub.aclose()


# ---------------------------------------------------------------------------
# Test: WebSocket endpoint emits 2 quotes then closes cleanly
# ---------------------------------------------------------------------------


def test_websocket_endpoint_delivers_two_quotes_then_disconnects(
    app: FastAPI,
) -> None:
    """The /v1/quotes/stream endpoint delivers quotes and shuts down cleanly.

    Messages from the hub can arrive between ACKs, so we collect all frames
    and then assert on the totals rather than assuming strict ordering.
    """
    hub = QuoteHub(
        StaticAdapterRegistry(
            {
                "longbridge": _SingleQuoteAdapter("longbridge", "AAPL", "180"),
                "binance": _SingleQuoteAdapter("binance", "BTCUSDT", "105000"),
            }
        ),
        heartbeat_interval=3600,
        reconnect_delay=0.01,
    )
    app.dependency_overrides[get_quote_hub] = lambda: hub

    acks: list[dict[str, object]] = []
    quotes: list[dict[str, object]] = []

    with TestClient(app) as tc:
        with tc.websocket_connect("/v1/quotes/stream") as ws:
            # Subscribe to one symbol per source.
            ws.send_json(
                {"type": "subscribe", "source": "longbridge", "symbols": ["AAPL"]}
            )
            ws.send_json(
                {"type": "subscribe", "source": "binance", "symbols": ["BTCUSDT"]}
            )

            # Drain frames until we have 2 acks and at least 2 quotes
            # (order is not guaranteed because the hub can deliver quotes
            # between the two ACKs).
            for _ in range(20):
                msg = ws.receive_json()
                if msg.get("type") == "ack":
                    acks.append(msg)
                elif msg.get("type") == "quote":
                    quotes.append(msg)
                if len(acks) >= 2 and len(quotes) >= 2:
                    break

    # Both subscribes were acknowledged.
    assert len(acks) == 2, f"Expected 2 ACKs, got {len(acks)}"
    ack_actions = {a.get("action") for a in acks}
    assert ack_actions == {"subscribe"}

    # At least 2 quotes arrived (one per subscribed source).
    assert len(quotes) >= 2, f"Expected ≥2 quotes, got {len(quotes)}"
    sources_seen = {q["source"] for q in quotes}
    assert "longbridge" in sources_seen
    assert "binance" in sources_seen
