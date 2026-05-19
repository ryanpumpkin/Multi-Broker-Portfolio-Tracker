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
from app.adapters.ibkr.adapter import IbkrAdapter, IBKRClient
from app.adapters.longbridge.adapter import LongBridgeAdapter
from app.adapters.longbridge.client import LongbridgeClient


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
            self._builders = {
                "binance": _build_binance_adapter,
                "longbridge": _build_longbridge_adapter,
                "ibkr": _build_ibkr_adapter,
                "futu": _build_futu_adapter,
            }

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
    # Accept both "host" (legacy/test) and "region" (Flutter dialog sends 'com' or 'us').
    host_raw = (
        _pick_optional_str(credentials, "host", "region") or "binance.com"
    ).strip().lower()
    if host_raw in {"binance.us", "us"}:
        host = BinanceHost.US
    else:
        host = BinanceHost.COM

    client = HttpxBinanceClient(
        BinanceCredentials(api_key=api_key, api_secret=api_secret),
        host=host,
    )
    return BinanceAdapter(client)


def _build_longbridge_adapter(credentials: dict[str, Any]) -> SourceAdapter:
    app_key = _pick_str(credentials, "appKey", "app_key")
    app_secret = _pick_str(credentials, "appSecret", "app_secret")
    access_token = _pick_str(credentials, "accessToken", "access_token")

    client = LongbridgeClient(
        app_key=app_key,
        app_secret=app_secret,
        access_token=access_token,
    )
    return LongBridgeAdapter(client)


def _build_ibkr_adapter(credentials: dict[str, Any]) -> SourceAdapter:
    # IBKR creds are validated for shape but the actual login happens at the
    # sidecar gateway. We only forward the optional account_id; user/pass
    # configure the gateway container itself (see infra/README.md).
    account_id = _pick_optional_str(credentials, "accountId", "account_id")
    client = IBKRClient(account_id=account_id)
    return IbkrAdapter(client)


def _build_futu_adapter(credentials: dict[str, Any]) -> SourceAdapter:
    # The OpenD sidecar already holds account login. We accept optional
    # acc_id + trd_env overrides; the trade unlock password is captured
    # per-request via the credential context middleware.
    from app.adapters.futu.adapter import FutuAdapter
    from app.adapters.futu.client import FutuOpenDClient

    acc_id_raw = _pick_optional_str(credentials, "accId", "acc_id")
    acc_id = int(acc_id_raw) if acc_id_raw and acc_id_raw.isdigit() else None
    trd_env = _pick_optional_str(credentials, "trdEnv", "trd_env")

    client = FutuOpenDClient(acc_id=acc_id, trd_env=trd_env)
    return FutuAdapter(client)


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
