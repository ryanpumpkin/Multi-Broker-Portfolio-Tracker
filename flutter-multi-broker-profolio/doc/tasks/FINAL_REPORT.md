# Multi-Broker Portfolio Tracker — Final Build Report

**Generated:** 2026-05-18  
**Status:** All modules complete (12 `[x]`, 2 `[~]` pending developer-side actions)

---

## Module Summary

| Module | Status | Tests | Coverage | Commit |
|---|---|---|---|---|
| firebase-setup | `[~]` ¹ | 10/10 emulator | n/a (infra) | a3a0f8b |
| flutter-bootstrap | `[~]` ² | 28 | ~97% (hand-written) | b5f40a4 |
| flutter-domain | `[x]` | 54 | 99.0% | 96e63ab |
| flutter-data | `[x]` | 166 | 87.5% | *(wave-4)* |
| flutter-state | `[x]` | 184 | 94.1% | be8c6d1 |
| flutter-presentation | `[x]` | 234 | 80.9% | ac11e3f |
| flutter-auth-and-lock | `[x]` | 209 | 87.4% | c4ba502 |
| flutter-notifications | `[x]` | — | — | 1a3ec45 |
| backend-bootstrap | `[x]` | 30 | 100% | 7b9bf03 |
| backend-adapters | `[x]` | 69 | 96.4% | eae74c5 |
| backend-aggregator-and-fx | `[x]` | 77 | 96.6% | 7482b2d |
| backend-vault | `[x]` | 87 | 97.2% | 95112b1 |
| backend-alert-worker | `[x]` | 90 | 97.2% | efa451c |
| infra-deployment | `[x]` | smoke test | n/a (infra) | e70f0e5 |

**Total tests:** ~1,238 passing across Flutter and Python  
**All lint gates:** `flutter analyze` + `ruff check` — clean  
**All type-check gates:** `dart analyze` + `mypy --strict` — clean  
**All coverage gates:** ≥ 80% on all applicable modules

---

## What Was Built

### Flutter Client (`flutter/`)
- **Scaffold** — go_router, Material 3 light/dark themes, ARB i18n (en + zh_Hant), structured logging with Crashlytics sink.
- **Domain layer** — 8 pure-Dart entities, 8 repository interfaces, 4 use cases (`GetAggregatedPortfolio`, `ConvertToBaseCurrency`, `EvaluateAlert`, `ExportReport`).
- **Data layer** — Drift SQLite cache (positions, transactions, FX rates), `flutter_secure_storage` wrapper, AES-GCM E2E crypto with Argon2id key derivation, REST + WebSocket backend client, Firestore client, concrete repository implementations.
- **State layer** — Riverpod providers: auth, connections, portfolio, quotes, transactions, alerts, settings.
- **Presentation** — all 9 screen groups (auth, onboarding, dashboard, positions, charts, transactions, connections, alerts, settings) + reusable widget library.
- **Auth & lock** — Firebase Auth (email/password), biometric/PIN gate via `local_auth`.
- **Notifications** — FCM registration, foreground/background handlers, token sync to Firestore.

### Backend Proxy (`backend/`)
- **Bootstrap** — FastAPI factory, Firebase ID-token auth middleware, `/healthz` + `/metrics` ops endpoints, correlation-ID tracing, structlog JSON logging.
- **Adapters** — `SourceAdapter` Protocol + 4 concrete adapters (LongBridge, IBKR, Futu, Binance) with exponential-backoff retry, per-source health tracking. Broker SDKs dependency-injected (not hard-imported) for testability.
- **Aggregator & FX** — parallel fan-out to adapters, FX rate caching (in-process + Firestore), live-quote WebSocket multiplexer, partial-result resilience.
- **Vault** — hybrid E2E (client sends short-lived token) and server-key (KMS-encrypted, GCP/AWS/noop backends) credential storage per connection.
- **Alert worker** — background APScheduler task: reads Firestore alert definitions, evaluates current prices/P&L for server-key-mode users, dispatches FCM push on trigger.

### Firebase (`firebase/`)
- Firestore security rules (users own their sub-collections; `fx_rates` public-read).
- Composite indexes (`alerts`, `alert_events`).
- Firebase Emulator Suite config + 10 rules unit tests.

### Infra (`docker-compose.yml`, `backend/Dockerfile`, `infra/`)
- Multi-stage Docker image (Python 3.11-slim, non-root user, healthcheck).
- `docker-compose.yml`: `backend` + `ibkr-gateway` + `futu-opend` sidecars on a shared bridge network.
- Dev override (`docker-compose.override.yml`): hot-reload, adapters disabled, Firebase emulator.
- Smoke test script and pytest equivalent.

---

## Deferred / Requires Developer Action

| Item | Reason | Instructions |
|---|---|---|
| `firebase_options.dart`, `GoogleService-Info.plist`, `google-services.json` | Requires access to `mbp-tracker-dev` Firebase console | See `firebase/CLIENT_CONFIG.md` — run `flutterfire configure` once |
| Live-device boot smoke test (flutter-bootstrap) | Requires `firebase_options.dart` above | Flip flutter-bootstrap to `[x]` in progress.md after manual smoke test passes |
| Broker SDK runtime deps (`longbridge`, `ib_insync`, `futu-api`, `python-binance`) | Not installed; adapters use dependency-injected Protocol wrappers | Add to `backend/pyproject.toml` and wire up in the adapter callers |
| IBKR/Futu sidecar credentials | User-supplied at runtime | See `infra/README.md` |

