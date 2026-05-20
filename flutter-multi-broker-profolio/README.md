# Multi-Broker Portfolio Tracker

A Flutter + FastAPI portfolio tracker that aggregates real-time and historical
positions across LongBridge, Binance, IBKR, and Futu into a single dashboard.
The Flutter client runs on web, iOS, and Android; the FastAPI backend proxies
broker API calls on behalf of signed-in users. Firebase Auth + Firestore handle
identity and connection metadata. Broker credentials are AES-GCM encrypted
end-to-end in the browser using an Argon2id-derived PIN key — the backend never
sees plaintext credentials outside the two-minute per-request unwrap window.
Real-time quotes are multiplexed from multiple broker WebSocket streams into a
single `/v1/quotes/stream` endpoint and bound live to the Positions screen.

See [doc/RUNBOOK.md](doc/RUNBOOK.md) for local setup instructions.

See [doc/ARCHITECTURE_NOTES.md](doc/ARCHITECTURE_NOTES.md) for implementation
decisions not in the original spec.

## Project layout

| Directory | Contents |
|---|---|
| `flutter/` | Flutter client — domain layer, Riverpod state, Drift SQLite cache, presentation screens, E2E crypto, Firebase Auth / Firestore clients |
| `backend/` | FastAPI proxy — broker adapters (LongBridge, Binance, IBKR, Futu), credential vault, FX rate service, alert worker, WebSocket quote multiplexer |
| `firebase/` | Firestore security rules, composite indexes, Firebase Emulator Suite config, rules unit tests |
| `infra/` | Docker Compose service definitions, Dockerfile, IBKR Client Portal Gateway + Futu OpenD sidecar configs, smoke-test script |

## Quick start

```bash
# 1. Copy and edit environment config
cp .env.example .env

# 2. Start the backend (skips broker sidecars)
docker compose up backend --no-deps -d

# 3. Run the Flutter web client
cd flutter && flutter run -d chrome
```

Full prerequisites and step-by-step walkthrough are in
[doc/RUNBOOK.md](doc/RUNBOOK.md).
