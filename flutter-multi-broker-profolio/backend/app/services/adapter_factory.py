"""Request-scoped source adapter construction from plaintext credentials."""

from __future__ import annotations

import json
from typing import Any, Protocol

from app.adapters.base import SourceAdapter
from app.adapters.binance.adapter import (
    BinanceAdapter,
    BinanceCredentials,
    BinanceHost,
    HttpxBinanceClient,
)


class AdapterFactoryError(ValueError):
    """Base error for adapter-factory input/build failures."""


class AdapterCredentialError(AdapterFactoryError):
    """Credential payload is malformed or missing required fields."""


class AdapterUnavailableError(AdapterFactoryError):
    """Connection kind has no configured adapter builder."""


class AdapterBuilder(Protocol):
    """Callable contract for connection-kind-specific adapter construction."""

    def __call__(self, credentials: dict[str, Any]) -> SourceAdapter: ...


class AdapterFactory:
    """Builds a fresh adapter instance per request and per connection."""

    def __init__(self, builders: dict[str, AdapterBuilder] | None = None) -> None:
        self._builders: dict[str, AdapterBuilder] = {}
        if builders is not None:
            self._builders = {key.lower(): value for key, value in builders.items()}
        else:
            self._builders = {"binance": _build_binance_adapter}

    def for_connection(self, *, connection_kind: str, plaintext_creds: str) -> SourceAdapter:
        kind = connection_kind.strip().lower()
        if not kind:
            raise AdapterCredentialError("connection_kind is required")

        builder = self._builders.get(kind)
        if builder is None:
            raise AdapterUnavailableError(f"No adapter builder configured for '{kind}'")

        credentials = _parse_credential_json(plaintext_creds)
        return builder(credentials)


def _parse_credential_json(raw: str) -> dict[str, Any]:
    if not raw.strip():
        raise AdapterCredentialError("plaintext credentials are required")
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise AdapterCredentialError("credentials must be valid JSON") from exc
    if not isinstance(payload, dict):
        raise AdapterCredentialError("credentials must be a JSON object")
    return payload


def _build_binance_adapter(credentials: dict[str, Any]) -> SourceAdapter:
    api_key = _pick_str(credentials, "apiKey", "api_key")
    api_secret = _pick_str(credentials, "apiSecret", "api_secret")
    host_raw = (_pick_optional_str(credentials, "host") or "binance.com").strip().lower()
    if host_raw in {"binance.us", "us"}:
        host = BinanceHost.US
    else:
        host = BinanceHost.COM

    client = HttpxBinanceClient(
        BinanceCredentials(api_key=api_key, api_secret=api_secret),
        host=host,
    )
    return BinanceAdapter(client)


def _pick_str(payload: dict[str, Any], *keys: str) -> str:
    value = _pick_optional_str(payload, *keys)
    if value is None:
        joined = ", ".join(keys)
        raise AdapterCredentialError(f"missing credential field: {joined}")
    return value


def _pick_optional_str(payload: dict[str, Any], *keys: str) -> str | None:
    for key in keys:
        value = payload.get(key)
        if isinstance(value, str) and value.strip():
            return value
    return None
