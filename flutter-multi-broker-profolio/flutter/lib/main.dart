// coverage:ignore-file
// Bootstrap glue: Firebase + platform channels can't run in unit tests, so
// this file is excluded from coverage. Logic worth testing lives in
// `app.dart`, `router/`, `theme/`, `i18n/`, and `logging/`.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'logging/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Note: we do NOT auto-sign-in anonymously. The router redirects
  // unauthenticated users to /auth/sign-in so they create a persistent
  // email/password account. Anonymous Firebase Auth on Flutter Web does
  // not survive a fresh `flutter run` (new Chrome profile, fresh
  // IndexedDB), which caused every restart to mint a new uid and lose
  // saved Firestore connections.

  // Initialize the structured logger. Firebase Crashlytics wiring is added
  // by the `flutter-notifications` / Firebase setup steps; for now the
  // logger runs with an in-memory buffer only.
  AppLogger.instance.init();
  AppLogger.instance.info('App bootstrapping', name: 'bootstrap');

  runApp(const ProviderScope(child: MultiBrokerPortfolioApp()));
}
