"""IBKR Client Portal Gateway adapter.

The adapter talks to a co-located gateway through an injected `IbkrClient`
Protocol. For production, `IBKRClient` wraps `ib_insync` and connects to the
gateway host/port configured via `MBP_IB_GATEWAY_HOST` /
`MBP_IB_GATEWAY_PORT`.

A keep-alive ping loop is exposed because IBKR sessions can expire after
periods of inactivity (detailed-design §4.3 / §7.2).
"""

from __future__ import annotations

import asyncio
import importlib
import os
import threading
from collections.abc import AsyncIterator, Awaitable, Callable, Iterable
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from typing import Any, Protocol

from app.adapters._common import (
    HealthTracker,
    PermanentError,
    RetryPolicy,
    TransientError,
    retry_async,
)
from app.adapters.base import SourceAdapter
from app.models.domain import (
    CashBalance,
    Position,
    Quote,
    SourceHealth,
    Transaction,
)

SOURCE_NAME = "ibkr"
_DEFAULT_TX_WINDOW_DAYS = 90


class IbkrClient(Protocol):
    """Thin wrapper around the CP Gateway HTTP/WS endpoints."""

    async def tickle(self) -> bool: ...

    async def fetch_positions(self) -> list[dict[str, Any]]: ...

    async def fetch_account_summary(self) -> list[dict[str, Any]]: ...

    async def fetch_executions(
        self, *, since: str | None, limit: int | None
    ) -> list[dict[str, Any]]: ...

    def stream_market_data(self, symbols: list[str]) -> AsyncIterator[dict[str, Any]]: ...


def _classify_ibkr_error(exc: Exception) -> Exception:
    message = str(exc).lower()
    permanent_markers = (
        "auth",
        "credential",
        "login",
        "permission",
        "not connected",
        "invalid account",
    )
    transient_markers = (
        "timeout",
        "temporarily",
        "try again",
        "connection reset",
        "rate limit",
        "too many requests",
    )
    if any(marker in message for marker in permanent_markers):
        return PermanentError(str(exc))
    if any(marker in message for marker in transient_markers):
        return TransientError(str(exc))
    return TransientError(str(exc))


