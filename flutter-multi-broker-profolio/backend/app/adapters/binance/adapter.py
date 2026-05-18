"""Binance adapter (binance.com + binance.us).

Read-only API key + secret, HMAC-SHA256 signed REST calls and a
WebSocket mini-ticker stream. We deliberately reject keys that have
trade or withdraw permissions at connect time as a defence-in-depth
sanity check (detailed-design §4.3, task spec).

The `BinanceClient` Protocol is the SDK boundary — production wires up
`HttpxBinanceClient` against the live host, tests inject a fake.
"""

from __future__ import annotations

import hashlib
import hmac
import time
import urllib.parse
from collections.abc import AsyncIterator, Awaitable, Callable, Iterable
from dataclasses import dataclass
from datetime import UTC, datetime
from decimal import Decimal
from enum import StrEnum
from typing import Any, Protocol

import httpx

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

SOURCE_NAME = "binance"


class BinanceHost(StrEnum):
    """Which Binance deployment to talk to."""

    COM = "binance.com"
    US = "binance.us"

    @property
    def rest_base(self) -> str:
        return "https://api.binance.com" if self is BinanceHost.COM else "https://api.binance.us"

    @property
    def ws_base(self) -> str:
        return (
            "wss://stream.binance.com:9443"
            if self is BinanceHost.COM
            else "wss://stream.binance.us:9443"
        )


def sign_query(secret: str, params: dict[str, Any]) -> str:
    """HMAC-SHA256 sign a query-string dict, returning `query&signature=...`."""
    query = urllib.parse.urlencode(params, doseq=True)
    sig = hmac.new(secret.encode("utf-8"), query.encode("utf-8"), hashlib.sha256).hexdigest()
    return f"{query}&signature={sig}"


@dataclass(slots=True)
class BinanceCredentials:
    api_key: str
    api_secret: str


class BinanceClient(Protocol):
    """SDK boundary for Binance REST + WS calls."""

    host: BinanceHost

    async def get_account(self) -> dict[str, Any]: ...

    async def get_my_trades(
        self,
        *,
        symbol: str | None,
        since: str | None,
        limit: int | None,
    ) -> list[dict[str, Any]]: ...

    async def get_deposit_history(
        self, *, since: str | None
    ) -> list[dict[str, Any]]: ...

    async def get_withdraw_history(
        self, *, since: str | None
    ) -> list[dict[str, Any]]: ...

    async def get_ticker_prices(self, symbols: list[str]) -> list[dict[str, Any]]: ...

    def stream_mini_tickers(self, symbols: list[str]) -> AsyncIterator[dict[str, Any]]: ...

    async def ping(self) -> bool: ...


def _dec(v: Any) -> Decimal:
    return Decimal(str(v))


def _opt_dec(v: Any) -> Decimal | None:
    if v is None or v == "":
        return None
    return Decimal(str(v))


def _ts_ms(value: Any) -> datetime:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=UTC)
    return datetime.fromtimestamp(int(value) / 1000.0, tz=UTC)


def _spot_balance_to_position(raw: dict[str, Any]) -> Position | None:
    """Map a Binance spot balance row to a Position (skipping zero balances)."""
    qty = _dec(raw["free"]) + _dec(raw.get("locked", "0"))
    if qty == 0:
        return None
    asset = raw["asset"]
    return Position(
        source=SOURCE_NAME,
        account_id=None,
        symbol=asset,
        exchange="BINANCE",
        quantity=qty,
        avg_cost=None,
        last_price=None,
        currency=asset,
        market_value=None,
        unrealized_pnl=None,
    )


def _spot_balance_to_cash(raw: dict[str, Any]) -> CashBalance | None:
    """For stable/fiat assets we also expose a CashBalance row."""
    qty = _dec(raw["free"]) + _dec(raw.get("locked", "0"))
    if qty == 0:
        return None
    return CashBalance(
        source=SOURCE_NAME,
        account_id=None,
        currency=raw["asset"],
        amount=qty,
    )


def _map_trade(raw: dict[str, Any]) -> Transaction:
    side = "buy" if raw.get("isBuyer", False) else "sell"
    return Transaction(
        source=SOURCE_NAME,
        account_id=None,
        transaction_id=str(raw["id"]),
        symbol=raw["symbol"],
        side=side,
        quantity=_opt_dec(raw.get("qty")),
        price=_opt_dec(raw.get("price")),
        currency=raw.get("commissionAsset"),
        amount=_opt_dec(raw.get("quoteQty")),
        timestamp=_ts_ms(raw["time"]),
    )


