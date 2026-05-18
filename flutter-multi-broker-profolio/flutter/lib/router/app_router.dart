import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../i18n/generated/app_localizations.dart';
import '../logging/logger.dart';
import '../presentation/auth/auth_screens.dart';
import '../presentation/screens/screens.dart';

/// Stable path constants for every screen referenced in the design.
///
/// Centralizing them avoids stringly-typed navigation and lets downstream
/// modules (auth guards, deep links) reference paths without re-declaring.
class AppRoutes {
  AppRoutes._();
  static const String signIn = '/auth/sign-in';
  static const String signUp = '/auth/sign-up';
  static const String passwordReset = '/auth/password-reset';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/';
  static const String positions = '/positions';
  static const String charts = '/charts';
  static const String transactions = '/transactions';
  static const String connections = '/connections';
  static const String alerts = '/alerts';
  static const String settings = '/settings';
  static const String manualHoldings = '/connections/manual';
  static const String debugLogViewer = '/settings/debug/logs';
}

/// Builds the application's [GoRouter].
///
/// Signature of an auth-state predicate used by the router redirect. The
/// router calls this on every navigation to decide whether to push the
/// user to /auth/sign-in. Production wires it to Firebase Auth; tests
/// pass an always-authed (or always-unauthed) stub.
typedef AuthStateSnapshot = bool Function();

GoRouter buildAppRouter({
  String initialLocation = AppRoutes.dashboard,
  AuthStateSnapshot? isAuthenticated,
  Listenable? authRefreshListenable,
}) {
  // When `isAuthenticated` is not supplied (tests, isolated harnesses),
  // skip the redirect entirely so every route is reachable. Production
  // wiring lives in `app.dart` and supplies a real check.
  GoRouterRedirect? redirect;
  if (isAuthenticated != null) {
    redirect = (context, state) {
      final isAuthRoute = state.matchedLocation.startsWith('/auth/');
      final signedIn = isAuthenticated();
      if (!signedIn && !isAuthRoute) return AppRoutes.signIn;
      if (signedIn && isAuthRoute) return AppRoutes.dashboard;
      return null;
    };
  }
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authRefreshListenable,
    redirect: redirect,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: 'sign-in',
        builder: (context, __) => SignInScreen(
          onCreateAccount: () => context.go(AppRoutes.signUp),
          onForgotPassword: () => context.go(AppRoutes.passwordReset),
        ),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: 'sign-up',
        builder: (context, __) => SignUpScreen(
          onSignedUp: () => context.go(AppRoutes.dashboard),
        ),
      ),
      GoRoute(
        path: AppRoutes.passwordReset,
        name: 'password-reset',
        builder: (_, __) => const PasswordResetScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.positions,
        name: 'positions',
        builder: (_, __) => const PositionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.charts,
        name: 'charts',
        builder: (_, __) => const ChartsScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        name: 'transactions',
        builder: (_, __) => const TransactionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.connections,
        name: 'connections',
        builder: (_, __) => const ConnectionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.alerts,
        name: 'alerts',
        builder: (_, __) => const AlertsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'debug/logs',
            name: 'debug-log-viewer',
            builder: (_, __) => const DebugLogViewerScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.manualHoldings,
        name: 'manual-holdings',
        builder: (_, __) => const ManualHoldingsScreen(),
      ),
    ],
  );
}

/// Whether the debug log viewer should expose log records.
///
/// Debug & profile builds: yes. Release builds: no (the screen stays
/// reachable so deep links don't 404, but renders an empty state).
bool get debugLogViewerEnabled => !kReleaseMode;

/// Debug-only screen that lists in-memory log records.
///
/// In release builds it renders the empty state so production users who
/// somehow reach the deep link never see internal log lines.
class DebugLogViewerScreen extends StatelessWidget {
  const DebugLogViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final records = debugLogViewerEnabled
        ? AppLogger.instance.buffered
        : const <AppLogRecord>[];
    return Scaffold(
      appBar: AppBar(title: Text(l.debugLogViewerTitle)),
      body: records.isEmpty
          ? Center(child: Text(l.debugLogViewerEmpty))
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (_, i) => ListTile(
                dense: true,
                title: Text(records[i].toString()),
              ),
            ),
    );
  }
}

/// Bridges a [Stream] (e.g. `FirebaseAuth.authStateChanges()`) into a
/// `Listenable` so `GoRouter` re-evaluates its `redirect` whenever the
/// auth state changes — pushing signed-out users to /auth/sign-in and
/// signed-in users away from auth screens.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