---

## Commit Chain

```
e70f0e5  feat(infra-deployment)
ac11e3f  feat(flutter-presentation)
1a3ec45  feat(flutter-notifications)
efa451c  feat(backend-alert-worker)
c4ba502  feat(flutter-auth-and-lock)
95112b1  feat(backend-vault)
be8c6d1  feat(flutter-state)
7482b2d  feat(backend-aggregator-and-fx)
eae74c5  feat(backend-adapters)
96e63ab  feat(flutter-domain)
b5f40a4  feat(flutter-bootstrap)
7b9bf03  feat(backend-bootstrap)
a3a0f8b  feat(firebase-setup)
```

---

## Update — Post-Orchestrator Iteration

**Updated:** 2026-05-19

After the initial 14 modules landed, a second iteration drove the
end-to-end LongBridge integration through real broker credentials,
encryption, and a working dashboard. **45 additional commits**
landed across these themes:

### Broker integration (Wave 1 – 4 of `broker-integration-prompt.md`)

| Slice | Commit | What |
|---|---|---|
| Shared backend plumbing | b607fff | X-MBP-Creds header parsing, Python unwrap_from_backend, adapter_factory, connection_status events |
| LongBridge | 19da9ee | SDK-backed `LongbridgeClient`, mappers, retry/error coverage |
| Binance | 7f06792 | python-binance client, kline mapping |
| IBKR | 92d5486 | ib_insync gateway client, retry/error coverage |
| Futu | 02c0997 | OpenD client with request-scoped unlock |
| Flutter wrapped creds | bada756 | wrapped credentials through portfolio + tx flows |
| UI polish | 38764b1 | sync recency, error details |
| Backend vault sync | 84e4205 | Firestore-backed `ConnectionVaultStore` |
| Adapter builders | 07d5fbc | Register LongBridge/IBKR/Futu builders in `AdapterFactory` |
| Coverage fix-ups | 4edfc18 | Bring all broker slices ≥80% coverage |

### Operational fixes (end-to-end debugging)

| Layer | Commits | Fix |
|---|---|---|
| Docker / KMS | f2150d1, 49f3428 | File-backed KMS path + bind-mount of `backend/.secrets/` |
| Auth | f8eeb63, 5992a28, 10133f2 | Real Firebase ID-token verification; remove anonymous fallback; nudge UX to sign up |
| Auth lifecycle | 1f0b3ed | Refresh app-lock state on sign-out |
| Router | (in 5992a28) | Auth-guard redirect to `/auth/sign-in` |
| Mappers | c4b3082, 797d2e8, 01cb5a0 | Accept snake_case + numeric strings + null fields from backend |
| BackendClient | 725a314 | Match `/portfolio?base_currency=USD` |
| Vault read | 2bdba03 | Handle `QueryResultsList` from `CollectionReference.get()` |
| Credential dialog | 91e25c7, ddc9dbd, 6369753 | Real PIN input, ConsumerStatefulWidget refactor, auto-prompt on refresh |
| Encryption | 9d14537 | Stop double-encoding the encrypted blob |
| Dashboard | 9f5ac19, 584d5b2 | AppBar refresh button + save snackbar |
| FX | 0a430d4, b73a62e | Soft-fail unsupported pairs; default to Frankfurter |
| LongBridge data shape | 47a53ec, e814d20 | Unwrap `StockPositionsResponse.channels`; clone position to dict to inject quote prices |
| LongBridge enrichment | d1cfd1a, d57650d, d539e79 | Fetch live quotes via `QuoteContext.quote()`; cost-basis market_value fallback |

### Documentation added in this iteration

- `doc/RUNBOOK.md` — proven local-setup recipe
- `doc/ARCHITECTURE_NOTES.md` — decisions made during implementation that aren't in the original spec
- `doc/POST_MVP_PLAN.md` — next-iteration backlog with detailed sub-tasks for items 1-5

### Verified working state (as of last commit)

- LongBridge connection live; real positions (PLTR, ORCL, Grayscale BTC ETF) rendered with last-close prices.
- HKD/USD conversion via Frankfurter (ECB rates, free).
- Total portfolio value matches LongBridge app within 0.4% (FX rate variance).
- E2E credential encryption verified — backend reads encrypted blob, never sees plaintext outside the 2-min request window.
- Email/password auth persists across `flutter run` restarts.
- PIN-derived AES key correctly populated via inline Unlock dialog when wiped by auto-lock.

### Known gaps (covered by `POST_MVP_PLAN.md`)

1. **Diagnostic INFO logging is verbose.** Listed in plan item 1.
2. **Binance / IBKR / Futu not yet driven end-to-end** with real credentials. Plan item 2.
3. **Transactions screen empty** — only `today_executions` wired. Plan item 3.
4. **Live quote streaming not wired** — scaffolding exists but no WebSocket connect. Plan item 4.
5. **`drift_db_worker.dart.js: 404`** in browser console — harmless, in-page sqlite3.wasm fallback works. Mentioned in RUNBOOK §"Common gotchas".
