"""API tests for /v1/quotes/stream WebSocket route."""

from __future__ import annotations

import asyncio
from collections.abc import AsyncIterator
from datetime import UTC, datetime
from decimal import Decimal

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


class _FakeQuoteAdapter(SourceAdapter):
    source = "longbridge"

    async def list_positions(self) -> list[Position]:
        return []

    async def list_balances(self) -> list[CashBalance]:
        return []

    async def list_transactions(
        self, *, since: str | None = None, limit: int | None = None
    ) -> list[Transaction]:
        _ = (since, limit)
        return []

    async def stream_quotes(self, symbols: list[str]) -> AsyncIterator[Quote]:
        _ = symbols
        yield Quote(
            source="longbridge",
            symbol="AAPL",
            price=Decimal("123"),
            currency="USD",
            timestamp=datetime.now(UTC),
        )
        await asyncio.sleep(3600)

    async def healthcheck(self) -> SourceHealth:
        return SourceHealth(source="longbridge", status=SourceHealthStatus.OK)


def test_quotes_websocket_subscribe_unsubscribe_and_ping(app: FastAPI) -> None:
    hub = QuoteHub(
        StaticAdapterRegistry({"longbridge": _FakeQuoteAdapter()}),
        heartbeat_interval=3600,
        reconnect_delay=0.01,
    )
    app.dependency_overrides[get_quote_hub] = lambda: hub

    with TestClient(app) as client:
        with client.websocket_connect("/v1/quotes/stream") as ws:
            ws.send_json({"type": "subscribe", "source": "longbridge", "symbols": ["AAPL"]})
            ack = ws.receive_json()
            assert ack["type"] == "ack"
            assert ack["action"] == "subscribe"

            quote = ws.receive_json()
            assert quote["type"] == "quote"
            assert quote["symbol"] == "AAPL"

            ws.send_json({"type": "ping"})
            pong = ws.receive_json()
            assert pong["type"] == "pong"

            ws.send_json({"type": "unsubscribe", "source": "longbridge", "symbols": ["AAPL"]})
            unack = ws.receive_json()
            assert unack["type"] == "ack"
            assert unack["action"] == "unsubscribe"

            ws.send_json({"type": "wat"})
            err = ws.receive_json()
            assert err["type"] == "error"
