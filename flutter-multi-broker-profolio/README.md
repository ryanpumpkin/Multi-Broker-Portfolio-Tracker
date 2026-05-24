# Multi-Broker Portfolio Tracker

Flutter + FastAPI portfolio dashboard. Aggregates positions, balances,
transactions, and live quotes across **LongBridge**, **Interactive
Brokers**, **Futu/moomoo**, and **Binance** under a single Firebase
account, with end-to-end encrypted broker credentials.

## Repo layout

```
flutter-multi-broker-profolio/
├── flutter/             # Flutter app (web / iOS / Android)
├── backend/             # FastAPI proxy + aggregator
│   ├── app/
│   │   ├── adapters/    # one per broker — longbridge, ibkr, futu, binance
│   │   └── services/    # aggregator, fx, vault, etc.
│   └── pyproject.toml
├── infra/
│   ├── ibkr-gateway/    # IB Gateway + IBC sidecar (adapted from gnzsnz)
│   └── futu-opend/      # Futu OpenD sidecar (self-built from official binary)
├── firebase/            # Firebase project config + emulator data
├── doc/                 # design, runbook, broker integration details
├── docker-compose.yml          # production stack
└── docker-compose.override.yml # local-dev overrides (firebase emulator, etc.)
```

## Quick start (local dev)

Full step-by-step setup in [`doc/RUNBOOK.md`](doc/RUNBOOK.md). Short version:

```bash
# Backend + sidecars
cp .env.example .env       # fill in broker credentials
docker compose up -d backend futu-opend ibkr-gateway
# Flutter web (against local backend)
cd flutter && flutter run -d chrome --dart-define=BACKEND_BASE_URL=http://localhost:8000/v1
```

## NAS / server deployment

The compose stack runs unchanged on any Linux Docker host (e.g. a
Synology with Container Manager / Portainer). The only per-machine
artefacts you need to place out-of-band are:

| File | Where | Why |
|---|---|---|
| `.env` | repo root | Broker credentials (gitignored) |
| `backend/.secrets/firebase-service-account.json` | as named | Firebase Admin SDK creds |
| `infra/futu-opend/OpenD.tar.gz` | as named | Futu OpenD Linux binary |
| `infra/futu-opend/conn_key.pem` | as named | RSA key (only if running OpenD on 0.0.0.0) |

For Synology + Portainer specifically, point the stack at this repo's
branch and supply env vars in the Portainer UI.

## Brokers

Each broker has its own integration doc in
[`doc/BROKER_INTEGRATION_DETAILS.md`](doc/BROKER_INTEGRATION_DETAILS.md)
with sample API responses, SDK call signatures, and known quirks.

| Broker | Sidecar required? | Setup time |
|---|---|---|
| LongBridge | no — direct SDK | 5 min (just API keys) |
| Binance | no — REST + WS | 5 min (API key with read-only) |
| Futu / moomoo | yes — OpenD | ~30 min (download OpenD, set login + trade unlock) |
| IBKR | yes — IB Gateway + IBC | ~30 min (set IBKR login, approve 2FA push) |

## Security model

- **End-to-end encryption.** Broker API keys are encrypted in the
  Flutter app with a key derived from your PIN (Argon2id) and stored
  in Firestore as opaque AES-GCM ciphertext. The backend can wrap
  these into short-lived tokens for SDK calls but never sees plaintext.
- **PIN scoped per Firebase user.** Multiple accounts can use the
  same device without leaking each other's PINs.
- **Read-only by policy.** Every broker adapter only calls read
  endpoints (positions, balances, transactions, quotes). IBC sets
  `ReadOnlyApi=yes` as defense in depth.
- **No third-party Docker images for sensitive paths.** The IBKR
  gateway is built from IBKR's official installer; the Futu OpenD
  image is built from Futu's official Linux binary.

## Documentation index

| Doc | What |
|---|---|
| [`doc/RUNBOOK.md`](doc/RUNBOOK.md) | Local setup, env-by-env smoke tests |
| [`doc/ARCHITECTURE_NOTES.md`](doc/ARCHITECTURE_NOTES.md) | Design decisions beyond the original spec |
| [`doc/BROKER_INTEGRATION_DETAILS.md`](doc/BROKER_INTEGRATION_DETAILS.md) | Per-broker SDK details + sample responses |
| [`doc/POST_MVP_PLAN.md`](doc/POST_MVP_PLAN.md) | What landed after the MVP, what's next |
| [`infra/ibkr-gateway/README.md`](infra/ibkr-gateway/README.md) | Build + run the IBKR sidecar |
| [`infra/futu-opend/README.md`](infra/futu-opend/README.md) | Build + run the Futu sidecar |
| [`CLAUDE.md`](CLAUDE.md) | Architectural conventions for AI-assisted edits |
