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
        # The LongBridge SDK returns a `StockPositionsResponse` whose
        # `.channels` attribute is a list of `StockPositionChannel`,
        # each with its own `.positions`. Some older SDK versions
        # returned the list directly, so we handle both shapes.
        result = await _to_thread(self._trade_ctx.stock_positions)
        channels = _to_iterable(result, attribute="channels")
        raw_rows: list[Any] = []
        for channel in channels:
            positions = getattr(channel, "positions", None)
            if positions is None:
                raw_rows.append(channel)
                continue
            raw_rows.extend(list(positions))

        # The trade-side `stock_positions` endpoint returns `last_price: null`
        # for many positions. Fetch live quotes for the symbols and inject the
        # price so the aggregator can compute market_value and unrealized_pnl.
        symbols = [
            str(getattr(p, "symbol", "")) for p in raw_rows if getattr(p, "symbol", None)
        ]
        price_by_symbol: dict[str, Any] = {}
        if symbols:
            import logging
            log = logging.getLogger("mbp.longbridge.client")
            try:
                quotes = await _to_thread(self._quote_ctx.quote, symbols)
                # Try both the documented attribute name and the bare list
                # shape; older SDK versions returned the list directly.
                quote_iter = _to_iterable(quotes, attribute="secu_quote")
                log.info(
                    "quote-enrich: symbols=%s quote_count=%d quotes_type=%s",
                    symbols,
                    len(quote_iter),
                    type(quotes).__name__,
                )
                for q in quote_iter:
                    sym = getattr(q, "symbol", None) or (
                        q.get("symbol") if isinstance(q, dict) else None
                    )
                    price = getattr(q, "last_done", None) or (
                        q.get("last_done") if isinstance(q, dict) else None
                    )
                    if sym and price is not None:
                        price_by_symbol[str(sym)] = price
                log.info("quote-enrich: prices_resolved=%s", price_by_symbol)
            except Exception as exc:  # noqa: BLE001 - quote enrichment is best-effort
                log.warning("quote-enrich failed: %s", exc, exc_info=True)

        # Convert each SDK position to a dict so we can reliably merge in
        # the live price. The SDK returns immutable (slotted) dataclasses,
        # so setattr() silently fails — and the adapter would then see
        # null last_price and fall back to cost-basis. Building a fresh
        # dict guarantees the merged price is visible downstream.
        out: list[dict[str, Any]] = []
        for raw in raw_rows:
            row = _position_to_dict(raw)
            sym = str(row.get("symbol") or "")
            live = price_by_symbol.get(sym)
            if live is not None:
                row["last_price"] = live
                row["last_done"] = live
            out.append(row)
        return out

    async def list_balances(self) -> list[Any]:
        # Same shape concern as list_positions: the response object
        # exposes a `.list` (or `.accounts`) attribute containing the
        # actual rows on newer SDK versions.
        result = await _to_thread(self._trade_ctx.account_balance)
        accounts = _to_iterable(result, attribute="list", attribute_fallback="accounts")
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
        # LongBridge executions endpoint is "today" scoped. The response
        # may be a `TodayExecutionsResponse` with `.trades` (newer SDK)
        # or a bare iterable of executions (older SDK).
        result = await _to_thread(self._trade_ctx.today_executions)
        rows = list(_to_iterable(result, attribute="trades"))

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


def _position_to_dict(raw: Any) -> dict[str, Any]:
    """Snapshot an SDK position object into a plain dict.

    The LongBridge SDK returns immutable (slotted) dataclasses, so
    `setattr` silently fails when we try to inject a live price.
    Cloning to a dict produces a mutable copy the adapter can read
    via dict-style access AND lets us drop in merged fields.

    If `raw` is already a dict, we pass it through. Otherwise we
    enumerate the known fields from `_lookup` in the adapter.
    """
    if isinstance(raw, dict):
        return dict(raw)
    # Known fields the adapter looks for, plus a few aliases used by
    # different LongBridge SDK versions.
    field_names = (
        "symbol",
        "quantity",
        "currency",
        "cost_price",
        "avg_cost",
        "last_price",
        "last_done",
        "price",
        "market_value",
        "unrealized_pnl",
        "market",
        "exchange",
        "account_no",
        "account_id",
        "account_channel",
        "available_quantity",
        "init_quantity",
    )
    out: dict[str, Any] = {}
    for name in field_names:
        value = getattr(raw, name, None)
        if value is not None:
            out[name] = value
    return out


def _to_iterable(
    value: Any,
    *,
    attribute: str,
    attribute_fallback: str | None = None,
) -> list[Any]:
    """Coerce an SDK response into a list of rows.

    Newer LongBridge SDK versions wrap query results in a typed response
    object (e.g. `StockPositionsResponse`) whose actual list lives under
    a named attribute. Older versions return the list directly. Handle
    both by:
      1. If `value` is iterable (list/tuple/dict-values), return list(value).
      2. Else if it has `.<attribute>` attribute, use that.
      3. Else if `attribute_fallback` is given and present, use that.
      4. Else return an empty list.
    """
    if value is None:
        return []
    # Already iterable list-likes — most importantly excludes plain objects
    # so we don't accidentally iterate field-by-field.
    if isinstance(value, list | tuple):
        return list(value)
    primary = getattr(value, attribute, None)
    if primary is not None:
        return list(primary)
    if attribute_fallback is not None:
        fallback = getattr(value, attribute_fallback, None)
        if fallback is not None:
            return list(fallback)
    # Last resort: try iterating; if not iterable, give up.
    try:
        return list(iter(value))
    except TypeError:
        return []


async def _to_thread(fn: Any, *args: Any, **kwargs: Any) -> Any:  # pragma: no cover - thin asyncio glue exercised only through real SDK calls
    try:
        return await asyncio.to_thread(fn, *args, **kwargs)
    except Exception as exc:  # noqa: BLE001 - normalized below
        raise _classify_sdk_error(exc) from exc


def _load_sdk_types() -> tuple[type[Any], type[Any], type[Any]]:  # pragma: no cover - imports real longbridge SDK; tested by env-gated integration test
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
