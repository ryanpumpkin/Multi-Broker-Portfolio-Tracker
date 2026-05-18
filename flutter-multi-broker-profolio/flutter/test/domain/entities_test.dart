import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';

void main() {
  group('Position', () {
    test('computed factory derives marketValue and unrealizedPnl', () {
      final p = Position.computed(
        sourceId: 'lb',
        symbol: 'AAPL',
        name: 'Apple',
        assetClass: AssetClass.stock,
        quantity: 10,
        avgCost: 100,
        currentPrice: 150,
        currency: 'USD',
      );
      expect(p.marketValue, 1500);
      expect(p.unrealizedPnl, 500);
    });

    test('copyWith and value equality', () {
      final p = Position.computed(
        sourceId: 'lb',
        symbol: 'AAPL',
        name: 'Apple',
        assetClass: AssetClass.stock,
        quantity: 1,
        avgCost: 1,
        currentPrice: 2,
        currency: 'USD',
      );
      final p2 = p.copyWith(name: 'Apple Inc.');
      expect(p2, isNot(equals(p)));
      expect(p2.copyWith(name: 'Apple'), equals(p));
      expect(p.hashCode, equals(p.copyWith().hashCode));
      expect(p.toString(), contains('AAPL'));
    });
  });

  group('Transaction.cashImpact', () {
    Transaction tx(TransactionType type, {double qty = 1, double price = 10, double fee = 0}) =>
        Transaction(
          id: 't',
          sourceId: 's',
          time: DateTime.utc(2026, 1, 1),
          type: type,
          symbol: 'X',
          quantity: qty,
          price: price,
          currency: 'USD',
          fee: fee,
        );

    test('buy is negative (qty*price + fee)', () {
      expect(tx(TransactionType.buy, qty: 2, price: 10, fee: 1).cashImpact, -21);
    });
    test('sell is positive minus fee', () {
      expect(tx(TransactionType.sell, qty: 2, price: 10, fee: 1).cashImpact, 19);
    });
    test('dividend is positive minus fee', () {
      expect(tx(TransactionType.dividend, qty: 1, price: 5, fee: 0).cashImpact, 5);
    });
    test('fee-only is -fee', () {
      expect(tx(TransactionType.fee, fee: 3).cashImpact, -3);
    });
    test('deposit/withdrawal use qty*price', () {
      expect(tx(TransactionType.deposit, qty: 1, price: 100).cashImpact, 100);
      expect(tx(TransactionType.withdrawal, qty: 1, price: 50).cashImpact, -50);
    });
    test('cryptoTrade is negative', () {
      expect(tx(TransactionType.cryptoTrade, qty: 1, price: 100, fee: 2).cashImpact, -102);
    });
    test('copyWith / equality / toString', () {
      final t = tx(TransactionType.buy);
      expect(t.copyWith(), equals(t));
      expect(t.copyWith(id: 'x'), isNot(equals(t)));
      expect(t.hashCode, equals(t.copyWith().hashCode));
      expect(t.toString(), contains('symbol: X'));
    });
  });

  group('CashBalance / Connection / ManualHolding / PriceQuote / FxRate', () {
    test('CashBalance equality and copyWith', () {
      const a = CashBalance(sourceId: 's', currency: 'USD', available: 100);
      expect(a.copyWith(available: 100), equals(a));
      expect(a.copyWith(available: 50), isNot(equals(a)));
      expect(a.hashCode, equals(a.copyWith().hashCode));
      expect(a.toString(), contains('USD'));
    });
    test('Connection equality / copyWith / toString', () {
      const c = Connection(
        id: 'c1',
        kind: ConnectionKind.binance,
        label: 'Binance Main',
        status: ConnectionStatus.ok,
        credentialMode: CredentialMode.e2e,
      );
      expect(c.copyWith(status: ConnectionStatus.error).status, ConnectionStatus.error);
      expect(c.copyWith(), equals(c));
      expect(c.hashCode, equals(c.copyWith().hashCode));
      expect(c.toString(), contains('Binance Main'));
    });
    test('ManualHolding equality / copyWith / toString', () {
      const m = ManualHolding(
        id: 'm1',
        label: 'House',
        assetClass: AssetClass.realEstate,
        quantity: 1,
        valueCurrency: 'HKD',
        valueAmount: 1000000,
      );
      expect(m.copyWith(), equals(m));
      expect(m.copyWith(label: 'Flat'), isNot(equals(m)));
      expect(m.hashCode, equals(m.copyWith().hashCode));
      expect(m.toString(), contains('House'));
    });
    test('PriceQuote equality / copyWith', () {
      final q = PriceQuote(
        symbol: 'AAPL',
        price: 1,
        currency: 'USD',
        timestamp: DateTime.utc(2026),
      );
      expect(q.copyWith(), equals(q));
      expect(q.copyWith(price: 2), isNot(equals(q)));
      expect(q.hashCode, equals(q.copyWith().hashCode));
      expect(q.toString(), contains('AAPL'));
    });
    test('FxRate.inverse and equality', () {
      final r = FxRate(
        base: 'USD',
        quote: 'HKD',
        rate: 8,
        timestamp: DateTime.utc(2026),
      );
      final inv = r.inverse();
      expect(inv.base, 'HKD');
      expect(inv.quote, 'USD');
      expect(inv.rate, closeTo(1 / 8, 1e-9));
      expect(r.copyWith(), equals(r));
      expect(r.copyWith(rate: 9), isNot(equals(r)));
      expect(r.hashCode, equals(r.copyWith().hashCode));
      expect(r.toString(), contains('USD/HKD'));
    });
  });

  group('Alert / AlertScope', () {
    test('AlertScope.symbol vs portfolio equality', () {
      const a = AlertScope.symbol('AAPL');
      const b = AlertScope.symbol('AAPL');
      const c = AlertScope.portfolio();
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.toString(), contains('AAPL'));
      expect(c.toString(), contains('portfolio'));
    });
    test('Alert copyWith / equality / toString', () {
      const a = Alert(
        id: 'a1',
        kind: AlertKind.priceAbove,
        scope: AlertScope.symbol('AAPL'),
        threshold: 200,
        active: true,
      );
      expect(a.copyWith(active: false).active, isFalse);
      expect(a.copyWith(), equals(a));
      expect(a.copyWith(threshold: 100), isNot(equals(a)));
      expect(a.hashCode, equals(a.copyWith().hashCode));
      expect(a.toString(), contains('priceAbove'));
    });
  });

  group('PortfolioSnapshot', () {
    PortfolioSnapshot mk({
      List<Position>? pos,
      Map<String, double>? src,
      Map<String, double>? cur,
      double base = 100,
    }) =>
        PortfolioSnapshot(
          asOf: DateTime.utc(2026),
          baseCurrency: 'USD',
          positions: pos ?? const [],
          cashBalances: const [],
          totalsBySource: src ?? const {'lb': 100},
          totalsByCurrency: cur ?? const {'USD': 100},
          totalBaseValue: base,
          totalUnrealizedPnlBase: 10,
        );

    test('equality compares deeply', () {
      final a = mk();
      final b = mk();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
    test('inequality on differing maps / positions / totals', () {
      final a = mk();
      expect(a, isNot(equals(mk(base: 101))));
      expect(a, isNot(equals(mk(src: {'lb': 99}))));
      expect(a, isNot(equals(mk(src: {'lb': 100, 'ibkr': 50}))));
      expect(a, isNot(equals(mk(cur: {'HKD': 100}))));
      final p = Position.computed(
        sourceId: 'lb',
        symbol: 'A',
        name: 'A',
        assetClass: AssetClass.stock,
        quantity: 1,
        avgCost: 1,
        currentPrice: 1,
        currency: 'USD',
      );
      expect(a, isNot(equals(mk(pos: [p]))));
    });
    test('copyWith returns equal when unchanged', () {
      final a = mk();
      expect(a.copyWith(), equals(a));
      expect(a.toString(), contains('USD'));
    });
  });

  group('DateRange', () {
    test('contains respects bounds', () {
      final r = DateRange(
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 12, 31),
      );
      expect(r.contains(DateTime.utc(2026, 6, 1)), isTrue);
      expect(r.contains(DateTime.utc(2025, 12, 31)), isFalse);
      expect(r.contains(DateTime.utc(2027)), isFalse);
      expect(const DateRange().contains(DateTime.utc(1999)), isTrue);
      expect(r, equals(DateRange(start: r.start, end: r.end)));
      expect(r.hashCode, isNot(0));
      expect(r.toString(), contains('DateRange'));
    });
  });

  group('AuthUser', () {
    test('equality / copyWith / toString', () {
      const u = AuthUser(uid: 'u', email: 'a@b.com', displayName: 'A');
      expect(u.copyWith(), equals(u));
      expect(u.copyWith(displayName: 'B'), isNot(equals(u)));
      expect(u.hashCode, equals(u.copyWith().hashCode));
      expect(u.toString(), contains('a@b.com'));
    });
  });
}
