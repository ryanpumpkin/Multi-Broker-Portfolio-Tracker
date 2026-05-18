import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_broker_portfolio/app.dart';
import 'package:multi_broker_portfolio/i18n/generated/app_localizations.dart';
import 'package:multi_broker_portfolio/logging/logger.dart';
import 'package:multi_broker_portfolio/router/app_router.dart';

import 'presentation/presentation_test_harness.dart';

Future<void> _pumpAt(WidgetTester tester, String location) async {
  // Pump an empty frame first so the previous app's State (which caches the
  // router) is disposed; otherwise `pumpWidget` reuses the State and we
  // navigate to the wrong initial location.
  await tester.pumpWidget(const SizedBox.shrink());
  final router = buildAppRouter(initialLocation: location);
  await tester.pumpWidget(
    ProviderScope(
      overrides: buildPresentationTestOverrides(),
      child: MultiBrokerPortfolioApp(
        routerOverride: router,
        localeOverride: const Locale('en'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('buildAppRouter', () {
    testWidgets('renders dashboard at "/"', (tester) async {
      await _pumpAt(tester, AppRoutes.dashboard);
      // Localized title for dashboard route
      final ctx = tester.element(find.byType(Scaffold));
      expect(
        find.text(AppLocalizations.of(ctx).navDashboard),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('renders every top-level route', (tester) async {
      final paths = <String, String Function(AppLocalizations)>{
        AppRoutes.dashboard: (l) => l.navDashboard,
        AppRoutes.positions: (l) => l.navPositions,
        AppRoutes.charts: (l) => l.navCharts,
        AppRoutes.transactions: (l) => l.navTransactions,
        AppRoutes.connections: (l) => l.navConnections,
        AppRoutes.alerts: (l) => l.navAlerts,
        AppRoutes.settings: (l) => l.navSettings,
      };
      for (final entry in paths.entries) {
        await _pumpAt(tester, entry.key);
        final ctx = tester.element(find.byType(Scaffold));
        expect(
          find.text(entry.value(AppLocalizations.of(ctx))),
          findsAtLeastNWidgets(1),
          reason: 'route ${entry.key} should display its localized title',
        );
      }
    });

    testWidgets('renders sign-in and onboarding screens', (tester) async {
      await _pumpAt(tester, AppRoutes.signIn);
      expect(find.text('Sign in'), findsAtLeastNWidgets(1));

      await _pumpAt(tester, AppRoutes.onboarding);
      expect(find.text('Get started'), findsAtLeastNWidgets(1));
    });

    testWidgets('debug log viewer shows empty state with no records',
        (tester) async {
      AppLogger.instance.init();
      AppLogger.instance.clearBuffer();
      AppLogger.instance.clearSinks();
      await _pumpAt(tester, AppRoutes.debugLogViewer);
      final ctx = tester.element(find.byType(Scaffold));
      expect(
        find.text(AppLocalizations.of(ctx).debugLogViewerEmpty),
        findsOneWidget,
      );
    });

    testWidgets('debug log viewer lists buffered records', (tester) async {
      AppLogger.instance.init();
      AppLogger.instance.clearBuffer();
      AppLogger.instance.clearSinks();
      AppLogger.instance.info('hello-router-test');
      await _pumpAt(tester, AppRoutes.debugLogViewer);
      expect(find.textContaining('hello-router-test'), findsOneWidget);
    });

    test('debugLogViewerEnabled is true in debug/test builds', () {
      expect(debugLogViewerEnabled, isTrue);
    });
  });

  group('AppRoutes', () {
    test('paths are stable and unique', () {
      final paths = <String>{
        AppRoutes.dashboard,
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.passwordReset,
        AppRoutes.onboarding,
        AppRoutes.positions,
        AppRoutes.charts,
        AppRoutes.transactions,
        AppRoutes.connections,
        AppRoutes.alerts,
        AppRoutes.settings,
        AppRoutes.debugLogViewer,
        AppRoutes.manualHoldings,
      };
      expect(paths.length, 13);
    });
  });
}
