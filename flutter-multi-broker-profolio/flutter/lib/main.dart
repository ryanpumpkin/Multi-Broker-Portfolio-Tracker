// coverage:ignore-file
// Bootstrap glue: Firebase + platform channels can't run in unit tests, so
// this file is excluded from coverage. Logic worth testing lives in
// `app.dart`, `router/`, `theme/`, `i18n/`, and `logging/`.

import 'package:firebase_auth/firebase_auth.dart';
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

  // Ensure we always have a Firebase user so Firestore reads/writes scoped
  // under /users/{uid}/ work. If the user later signs in with email/password,
  // their data can be migrated from the anonymous account.
  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e, st) {
      // Anonymous auth must be enabled in the Firebase console under
      // Authentication → Sign-in method → Anonymous.
      AppLogger.instance.error(
        'Anonymous sign-in failed; enable Anonymous auth in Firebase console.',
        name: 'bootstrap',
        error: e,
        stackTrace: st,
      );
    }
  }

  // Initialize the structured logger. Firebase Crashlytics wiring is added
  // by the `flutter-notifications` / Firebase setup steps; for now the
  // logger runs with an in-memory buffer only.
  AppLogger.instance.init();
  AppLogger.instance.info('App bootstrapping', name: 'bootstrap');

  runApp(const ProviderScope(child: MultiBrokerPortfolioApp()));
}