def _map_deposit(raw: dict[str, Any]) -> Transaction:
    return Transaction(
        source=SOURCE_NAME,
        account_id=None,
        transaction_id=str(raw.get("txId") or raw["id"]),
        symbol=None,
        side="deposit",
        quantity=None,
        price=None,
        currency=raw["coin"],
        amount=_opt_dec(raw.get("amount")),
        timestamp=_ts_ms(raw.get("insertTime") or raw["time"]),
    )


def _map_withdrawal(raw: dict[str, Any]) -> Transaction:
    return Transaction(
        source=SOURCE_NAME,
        account_id=None,
        transaction_id=str(raw.get("id") or raw["txId"]),
        symbol=None,
        side="withdrawal",
        quantity=None,
        price=None,
        currency=raw["coin"],
        amount=_opt_dec(raw.get("amount")),
        timestamp=_ts_ms(raw.get("applyTime") or raw["time"]),
    )


def _map_quote(raw: dict[str, Any]) -> Quote:
    symbol = raw.get("s") or raw["symbol"]
    price = raw.get("c") or raw.get("price") or raw["p"]
    ts_value = raw.get("E") or raw.get("time")
    timestamp = _ts_ms(ts_value) if ts_value is not None else datetime.now(UTC)
    # Spot pairs end in USDT/USDC/BUSD/USD — treat the suffix as the quote currency.
    currency = "USD"
    for suffix in ("USDT", "USDC", "BUSD", "USD", "BTC", "ETH"):
        if isinstance(symbol, str) and symbol.endswith(suffix):
            currency = suffix
            break
    return Quote(
        source=SOURCE_NAME,
        symbol=symbol,
        price=_dec(price),
        currency=currency,
        timestamp=timestamp,
    )


def _assert_read_only(account: dict[str, Any]) -> None:
    """Reject keys with trade or withdraw permissions enabled."""
    perms = account.get("permissions") or []
    forbidden = {"SPOT", "MARGIN", "FUTURES", "TRD_GRP_002"}
    bad = [p for p in perms if isinstance(p, str) and p.upper() in forbidden]
    if bad:
        raise PermanentError(
            f"Binance API key has non-read permissions {bad}; refuse to use"
        )
    if account.get("canTrade") or account.get("canWithdraw"):
        raise PermanentError(
            "Binance API key allows trade/withdraw; refuse to use"
        )


class BinanceAdapter(SourceAdapter):
    """Binance spot adapter (works against `.com` or `.us`)."""

    source = SOURCE_NAME

    def __init__(
        self,
        client: BinanceClient,
        *,
        retry: RetryPolicy | None = None,
        health: HealthTracker | None = None,
    ) -> None:
        self._client = client
        self._retry = retry or RetryPolicy()
        self._health = health or HealthTracker(source=SOURCE_NAME)
        self._verified_read_only = False

    @property
    def host(self) -> BinanceHost:
        return self._client.host

    async def _call(self, func: Callable[[], Awaitable[Any]]) -> Any:
        try:
            result = await retry_async(func, policy=self._retry)
        except Exception as exc:
            self._health.record_failure(str(exc))
            raise
        self._health.record_success()
        return result

    async def verify_read_only(self) -> None:
        account = await self._call(self._client.get_account)
        _assert_read_only(account)
        self._verified_read_only = True

    async def _ensure_verified(self) -> dict[str, Any]:
        account: dict[str, Any] = await self._call(self._client.get_account)
        _assert_read_only(account)
        self._verified_read_only = True
        return account

    async def list_positions(self) -> list[Position]:
        account = await self._ensure_verified()
        out: list[Position] = []
        for row in account.get("balances", []):
            pos = _spot_balance_to_position(row)
            if pos is not None:
                out.append(pos)
        return out

    async def list_balances(self) -> list[CashBalance]:
        account = await self._ensure_verified()
        out: list[CashBalance] = []
        for row in account.get("balances", []):
            bal = _spot_balance_to_cash(row)
            if bal is not None:
                out.append(bal)
        return out

    async def list_transactions(
        self,
        *,
        since: str | None = None,
        limit: int | None = None,
    ) -> list[Transaction]:
        async def _trades() -> list[dict[str, Any]]:
            return await self._client.get_my_trades(symbol=None, since=since, limit=limit)

        async def _deposits() -> list[dict[str, Any]]:
            return await self._client.get_deposit_history(since=since)

        async def _withdrawals() -> list[dict[str, Any]]:
            return await self._client.get_withdraw_history(since=since)

        trades = await self._call(_trades)
        deposits = await self._call(_deposits)
        withdrawals = await self._call(_withdrawals)
        out: list[Transaction] = [_map_trade(t) for t in trades]
        out.extend(_map_deposit(d) for d in deposits)
        out.extend(_map_withdrawal(w) for w in withdrawals)
        out.sort(key=lambda tx: tx.timestamp)
        return out

    async def stream_quotes(self, symbols: Iterable[str]) -> AsyncIterator[Quote]:
        async for raw in self._client.stream_mini_tickers(list(symbols)):
            yield _map_quote(raw)

    async def healthcheck(self) -> SourceHealth:
        try:
            ok = await self._client.ping()
            if ok:
                self._health.record_success()
            else:
                self._health.record_failure("ping failed")
        except Exception as exc:  # noqa: BLE001
            self._health.record_failure(str(exc))
        return self._health.snapshot()


