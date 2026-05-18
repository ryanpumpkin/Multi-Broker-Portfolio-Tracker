import '../entities/connection.dart';

/// Manages user-configured broker / exchange / manual connections.
abstract class ConnectionsRepository {
  Future<List<Connection>> list();

  Future<Connection> add(Connection connection);

  Future<void> remove(String connectionId);

  Future<Connection> updateMode(
    String connectionId,
    CredentialMode mode,
  );

  /// Persists an opaque encrypted credential blob for [connectionId].
  ///
  /// In E2E mode the blob is the AES-GCM ciphertext of the broker
  /// credentials (base64-encoded) and the backend never decrypts it.
  /// In server-key mode the blob is a KMS-wrapped envelope produced by
  /// the backend on the user's behalf.
  Future<void> setCredentials(String connectionId, String encryptedBlob);
}
