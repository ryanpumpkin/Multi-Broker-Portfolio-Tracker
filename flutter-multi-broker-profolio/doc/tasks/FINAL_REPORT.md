# Multi-Broker Portfolio Tracker — Final Build Report

**Generated:** 2026-05-19  **Updated:** 2026-05-25  
**Status:** All orchestrated modules complete. Post-orchestrator infrastructure hardening landed on main (see Theme F below).

---

## Shipping State

The app now runs end-to-end with Firebase auth, encrypted broker
credentials, broker fan-out aggregation, historical transactions,
and authenticated quote streaming into the live Positions UI.

Latest validated full-suite gates (from `88d4604`):

- Backend: `257 passed, 8 skipped` (`pytest --cov=app --cov-fail-under=80 -q`), coverage `93.09%`
- Backend lint/type: `ruff check .` clean, `mypy --strict app` clean
- Flutter: `flutter analyze` clean, `250 passed` in `flutter test`

---

## Module Summary (Base 14)

| Module | Status | Commit |
|---|---|---|
| firebase-setup | complete | a3a0f8b |
| flutter-bootstrap | complete | b5f40a4 |
| flutter-domain | complete | 96e63ab |
| flutter-data | complete | dad720f |
| flutter-state | complete | be8c6d1 |
| flutter-presentation | complete | ac11e3f |
| flutter-auth-and-lock | complete | c4ba502 |
| flutter-notifications | complete | 1a3ec45 |
| backend-bootstrap | complete | 7b9bf03 |
| backend-adapters | complete | eae74c5 |
| backend-aggregator-and-fx | complete | 7482b2d |
| backend-vault | complete | 95112b1 |
| backend-alert-worker | complete | efa451c |
| infra-deployment | complete | e70f0e5 |

---

## Post-MVP Slice Status

| Slice | Status | Commit |
|---|---|---|
| cleanup-diagnostic-logging | complete | 386b3ea |
| broker-integration-ibkr | complete | 5617ef3 |
| broker-integration-futu | complete | 724f830 |
| broker-integration-binance | complete | b60ca13 |
| transactions-history | complete | 55b82ea |
| live-quote-streaming | complete | 88d4604 |
| final-report | this slice | pending commit |

---

## Commit Ledger Since Original Orchestrator

Range: `dcc8a54..88d4604` on `main` (52 commits), grouped by theme.

### Theme A — Foundation + credential UX hardening

- `f5cac2c` feat(firebase-setup): add flutterfire platform config files
- `1684014` fix(bootstrap): wire concrete repo implementations and init Firebase
- `dad720f` fix(data-layer): un-ignore Flutter data layer and apply runtime fixes
- `348be72` feat(connections): PIN-derived E2E credential encryption flow
- `c75e7cd` feat(app-lock): add Set PIN / Change PIN UI in Settings
- `be37e5c` fix(app-lock): convert Set PIN dialog to ConsumerStatefulWidget

### Theme B — Broker-integration waves (shared plumbing + four brokers)

- `ff9e1db` docs(broker-integration): add task checklist and orchestrator prompt
- `b607fff` feat(broker-integration/shared-backend-plumbing): wire wrapped-creds flow through backend shared services
- `19da9ee` feat(broker-integration/longbridge): add SDK-backed LongBridge adapter client and tests
- `02c0997` feat(broker-integration/futu): add OpenD client with request-scoped unlock
- `7f06792` feat(broker-integration/binance): wire python-binance client and kline mapping
- `92d5486` feat(broker-integration/ibkr): add ib_insync gateway client and IBKR retry/error coverage
- `873b742` chore(gitignore): exclude .secrets/ and *.key from git
- `4edfc18` feat(broker-integration/flutter-credentials-header): wire wrapped credential headers for e2e broker calls
- `bada756` feat(broker-integration/flutter-wrapped-creds): wire wrapped credentials through snapshot and tx flows
- `38764b1` feat(broker-integration/ui-polish): show sync recency and connection error details
- `0bc4f14` docs(broker-integration): add final status heartbeat and completion report
- `84e4205` feat(broker-integration/backend-vault-sync): read connection records from Firestore
- `07d5fbc` feat(broker-integration): register LongBridge/IBKR/Futu adapter builders

### Theme C — Runtime fixes, auth, FX, and LongBridge data-shape corrections

- `91e25c7` fix(connections): make PIN-required dialog actually accept a PIN
- `584d5b2` fix(connections): show success snackbar after saving a connection
- `9f5ac19` feat(dashboard): add explicit refresh button to AppBar
- `49f3428` fix(infra): point file-backed KMS at writable /home/mbp/.secrets/
- `f2150d1` docs(env): default file-KMS path to the bind-mounted /home/mbp/.secrets/
- `725a314` fix(backend-client): use /portfolio + base_currency to match server
- `c4b3082` fix(mappers): accept backend snake_case in snapshotFromJson
- `797d2e8` fix(mappers): _num accepts numeric strings from the backend wire shape
- `f8eeb63` fix(auth): turn on real Firebase ID-token verification in dev
- `ddc9dbd` fix(connections): convert Add Connection dialog to ConsumerStatefulWidget
- `10133f2` feat(settings): nudge anonymous users to create an account
- `5992a28` fix(auth): require persistent sign-in; stop auto-creating anonymous users
- `2bdba03` fix(vault): iterate QueryResultsList from CollectionReference.get()
- `6369753` fix(refresh): prompt for PIN when the credential key has been wiped
- `9d14537` fix(connections): stop double-encoding the encrypted credential blob
- `1f0b3ed` fix(auth): refresh app-lock state on sign-out so PIN flow self-heals
- `0a430d4` fix(fx): soft-fail individual pairs in get_rates_for
- `47a53ec` fix(longbridge): unwrap typed SDK response objects via _to_iterable
- `01cb5a0` fix(mappers): handle backend snake_case + null fields in Position and CashBalance
- `d1cfd1a` feat(longbridge): enrich positions with live quotes + cost-basis fallback
- `b73a62e` feat(fx): default to Frankfurter (no API key needed) instead of broken exchangerate.host
- `d57650d` chore(longbridge): structured logs for live-quote enrichment
- `e814d20` fix(longbridge): clone position to dict so injected quote prices stick
- `d539e79` chore(longbridge): log raw stock_positions response + per-channel counts

