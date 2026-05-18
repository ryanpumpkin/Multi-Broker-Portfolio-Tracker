/// Kind of trigger condition for an [Alert].
enum AlertKind {
  priceAbove,
  priceBelow,
  pnlPctAbove,
  pnlPctBelow,
}

/// Scope of an alert.
///
/// - `symbol`: a specific instrument symbol (e.g. `AAPL`).
/// - `portfolio`: the whole aggregated portfolio (only valid for
///   `pnlPctAbove` / `pnlPctBelow`).
class AlertScope {
  const AlertScope.symbol(this.symbol) : isPortfolio = false;

  const AlertScope.portfolio()
      : symbol = null,
        isPortfolio = true;

  final String? symbol;
  final bool isPortfolio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertScope &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          isPortfolio == other.isPortfolio;

  @override
  int get hashCode => Object.hash(symbol, isPortfolio);

  @override
  String toString() =>
      isPortfolio ? 'AlertScope(portfolio)' : 'AlertScope(symbol: $symbol)';
}

/// A user-defined alert that fires on a price or P&L threshold.
class Alert {
  const Alert({
    required this.id,
    required this.kind,
    required this.scope,
    required this.threshold,
    required this.active,
  });

  final String id;
  final AlertKind kind;
  final AlertScope scope;

  /// Threshold value. For price kinds: a price in the symbol's currency.
  /// For P&L pct kinds: a percentage (e.g. `5.0` means 5%).
  final double threshold;
  final bool active;

  Alert copyWith({
    String? id,
    AlertKind? kind,
    AlertScope? scope,
    double? threshold,
    bool? active,
  }) {
    return Alert(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      scope: scope ?? this.scope,
      threshold: threshold ?? this.threshold,
      active: active ?? this.active,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alert &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          kind == other.kind &&
          scope == other.scope &&
          threshold == other.threshold &&
          active == other.active;

  @override
  int get hashCode => Object.hash(id, kind, scope, threshold, active);

  @override
  String toString() =>
      'Alert(id: $id, kind: $kind, scope: $scope, threshold: $threshold, '
      'active: $active)';
}
