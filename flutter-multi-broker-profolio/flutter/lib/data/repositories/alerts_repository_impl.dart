import '../../domain/domain.dart';
import '../remote/firestore_client/firestore_client.dart';
import 'mappers.dart';

/// [AlertsRepository] implementation. The trigger evaluator is pure and
/// shared between the local foreground evaluation path and the backend
/// alert worker.
class AlertsRepositoryImpl implements AlertsRepository {
  AlertsRepositoryImpl({required this.firestore, required this.userId});

  final FirestoreClient firestore;
  final String userId;

  @override
  Future<List<Alert>> list() async {
    final raw = await firestore.listAlerts(userId);
    return raw.map(Mappers.alertFromJson).toList(growable: false);
  }

  @override
  Future<Alert> create(Alert alert) async {
    await firestore.upsertAlert(userId, alert.id, Mappers.alertToJson(alert));
    return alert;
  }

  @override
  Future<Alert> update(Alert alert) async {
    await firestore.upsertAlert(userId, alert.id, Mappers.alertToJson(alert));
    return alert;
  }

  @override
  Future<void> delete(String alertId) =>
      firestore.deleteAlert(userId, alertId);

  @override
  bool evaluateLocal(
    Alert alert, {
    PriceQuote? quote,
    PortfolioSnapshot? snapshot,
  }) {
    if (!alert.active) return false;
    switch (alert.kind) {
      case AlertKind.priceAbove:
        if (quote == null) return false;
        if (alert.scope.symbol != null && alert.scope.symbol != quote.symbol) {
          return false;
        }
        return quote.price > alert.threshold;
      case AlertKind.priceBelow:
        if (quote == null) return false;
        if (alert.scope.symbol != null && alert.scope.symbol != quote.symbol) {
          return false;
        }
        return quote.price < alert.threshold;
      case AlertKind.pnlPctAbove:
      case AlertKind.pnlPctBelow:
        if (snapshot == null) return false;
        if (!alert.scope.isPortfolio) return false;
        if (snapshot.totalBaseValue == 0) return false;
        final pct =
            100.0 * snapshot.totalUnrealizedPnlBase / snapshot.totalBaseValue;
        return alert.kind == AlertKind.pnlPctAbove
            ? pct > alert.threshold
            : pct < alert.threshold;
    }
  }
}
