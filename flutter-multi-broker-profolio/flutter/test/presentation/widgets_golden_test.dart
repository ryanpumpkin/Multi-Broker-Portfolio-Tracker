import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/presentation/widgets/allocation_donut.dart';
import 'package:multi_broker_portfolio/presentation/widgets/currency_amount.dart';
import 'package:multi_broker_portfolio/presentation/widgets/pnl_badge.dart';

import 'presentation_test_harness.dart';

void main() {
  testWidgets('PnlBadge golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapForTest(
        const Scaffold(
          body: Center(
            child: PnlBadge(amount: 150.5, percent: 6.25, currency: 'USD'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/pnl_badge.png'),
    );
  });

  testWidgets('CurrencyAmount golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapForTest(
        const Scaffold(
          body: Center(
            child: CurrencyAmount(
              amount: 12345.678,
              currency: 'USD',
              baseCurrency: 'USD',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/currency_amount.png'),
    );
  });

  testWidgets('AllocationDonut golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(520, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapForTest(
        const Scaffold(
          body: AllocationDonut(
            allocations: {
              'Equity': 55,
              'Crypto': 25,
              'Cash': 20,
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/allocation_donut.png'),
    );
  });
}
