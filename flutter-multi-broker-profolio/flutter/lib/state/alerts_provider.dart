import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/domain.dart';
import 'repository_providers.dart';

final alertsProvider = AsyncNotifierProvider<AlertsController, AlertsState>(
  AlertsController.new,
);

class AlertTriggerEvent {
  const AlertTriggerEvent({
    required this.alertId,
    required this.triggeredAt,
    this.quote,
    this.portfolioUnrealizedPnlPct,
  });

  final String alertId;
  final DateTime triggeredAt;
  final PriceQuote? quote;
  final double? portfolioUnrealizedPnlPct;
}

class AlertsState {
  const AlertsState({
    required this.alerts,
    required this.triggerHistory,
  });

  final List<Alert> alerts;
  final List<AlertTriggerEvent> triggerHistory;

  AlertsState copyWith({
    List<Alert>? alerts,
    List<AlertTriggerEvent>? triggerHistory,
  }) {
    return AlertsState(
      alerts: alerts ?? this.alerts,
      triggerHistory: triggerHistory ?? this.triggerHistory,
    );
  }
}

class AlertsController extends AsyncNotifier<AlertsState> {
  static const int _maxHistory = 200;

  @override
  Future<AlertsState> build() async {
    final alerts = await ref.read(alertsRepositoryProvider).list();
    return AlertsState(
      alerts: List<Alert>.unmodifiable(alerts),
      triggerHistory: const <AlertTriggerEvent>[],
    );
  }

  Future<void> refresh() async {
    final existingHistory =
        state.value?.triggerHistory ?? const <AlertTriggerEvent>[];
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final alerts = await ref.read(alertsRepositoryProvider).list();
      return AlertsState(
        alerts: List<Alert>.unmodifiable(alerts),
        triggerHistory: existingHistory,
      );
    });
  }

  Future<Alert> create(Alert alert) async {
    final created = await ref.read(alertsRepositoryProvider).create(alert);
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          alerts: List<Alert>.unmodifiable(<Alert>[
            ...current.alerts,
            created,
          ]),
        ),
      );
    } else {
      await refresh();
    }
    return created;
  }

  Future<Alert> updateAlert(Alert alert) async {
    final updated = await ref.read(alertsRepositoryProvider).update(alert);
    final current = state.value;
    if (current != null) {
      final next = current.alerts
          .map((existing) => existing.id == updated.id ? updated : existing)
          .toList(growable: false);
      state = AsyncData(
        current.copyWith(alerts: List<Alert>.unmodifiable(next)),
      );
    } else {
      await refresh();
    }
    return updated;
  }

  Future<void> delete(String alertId) async {
    await ref.read(alertsRepositoryProvider).delete(alertId);
    final current = state.value;
    if (current != null) {
      final alerts = current.alerts
          .where((alert) => alert.id != alertId)
          .toList(growable: false);
      state = AsyncData(
        current.copyWith(alerts: List<Alert>.unmodifiable(alerts)),
      );
    } else {
      await refresh();
    }
  }

  Future<bool> evaluateAndRecord(
    String alertId, {
    PriceQuote? quote,
    PortfolioSnapshot? snapshot,
  }) async {
    final current = state.value;
    if (current == null) return false;
    final alert = current.alerts
        .where((item) => item.id == alertId)
        .cast<Alert?>()
        .firstWhere((_) => true, orElse: () => null);
    if (alert == null) return false;
    final triggered = ref.read(alertsRepositoryProvider).evaluateLocal(
          alert,
          quote: quote,
          snapshot: snapshot,
        );
    if (!triggered) return false;

    final pnlPct = snapshot == null || snapshot.totalBaseValue == 0
        ? null
        : 100.0 * snapshot.totalUnrealizedPnlBase / snapshot.totalBaseValue;
    final history = <AlertTriggerEvent>[
      AlertTriggerEvent(
        alertId: alert.id,
        triggeredAt: DateTime.now().toUtc(),
        quote: quote,
        portfolioUnrealizedPnlPct: pnlPct,
      ),
      ...current.triggerHistory,
    ];
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }
    state = AsyncData(
      current.copyWith(
        triggerHistory: List<AlertTriggerEvent>.unmodifiable(history),
      ),
    );
    return true;
  }

  void clearTriggerHistory() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(triggerHistory: const <AlertTriggerEvent>[]),
    );
  }
}
