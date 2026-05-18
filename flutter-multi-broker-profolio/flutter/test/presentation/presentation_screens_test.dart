import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/presentation/screens/alerts/alerts_screen.dart';
import 'package:multi_broker_portfolio/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:multi_broker_portfolio/presentation/screens/positions/positions_screen.dart';

import 'presentation_test_harness.dart';

void main() {
  testWidgets('dashboard happy path renders totals and sources',
      (tester) async {
    await tester.pumpWidget(wrapForTest(const DashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_total_value')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_total_pnl')), findsOneWidget);
    expect(find.text('LongBridge'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Binance'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Binance'), findsOneWidget);
  });

  testWidgets('positions sorting changes row order', (tester) async {
    await tester.pumpWidget(wrapForTest(const PositionsScreen()));
    await tester.pumpAndSettle();

    final btcFinder = find.byKey(const Key('position_BTC'));
    final aaplFinder = find.byKey(const Key('position_AAPL'));

    expect(
      tester.getTopLeft(btcFinder).dy,
      lessThan(tester.getTopLeft(aaplFinder).dy),
    );

    await tester.tap(find.byKey(const Key('positions_sort_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Symbol').last);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(aaplFinder).dy,
      lessThan(tester.getTopLeft(btcFinder).dy),
    );
  });

  testWidgets('alerts form validates required fields', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        const Scaffold(body: AlertFormSheet()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('alert_form_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Symbol is required'), findsOneWidget);
    expect(find.text('Threshold must be greater than 0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('alert_form_scope_portfolio')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('alert_form_submit')));
    await tester.pumpAndSettle();
    expect(
      find.text('Portfolio scope supports P&L alerts only'),
      findsOneWidget,
    );
  });
}
