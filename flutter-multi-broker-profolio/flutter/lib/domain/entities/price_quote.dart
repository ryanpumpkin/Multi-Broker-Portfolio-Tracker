/// A point-in-time price quote for a symbol.
class PriceQuote {
  const PriceQuote({
    required this.symbol,
    required this.price,
    required this.currency,
    required this.timestamp,
  });

  final String symbol;
  final double price;
  final String currency;
  final DateTime timestamp;

  PriceQuote copyWith({
    String? symbol,
    double? price,
    String? currency,
    DateTime? timestamp,
  }) {
    return PriceQuote(
      symbol: symbol ?? this.symbol,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceQuote &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          price == other.price &&
          currency == other.currency &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(symbol, price, currency, timestamp);

  @override
  String toString() =>
      'PriceQuote(symbol: $symbol, price: $price $currency @ $timestamp)';
}
