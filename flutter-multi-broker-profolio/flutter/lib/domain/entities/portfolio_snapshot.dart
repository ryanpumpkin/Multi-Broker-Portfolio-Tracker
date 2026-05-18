import 'cash_balance.dart';
import 'position.dart';
import 'source_health.dart';

/// Aggregated portfolio at a point in time.
class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.asOf,
    required this.baseCurrency,
    required this.positions,
    required this.cashBalances,
    this.sourceHealth = const <SourceHealth>[],
    required this.totalsBySource,
    required this.totalsByCurrency,
    required this.totalBaseValue,
    required this.totalUnrealizedPnlBase,
  });

  final DateTime asOf;
  final String baseCurrency;
  final List<Position> positions;
  final List<CashBalance> cashBalances;
  final List<SourceHealth> sourceHealth;

  /// Total market value per source, expressed in [baseCurrency].
  final Map<String, double> totalsBySource;

  /// Total market value per native currency (NOT converted).
  final Map<String, double> totalsByCurrency;

  /// Grand total in [baseCurrency].
  final double totalBaseValue;

  /// Total unrealized P&L in [baseCurrency].
  final double totalUnrealizedPnlBase;

  PortfolioSnapshot copyWith({
    DateTime? asOf,
    String? baseCurrency,
    List<Position>? positions,
    List<CashBalance>? cashBalances,
    List<SourceHealth>? sourceHealth,
    Map<String, double>? totalsBySource,
    Map<String, double>? totalsByCurrency,
    double? totalBaseValue,
    double? totalUnrealizedPnlBase,
  }) {
    return PortfolioSnapshot(
      asOf: asOf ?? this.asOf,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      positions: positions ?? this.positions,
      cashBalances: cashBalances ?? this.cashBalances,
      sourceHealth: sourceHealth ?? this.sourceHealth,
      totalsBySource: totalsBySource ?? this.totalsBySource,
      totalsByCurrency: totalsByCurrency ?? this.totalsByCurrency,
      totalBaseValue: totalBaseValue ?? this.totalBaseValue,
      totalUnrealizedPnlBase:
          totalUnrealizedPnlBase ?? this.totalUnrealizedPnlBase,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PortfolioSnapshot) return false;
    if (runtimeType != other.runtimeType) return false;
    if (asOf != other.asOf) return false;
    if (baseCurrency != other.baseCurrency) return false;
    if (totalBaseValue != other.totalBaseValue) return false;
    if (totalUnrealizedPnlBase != other.totalUnrealizedPnlBase) return false;
    if (!_listEq(positions, other.positions)) return false;
    if (!_listEq(cashBalances, other.cashBalances)) return false;
    if (!_listEq(sourceHealth, other.sourceHealth)) return false;
    if (!_mapEq(totalsBySource, other.totalsBySource)) return false;
    if (!_mapEq(totalsByCurrency, other.totalsByCurrency)) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
        asOf,
        baseCurrency,
        Object.hashAll(positions),
        Object.hashAll(cashBalances),
        Object.hashAll(sourceHealth),
        Object.hashAllUnordered(totalsBySource.entries.map(_entryHash)),
        Object.hashAllUnordered(totalsByCurrency.entries.map(_entryHash)),
        totalBaseValue,
        totalUnrealizedPnlBase,
      );

  static int _entryHash(MapEntry<String, double> e) =>
      Object.hash(e.key, e.value);

  static bool _listEq<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEq<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || a[k] != b[k]) return false;
    }
    return true;
  }

  @override
  String toString() => 'PortfolioSnapshot(asOf: $asOf, base: $baseCurrency, '
      'totalBaseValue: $totalBaseValue, positions: ${positions.length}, '
      'sourceHealth: ${sourceHealth.length})';
}
