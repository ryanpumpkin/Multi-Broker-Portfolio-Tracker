# Multi-Broker Portfolio Tracker

> A self-hosted portfolio dashboard that aggregates positions, balances,
> transactions, and live quotes across **LongBridge**, **Interactive
> Brokers**, **Futu/moomoo**, and **Binance** — with end-to-end
> encrypted broker credentials, Firebase auth, and a Flutter UI.

[![status](https://img.shields.io/badge/status-self--hosted-blue)](#)
[![brokers](https://img.shields.io/badge/brokers-4-green)](#supported-brokers)
[![license](https://img.shields.io/badge/license-MIT-lightgrey)](#)

📂 **The full project lives in [`flutter-multi-broker-profolio/`](./flutter-multi-broker-profolio/)** —
including the Flutter app, FastAPI backend, broker SDK adapters, and
Docker deployment recipes.

---

## What it does

- **One dashboard, four brokers.** See your total P&L, allocation,
  and per-symbol positions in your base currency, no matter where the
  cash actually sits.
- **End-to-end encrypted credentials.** Your broker API keys are
  encrypted on-device with a PIN-derived key (Argon2id + AES-GCM). The
  backend never sees plaintext — it relays opaque tokens to short-lived
  broker SDK calls.
- **Self-hosted.** Runs on your laptop, a NAS, or a small VPS via
  `docker-compose`. Your data stays with you.
- **Live quotes.** Authenticated WebSocket stream pushes price ticks
  to the Positions screen.

## Supported brokers

| Broker | Status | Notes |
|---|---|---|
| LongBridge / Longport | ✅ live | Stocks (HK / US / CN), FX-converted to base currency |
| Interactive Brokers (live) | ✅ live | Via IB Gateway + IBC sidecar (built from Apache-2.0 [gnzsnz/ib-gateway-docker](https://github.com/gnzsnz/ib-gateway-docker)) |
| Futu / moomoo | ✅ live | Via OpenD sidecar; backend shares network namespace for local-mode auth |
| Binance (spot) | ✅ live | Read-only API key; trades + balances |
| Manual holdings | ✅ live | For anything none of the above tracks (real estate, cash, etc.) |

## Architecture (TL;DR)

```
┌──────────────┐    HTTPS + JWT     ┌──────────────┐    SDK     ┌─────────────┐
│ Flutter app  │  ──────────────▶   │ FastAPI BE   │ ────────▶  │ Broker APIs │
│ (web / iOS / │                    │ (Python)     │            │             │
│  Android)    │  ◀── source_health ┤  + aggregator│ ◀─ data ── │ LB IBKR     │
└──────────────┘     + positions    └──────────────┘            │ Futu Binance│
                                            │                   └─────────────┘
                                            │
                                    ┌───────▼───────┐
                                    │ Firebase Auth │
                                    │ + Firestore   │
                                    │ (encrypted    │
                                    │  cred blobs)  │
                                    └───────────────┘
```

Full architecture notes:
[`flutter-multi-broker-profolio/doc/ARCHITECTURE_NOTES.md`](./flutter-multi-broker-profolio/doc/ARCHITECTURE_NOTES.md).

## Get started

| I want to… | Read |
|---|---|
| Run it locally for development | [`flutter-multi-broker-profolio/doc/RUNBOOK.md`](./flutter-multi-broker-profolio/doc/RUNBOOK.md) |
| Deploy to a Synology / Linux server | [`flutter-multi-broker-profolio/README.md`](./flutter-multi-broker-profolio/README.md) |
| Add a broker | [`flutter-multi-broker-profolio/doc/BROKER_INTEGRATION_DETAILS.md`](./flutter-multi-broker-profolio/doc/BROKER_INTEGRATION_DETAILS.md) |
| Understand the design decisions | [`flutter-multi-broker-profolio/doc/ARCHITECTURE_NOTES.md`](./flutter-multi-broker-profolio/doc/ARCHITECTURE_NOTES.md) |
| Build the IBKR sidecar | [`flutter-multi-broker-profolio/infra/ibkr-gateway/README.md`](./flutter-multi-broker-profolio/infra/ibkr-gateway/README.md) |
| Build the Futu sidecar | [`flutter-multi-broker-profolio/infra/futu-opend/README.md`](./flutter-multi-broker-profolio/infra/futu-opend/README.md) |

---

## Other project in this repo

This repository also hosts **rnpksync** — a real-time YouTube
watch-together app (Express + Socket.IO). Unrelated to the portfolio
tracker; lives at the repo root for historical reasons. See
[`README-rnpksync.md`](./README-rnpksync.md) for details.
