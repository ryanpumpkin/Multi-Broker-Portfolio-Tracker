/// Type of a portfolio transaction.
enum TransactionType {
  buy,
  sell,
  dividend,
  fee,
  deposit,
  withdrawal,
  cryptoTrade,
}

/// A single broker / exchange transaction.
class Transaction {
  const Transaction({
    required this.id,
    required this.sourceId,
    required this.time,
    required this.type,
    required this.symbol,
    required this.quantity,
    required this.price,
    required this.currency,
    required this.fee,
  });

  final String id;
  final String sourceId;
  final DateTime time;
  final TransactionType type;

  /// May be empty for deposit/withdrawal where no symbol is involved.
  final String symbol;
  final double quantity;
  final double price;
  final String currency;
  final double fee;

  /// Signed cash impact of the transaction in [currency], including fees.
  ///
  /// Positive = inflow to cash (sell, dividend, deposit).
  /// Negative = outflow from cash (buy, fee, withdrawal).
  double get cashImpact {
    switch (type) {
      case TransactionType.buy:
      case TransactionType.cryptoTrade:
        return -(quantity * price) - fee;
      case TransactionType.sell:
        return (quantity * price) - fee;
      case TransactionType.dividend:
        return (quantity * price) - fee;
      case TransactionType.fee:
        return -fee;
      case TransactionType.deposit:
        return quantity * price; // amount * 1 typically
      case TransactionType.withdrawal:
        return -(quantity * price);
    }
  }

  Transaction copyWith({
    String? id,
    String? sourceId,
    DateTime? time,
    TransactionType? type,
    String? symbol,
    double? quantity,
    double? price,
    String? currency,
    double? fee,
  }) {
    return Transaction(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      time: time ?? this.time,
      type: type ?? this.type,
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      fee: fee ?? this.fee,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sourceId == other.sourceId &&
          time == other.time &&
          type == other.type &&
          symbol == other.symbol &&
          quantity == other.quantity &&
          price == other.price &&
          currency == other.currency &&
          fee == other.fee;

  @override
  int get hashCode => Object.hash(
        id,
        sourceId,
        time,
        type,
        symbol,
        quantity,
        price,
        currency,
        fee,
      );

  @override
  String toString() =>
      'Transaction(id: $id, type: $type, symbol: $symbol, qty: $quantity)';
}
