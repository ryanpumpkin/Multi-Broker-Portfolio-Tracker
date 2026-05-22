import '../entities/manual_holding.dart';
import '../entities/portfolio_snapshot.dart';
import '../entities/position.dart';
import '../repositories/fx_repository.dart';
import '../repositories/manual_holdings_repository.dart';
import '../repositories/portfolio_repository.dart';

/// Composes the broker-backed [PortfolioSnapshot] with user-entered
/// manual holdings, converting each manual holding into the requested
/// [baseCurrency] using [FxRepository].
///
/// Manual holdings are surfaced as synthetic [Position]s tagged with
/// `sourceId = 'manual'`. They have no `avgCost` (cost basis is unknown
/// for manually-entered items), so `unrealizedPnl` is reported as 0 and
/// `marketValue == valueAmount` (in their own currency).
class GetAggregatedPortfolio {
  const GetAggregatedPortfolio({
    required PortfolioRepository portfolio,
    required FxRepository fx,
    required ManualHoldingsRepository manualHoldings,
  })  : _portfolio = portfolio,
        _fx = fx,
        _manualHoldings = manualHoldings;

  final PortfolioRepository _portfolio;
  final FxRepository _fx;
  final ManualHoldingsRepository _manualHoldings;

  static const String manualSourceId = 'manual';

  /// Cache-only variant — never hits the network. Used on app launch so
  /// the UI can render the last-known positions immediately while we
  /// wait for the user to enter their PIN (required for live broker
  /// calls). Manual holdings are still applied on top of the cache.
  Future<PortfolioSnapshot> callCached({required String baseCurrency}) async {
    final snapshot =
        await _portfolio.getCachedSnapshot(baseCurrency: baseCurrency);
    return _withManualHoldings(snapshot, baseCurrency);
  }

  Future<PortfolioSnapshot> call({required String baseCurrency}) async {
    final snapshot = await _portfolio.getSnapshot(baseCurrency: baseCurrency);
    return _withManualHoldings(snapshot, baseCurrency);
  }

  Future<PortfolioSnapshot> _withManualHoldings(
    PortfolioSnapshot snapshot,
    String baseCurrency,
  ) async {
    final manuals = await _manualHoldings.list();
    if (manuals.isEmpty) return snapshot;

    final positions = List<Position>.from(snapshot.positions);
    final totalsBySource = Map<String, double>.from(snapshot.totalsBySource);
    final totalsByCurrency =
        Map<String, double>.from(snapshot.totalsByCurrency);
    var totalBaseValue = snapshot.totalBaseValue;

    for (final h in manuals) {
      positions.add(_manualAsPosition(h));
      totalsByCurrency.update(
        h.valueCurrency,
        (v) => v + h.valueAmount,
        ifAbsent: () => h.valueAmount,
      );
      final converted = await _convert(
        value: h.valueAmount,
        from: h.valueCurrency,
        to: baseCurrency,
      );
      if (converted != null) {
        totalsBySource.update(
          manualSourceId,
          (v) => v + converted,
          ifAbsent: () => converted,
        );
        totalBaseValue += converted;
      }
    }

    return snapshot.copyWith(
      positions: positions,
      totalsBySource: totalsBySource,
      totalsByCurrency: totalsByCurrency,
      totalBaseValue: totalBaseValue,
    );
  }

  Future<double?> _convert({
    required double value,
    required String from,
    required String to,
  }) async {
    if (from == to) return value;
    final rate = await _fx.getRate(base: from, quote: to);
    if (rate == null) return null;
    return value * rate.rate;
  }

  Position _manualAsPosition(ManualHolding h) {
    return Position(
      sourceId: manualSourceId,
      symbol: h.id,
      name: h.label,
      assetClass: h.assetClass,
      quantity: h.quantity,
      avgCost: 0,
      currentPrice: h.quantity == 0 ? 0 : h.valueAmount / h.quantity,
      currency: h.valueCurrency,
      marketValue: h.valueAmount,
      unrealizedPnl: 0,
    );
  }
}

