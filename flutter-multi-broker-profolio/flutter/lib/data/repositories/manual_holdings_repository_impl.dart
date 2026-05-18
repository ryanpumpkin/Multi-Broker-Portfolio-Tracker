import '../../domain/domain.dart';
import '../remote/firestore_client/firestore_client.dart';
import 'mappers.dart';

/// CRUD over manual holdings backed by Firestore.
class ManualHoldingsRepositoryImpl implements ManualHoldingsRepository {
  ManualHoldingsRepositoryImpl({
    required this.firestore,
    required this.userId,
  });

  final FirestoreClient firestore;
  final String userId;

  @override
  Future<List<ManualHolding>> list() async {
    final raw = await firestore.listManualHoldings(userId);
    return raw.map(Mappers.manualFromJson).toList(growable: false);
  }

  @override
  Future<ManualHolding> create(ManualHolding holding) async {
    await firestore.upsertManualHolding(
      userId,
      holding.id,
      Mappers.manualToJson(holding),
    );
    return holding;
  }

  @override
  Future<ManualHolding> update(ManualHolding holding) async {
    await firestore.upsertManualHolding(
      userId,
      holding.id,
      Mappers.manualToJson(holding),
    );
    return holding;
  }

  @override
  Future<void> delete(String holdingId) =>
      firestore.deleteManualHolding(userId, holdingId);
}
