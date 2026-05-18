/// Foreign-exchange rate.
///
/// `rate` is the multiplier to convert 1 unit of [base] into [quote].
/// e.g. `FxRate(base: 'USD', quote: 'HKD', rate: 7.8)` means
///   1 USD = 7.8 HKD.
class FxRate {
  const FxRate({
    required this.base,
    required this.quote,
    required this.rate,
    required this.timestamp,
  });

  final String base;
  final String quote;
  final double rate;
  final DateTime timestamp;

  /// Returns the inverse rate (quote -> base).
  FxRate inverse() => FxRate(
        base: quote,
        quote: base,
        rate: 1.0 / rate,
        timestamp: timestamp,
      );

  FxRate copyWith({
    String? base,
    String? quote,
    double? rate,
    DateTime? timestamp,
  }) {
    return FxRate(
      base: base ?? this.base,
      quote: quote ?? this.quote,
      rate: rate ?? this.rate,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FxRate &&
          runtimeType == other.runtimeType &&
          base == other.base &&
          quote == other.quote &&
          rate == other.rate &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(base, quote, rate, timestamp);

  @override
  String toString() =>
      'FxRate($base/$quote = $rate @ $timestamp)';
}
