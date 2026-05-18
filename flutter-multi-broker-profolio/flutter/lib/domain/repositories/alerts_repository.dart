import '../entities/alert.dart';
import '../entities/portfolio_snapshot.dart';
import '../entities/price_quote.dart';

/// Manages user-defined alerts.
abstract class AlertsRepository {
  Future<List<Alert>> list();

  Future<Alert> create(Alert alert);

  Future<Alert> update(Alert alert);

  Future<void> delete(String alertId);

  /// Locally evaluates [alert] against the latest [quote] and [snapshot].
  ///
  /// Returns true if the alert's trigger condition is met. Either of
  /// [quote] / [snapshot] may be null when not applicable; callers should
  /// pass whichever is relevant to the alert's scope.
  bool evaluateLocal(
    Alert alert, {
    PriceQuote? quote,
    PortfolioSnapshot? snapshot,
  });
}
