import 'dart:async';

import 'package:multi_broker_portfolio/domain/domain.dart';

class FakeFxRepository implements FxRepository {
  FakeFxRepository(this.rates);

  /// Map of 'BASE/QUOTE' -> rate.
  final Map<String, double> rates;

  @override
  Future<FxRate?> getRate({required String base, required String quote}) async {
    final r = rates['$base/$quote'];
    if (r == null) return null;
    return FxRate(
      base: base,
      quote: quote,
      rate: r,
      timestamp: DateTime.utc(2026, 1, 1),
    );
  }

  @override
  Stream<FxRate> watchRates(List<({String base, String quote})> pairs) async* {
    for (final p in pairs) {
      final r = await getRate(base: p.base, quote: p.quote);
      if (r != null) yield r;
    }
  }
}

class FakePortfolioRepository implements PortfolioRepository {
  FakePortfolioRepository(this.snapshot);
  final PortfolioSnapshot snapshot;

  @override
  Future<PortfolioSnapshot> getSnapshot({required String baseCurrency}) async =>
      snapshot;

  @override
  Stream<PortfolioSnapshot> watchSnapshot({required String baseCurrency}) =>
      Stream<PortfolioSnapshot>.value(snapshot);
}

class FakeManualHoldingsRepository implements ManualHoldingsRepository {
  FakeManualHoldingsRepository(this.items);
  final List<ManualHolding> items;

  @override
  Future<ManualHolding> create(ManualHolding holding) async {
    items.add(holding);
    return holding;
  }

  @override
  Future<void> delete(String holdingId) async {
    items.removeWhere((h) => h.id == holdingId);
  }

  @override
  Future<List<ManualHolding>> list() async => List.unmodifiable(items);

  @override
  Future<ManualHolding> update(ManualHolding holding) async {
    final i = items.indexWhere((h) => h.id == holding.id);
    if (i >= 0) items[i] = holding;
    return holding;
  }
}
