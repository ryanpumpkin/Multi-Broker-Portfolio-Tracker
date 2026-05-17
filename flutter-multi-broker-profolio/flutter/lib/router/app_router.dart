import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../i18n/generated/app_localizations.dart';
import '../logging/logger.dart';

/// Stable path constants for every screen referenced in the design.
///
/// Centralizing them avoids stringly-typed navigation and lets downstream
/// modules (auth guards, deep links) reference paths without re-declaring.
class AppRoutes {
  AppRoutes._();
  static const String signIn = '/auth/sign-in';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/';
  static const String positions = '/positions';
  static const String charts = '/charts';
  static const String transactions = '/transactions';
  static const String connections = '/connections';
  static const String alerts = '/alerts';
  static const String settings = '/settings';
  static const String debugLogViewer = '/settings/debug/logs';
}

/// Builds the application's [GoRouter].
///
/// The router is intentionally configured with placeholder screens — the
/// presentation module will replace each `_Placeholder` with a real widget.
/// Registering every route up front means deep links and tests work from
/// day one.
GoRouter buildAppRouter({String initialLocation = AppRoutes.dashboard}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (_, __) => const _Placeholder(titleKey: _TitleKey.dashboard),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: 'sign-in',
        builder: (_, __) => const _Placeholder(titleKey: _TitleKey.signIn),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (_, __) =>
            const _Placeholder(titleKey: _TitleKey.onboarding),
      ),
      GoRoute(
        path: AppRoutes.positions,
        name: 'positions',
        builder: (_, __) =>
            const _Placeholder(titleKey: _TitleKey.positions),
      ),
      GoRoute(
        path: AppRoutes.charts,
        name: 'charts',
        builder: (_, __) => const _Placeholder(titleKey: _TitleKey.charts),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        name: 'transactions',
        builder: (_, __) =>
            const _Placeholder(titleKey: _TitleKey.transactions),
      ),
      GoRoute(
        path: AppRoutes.connections,
        name: 'connections',
        builder: (_, __) =>
            const _Placeholder(titleKey: _TitleKey.connections),
      ),
      GoRoute(
        path: AppRoutes.alerts,
        name: 'alerts',
        builder: (_, __) => const _Placeholder(titleKey: _TitleKey.alerts),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (_, __) =>
            const _Placeholder(titleKey: _TitleKey.settings),
        routes: <RouteBase>[
          GoRoute(
            path: 'debug/logs',
            name: 'debug-log-viewer',
            builder: (_, __) => const DebugLogViewerScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Whether the debug log viewer should expose log records.
///
/// Debug & profile builds: yes. Release builds: no (the screen stays
/// reachable so deep links don't 404, but renders an empty state).
bool get debugLogViewerEnabled => !kReleaseMode;

enum _TitleKey {
  signIn,
  onboarding,
  dashboard,
  positions,
  charts,
  transactions,
  connections,
  alerts,
  settings,
}

String _titleFor(_TitleKey k, AppLocalizations l) {
  switch (k) {
    case _TitleKey.signIn:
    case _TitleKey.onboarding:
      return l.appTitle;
    case _TitleKey.dashboard:
      return l.navDashboard;
    case _TitleKey.positions:
      return l.navPositions;
    case _TitleKey.charts:
      return l.navCharts;
    case _TitleKey.transactions:
      return l.navTransactions;
    case _TitleKey.connections:
      return l.navConnections;
    case _TitleKey.alerts:
      return l.navAlerts;
    case _TitleKey.settings:
      return l.navSettings;
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.titleKey});
  final _TitleKey titleKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(titleKey, l))),
      body: Center(child: Text(l.placeholderScreen)),
    );
  }
}

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
