import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/data/repositories/mappers.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';

void main() {
  group('Mappers', () {
    test('assetClassFromString handles unknown', () {
      expect(Mappers.assetClassFromString('stock'), AssetClass.stock);
      expect(Mappers.assetClassFromString('???'), AssetClass.other);
    });

    test('positionFromJson and toJson round-trip', () {
      const p = Position(
        sourceId: 'lb',
        symbol: 'AAPL',
        name: 'Apple',
        assetClass: AssetClass.stock,
        quantity: 1,
        avgCost: 100,
        currentPrice: 150,
        currency: 'USD',
        marketValue: 150,
        unrealizedPnl: 50,
      );
      final j = Mappers.positionToJson(p);
      final back = Mappers.positionFromJson(j);
      expect(back, p);
    });

    test('transactionFromJson parses ISO time and enum', () {
      final t = Mappers.transactionFromJson({
        'id': '1',
        'sourceId': 'a',
        'time': '2025-01-01T00:00:00Z',
        'type': 'sell',
        'symbol': 'X',
        'quantity': 2,
        'price': 5,
        'currency': 'USD',
        'fee': 0.1,
      });
      expect(t.type, TransactionType.sell);
      expect(t.time.isUtc, true);
    });

    test('cashBalanceFromJson', () {
      final c = Mappers.cashBalanceFromJson({
        'sourceId': 'a',
        'currency': 'USD',
        'available': 100,
      });
      expect(c.available, 100);
    });

    test('fxFromJson parses', () {
      final f = Mappers.fxFromJson({
        'base': 'USD',
        'quote': 'HKD',
        'rate': 7.8,
        'timestamp': '2025-01-01T00:00:00Z',
      });
      expect(f.rate, 7.8);
    });

    test('snapshotFromJson handles empty fields gracefully', () {
      final s = Mappers.snapshotFromJson({
        'asOf': '2025-01-01T00:00:00Z',
        'baseCurrency': 'USD',
        'totalBaseValue': 100,
        'totalUnrealizedPnlBase': 10,
      });
      expect(s.baseCurrency, 'USD');
      expect(s.positions, isEmpty);
      expect(s.cashBalances, isEmpty);
    });

    test('connection round-trip', () {
      const c = Connection(
        id: 'c1',
        kind: ConnectionKind.longbridge,
        label: 'My LB',
        status: ConnectionStatus.ok,
        credentialMode: CredentialMode.e2e,
      );
      final back = Mappers.connectionFromJson(Mappers.connectionToJson(c));
      expect(back, c);
    });

    test('manual holding round-trip', () {
      const h = ManualHolding(
        id: 'h1',
        label: 'House',
        assetClass: AssetClass.realEstate,
        quantity: 1,
        valueCurrency: 'USD',
        valueAmount: 1000,
      );
      final back = Mappers.manualFromJson(Mappers.manualToJson(h));
      expect(back, h);
    });

    test('alert symbol scope round-trip', () {
      const a = Alert(
        id: 'a1',
        kind: AlertKind.priceAbove,
        scope: AlertScope.symbol('AAPL'),
        threshold: 100,
        active: true,
      );
      final back = Mappers.alertFromJson(Mappers.alertToJson(a));
      expect(back, a);
    });

    test('alert portfolio scope round-trip', () {
      const a = Alert(
        id: 'a2',
        kind: AlertKind.pnlPctAbove,
        scope: AlertScope.portfolio(),
        threshold: 5,
        active: false,
      );
      final back = Mappers.alertFromJson(Mappers.alertToJson(a));
      expect(back, a);
    });

    test('quoteFromJson parses both ISO string and millis timestamps', () {
      final q1 = Mappers.quoteFromJson({
        'symbol': 'X',
        'price': 1.0,
        'timestamp': '2025-01-01T00:00:00Z',
      });
      expect(q1.timestamp.isUtc, true);
      final q2 = Mappers.quoteFromJson({
        'symbol': 'X',
        'price': 1.0,
        'timestamp': 1000,
      });
      expect(q2.timestamp.millisecondsSinceEpoch, 1000);
    });
  });
}
