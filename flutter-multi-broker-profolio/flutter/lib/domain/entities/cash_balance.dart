/// Available cash balance for a given source and currency.
class CashBalance {
  const CashBalance({
    required this.sourceId,
    required this.currency,
    required this.available,
  });

  final String sourceId;
  final String currency;
  final double available;

  CashBalance copyWith({
    String? sourceId,
    String? currency,
    double? available,
  }) {
    return CashBalance(
      sourceId: sourceId ?? this.sourceId,
      currency: currency ?? this.currency,
      available: available ?? this.available,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashBalance &&
          runtimeType == other.runtimeType &&
          sourceId == other.sourceId &&
          currency == other.currency &&
          available == other.available;

  @override
  int get hashCode => Object.hash(sourceId, currency, available);

  @override
  String toString() =>
      'CashBalance(sourceId: $sourceId, currency: $currency, '
      'available: $available)';
}
