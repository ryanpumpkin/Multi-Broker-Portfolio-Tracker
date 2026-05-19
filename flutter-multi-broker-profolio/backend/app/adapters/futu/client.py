"""Concrete Futu OpenD client backed by the official `futu-api` package."""

from __future__ import annotations

import asyncio
import importlib
from collections.abc import AsyncIterator
from datetime import UTC, datetime
from typing import Any

from app.adapters._common import PermanentError, TransientError
from app.core.settings import get_settings

_RATE_LIMIT_MARKERS = (
    "rate limit",
    "too many request",
    "too many requests",
    "quota",
    "throttle",
    "temporarily unavailable",
    "timeout",
)
_CREDENTIAL_MARKERS = (
    "unlock",
    "password",
    "pwd",
    "credential",
    "permission",
    "unauthorized",
    "forbidden",
    "auth",
)


class FutuOpenDClient:  # pragma: no cover - SDK-bound; exercised via real OpenD integration test
    """Thin async wrapper around OpenD quote/trade contexts."""

    def __init__(
        self,
        *,
        host: str | None = None,
        port: int | None = None,
        trd_env: str | None = None,
        acc_id: int | None = None,
        quote_poll_interval: float = 1.0,
    ) -> None:
        settings = get_settings()
        self._host = host or settings.futu_opend_host
        self._port = port or settings.futu_opend_port
        self._trd_env_raw = trd_env or "REAL"
        self._acc_id = acc_id
        self._quote_poll_interval = quote_poll_interval
        self._sdk = _load_futu_sdk()

    async def unlock_trade(self, password: str) -> None:
        await asyncio.to_thread(self._unlock_trade_sync, password)

    async def lock_trade(self) -> None:
        await asyncio.to_thread(self._lock_trade_sync)

    async def fetch_positions(self) -> list[dict[str, Any]]:
        return await asyncio.to_thread(self._fetch_positions_sync)

    async def fetch_accounts(self) -> list[dict[str, Any]]:
        return await asyncio.to_thread(self._fetch_accounts_sync)

    async def fetch_history_deals(
        self,
        *,
        since: str | None,
        limit: int | None,
    ) -> list[dict[str, Any]]:
        rows = await asyncio.to_thread(self._fetch_history_deals_sync, since)
        return rows[:limit] if limit is not None else rows

    async def ping(self) -> bool:
        return await asyncio.to_thread(self._ping_sync)

    async def subscribe_quotes(self, symbols: list[str]) -> AsyncIterator[dict[str, Any]]:
        if not symbols:
            return
        quote_ctx = self._sdk.OpenQuoteContext(host=self._host, port=self._port)
        try:
            sub_type = getattr(getattr(self._sdk, "SubType", None), "QUOTE", None)
            if sub_type is not None:
                ret, data = quote_ctx.subscribe(symbols, [sub_type], is_first_push=False)
                _ensure_ok(ret, data, operation="subscribe")
            while True:
                ret, frame = quote_ctx.get_stock_quote(symbols)
                _ensure_ok(ret, frame, operation="get_stock_quote")
                rows = _rows_from_payload(frame)
                for row in rows:
                    if "timestamp" not in row:
                        row["timestamp"] = datetime.now(UTC).isoformat()
                    yield row
                await asyncio.sleep(self._quote_poll_interval)
        finally:
            quote_ctx.close()

    def _trade_context(self) -> Any:
        return self._sdk.OpenSecTradeContext(host=self._host, port=self._port)

    def _trd_env(self) -> Any:
        trd_env_enum = getattr(self._sdk, "TrdEnv", None)
        if trd_env_enum is None:
            return self._trd_env_raw
        return getattr(trd_env_enum, self._trd_env_raw.upper(), trd_env_enum.REAL)

    def _unlock_trade_sync(self, password: str) -> None:
        trade_ctx = self._trade_context()
        try:
            try:
                ret, data = trade_ctx.unlock_trade(password=password)
            except TypeError:
                ret, data = trade_ctx.unlock_trade(password_md5=password)
            _ensure_ok(ret, data, operation="unlock_trade")
        finally:
            trade_ctx.close()

    def _lock_trade_sync(self) -> None:
        trade_ctx = self._trade_context()
        try:
            ret, data = trade_ctx.unlock_trade(is_unlock=False)
            _ensure_ok(ret, data, operation="lock_trade")
        finally:
            trade_ctx.close()

    def _fetch_positions_sync(self) -> list[dict[str, Any]]:
        trade_ctx = self._trade_context()
        try:
            kwargs = {"trd_env": self._trd_env()}
            if self._acc_id is not None:
                kwargs["acc_id"] = self._acc_id
            ret, frame = trade_ctx.position_list_query(**kwargs)
            _ensure_ok(ret, frame, operation="position_list_query")
            return _rows_from_payload(frame)
        finally:
            trade_ctx.close()

    def _fetch_accounts_sync(self) -> list[dict[str, Any]]:
        trade_ctx = self._trade_context()
        try:
            kwargs = {"trd_env": self._trd_env()}
            if self._acc_id is not None:
                kwargs["acc_id"] = self._acc_id
            ret, frame = trade_ctx.accinfo_query(**kwargs)
            _ensure_ok(ret, frame, operation="accinfo_query")
            return _rows_from_payload(frame)
        finally:
            trade_ctx.close()

    def _fetch_history_deals_sync(self, since: str | None) -> list[dict[str, Any]]:
        from datetime import date, timedelta

        trade_ctx = self._trade_context()
        try:
            kwargs: dict[str, Any] = {"trd_env": self._trd_env()}
            if since:
                # Parse ISO date portion for the Futu SDK's start parameter.
                try:
                    start_date = date.fromisoformat(since[:10])
                except ValueError:
                    start_date = date.today() - timedelta(days=90)
            else:
                start_date = date.today() - timedelta(days=90)
            kwargs["start"] = start_date.isoformat()
            kwargs["end"] = date.today().isoformat()
            if self._acc_id is not None:
                kwargs["acc_id"] = self._acc_id
            ret, frame = trade_ctx.history_deal_list_query(**kwargs)
            _ensure_ok(ret, frame, operation="history_deal_list_query")
            return _rows_from_payload(frame)
        finally:
            trade_ctx.close()

    def _ping_sync(self) -> bool:
        quote_ctx = self._sdk.OpenQuoteContext(host=self._host, port=self._port)
        try:
            ret, data = quote_ctx.get_global_state()
            _ensure_ok(ret, data, operation="get_global_state")
            return True
        finally:
            quote_ctx.close()