### Theme D — Documentation, runbooking, and orchestrator control plane

- `64faf28` docs: runbook, architecture notes, post-MVP plan, final-report update
- `ec6f115` docs(brokers): per-broker integration details with real API response samples
- `0b9ffc3` docs: orchestrator prompt for the post-MVP iteration

### Theme E — Post-MVP execution slices

- `386b3ea` feat(post-mvp/cleanup-diagnostic-logging): demote verbose broker diagnostics to DEBUG
- `5617ef3` feat(post-mvp/broker-integration-ibkr): wire opportunistic tickle and env-gated gateway test
- `724f830` feat(post-mvp/broker-integration-futu): wire request-scoped trade unlock credentials
- `b60ca13` feat(post-mvp/broker-integration-binance): complete binance trades/balances flow and env-gated integration test
- `55b82ea` feat(post-mvp/transactions-history): wire 90d historical transactions across brokers
- `88d4604` feat(post-mvp/live-quote-streaming): wire authenticated quote WS with broker streaming and live UI prices

---

## Theme F — Post-orchestrator infrastructure hardening (manual, 2026-05-19 onwards)

After the orchestrator finished, 29 additional commits landed on `main` covering runtime fixes
and sidecar automation. Range: `b9f9b8a..7641187`.

### F1 — Auth + app-lock fixes
- `8f0a9f2` fix(app-lock): reset lock state on sign-out and await PIN-derived key
- `4fef6d1` fix(auth): submit on Enter in sign-in/up/reset screens
- `ec3b0b3` fix(app-lock): scope PIN+salt per user and stop wiping storage on sign-out

### F2 — Portfolio cache + PIN gate
- `a893308` fix(portfolio): cache-first build + explicit PIN-gated refresh
- `6587715` fix(dashboard): route pull-to-refresh through the PIN gate
- `f48a9f0` fix(portfolio): never overwrite cached snapshot with a creds-less fetch

### F3 — Futu OpenD self-built Docker image
- `035ff7a` feat(infra/futu): self-built OpenD Docker image with RSA encryption scaffold
- `457b1dc` feat(infra/futu): make backend share OpenD network so we can skip RSA
- `3b9d030` fix(compose): drop backend port publish in override (conflicts with shared netns)
- `0f3dc3e` fix(compose): use container:NAME for backend's network_mode (older compose compat)
- `a74e097` fix(futu): drop <rsa_private_key> tag — forces encryption on all connections
- `ddd3880` chore(backend): bump futu-api to ~=10.6.0 to match OpenD 10.6.6608

### F4 — IBKR self-built gateway image with IBC headless automation
- `e2b1995` feat(infra/ibkr): self-built IB Gateway image with IBC headless automation
- `dbc08e1` fix(ibkr): chmod IBC scripts recursively, use gatewaystart.sh, skip data/ dir
- `ad29251` fix(ibkr): install to /root/Jts (not /root/Jts/ibgateway), drive IBC via env vars
- `33eca6b` fix(ibkr): export TRADING_MODE / TWSUSERID / TWSPASSWORD for IBC launcher
- `ab31962` fix(ibkr): parse version and reorganize install into /root/Jts/<version>/
- `5d6cf8a` fix(ibkr): patch gatewaystart hardcode + clean Xvfb lock on restart
- `f06934a` fix(ibkr): patch out ALL gatewaystart.sh hardcoded defaults
- `3ed4831` fix(ibkr): change sed delimiter so | alternation parses correctly
- `26f0b8e` fix(ibkr): TWS_PATH points to version dir directly so IBC finds vmoptions
- `832b15e` feat(infra/ibkr): adopt gnzsnz/ib-gateway-docker recipe (Apache-2.0)
- `f557de1` feat(ibkr): set EXISTING_SESSION_DETECTED_ACTION=primary
- `baf8bbc` fix(ibkr): set TWS_ACCEPT_INCOMING=accept so API socket actually binds
- `92802c9` debug(ibkr): temp VNC enabled to see blocking dialog
- `c985ab0` debug(ibkr): use port 25901 for VNC (5901 already in use on NAS)
- `fe5df3a` chore(ibkr): remove temp VNC debug exposure

### F5 — Docs
- `7641187` docs: rewrite root README to lead with broker tracker; preserve rnpksync separately

---

## Remaining Manual-Only Work

1. Real broker credential smoke on a live account for each source (Binance, IBKR gateway-authenticated, Futu OpenD-authenticated).
2. Capture and commit a screenshot of the dashboard with real data to `doc/screenshots/post-mvp-dashboard.png`.
3. Optional release tag (for example: `v0.1-personal-mvp`).
