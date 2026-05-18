import 'asset_class.dart';

/// A user-entered holding that is not backed by any connected source.
///
/// Manual holdings carry a total value in a chosen currency rather than
/// a market price, because they may not have a quotable market price
/// (real estate, physical cash, private equity).
class ManualHolding {
  const ManualHolding({
    required this.id,
    required this.label,
    required this.assetClass,
    required this.quantity,
    required this.valueCurrency,
    required this.valueAmount,
  });

  final String id;
  final String label;
  final AssetClass assetClass;
  final double quantity;
  final String valueCurrency;

  /// Total current value in [valueCurrency] (not per-unit).
  final double valueAmount;

  ManualHolding copyWith({
    String? id,
    String? label,
    AssetClass? assetClass,
    double? quantity,
    String? valueCurrency,
    double? valueAmount,
  }) {
    return ManualHolding(
      id: id ?? this.id,
      label: label ?? this.label,
      assetClass: assetClass ?? this.assetClass,
      quantity: quantity ?? this.quantity,
      valueCurrency: valueCurrency ?? this.valueCurrency,
      valueAmount: valueAmount ?? this.valueAmount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManualHolding &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          assetClass == other.assetClass &&
          quantity == other.quantity &&
          valueCurrency == other.valueCurrency &&
          valueAmount == other.valueAmount;

  @override
  int get hashCode => Object.hash(
        id,
        label,
        assetClass,
        quantity,
        valueCurrency,
        valueAmount,
      );

  @override
  String toString() =>
      'ManualHolding(id: $id, label: $label, value: $valueAmount '
      '$valueCurrency)';
}
