import 'package:drift/drift.dart';

import '../../domain/domain.dart';
import '../local/database/app_database.dart';
import '../remote/firestore_client/firestore_client.dart';
import 'mappers.dart';

/// [ConnectionsRepository] backed by Firestore (authoritative) with a
/// local Drift cache for instant cold-start render.
class ConnectionsRepositoryImpl implements ConnectionsRepository {
  ConnectionsRepositoryImpl({
    required this.db,
    required this.firestore,
    required this.userId,
  });

  final AppDatabase db;
  final FirestoreClient firestore;
  final String userId;

  @override
  Future<List<Connection>> list() async {
    try {
      final raw = await firestore.listConnections(userId);
      final conns = raw.map(Mappers.connectionFromJson).toList(growable: false);
      await _writeCache(conns);
      return conns;
    } catch (_) {
      final rows = await db.listConnections();
      return rows
          .map((r) => Connection(
                id: r.id,
                kind: ConnectionKind.values.firstWhere(
                  (k) => k.name == r.kind,
                  orElse: () => ConnectionKind.manual,
                ),
                label: r.label,
                status: ConnectionStatus.values.firstWhere(
                  (s) => s.name == r.status,
                  orElse: () => ConnectionStatus.unknown,
                ),
                credentialMode: CredentialMode.values.firstWhere(
                  (m) => m.name == r.credentialMode,
                  orElse: () => CredentialMode.e2e,
                ),
              ),)
          .toList(growable: false);
    }
  }

  @override
  Future<Connection> add(Connection connection) async {
    await firestore.upsertConnection(
      userId,
      connection.id,
      Mappers.connectionToJson(connection),
    );
    await _writeCache([connection]);
    return connection;
  }

  @override
  Future<void> setCredentials(String connectionId, String encryptedBlob) async {
    await firestore.upsertConnection(userId, connectionId, <String, dynamic>{
      'encryptedBlob': encryptedBlob,
    });
  }

  @override
  Future<void> remove(String connectionId) async {
    await firestore.deleteConnection(userId, connectionId);
    await db.deleteConnection(connectionId);
  }

  @override
  Future<Connection> updateMode(
    String connectionId,
    CredentialMode mode,
  ) async {
    await firestore.upsertConnection(userId, connectionId, <String, dynamic>{
      'credentialMode': mode.name,
    });
    // Reflect in cache.
    final existing = await db.listConnections();
    final hit = existing.where((e) => e.id == connectionId).cast<ConnectionMetaRow?>().firstWhere(
          (_) => true,
          orElse: () => null,
        );
    final updated = hit != null
        ? Connection(
            id: hit.id,
            kind: ConnectionKind.values.firstWhere(
              (k) => k.name == hit.kind,
              orElse: () => ConnectionKind.manual,
            ),
            label: hit.label,
            status: ConnectionStatus.values.firstWhere(
              (s) => s.name == hit.status,
              orElse: () => ConnectionStatus.unknown,
            ),
            credentialMode: mode,
          )
        : Connection(
            id: connectionId,
            kind: ConnectionKind.manual,
            label: connectionId,
            status: ConnectionStatus.unknown,
            credentialMode: mode,
          );
    await _writeCache([updated]);
    return updated;
  }

  Future<void> _writeCache(Iterable<Connection> conns) async {
    for (final c in conns) {
      await db.upsertConnection(ConnectionsMetaCompanion.insert(
        id: c.id,
        kind: c.kind.name,
        label: c.label,
        status: c.status.name,
        credentialMode: c.credentialMode.name,
        lastSyncAt: Value(DateTime.now().toUtc()),
      ),);
    }
  }
}