def _load_futu_sdk() -> Any:  # pragma: no cover - imports real futu SDK; covered by integration test
    try:
        return importlib.import_module("futu")
    except ModuleNotFoundError as exc:
        msg = "futu-api is not installed; add the `futu-api` dependency"
        raise RuntimeError(msg) from exc


def _rows_from_payload(payload: Any) -> list[dict[str, Any]]:
    if payload is None:
        return []
    if isinstance(payload, list):
        return [row for row in payload if isinstance(row, dict)]
    if hasattr(payload, "to_dict"):
        rows = payload.to_dict("records")
        if isinstance(rows, list):
            return [row for row in rows if isinstance(row, dict)]
    if isinstance(payload, dict):
        return [payload]
    msg = f"unsupported futu payload type: {type(payload)!r}"
    raise RuntimeError(msg)


def _extract_error_message(payload: Any) -> str:
    if isinstance(payload, str):
        return payload
    if isinstance(payload, dict):
        value = payload.get("msg") or payload.get("message") or payload.get("err_msg")
        if value is not None:
            return str(value)
    return str(payload)


def _ensure_ok(ret_code: Any, payload: Any, *, operation: str) -> None:
    sdk = _load_futu_sdk()
    if ret_code == sdk.RET_OK:
        return
    message = f"{operation} failed: {_extract_error_message(payload)}"
    lowered = message.lower()
    if any(marker in lowered for marker in _RATE_LIMIT_MARKERS):
        raise TransientError(message)
    if any(marker in lowered for marker in _CREDENTIAL_MARKERS):
        raise PermanentError(message)
    raise RuntimeError(message)


__all__ = ["FutuOpenDClient"]
