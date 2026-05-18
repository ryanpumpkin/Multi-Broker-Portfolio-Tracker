import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';

import 'fakes.dart';

PortfolioSnapshot _baseSnapshot() {
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
  return PortfolioSnapshot(
    asOf: DateTime.utc(2026, 1, 1),
    baseCurrency: 'USD',
    positions: [p],
    cashBalances: const [],
    totalsBySource: const {'lb': 1500},
    totalsByCurrency: const {'USD': 1500},
    totalBaseValue: 1500,
    totalUnrealizedPnlBase: 500,
  );
}

void main() {
  group('GetAggregatedPortfolio', () {
    test('returns snapshot unchanged when no manual holdings', () async {
      final uc = GetAggregatedPortfolio(
        portfolio: FakePortfolioRepository(_baseSnapshot()),
        fx: FakeFxRepository(const {}),
        manualHoldings: FakeManualHoldingsRepository([]),
      );
      final out = await uc(baseCurrency: 'USD');
      expect(out, equals(_baseSnapshot()));
    });

    test('adds manual holding in matching base currency', () async {
      final uc = GetAggregatedPortfolio(
        portfolio: FakePortfolioRepository(_baseSnapshot()),
        fx: FakeFxRepository(const {}),
        manualHoldings: FakeManualHoldingsRepository([
          const ManualHolding(
            id: 'm1',
            label: 'Cash',
            assetClass: AssetClass.cash,
            quantity: 1,
            valueCurrency: 'USD',
            valueAmount: 500,
          ),
        ]),
      );
      final out = await uc(baseCurrency: 'USD');
      expect(out.positions, hasLength(2));
      expect(out.totalBaseValue, 2000);
      expect(out.totalsBySource['manual'], 500);
      expect(out.totalsByCurrency['USD'], 2000);
    });

    test('converts manual holding via fx into base', () async {
      final uc = GetAggregatedPortfolio(
        portfolio: FakePortfolioRepository(_baseSnapshot()),
        fx: FakeFxRepository(const {'HKD/USD': 0.125}),
        manualHoldings: FakeManualHoldingsRepository([
          const ManualHolding(
            id: 'm2',
            label: 'Flat',
            assetClass: AssetClass.realEstate,
            quantity: 1,
            valueCurrency: 'HKD',
            valueAmount: 8000,
          ),
        ]),
      );
      final out = await uc(baseCurrency: 'USD');
      expect(out.totalsByCurrency['HKD'], 8000);
      expect(out.totalsBySource['manual'], closeTo(1000, 1e-9));
      expect(out.totalBaseValue, closeTo(2500, 1e-9));
    });

    test('skips totalsBySource bump when no fx rate', () async {
      final uc = GetAggregatedPortfolio(
        portfolio: FakePortfolioRepository(_baseSnapshot()),
        fx: FakeFxRepository(const {}),
        manualHoldings: FakeManualHoldingsRepository([
          const ManualHolding(
            id: 'm3',
            label: 'Other',
            assetClass: AssetClass.other,
            quantity: 1,
            valueCurrency: 'JPY',
            valueAmount: 10000,
          ),
        ]),
      );
      final out = await uc(baseCurrency: 'USD');
      // native-currency total still tracked
      expect(out.totalsByCurrency['JPY'], 10000);
      // base total unchanged because no fx
      expect(out.totalBaseValue, 1500);
      expect(out.totalsBySource.containsKey('manual'), isFalse);
    });

    test('handles zero-quantity manual holding without dividing by zero', () async {
      final uc = GetAggregatedPortfolio(
        portfolio: FakePortfolioRepository(_baseSnapshot()),
        fx: FakeFxRepository(const {}),
        manualHoldings: FakeManualHoldingsRepository([
          const ManualHolding(
            id: 'm4',
            label: 'Zero',
            assetClass: AssetClass.other,
            quantity: 0,
            valueCurrency: 'USD',
            valueAmount: 50,
          ),
        ]),
      );
      final out = await uc(baseCurrency: 'USD');
      final m = out.positions.firstWhere((p) => p.sourceId == 'manual');
      expect(m.currentPrice, 0);
      expect(m.marketValue, 50);
    });
  });
}
