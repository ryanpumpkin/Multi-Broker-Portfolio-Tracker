"""Tests for request-scoped adapter factory."""

from __future__ import annotations

import json

import pytest

from app.adapters.binance import BinanceAdapter, BinanceHost
from app.services.adapter_factory import (
    AdapterCredentialError,
    AdapterFactory,
    AdapterUnavailableError,
)


def test_factory_builds_binance_adapter_default_host() -> None:
    factory = AdapterFactory()
    adapter = factory.for_connection(
        connection_kind="binance",
        plaintext_creds=json.dumps({"apiKey": "k", "apiSecret": "s"}),
    )

    assert isinstance(adapter, BinanceAdapter)
    assert adapter.host is BinanceHost.COM


def test_factory_builds_binance_us_when_host_specified() -> None:
    factory = AdapterFactory()
    adapter = factory.for_connection(
        connection_kind="binance",
        plaintext_creds=json.dumps({"api_key": "k", "api_secret": "s", "host": "binance.us"}),
    )

    assert isinstance(adapter, BinanceAdapter)
    assert adapter.host is BinanceHost.US


def test_factory_rejects_invalid_credential_json() -> None:
    factory = AdapterFactory()
    with pytest.raises(AdapterCredentialError):
        factory.for_connection(connection_kind="binance", plaintext_creds="nope")


def test_factory_rejects_missing_required_fields() -> None:
    factory = AdapterFactory()
    with pytest.raises(AdapterCredentialError):
        factory.for_connection(
            connection_kind="binance",
            plaintext_creds=json.dumps({"apiKey": "k"}),
        )


def test_factory_rejects_unknown_connection_kind() -> None:
    factory = AdapterFactory()
    with pytest.raises(AdapterUnavailableError):
        factory.for_connection(connection_kind="longbridge", plaintext_creds=json.dumps({"x": "y"}))