class IBKRClient:
    """`ib_insync` wrapper for IBKR gateway sidecar calls.

    The wrapper normalizes `accountSummary()`, `positions()`, and `trades()`
    responses to dict payloads consumed by `IbkrAdapter` map functions.
    """

    def __init__(
        self,
        *,
        host: str | None = None,
        port: int | None = None,
        client_id: int = 1,
        account_id: str | None = None,
        connect_timeout: float = 10.0,
        ib: Any | None = None,
    ) -> None:
        self._host = host or os.getenv("MBP_IB_GATEWAY_HOST", "localhost")
        self._port = port or int(os.getenv("MBP_IB_GATEWAY_PORT", "5000"))
        self._client_id = client_id
        self._account_id = account_id
        self._connect_timeout = connect_timeout
        self._ib: Any | None = ib

    def _ensure_ib(self) -> Any:
        if self._ib is None:  # pragma: no cover - exercises real ib_insync import, covered by env-gated integration test
            try:
                ib_insync_mod = importlib.import_module("ib_insync")
            except ModuleNotFoundError as exc:
                raise PermanentError("ib_insync is not installed") from exc
            ib_cls = getattr(ib_insync_mod, "IB", None)
            if ib_cls is None:
                raise PermanentError("ib_insync is not installed")
            self._ib = ib_cls()
        return self._ib

    async def _connect(self) -> Any:
        ib = self._ensure_ib()
        if bool(ib.isConnected()):
            return ib
        try:
            await asyncio.to_thread(
                ib.connect,
                self._host,
                self._port,
                clientId=self._client_id,
                timeout=self._connect_timeout,
                readonly=True,
                account=self._account_id or "",
            )
        except Exception as exc:  # noqa: BLE001 - normalized below
            raise _classify_ibkr_error(exc) from exc
        if not bool(ib.isConnected()):
            raise TransientError("IBKR gateway connection failed")
        return ib

    async def tickle(self) -> bool:
        ib = await self._connect()
        return bool(ib.isConnected())

    async def fetch_positions(self) -> list[dict[str, Any]]:
        ib = await self._connect()
        try:
            rows = await asyncio.to_thread(ib.positions, self._account_id or "")
        except Exception as exc:  # noqa: BLE001
            raise _classify_ibkr_error(exc) from exc

        out: list[dict[str, Any]] = []
        for row in rows:
            contract = getattr(row, "contract", None)
            out.append(
                {
                    "acctId": getattr(row, "account", None),
                    "contractDesc": getattr(contract, "localSymbol", None)
                    or getattr(contract, "symbol", None),
                    "listingExchange": getattr(contract, "primaryExchange", None)
                    or getattr(contract, "exchange", None),
                    "position": str(getattr(row, "position", "0")),
                    "avgCost": str(getattr(row, "avgCost", "")),
                    "mktPrice": str(getattr(row, "marketPrice", "")),
                    "mktValue": str(getattr(row, "marketValue", "")),
                    "unrealizedPnl": str(getattr(row, "unrealizedPNL", "")),
                    "currency": getattr(contract, "currency", "USD"),
                }
            )
        return out

    async def fetch_account_summary(self) -> list[dict[str, Any]]:
        ib = await self._connect()
        try:
            rows = await asyncio.to_thread(ib.accountSummary, self._account_id or "")
        except Exception as exc:  # noqa: BLE001
            raise _classify_ibkr_error(exc) from exc

        out: list[dict[str, Any]] = []
        for row in rows:
            tag = str(getattr(row, "tag", ""))
            if tag not in {"CashBalance", "TotalCashValue"}:
                continue
            currency = str(getattr(row, "currency", "")).strip()
            value = str(getattr(row, "value", "")).strip()
            if not currency or not value:
                continue
            out.append(
                {
                    "acctId": getattr(row, "account", None),
                    "currency": currency,
                    "cashBalance": value,
                }
            )
        return out

    async def fetch_executions(
        self, *, since: str | None, limit: int | None
    ) -> list[dict[str, Any]]:
        ib = await self._connect()
        try:
            trades = await asyncio.to_thread(ib.trades)
        except Exception as exc:  # noqa: BLE001
            raise _classify_ibkr_error(exc) from exc

        out: list[dict[str, Any]] = []
        for trade in trades:
            contract = getattr(trade, "contract", None)
            fills = getattr(trade, "fills", None) or []
            for fill in fills:
                execution = getattr(fill, "execution", None)
                if execution is None:
                    continue
                out.append(
                    {
                        "acctId": getattr(execution, "acctNumber", None),
                        "execId": getattr(execution, "execId", None),
                        "symbol": getattr(contract, "localSymbol", None)
                        or getattr(contract, "symbol", None),
                        "side": getattr(execution, "side", None),
                        "size": str(getattr(execution, "shares", "")),
                        "price": str(getattr(execution, "price", "")),
                        "currency": getattr(contract, "currency", None),
                        "net_amount": None,
                        "time": getattr(execution, "time", None),
                    }
                )

        since_dt = _since_or_default(since)
        out = [row for row in out if _parse_ts(row["time"]) >= since_dt]
        out.sort(key=lambda row: _parse_ts(row["time"]))
        if limit is not None and limit >= 0:
            out = out[-limit:]
        return out

    async def stream_market_data(self, symbols: list[str]) -> AsyncIterator[dict[str, Any]]:
        ib = await self._connect()
        try:
            ib_insync_mod = importlib.import_module("ib_insync")
        except ModuleNotFoundError as exc:  # pragma: no cover - env/setup issue
            raise PermanentError("ib_insync is not installed") from exc
        stock_cls = getattr(ib_insync_mod, "Stock", None)
        if stock_cls is None:  # pragma: no cover - env/setup issue
            raise PermanentError("ib_insync is not installed")

        if not symbols:
            return

        contracts = [stock_cls(symbol, "SMART", "USD") for symbol in symbols]
        loop = asyncio.get_running_loop()
        queue: asyncio.Queue[dict[str, Any]] = asyncio.Queue()
        stop_event = threading.Event()

        def _to_payload(ticker: Any) -> dict[str, Any] | None:
            contract = getattr(ticker, "contract", None)
            symbol = getattr(contract, "symbol", None)
            if symbol is None:
                return None
            price = getattr(ticker, "marketPrice", lambda: None)()
            if price is None or price != price:  # NaN guard
                return None
            return {
                "symbol": symbol,
                "price": str(price),
                "currency": getattr(contract, "currency", "USD"),
                "timestamp": datetime.now(UTC),
            }

        def _pump() -> None:
            listener = getattr(ib, "pendingTickersEvent", None)

            def _on_pending(tickers: list[Any]) -> None:
                for ticker in tickers:
                    payload = _to_payload(ticker)
                    if payload is None:
                        continue
                    loop.call_soon_threadsafe(queue.put_nowait, payload)

            try:
                for contract in contracts:
                    ib.reqMktData(contract, "", False, False)
                if listener is not None:
                    listener += _on_pending
                while not stop_event.is_set():
                    ib.waitOnUpdate(timeout=1)
            except Exception as exc:  # noqa: BLE001 - normalized on async side
                loop.call_soon_threadsafe(
                    queue.put_nowait,
                    {"__error__": str(_classify_ibkr_error(exc))},
                )
            finally:
                if listener is not None:
                    try:
                        listener -= _on_pending
                    except Exception:
                        pass
                for contract in contracts:
                    try:
                        ib.cancelMktData(contract)
                    except Exception:
                        pass

        pump_task = asyncio.create_task(asyncio.to_thread(_pump))
        try:
            while True:
                payload = await queue.get()
                error = payload.get("__error__")
                if isinstance(error, str) and error:
                    raise _classify_ibkr_error(RuntimeError(error))
                yield payload
        except asyncio.CancelledError:
            raise
        finally:
            stop_event.set()
            pump_task.cancel()
            await asyncio.gather(pump_task, return_exceptions=True)


