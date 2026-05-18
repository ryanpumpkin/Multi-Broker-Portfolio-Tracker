import '../entities/manual_holding.dart';

/// CRUD over user-entered manual holdings.
abstract class ManualHoldingsRepository {
  Future<List<ManualHolding>> list();

  Future<ManualHolding> create(ManualHolding holding);

  Future<ManualHolding> update(ManualHolding holding);

  Future<void> delete(String holdingId);
}
