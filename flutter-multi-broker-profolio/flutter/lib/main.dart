// coverage:ignore-file
// Bootstrap glue: Firebase + platform channels can't run in unit tests, so
// this file is excluded from coverage. Logic worth testing lives in
// `app.dart`, `router/`, `theme/`, `i18n/`, and `logging/`.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'logging/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the structured logger. Firebase Crashlytics wiring is added
  // by the `flutter-notifications` / Firebase setup steps; for now the
  // logger runs with an in-memory buffer only.
  AppLogger.instance.init();
  AppLogger.instance.info('App bootstrapping', name: 'bootstrap');

  runApp(const ProviderScope(child: MultiBrokerPortfolioApp()));
}