class HttpxBinanceClient:  # pragma: no cover - real network wrapper
    """Live Binance REST client. Excluded from coverage; tests use a fake.

    The mini-ticker WS stream is intentionally a stub here — real-time
    streaming is wired in by the aggregator module; this class only exposes
    the REST signing logic so other modules don't reinvent it.
    """

    def __init__(
        self,
        creds: BinanceCredentials,
        *,
        host: BinanceHost = BinanceHost.COM,
        http: httpx.AsyncClient | None = None,
        recv_window_ms: int = 5000,
    ) -> None:
        self._creds = creds
        self.host = host
        self._http = http or httpx.AsyncClient(base_url=host.rest_base, timeout=10.0)
        self._recv_window = recv_window_ms

    def _signed(self, params: dict[str, Any]) -> str:
        params = {**params, "timestamp": int(time.time() * 1000), "recvWindow": self._recv_window}
        return sign_query(self._creds.api_secret, params)

    async def _signed_get(self, path: str, params: dict[str, Any]) -> Any:
        query = self._signed(params)
        try:
            resp = await self._http.get(
                f"{path}?{query}",
                headers={"X-MBX-APIKEY": self._creds.api_key},
            )
        except httpx.HTTPError as exc:
            raise TransientError(str(exc)) from exc
        if resp.status_code in (429, 418, 500, 502, 503, 504):
            raise TransientError(f"binance {resp.status_code}: {resp.text}")
        if resp.status_code >= 400:
            raise PermanentError(f"binance {resp.status_code}: {resp.text}")
        return resp.json()

    async def get_account(self) -> dict[str, Any]:
        result: dict[str, Any] = await self._signed_get("/api/v3/account", {})
        return result

    async def get_my_trades(
        self, *, symbol: str | None, since: str | None, limit: int | None
    ) -> list[dict[str, Any]]:
        if symbol is None:
            return []
        params: dict[str, Any] = {"symbol": symbol}
        if since is not None:
            params["startTime"] = since
        if limit is not None:
            params["limit"] = limit
        result: list[dict[str, Any]] = await self._signed_get("/api/v3/myTrades", params)
        return result

    async def get_deposit_history(self, *, since: str | None) -> list[dict[str, Any]]:
        params: dict[str, Any] = {}
        if since is not None:
            params["startTime"] = since
        result: list[dict[str, Any]] = await self._signed_get(
            "/sapi/v1/capital/deposit/hisrec", params
        )
        return result

    async def get_withdraw_history(self, *, since: str | None) -> list[dict[str, Any]]:
        params: dict[str, Any] = {}
        if since is not None:
            params["startTime"] = since
        result: list[dict[str, Any]] = await self._signed_get(
            "/sapi/v1/capital/withdraw/history", params
        )
        return result

    async def get_ticker_prices(self, symbols: list[str]) -> list[dict[str, Any]]:
        resp = await self._http.get("/api/v3/ticker/price")
        return list(resp.json())

    def stream_mini_tickers(self, symbols: list[str]) -> AsyncIterator[dict[str, Any]]:
        raise NotImplementedError("WS streaming is wired up by the aggregator module")

    async def ping(self) -> bool:
        try:
            resp = await self._http.get("/api/v3/ping")
        except httpx.HTTPError:
            return False
        return resp.status_code == 200
