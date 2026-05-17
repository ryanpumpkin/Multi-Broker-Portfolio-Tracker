# multi_broker_portfolio

Flutter client for the Multi-Broker Portfolio Tracker. This sub-folder is
owned by the `flutter-bootstrap` module and downstream Flutter modules
(`flutter-domain`, `flutter-data`, `flutter-state`, `flutter-presentation`,
`flutter-auth-and-lock`, `flutter-notifications`). See
`../doc/detailed-design.md` for the layered architecture overview.

## Targets

- iOS, Android, Web (configured at `flutter create` time)

## Layout

```
lib/
  app.dart                Root MaterialApp + router/theme/i18n wiring
  main.dart               Bootstrap (Firebase + ProviderScope) — excluded from coverage
  router/                 go_router config and placeholder screens
  theme/                  Material 3 light + dark themes, follow-system mode
  i18n/                   ARB files (en, zh_Hant) + generated AppLocalizations
  logging/                Structured logger + Crashlytics adapter
  domain/  data/  state/  presentation/  notifications/  app_lock/
                          Placeholders implemented by other modules.
```

## Running gates locally

```
cd flutter
flutter pub get
flutter gen-l10n              # regenerates lib/i18n/generated/* from ARB
flutter analyze               # zero issues required
flutter test --coverage       # unit + widget tests, lcov.info under coverage/
```

## Smoke run

```
flutter run -d chrome          # web
flutter run -d <ios-sim-id>    # iOS simulator
flutter run -d <android-id>    # Android emulator
```

The app boots to `/` (dashboard placeholder). Real screens land with the
`flutter-presentation` module.