def _dec(v: Any) -> Decimal:
    return Decimal(str(v))


def _opt_dec(v: Any) -> Decimal | None:
    if v is None or v == "":
        return None
    return Decimal(str(v))


def _parse_ts(value: Any) -> datetime:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=UTC)
    if isinstance(value, int | float):
        return datetime.fromtimestamp(float(value), tz=UTC)
    return datetime.fromisoformat(str(value).replace("Z", "+00:00"))


def _map_position(raw: dict[str, Any]) -> Position:
    return Position(
        source=SOURCE_NAME,
        account_id=raw.get("acctId") or raw.get("account_id"),
        symbol=raw["contractDesc"] if "contractDesc" in raw else raw["symbol"],
        exchange=raw.get("listingExchange") or raw.get("exchange"),
        quantity=_dec(raw["position"]),
        avg_cost=_opt_dec(raw.get("avgCost") or raw.get("avg_cost")),
        last_price=_opt_dec(raw.get("mktPrice")),
        currency=raw["currency"],
        market_value=_opt_dec(raw.get("mktValue")),
        unrealized_pnl=_opt_dec(raw.get("unrealizedPnl")),
    )


def _map_balance(raw: dict[str, Any]) -> CashBalance:
    return CashBalance(
        source=SOURCE_NAME,
        account_id=raw.get("acctId") or raw.get("account_id"),
        currency=raw["currency"],
        amount=_dec(raw["cashBalance"] if "cashBalance" in raw else raw["amount"]),
    )


def _map_transaction(raw: dict[str, Any]) -> Transaction:
    side_raw = raw.get("side")
    side = side_raw.lower() if isinstance(side_raw, str) else None
    return Transaction(
        source=SOURCE_NAME,
        account_id=raw.get("acctId") or raw.get("account_id"),
        transaction_id=str(raw.get("execId") or raw["transaction_id"]),
        symbol=raw.get("symbol"),
        side=side,
        quantity=_opt_dec(raw.get("size") or raw.get("quantity")),
        price=_opt_dec(raw.get("price")),
        currency=raw.get("currency"),
        amount=_opt_dec(raw.get("net_amount") or raw.get("amount")),
        timestamp=_parse_ts(raw.get("time") or raw["timestamp"]),
    )


