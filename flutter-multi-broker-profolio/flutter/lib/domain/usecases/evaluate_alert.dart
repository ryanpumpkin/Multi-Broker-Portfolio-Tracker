import '../entities/alert.dart';
import '../entities/portfolio_snapshot.dart';
import '../entities/price_quote.dart';

/// Pure-function evaluation of an [Alert] against the latest market data.
///
/// Returns `false` for inactive alerts or when the required input
/// (quote / snapshot) is missing for the alert's kind/scope.
///
/// This is intentionally a stateless use case so it can run from either
/// the client (E2E mode) or the backend alert worker (server-key mode).
class EvaluateAlert {
  const EvaluateAlert();

  bool call(
    Alert alert, {
    PriceQuote? quote,
    PortfolioSnapshot? snapshot,
  }) {
    if (!alert.active) return false;

    switch (alert.kind) {
      case AlertKind.priceAbove:
      case AlertKind.priceBelow:
        if (alert.scope.isPortfolio) return false;
        if (quote == null) return false;
        if (alert.scope.symbol != quote.symbol) return false;
        return alert.kind == AlertKind.priceAbove
            ? quote.price > alert.threshold
            : quote.price < alert.threshold;

      case AlertKind.pnlPctAbove:
      case AlertKind.pnlPctBelow:
        final pct = _pnlPct(alert, snapshot);
        if (pct == null) return false;
        return alert.kind == AlertKind.pnlPctAbove
            ? pct > alert.threshold
            : pct < alert.threshold;
    }
  }

  double? _pnlPct(Alert alert, PortfolioSnapshot? snapshot) {
    if (snapshot == null) return null;
    if (alert.scope.isPortfolio) {
      final cost = snapshot.totalBaseValue - snapshot.totalUnrealizedPnlBase;
      if (cost == 0) return null;
      return (snapshot.totalUnrealizedPnlBase / cost) * 100.0;
    }
    final symbol = alert.scope.symbol;
    if (symbol == null) return null;
    var qty = 0.0;
    var mv = 0.0;
    var pnl = 0.0;
    for (final p in snapshot.positions) {
      if (p.symbol != symbol) continue;
      qty += p.quantity;
      mv += p.marketValue;
      pnl += p.unrealizedPnl;
    }
    if (qty == 0) return null;
    final cost = mv - pnl;
    if (cost == 0) return null;
    return (pnl / cost) * 100.0;
  }
}
