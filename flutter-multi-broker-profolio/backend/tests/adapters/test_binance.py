"""Tests for the Binance adapter (binance.com + binance.us)."""

from __future__ import annotations

from collections.abc import AsyncIterator
from decimal import Decimal
from typing import Any

import pytest

from app.adapters._common import PermanentError, RetryPolicy
from app.adapters.binance import (
    BinanceAdapter,
    BinanceHost,
    sign_query,
)
from app.models.domain import SourceHealthStatus


class FakeBinanceClient:
    def __init__(
        self,
        *,
        host: BinanceHost = BinanceHost.COM,
        account: dict[str, Any] | None = None,
        trades: list[dict[str, Any]] | None = None,
        deposits: list[dict[str, Any]] | None = None,
        withdrawals: list[dict[str, Any]] | None = None,
        quotes: list[dict[str, Any]] | None = None,
        klines: dict[str, list[Any]] | None = None,
        tickers: dict[str, str] | None = None,
        fail_account: int = 0,
        ping_result: bool = True,
        ping_raises: Exception | None = None,
    ) -> None:
        self.host = host
        self._account = account or {
            "canTrade": False,
            "canWithdraw": False,
            "permissions": ["READ_ONLY"],
            "balances": [],
        }
        self._trades = trades or []
        self._deposits = deposits or []
        self._withdrawals = withdrawals or []
        self._quotes = quotes or []
        self._klines = klines or {}
        # ticker prices keyed by symbol (e.g. {"BTCUSDT": "65000"})
        self._tickers: dict[str, str] = tickers or {}
        self._fail_account = fail_account
        self._ping_result = ping_result
        self._ping_raises = ping_raises
        self.account_calls = 0

    async def get_account(self) -> dict[str, Any]:
        self.account_calls += 1
        if self._fail_account > 0:
            self._fail_account -= 1
            from app.adapters._common import TransientError

            raise TransientError("rate-limited")
        return self._account

    async def get_my_trades(
        self, *, symbol: str | None, since: str | None, limit: int | None
    ) -> list[dict[str, Any]]:
        return self._trades

    async def get_deposit_history(self, *, since: str | None) -> list[dict[str, Any]]:
        return self._deposits

    async def get_withdraw_history(self, *, since: str | None) -> list[dict[str, Any]]:
        return self._withdrawals

    async def get_klines(
        self, *, symbol: str, interval: str, limit: int
    ) -> list[Any]:
        return self._klines.get(symbol, [])

    async def get_symbol_ticker(self, *, symbol: str) -> dict[str, Any]:
        from app.adapters._common import PermanentError

        if symbol not in self._tickers:
            raise PermanentError(f"symbol {symbol} not found")
        return {"symbol": symbol, "price": self._tickers[symbol]}

    async def get_ticker_prices(self, symbols: list[str]) -> list[dict[str, Any]]:
        return []

    async def stream_mini_tickers(
        self, symbols: list[str]
    ) -> AsyncIterator[dict[str, Any]]:
        for q in self._quotes:
            yield q

    async def ping(self) -> bool:
        if self._ping_raises is not None:
            raise self._ping_raises
        return self._ping_result

    async def close(self) -> None:
        return None


def _no_jitter() -> RetryPolicy:
    return RetryPolicy(max_attempts=2, initial_delay=0.0, jitter=0.0)


def _read_only_account(**balances_kwargs: Any) -> dict[str, Any]:
    return {
        "canTrade": False,
        "canWithdraw": False,
        "permissions": ["READ_ONLY"],
        "balances": balances_kwargs.get(
            "balances",
            [
                {"asset": "BTC", "free": "0.5", "locked": "0"},
                {"asset": "USDT", "free": "100", "locked": "0"},
                {"asset": "ETH", "free": "0", "locked": "0"},
            ],
        ),
    }


def test_sign_query_is_deterministic_hmac_sha256() -> None:
    a = sign_query("s3cr3t", {"a": "1", "b": "2"})
    b = sign_query("s3cr3t", {"a": "1", "b": "2"})
    assert a == b
    assert "signature=" in a
    # Different secret -> different signature.
    c = sign_query("other", {"a": "1", "b": "2"})
    assert a != c


def test_binance_host_urls() -> None:
    assert BinanceHost.COM.rest_base == "https://api.binance.com"
    assert BinanceHost.US.rest_base == "https://api.binance.us"
    assert BinanceHost.COM.ws_base.startswith("wss://")
    assert BinanceHost.US.ws_base.startswith("wss://")


@pytest.mark.asyncio
async def test_rejects_trade_enabled_key() -> None:
    bad = {
        "canTrade": True,
        "canWithdraw": False,
        "permissions": ["SPOT"],
        "balances": [],
    }
    client = FakeBinanceClient(account=bad)
    adapter = BinanceAdapter(client, retry=_no_jitter())
    with pytest.raises(PermanentError):
        await adapter.verify_read_only()


@pytest.mark.asyncio
async def test_rejects_withdraw_enabled_key() -> None:
    bad = {
        "canTrade": False,
        "canWithdraw": True,
        "permissions": ["READ_ONLY"],
        "balances": [],
    }
    adapter = BinanceAdapter(FakeBinanceClient(account=bad), retry=_no_jitter())
    with pytest.raises(PermanentError):
        await adapter.verify_read_only()


