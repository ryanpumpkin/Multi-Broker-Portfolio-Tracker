import '../../domain/domain.dart';

/// Pure-function mappers between domain entities and their JSON / DB row
/// representations. Keeping these here avoids leaking JSON shape into the
/// domain layer.
class Mappers {
  Mappers._();

  // ---------------- AssetClass -------------------------------------------

  static AssetClass assetClassFromString(String s) {
    return AssetClass.values.firstWhere(
      (a) => a.name == s,
      orElse: () => AssetClass.other,
    );
  }

  // ---------------- Position ---------------------------------------------

  static Position positionFromJson(Map<String, dynamic> j) {
    return Position(
      sourceId: j['sourceId'] as String,
      symbol: j['symbol'] as String,
      name: j['name'] as String? ?? j['symbol'] as String,
      assetClass: assetClassFromString(
        j['assetClass'] as String? ?? 'other',
      ),
      quantity: _num(j['quantity']),
      avgCost: _num(j['avgCost']),
      currentPrice: _num(j['currentPrice']),
      currency: j['currency'] as String,
      marketValue: _num(j['marketValue']),
      unrealizedPnl: _num(j['unrealizedPnl']),
    );
  }

  static Map<String, dynamic> positionToJson(Position p) => <String, dynamic>{
        'sourceId': p.sourceId,
        'symbol': p.symbol,
        'name': p.name,
        'assetClass': p.assetClass.name,
        'quantity': p.quantity,
        'avgCost': p.avgCost,
        'currentPrice': p.currentPrice,
        'currency': p.currency,
        'marketValue': p.marketValue,
        'unrealizedPnl': p.unrealizedPnl,
      };

  // ---------------- Transaction ------------------------------------------

  static Transaction transactionFromJson(Map<String, dynamic> j) {
    return Transaction(
      id: j['id'] as String,
      sourceId: j['sourceId'] as String,
      time: DateTime.parse(j['time'] as String).toUtc(),
      type: TransactionType.values.firstWhere(
        (t) => t.name == (j['type'] as String? ?? 'buy'),
        orElse: () => TransactionType.buy,
      ),
      symbol: j['symbol'] as String? ?? '',
      quantity: _num(j['quantity']),
      price: _num(j['price']),
      currency: j['currency'] as String? ?? 'USD',
      fee: _num(j['fee']),
    );
  }

  // ---------------- CashBalance ------------------------------------------

  static CashBalance cashBalanceFromJson(Map<String, dynamic> j) {
    return CashBalance(
      sourceId: j['sourceId'] as String,
      currency: j['currency'] as String,
      available: _num(j['available']),
    );
  }

  // ---------------- FxRate -----------------------------------------------

  static FxRate fxFromJson(Map<String, dynamic> j) {
    return FxRate(
      base: j['base'] as String,
      quote: j['quote'] as String,
      rate: _num(j['rate']),
      timestamp: DateTime.parse(j['timestamp'] as String).toUtc(),
    );
  }

  // ---------------- PortfolioSnapshot ------------------------------------

  static PortfolioSnapshot snapshotFromJson(Map<String, dynamic> j) {
    final positions = (j['positions'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(positionFromJson)
        .toList(growable: false);
    final balances = (j['cashBalances'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(cashBalanceFromJson)
        .toList(growable: false);
    return PortfolioSnapshot(
      asOf: DateTime.parse(j['asOf'] as String).toUtc(),
      baseCurrency: j['baseCurrency'] as String,
      positions: positions,
      cashBalances: balances,
      totalsBySource: ((j['totalsBySource'] as Map?) ?? const {})
          .map((k, v) => MapEntry(k as String, _num(v))),
      totalsByCurrency: ((j['totalsByCurrency'] as Map?) ?? const {})
          .map((k, v) => MapEntry(k as String, _num(v))),
      totalBaseValue: _num(j['totalBaseValue']),
      totalUnrealizedPnlBase: _num(j['totalUnrealizedPnlBase']),
    );
  }

  // ---------------- Connection -------------------------------------------

  static Connection connectionFromJson(Map<String, dynamic> j) {
    return Connection(
      id: j['id'] as String,
      kind: ConnectionKind.values.firstWhere(
        (k) => k.name == (j['kind'] as String? ?? 'manual'),
        orElse: () => ConnectionKind.manual,
      ),
      label: j['label'] as String? ?? '',
      status: ConnectionStatus.values.firstWhere(
        (s) => s.name == (j['status'] as String? ?? 'unknown'),
        orElse: () => ConnectionStatus.unknown,
      ),
      credentialMode: CredentialMode.values.firstWhere(
        (m) => m.name == (j['credentialMode'] as String? ?? 'e2e'),
        orElse: () => CredentialMode.e2e,
      ),
    );
  }

  static Map<String, dynamic> connectionToJson(Connection c) =>
      <String, dynamic>{
        'id': c.id,
        'kind': c.kind.name,
        'label': c.label,
        'status': c.status.name,
        'credentialMode': c.credentialMode.name,
      };

  // ---------------- ManualHolding ----------------------------------------

  static ManualHolding manualFromJson(Map<String, dynamic> j) {
    return ManualHolding(
      id: j['id'] as String,
      label: j['label'] as String? ?? '',
      assetClass:
          assetClassFromString(j['assetClass'] as String? ?? 'other'),
      quantity: _num(j['quantity']),
      valueCurrency: j['valueCurrency'] as String? ?? 'USD',
      valueAmount: _num(j['valueAmount']),
    );
  }

  static Map<String, dynamic> manualToJson(ManualHolding h) =>
      <String, dynamic>{
        'id': h.id,
        'label': h.label,
        'assetClass': h.assetClass.name,
        'quantity': h.quantity,
        'valueCurrency': h.valueCurrency,
        'valueAmount': h.valueAmount,
      };

  // ---------------- Alert ------------------------------------------------

  static Alert alertFromJson(Map<String, dynamic> j) {
    final isPortfolio = j['scope'] == 'portfolio' || j['symbol'] == null;
    return Alert(
      id: j['id'] as String,
      kind: AlertKind.values.firstWhere(
        (k) => k.name == (j['kind'] as String? ?? 'priceAbove'),
        orElse: () => AlertKind.priceAbove,
      ),
      scope: isPortfolio
          ? const AlertScope.portfolio()
          : AlertScope.symbol(j['symbol'] as String),
      threshold: _num(j['threshold']),
      active: j['active'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> alertToJson(Alert a) => <String, dynamic>{
        'id': a.id,
        'kind': a.kind.name,
        'scope': a.scope.isPortfolio ? 'portfolio' : 'symbol',
        if (a.scope.symbol != null) 'symbol': a.scope.symbol,
        'threshold': a.threshold,
        'active': a.active,
      };

  // ---------------- PriceQuote -------------------------------------------

  static PriceQuote quoteFromJson(Map<String, dynamic> j) {
    return PriceQuote(
      symbol: j['symbol'] as String,
      price: _num(j['price']),
      currency: j['currency'] as String? ?? 'USD',
      timestamp: j['timestamp'] is String
          ? DateTime.parse(j['timestamp'] as String).toUtc()
          : DateTime.fromMillisecondsSinceEpoch(
              (j['timestamp'] as num?)?.toInt() ?? 0,
              isUtc: true,
            ),
    );
  }

  static double _num(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
}
