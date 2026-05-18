import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';

PriceQuote _q(String s, double p) => PriceQuote(
      symbol: s,
      price: p,
      currency: 'USD',
      timestamp: DateTime.utc(2026),
    );

PortfolioSnapshot _snap({
  required double totalBase,
  required double pnl,
  List<Position> positions = const [],
}) =>
    PortfolioSnapshot(
      asOf: DateTime.utc(2026),
      baseCurrency: 'USD',
      positions: positions,
      cashBalances: const [],
      totalsBySource: const {},
      totalsByCurrency: const {},
      totalBaseValue: totalBase,
      totalUnrealizedPnlBase: pnl,
    );

void main() {
  const ev = EvaluateAlert();

  group('priceAbove / priceBelow', () {
    const above = Alert(
      id: 'a',
      kind: AlertKind.priceAbove,
      scope: AlertScope.symbol('AAPL'),
      threshold: 150,
      active: true,
    );
    test('triggers when price exceeds threshold', () {
      expect(ev(above, quote: _q('AAPL', 200)), isTrue);
    });
    test('does not trigger below or equal', () {
      expect(ev(above, quote: _q('AAPL', 150)), isFalse);
      expect(ev(above, quote: _q('AAPL', 100)), isFalse);
    });
    test('does not trigger for a different symbol', () {
      expect(ev(above, quote: _q('GOOG', 999)), isFalse);
    });
    test('priceBelow', () {
      const below = Alert(
        id: 'b',
        kind: AlertKind.priceBelow,
        scope: AlertScope.symbol('AAPL'),
        threshold: 100,
        active: true,
      );
      expect(ev(below, quote: _q('AAPL', 99)), isTrue);
      expect(ev(below, quote: _q('AAPL', 100)), isFalse);
    });
    test('inactive alert never triggers', () {
      expect(ev(above.copyWith(active: false), quote: _q('AAPL', 9999)), isFalse);
    });
    test('missing quote returns false', () {
      expect(ev(above), isFalse);
    });
    test('portfolio scope is invalid for price kinds', () {
      const p = Alert(
        id: 'c',
        kind: AlertKind.priceAbove,
        scope: AlertScope.portfolio(),
        threshold: 1,
        active: true,
      );
      expect(ev(p, quote: _q('AAPL', 100)), isFalse);
    });
  });

  group('pnlPctAbove / pnlPctBelow — portfolio scope', () {
    const a = Alert(
      id: 'p',
      kind: AlertKind.pnlPctAbove,
      scope: AlertScope.portfolio(),
      threshold: 5,
      active: true,
    );
    test('triggers when portfolio pnl pct exceeds threshold', () {
      // cost = 1000 - 100 = 900, pct = 100/900 = 11.11%
      expect(ev(a, snapshot: _snap(totalBase: 1000, pnl: 100)), isTrue);
    });
    test('does not trigger at or below threshold', () {
      // 4% < 5%
      expect(ev(a, snapshot: _snap(totalBase: 104, pnl: 4)), isFalse);
    });
    test('pnlPctBelow', () {
      const b = Alert(
        id: 'p2',
        kind: AlertKind.pnlPctBelow,
        scope: AlertScope.portfolio(),
        threshold: -10,
        active: true,
      );
      // pnl = -20, cost = 100, pct = -20%
      expect(ev(b, snapshot: _snap(totalBase: 80, pnl: -20)), isTrue);
      // pct = -5%
      expect(ev(b, snapshot: _snap(totalBase: 95, pnl: -5)), isFalse);
    });
    test('missing snapshot returns false', () {
      expect(ev(a), isFalse);
    });
    test('zero cost basis returns false (no div by zero)', () {
      expect(ev(a, snapshot: _snap(totalBase: 100, pnl: 100)), isFalse);
    });
  });

  group('pnlPctAbove — symbol scope', () {
    Position p({double qty = 10, double cur = 150, double avg = 100}) =>
        Position.computed(
          sourceId: 'lb',
          symbol: 'AAPL',
          name: 'Apple',
          assetClass: AssetClass.stock,
          quantity: qty,
          avgCost: avg,
          currentPrice: cur,
          currency: 'USD',
        );

    const a = Alert(
      id: 's',
      kind: AlertKind.pnlPctAbove,
      scope: AlertScope.symbol('AAPL'),
      threshold: 20,
      active: true,
    );

    test('triggers from aggregated position rows', () {
      // mv = 1500, pnl = 500 => 50%
      expect(ev(a, snapshot: _snap(totalBase: 0, pnl: 0, positions: [p()])), isTrue);
    });
    test('does not trigger when symbol absent', () {
      expect(ev(a, snapshot: _snap(totalBase: 0, pnl: 0)), isFalse);
    });
    test('zero quantity returns false', () {
      expect(
        ev(a, snapshot: _snap(totalBase: 0, pnl: 0, positions: [p(qty: 0)])),
        isFalse,
      );
    });
    test('zero cost basis returns false', () {
      // current == avg means pnl 0, cost = mv => non-zero, pct = 0
      final flat = p(cur: 100);
      // construct snapshot with positions list
      expect(
        ev(a, snapshot: _snap(totalBase: 0, pnl: 0, positions: [flat])),
        isFalse,
      );
    });
    test('missing snapshot returns false', () {
      expect(ev(a), isFalse);
    });
  });
}