def _map_quote(raw: dict[str, Any]) -> Quote:
    return Quote(
        source=SOURCE_NAME,
        symbol=raw["symbol"],
        price=_dec(raw.get("last") or raw["price"]),
        currency=raw["currency"],
        timestamp=_parse_ts(raw.get("t") or raw["timestamp"]),
    )


def _since_or_default(since: str | None) -> datetime:
    if since is None:
        return datetime.now(UTC) - timedelta(days=_DEFAULT_TX_WINDOW_DAYS)
    return _parse_ts(since)


class IbkrAdapter(SourceAdapter):
    """IBKR adapter."""

    source = SOURCE_NAME

    def __init__(
        self,
        client: IbkrClient,
        *,
        retry: RetryPolicy | None = None,
        health: HealthTracker | None = None,
        keepalive_interval: float = 60.0,
    ) -> None:
        self._client = client
        self._retry = retry or RetryPolicy()
        self._health = health or HealthTracker(source=SOURCE_NAME)
        self._keepalive_interval = keepalive_interval
        self._keepalive_task: asyncio.Task[None] | None = None

    async def _call(self, func: Callable[[], Awaitable[Any]]) -> Any:
        try:
            result = await retry_async(func, policy=self._retry)
        except Exception as exc:
            self._health.record_failure(str(exc))
            raise
        self._health.record_success()
        return result

    async def _tickle_before_request(self) -> None:
        async def _tickle() -> None:
            ok = await self._client.tickle()
            if not ok:
                raise TransientError("tickle returned false")

        await self._call(_tickle)

    async def list_positions(self) -> list[Position]:
        await self._tickle_before_request()
        raw = await self._call(self._client.fetch_positions)
        return [_map_position(item) for item in raw]

    async def list_balances(self) -> list[CashBalance]:
        await self._tickle_before_request()
        raw = await self._call(self._client.fetch_account_summary)
        return [_map_balance(item) for item in raw]

    async def list_transactions(
        self,
        *,
        since: str | None = None,
        limit: int | None = None,
    ) -> list[Transaction]:
        async def _do() -> list[dict[str, Any]]:
            return await self._client.fetch_executions(since=since, limit=limit)

        await self._tickle_before_request()
        raw = await self._call(_do)
        return [_map_transaction(item) for item in raw]

    async def stream_quotes(self, symbols: Iterable[str]) -> AsyncIterator[Quote]:
        await self._tickle_before_request()
        async for raw in self._client.stream_market_data(list(symbols)):
            yield _map_quote(raw)

    async def healthcheck(self) -> SourceHealth:
        try:
            ok = await self._client.tickle()
            if ok:
                self._health.record_success()
            else:
                self._health.record_failure("tickle returned false")
        except Exception as exc:  # noqa: BLE001
            self._health.record_failure(str(exc))
        return self._health.snapshot()

    async def _keepalive_loop(
        self,
        sleep: Callable[[float], Awaitable[None]] = asyncio.sleep,
    ) -> None:
        while True:
            try:
                await self._client.tickle()
            except Exception as exc:  # noqa: BLE001 - keepalive must keep looping
                self._health.record_failure(str(exc))
            await sleep(self._keepalive_interval)

    def start_keepalive(self) -> asyncio.Task[None]:
        """Spawn the CP Gateway tickle loop."""
        if self._keepalive_task is None or self._keepalive_task.done():
            self._keepalive_task = asyncio.create_task(self._keepalive_loop())
        return self._keepalive_task

    async def stop_keepalive(self) -> None:
        task = self._keepalive_task
        if task is None:
            return
        task.cancel()
        try:
            await task
        except (asyncio.CancelledError, Exception):  # noqa: BLE001
            pass
        self._keepalive_task = None
