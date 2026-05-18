"""API tests for portfolio/fx routes from aggregator-and-fx module."""

from __future__ import annotations

from fastapi.testclient import TestClient


def test_get_portfolio_returns_empty_snapshot(client: TestClient) -> None:
    resp = client.get(
        "/v1/portfolio",
        headers={"Authorization": "Bearer good-token"},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["base_currency"] == "USD"
    assert body["positions"] == []
    assert body["balances"] == []


def test_get_positions_balances_transactions_empty(client: TestClient) -> None:
    headers = {"Authorization": "Bearer good-token"}
    pos = client.get("/v1/positions", headers=headers)
    bal = client.get("/v1/balances", headers=headers)
    tx = client.get("/v1/transactions", headers=headers)
    assert pos.status_code == 200
    assert bal.status_code == 200
    assert tx.status_code == 200
    assert pos.json()["items"] == []
    assert bal.json()["items"] == []
    assert tx.json()["items"] == []


def test_get_fx_accepts_pairs(client: TestClient) -> None:
    resp = client.get("/v1/fx", params={"pairs": "USD:USD"})
    assert resp.status_code == 200
    body = resp.json()
    assert body[0]["base"] == "USD"
    assert body[0]["quote"] == "USD"
    assert body[0]["rate"] == "1"


def test_get_fx_rejects_invalid_pair(client: TestClient) -> None:
    resp = client.get("/v1/fx", params={"pairs": "USDUSD"})
    assert resp.status_code == 422
