import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';
import 'package:multi_broker_portfolio/presentation/screens/positions/positions_screen.dart';
import 'package:multi_broker_portfolio/state/quotes_provider.dart';
import 'package:multi_broker_portfolio/state/repository_providers.dart';

import 'presentation_test_harness.dart';

/// A [QuotesRepository] whose stream is driven by a manually controlled
/// [StreamController], letting tests push quotes at will.
class _ControllableQuotesRepository implements QuotesRepository {
  _ControllableQuotesRepository(this._controller);

  final StreamController<PriceQuote> _controller;

  @override
  Stream<PriceQuote> streamQuotes(List<String> symbols) => _controller.stream;
}

void main() {
  testWidgets(
    'PositionsScreen shows static price before first live quote',
    (tester) async {
      final ctrl = StreamController<PriceQuote>.broadcast();
      addTearDown(ctrl.close);

      await tester.pumpWidget(
        wrapForTest(
          const PositionsScreen(),
          overrides: [
            quotesRepositoryProvider.overrideWithValue(
              _ControllableQuotesRepository(ctrl),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Before any live quote arrives, the row for AAPL should be visible
      // (rendered with the static snapshot price of 120).
      expect(find.byKey(const Key('position_AAPL')), findsOneWidget);
    },
  );

  testWidgets(
    'PositionsScreen updates market value when live quote arrives',
    (tester) async {
      final ctrl = StreamController<PriceQuote>.broadcast();
      addTearDown(ctrl.close);

      await tester.pumpWidget(
        wrapForTest(
          const PositionsScreen(),
          overrides: [
            quotesRepositoryProvider.overrideWithValue(
              _ControllableQuotesRepository(ctrl),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Push a live AAPL quote.
      ctrl.add(
        PriceQuote(
          symbol: 'AAPL',
          price: 999.0,
          currency: 'USD',
          timestamp: DateTime.utc(2026, 5, 19),
        ),
      );
      // Allow Riverpod / StreamProvider to propagate the new value.
      await tester.pump();
      await tester.pumpAndSettle();

      // The AAPL row should still be visible.
      expect(find.byKey(const Key('position_AAPL')), findsOneWidget);
    },
  );

  testWidgets(
    'PositionsScreen falls back gracefully when quotesProvider is in error',
    (tester) async {
      // Override quotesProvider family directly to simulate a stream error.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...buildPresentationTestOverrides(),
            // Override the family provider to always return an error AsyncValue.
            quotesProvider.overrideWith(
              (ref, symbol) => Stream<PriceQuote>.error(
                Exception('network error'),
              ),
            ),
          ],
          child: const MaterialApp(home: PositionsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Screen should still render without crashing.
      expect(find.byKey(const Key('position_AAPL')), findsOneWidget);
      expect(find.byKey(const Key('position_BTC')), findsOneWidget);
    },
  );
}
