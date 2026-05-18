"""Tests for the FX service."""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal

import pytest

from app.models.domain import FxRate
from app.services.fx import FxService, InMemoryFxCacheStore


class _FakeProvider:
    def __init__(self) -> None:
        self.calls: list[tuple[str, str]] = []

    async def fetch_rate(self, base: str, quote: str) -> FxRate | None:
        self.calls.append((base, quote))
        table: dict[tuple[str, str], Decimal] = {
            ("EUR", "USD"): Decimal("1.10"),
            ("USD", "HKD"): Decimal("7.80"),
        }
        rate = table.get((base, quote))
        if rate is None:
            return None
        return FxRate(base=base, quote=quote, rate=rate, as_of=datetime.now(UTC))


@pytest.mark.asyncio
async def test_fx_service_triangulates_via_usd_when_direct_pair_missing() -> None:
    provider = _FakeProvider()
    service = FxService(provider=provider, firestore_cache=InMemoryFxCacheStore(), ttl_seconds=60.0)

    eur_hkd = await service.get_rate("EUR", "HKD")
    assert eur_hkd.rate == Decimal("8.5800")

    cached = await service.get_rate("EUR", "HKD")
    assert cached.rate == eur_hkd.rate

    # Direct pair was absent; service resolved via EUR/USD and USD/HKD.
    assert ("EUR", "USD") in provider.calls
    assert ("USD", "HKD") in provider.calls


# ---------------------------------------------------------------------------
# FrankfurterProvider
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_frankfurter_provider_parses_rate() -> None:
    import httpx

    from app.services.fx import FrankfurterProvider

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path.endswith("/latest")
        assert request.url.params["base"] == "USD"
        assert request.url.params["symbols"] == "HKD"
        return httpx.Response(
            200,
            json={
                "amount": 1,
                "base": "USD",
                "date": "2026-05-18",
                "rates": {"HKD": 7.79},
            },
        )

    client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    provider = FrankfurterProvider(client=client)
    rate = await provider.fetch_rate("USD", "HKD")
    assert rate is not None
    assert rate.rate == Decimal("7.79")


@pytest.mark.asyncio
async def test_frankfurter_provider_returns_none_when_quote_absent() -> None:
    import httpx

    from app.services.fx import FrankfurterProvider

    def handler(_: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200, json={"base": "USD", "rates": {"EUR": 0.9}},
        )

    client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    provider = FrankfurterProvider(client=client)
    rate = await provider.fetch_rate("USD", "HKD")
    assert rate is None
