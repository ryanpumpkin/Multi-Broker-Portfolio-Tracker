import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/presentation/screens/alerts/alerts_screen.dart';
import 'package:multi_broker_portfolio/presentation/screens/charts/charts_screen.dart';
import 'package:multi_broker_portfolio/presentation/screens/connections/connections_screen.dart';
import 'package:multi_broker_portfolio/presentation/screens/connections/manual/manual_holdings_screen.dart';
import 'package:multi_broker_portfolio/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:multi_broker_portfolio/presentation/screens/settings/settings_screen.dart';
import 'package:multi_broker_portfolio/presentation/screens/transactions/transactions_screen.dart';

import 'presentation_test_harness.dart';

void main() {
  testWidgets('onboarding renders setup form', (tester) async {
    await tester.pumpWidget(wrapForTest(const OnboardingScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(
      find.byKey(const Key('onboarding_connection_label')),
      'Primary broker',
    );
    expect(find.byKey(const Key('onboarding_continue')), findsOneWidget);
  });

  testWidgets('charts screen renders all tabs', (tester) async {
    await tester.pumpWidget(wrapForTest(const ChartsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Portfolio value'), findsOneWidget);
    await tester.tap(find.text('P&L'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allocation'));
    await tester.pumpAndSettle();
  });

  testWidgets('transactions applies filters and shows export action',
      (tester) async {
    await tester.pumpWidget(wrapForTest(const TransactionsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.download_outlined));
    await tester.pumpAndSettle();
    expect(find.textContaining('Export started'), findsOneWidget);
  });

  testWidgets('connections screen can open add dialog', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        const ConnectionsScreen(),
        overrides: buildAppLockUnlockedOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('connections_add_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('connection_label_input')),
      'IBKR account',
    );
    await tester.tap(find.byKey(const Key('connection_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('IBKR account'), findsOneWidget);
  });

  testWidgets('manual holdings screen supports add holding', (tester) async {
    await tester.pumpWidget(wrapForTest(const ManualHoldingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Cash reserve');
    await tester.enterText(find.byType(TextFormField).at(1), '2');
    await tester.enterText(find.byType(TextFormField).at(2), 'USD');
    await tester.enterText(find.byType(TextFormField).at(3), '1500');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Cash reserve'), findsOneWidget);
  });

  testWidgets('alerts screen can open add sheet', (tester) async {
    await tester.pumpWidget(wrapForTest(const AlertsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('alerts_add_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('alert_form_submit')), findsOneWidget);
  });

  testWidgets('settings screen renders and signs out', (tester) async {
    await tester.pumpWidget(wrapForTest(const SettingsScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('settings_currency_mode')), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
