import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/domain.dart';
import 'repository_providers.dart';

final manualHoldingsProvider =
    AsyncNotifierProvider<ManualHoldingsController, List<ManualHolding>>(
  ManualHoldingsController.new,
);

class ManualHoldingsController extends AsyncNotifier<List<ManualHolding>> {
  @override
  Future<List<ManualHolding>> build() async {
    final holdings = await ref.read(manualHoldingsRepositoryProvider).list();
    return List<ManualHolding>.unmodifiable(holdings);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final holdings = await ref.read(manualHoldingsRepositoryProvider).list();
      return List<ManualHolding>.unmodifiable(holdings);
    });
  }

  Future<ManualHolding> create(ManualHolding holding) async {
    final created =
        await ref.read(manualHoldingsRepositoryProvider).create(holding);
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        List<ManualHolding>.unmodifiable(<ManualHolding>[
          ...current,
          created,
        ]),
      );
    } else {
      await refresh();
    }
    return created;
  }

  Future<ManualHolding> updateHolding(ManualHolding holding) async {
    final updated =
        await ref.read(manualHoldingsRepositoryProvider).update(holding);
    final current = state.value;
    if (current != null) {
      final next = current
          .map((existing) => existing.id == updated.id ? updated : existing)
          .toList(growable: false);
      state = AsyncData(List<ManualHolding>.unmodifiable(next));
    } else {
      await refresh();
    }
    return updated;
  }

  Future<void> delete(String holdingId) async {
    await ref.read(manualHoldingsRepositoryProvider).delete(holdingId);
    final current = state.value;
    if (current != null) {
      final next = current
          .where((holding) => holding.id != holdingId)
          .toList(growable: false);
      state = AsyncData(List<ManualHolding>.unmodifiable(next));
    } else {
      await refresh();
    }
  }
}
