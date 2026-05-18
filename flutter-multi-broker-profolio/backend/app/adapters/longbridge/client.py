"""LongBridge SDK-backed client wrapper.

This module wraps the official `longbridge` SDK so `LongBridgeAdapter`
can stay pure and testable behind a Protocol boundary.
"""

from __future__ import annotations

import asyncio
import importlib
import types
from collections.abc import AsyncIterator
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

from app.adapters._common import PermanentError, TransientError


@dataclass(slots=True)
class LongbridgeCredentials:
    app_key: str
    app_secret: str
    access_token: str


class LongbridgeClient:  # pragma: no cover - integration exercised via env-gated test
    """Thin async wrapper around LongBridge quote + trade contexts."""

    def __init__(
        self,
        *,
        app_key: str,
        app_secret: str,
        access_token: str,
        quote_poll_interval: float = 1.0,
    ) -> None:
        config_cls, quote_context_cls, trade_context_cls = _load_sdk_types()

        # Official SDK helper for app-key auth flow.
        if hasattr(config_cls, "from_app_key"):
            config = config_cls.from_app_key(app_key, app_secret, access_token)
        elif hasattr(config_cls, "from_apikey"):
            config = config_cls.from_apikey(app_key, app_secret, access_token)
        else:
            raise PermanentError("longbridge Config missing from_app_key/from_apikey constructor")
        self._quote_ctx = quote_context_cls(config)
        self._trade_ctx = trade_context_cls(config)
        self._quote_poll_interval = quote_poll_interval

    async def list_positions(self) -> list[Any]:
        channels = await _to_thread(self._trade_ctx.stock_positions)
        rows: list[Any] = []
        for channel in channels:
            positions = getattr(channel, "positions", None)
            if positions is None:
                rows.append(channel)
                continue
            rows.extend(list(positions))
        return rows

    async def list_balances(self) -> list[Any]:
        accounts = await _to_thread(self._trade_ctx.account_balance)
        rows: list[Any] = []
        for account in accounts:
            cash_infos = getattr(account, "cash_infos", None)
            if cash_infos is None:
                rows.append(account)
                continue
            for cash in cash_infos:
                payload = {
                    "account_channel": getattr(account, "account_channel", None),
                    "currency": getattr(cash, "currency", None),
                    "withdraw_cash": getattr(cash, "withdraw_cash", None),
                    "available_cash": getattr(cash, "available_cash", None),
                    "cash": getattr(cash, "cash", None),
                    "total_cash": getattr(cash, "withdraw_cash", None),
                }
                rows.append(payload)
        return rows

    async def list_transactions(
        self,
        *,
        since: str | None,
        limit: int | None,
    ) -> list[Any]:
        # LongBridge executions endpoint is "today" scoped.
        executions = await _to_thread(self._trade_ctx.today_executions)
        rows = list(executions)

        if since is not None:
            threshold = _parse_since(since)
            kept: list[Any] = []
            for row in rows:
                timestamp = _row_timestamp(row)
                if timestamp is None or timestamp >= threshold:
                    kept.append(row)
            rows = kept
        if limit is not None and limit >= 0:
            rows = rows[:limit]
        return rows

    async def ping(self) -> bool:
        await _to_thread(self._trade_ctx.account_balance)
        return True

    async def stream_quotes(self, symbols: list[str]) -> AsyncIterator[Any]:
        if not symbols:
            return

        while True:
            quotes = await _to_thread(self._quote_ctx.quote, symbols)
            now = datetime.now(UTC)
            for quote in quotes:
                if isinstance(quote, dict):
                    payload = dict(quote)
                else:
                    payload = {
                        "symbol": getattr(quote, "symbol", None),
                        "last_done": getattr(quote, "last_done", None),
                        "currency": getattr(quote, "currency", None),
                        "timestamp": getattr(quote, "timestamp", now),
                    }
                payload.setdefault("timestamp", now)
                yield payload
            await asyncio.sleep(self._quote_poll_interval)


async def _to_thread(fn: Any, *args: Any, **kwargs: Any) -> Any:
    try:
        return await asyncio.to_thread(fn, *args, **kwargs)
    except Exception as exc:  # noqa: BLE001 - normalized below
        raise _classify_sdk_error(exc) from exc


def _load_sdk_types() -> tuple[type[Any], type[Any], type[Any]]:
    try:
        module = importlib.import_module("longbridge.openapi")
    except ModuleNotFoundError as exc:
        msg = "longbridge SDK not installed; add dependency and install backend requirements"
        raise PermanentError(msg) from exc

    if not isinstance(module, types.ModuleType):
        raise PermanentError("longbridge SDK module failed to load")

    config_cls = getattr(module, "Config", None)
    quote_context_cls = getattr(module, "QuoteContext", None)
    trade_context_cls = getattr(module, "TradeContext", None)
    if (
        not isinstance(config_cls, type)
        or not isinstance(quote_context_cls, type)
        or not isinstance(trade_context_cls, type)
    ):
        raise PermanentError("longbridge SDK missing Config/QuoteContext/TradeContext")
    return config_cls, quote_context_cls, trade_context_cls


def _classify_sdk_error(exc: Exception) -> Exception:
    if isinstance(exc, (PermanentError, TransientError)):
        return exc

    message = str(exc).lower()
    code_raw = getattr(exc, "code", None) or getattr(exc, "status_code", None)
    code = str(code_raw).lower() if code_raw is not None else ""

    if (
        "rate limit" in message
        or "too many request" in message
        or "timeout" in message
        or "temporarily unavailable" in message
        or code in {"429", "301606", "500", "502", "503", "504"}
    ):
        return TransientError(str(exc))

    if (
        "invalid access token" in message
        or "access token" in message
        or "invalid app key" in message
        or "app secret" in message
        or "unauthorized" in message
        or "forbidden" in message
        or "credential" in message
        or code in {"401", "403", "100002", "100004"}
    ):
        return PermanentError(str(exc))

    return exc


def _parse_since(value: str) -> datetime:
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=UTC)
    return parsed


def _row_timestamp(row: Any) -> datetime | None:
    value = getattr(row, "trade_done_at", None)
    if value is None and isinstance(row, dict):
        value = row.get("trade_done_at")
    if value is None:
        return None
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=UTC)
    return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