@pytest.mark.asyncio
async def test_list_positions_skips_zero_and_maps() -> None:
    # BTC is non-stablecoin → position; USDT is stablecoin → balance; ETH is zero → skip.
    client = FakeBinanceClient(
        account=_read_only_account(),
        tickers={"BTCUSDT": "65000"},
    )
    adapter = BinanceAdapter(client, retry=_no_jitter())
    positions = await adapter.list_positions()
    symbols = {p.symbol for p in positions}
    # USDT is a stablecoin: must not appear in positions.
    assert symbols == {"BTC"}
    btc = next(p for p in positions if p.symbol == "BTC")
    assert btc.quantity == Decimal("0.5")
    assert btc.last_price == Decimal("65000")
    assert btc.market_value == Decimal("32500.0")
    assert btc.currency == "USDT"


@pytest.mark.asyncio
async def test_list_positions_falls_back_to_klines_when_ticker_fails() -> None:
    """When get_symbol_ticker raises PermanentError, fall back to klines."""
    client = FakeBinanceClient(
        account=_read_only_account(),
        # No tickers supplied → get_symbol_ticker raises PermanentError.
        klines={"BTCUSDT": [[0, "0", "0", "0", "60000", "0"]]},
    )
    adapter = BinanceAdapter(client, retry=_no_jitter())
    positions = await adapter.list_positions()
    btc = next(p for p in positions if p.symbol == "BTC")
    assert btc.last_price == Decimal("60000")


@pytest.mark.asyncio
async def test_list_balances_skips_zero_and_non_stablecoins() -> None:
    # USDT is stablecoin → included; BTC is non-stablecoin → excluded; ETH is zero → skip.
    client = FakeBinanceClient(account=_read_only_account())
    adapter = BinanceAdapter(client, retry=_no_jitter())
    balances = await adapter.list_balances()
    # BTC must NOT appear in balances (it's a non-stablecoin position).
    assert {b.currency for b in balances} == {"USDT"}


@pytest.mark.asyncio
async def test_transactions_merge_and_sort() -> None:
    client = FakeBinanceClient(
        account=_read_only_account(),
        trades=[
            {
                "id": 42,
                "symbol": "BTCUSDT",
                "isBuyer": True,
                "qty": "0.1",
                "price": "50000",
                "quoteQty": "5000",
                "commissionAsset": "USDT",
                "time": 1700000000000,
            }
        ],
        deposits=[
            {
                "txId": "dep-1",
                "coin": "USDT",
                "amount": "1000",
                "insertTime": 1690000000000,
            }
        ],
        withdrawals=[
            {
                "id": "wd-1",
                "coin": "USDT",
                "amount": "500",
                "applyTime": 1710000000000,
            }
        ],
    )
    adapter = BinanceAdapter(client, retry=_no_jitter())
    txs = await adapter.list_transactions()
    sides = [t.side for t in txs]
    assert sides == ["deposit", "buy", "withdrawal"]
    assert txs[0].timestamp < txs[1].timestamp < txs[2].timestamp
    assert txs[1].currency == "USDT"
    assert txs[1].amount == Decimal("5000")


@pytest.mark.asyncio
async def test_stream_quotes_infers_quote_currency() -> None:
    client = FakeBinanceClient(
        quotes=[
            {"s": "BTCUSDT", "c": "50000", "E": 1700000000000},
            {"s": "ETHBTC", "c": "0.05", "E": 1700000000000},
        ]
    )
    adapter = BinanceAdapter(client, retry=_no_jitter())
    out = [q async for q in adapter.stream_quotes(["BTCUSDT", "ETHBTC"])]
    assert out[0].currency == "USDT"
    assert out[1].currency == "BTC"


@pytest.mark.asyncio
async def test_healthcheck_paths() -> None:
    adapter = BinanceAdapter(FakeBinanceClient(), retry=_no_jitter())
    snap = await adapter.healthcheck()
    assert snap.status is SourceHealthStatus.OK

    adapter = BinanceAdapter(FakeBinanceClient(ping_result=False), retry=_no_jitter())
    snap = await adapter.healthcheck()
    assert snap.status is not SourceHealthStatus.OK

    adapter = BinanceAdapter(
        FakeBinanceClient(ping_raises=RuntimeError("net")), retry=_no_jitter()
    )
    snap = await adapter.healthcheck()
    assert snap.message is not None and "net" in snap.message


@pytest.mark.asyncio
async def test_supports_binance_us_host() -> None:
    client = FakeBinanceClient(
        host=BinanceHost.US,
        account=_read_only_account(),
        tickers={"BTCUSDT": "65000"},
    )
    adapter = BinanceAdapter(client, retry=_no_jitter())
    assert adapter.host is BinanceHost.US
    positions = await adapter.list_positions()
    assert any(p.symbol == "BTC" for p in positions)


@pytest.mark.asyncio
async def test_retries_rate_limited_account_then_succeeds() -> None:
    client = FakeBinanceClient(
        account=_read_only_account(),
        fail_account=1,
        tickers={"BTCUSDT": "65000"},
    )
    adapter = BinanceAdapter(client, retry=RetryPolicy(max_attempts=3, initial_delay=0.0, jitter=0.0))
    positions = await adapter.list_positions()
    assert client.account_calls == 2
    assert any(p.symbol == "BTC" for p in positions)


@pytest.mark.asyncio
async def test_trade_or_withdraw_key_rejected_on_transactions_init_check() -> None:
    bad = {
        "canTrade": True,
        "canWithdraw": False,
        "permissions": ["SPOT"],
        "balances": [],
    }
    adapter = BinanceAdapter(FakeBinanceClient(account=bad), retry=_no_jitter())
    with pytest.raises(PermanentError):
        await adapter.list_transactions()
