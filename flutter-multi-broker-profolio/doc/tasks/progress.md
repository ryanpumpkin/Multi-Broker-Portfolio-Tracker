# Overall Progress

Each module has its own task file under `doc/tasks/`. Tick a module here once **all** its subtasks are done.

## Flutter Client

- [ ] [flutter-bootstrap](./flutter-bootstrap.md) — project scaffold, router, theme, i18n, logging
- [ ] [flutter-domain](./flutter-domain.md) — entities, repo interfaces, use cases
- [ ] [flutter-data](./flutter-data.md) — Drift, secure storage, E2E crypto, remote clients, repos
- [ ] [flutter-state](./flutter-state.md) — Riverpod providers
- [ ] [flutter-presentation](./flutter-presentation.md) — all screens and widgets
- [ ] [flutter-auth-and-lock](./flutter-auth-and-lock.md) — Firebase Auth + biometric/PIN lock
- [ ] [flutter-notifications](./flutter-notifications.md) — FCM client integration

## Backend Proxy

- [x] [backend-bootstrap](./backend-bootstrap.md) — FastAPI scaffold, auth middleware, ops endpoints
- [ ] [backend-adapters](./backend-adapters.md) — LongBridge, IBKR, Futu, Binance adapters
- [ ] [backend-aggregator-and-fx](./backend-aggregator-and-fx.md) — aggregation + FX service
- [ ] [backend-vault](./backend-vault.md) — credential vault (E2E + KMS)
- [ ] [backend-alert-worker](./backend-alert-worker.md) — background alert evaluator

## Platform / Infra

- [~] [firebase-setup](./firebase-setup.md) — rules, indexes, schema, and emulator tests landed (10/10 passing); client SDK config files (plist/json/`firebase_options.dart`) deferred to developer via `flutterfire configure` — see `firebase/CLIENT_CONFIG.md`
- [ ] [infra-deployment](./infra-deployment.md) — docker-compose with broker gateway sidecars

---

**Legend:** `[ ]` not started · `[~]` in progress · `[x]` done. Update both the module file and this index when status changes.
