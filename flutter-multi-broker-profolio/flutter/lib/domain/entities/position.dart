import 'asset_class.dart';

/// A holding in a single connected source.
///
/// `marketValue` and `unrealizedPnl` are derivable from quantity, avgCost
/// and currentPrice; they are kept as explicit fields because some brokers
/// return them directly with their own rounding. Use the factory
/// [Position.computed] when you want them derived.
class Position {
  const Position({
    required this.sourceId,
    required this.symbol,
    required this.name,
    required this.assetClass,
    required this.quantity,
    required this.avgCost,
    required this.currentPrice,
    required this.currency,
    required this.marketValue,
    required this.unrealizedPnl,
  });

  /// Builds a [Position] deriving `marketValue` and `unrealizedPnl`
  /// from `quantity`, `avgCost`, and `currentPrice`.
  factory Position.computed({
    required String sourceId,
    required String symbol,
    required String name,
    required AssetClass assetClass,
    required double quantity,
    required double avgCost,
    required double currentPrice,
    required String currency,
  }) {
    final mv = quantity * currentPrice;
    final pnl = (currentPrice - avgCost) * quantity;
    return Position(
      sourceId: sourceId,
      symbol: symbol,
      name: name,
      assetClass: assetClass,
      quantity: quantity,
      avgCost: avgCost,
      currentPrice: currentPrice,
      currency: currency,
      marketValue: mv,
      unrealizedPnl: pnl,
    );
  }

  final String sourceId;
  final String symbol;
  final String name;
  final AssetClass assetClass;
  final double quantity;
  final double avgCost;
  final double currentPrice;
  final String currency;
  final double marketValue;
  final double unrealizedPnl;

  Position copyWith({
    String? sourceId,
    String? symbol,
    String? name,
    AssetClass? assetClass,
    double? quantity,
    double? avgCost,
    double? currentPrice,
    String? currency,
    double? marketValue,
    double? unrealizedPnl,
  }) {
    return Position(
      sourceId: sourceId ?? this.sourceId,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      assetClass: assetClass ?? this.assetClass,
      quantity: quantity ?? this.quantity,
      avgCost: avgCost ?? this.avgCost,
      currentPrice: currentPrice ?? this.currentPrice,
      currency: currency ?? this.currency,
      marketValue: marketValue ?? this.marketValue,
      unrealizedPnl: unrealizedPnl ?? this.unrealizedPnl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          sourceId == other.sourceId &&
          symbol == other.symbol &&
          name == other.name &&
          assetClass == other.assetClass &&
          quantity == other.quantity &&
          avgCost == other.avgCost &&
          currentPrice == other.currentPrice &&
          currency == other.currency &&
          marketValue == other.marketValue &&
          unrealizedPnl == other.unrealizedPnl;

  @override
  int get hashCode => Object.hash(
        sourceId,
        symbol,
        name,
        assetClass,
        quantity,
        avgCost,
        currentPrice,
        currency,
        marketValue,
        unrealizedPnl,
      );

  @override
  String toString() =>
      'Position(sourceId: $sourceId, symbol: $symbol, qty: $quantity, '
      'currency: $currency, mv: $marketValue)';
}
