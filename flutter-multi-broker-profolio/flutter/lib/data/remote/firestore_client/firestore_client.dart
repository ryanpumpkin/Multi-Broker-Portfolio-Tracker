/// User-scoped Firestore facade.
///
/// The real implementation in `firestore_adapter.dart` wraps
/// `cloud_firestore`; this interface lets repos and tests stay
/// SDK-agnostic.
library;

/// Read/write contract for the user-scoped Firestore documents this app
/// owns. Every method takes the current [userId] explicitly to avoid
/// silent reads of the wrong user's data when auth state flips.
abstract class FirestoreClient {
  // ----- User settings (single doc at users/{uid}) ------------------------

  Future<Map<String, dynamic>?> getUserSettings(String userId);
  Future<void> setUserSettings(String userId, Map<String, dynamic> data);
  Stream<Map<String, dynamic>?> watchUserSettings(String userId);

  // ----- Manual holdings (subcollection) ----------------------------------

  Future<List<Map<String, dynamic>>> listManualHoldings(String userId);
  Future<void> upsertManualHolding(
    String userId,
    String holdingId,
    Map<String, dynamic> data,
  );
  Future<void> deleteManualHolding(String userId, String holdingId);
  Stream<List<Map<String, dynamic>>> watchManualHoldings(String userId);

  // ----- Alerts (subcollection) -------------------------------------------

  Future<List<Map<String, dynamic>>> listAlerts(String userId);
  Future<void> upsertAlert(
    String userId,
    String alertId,
    Map<String, dynamic> data,
  );
  Future<void> deleteAlert(String userId, String alertId);
  Stream<List<Map<String, dynamic>>> watchAlerts(String userId);

  // ----- Connections & credential blobs -----------------------------------

  Future<List<Map<String, dynamic>>> listConnections(String userId);
  Future<void> upsertConnection(
    String userId,
    String connectionId,
    Map<String, dynamic> data,
  );
  Future<void> deleteConnection(String userId, String connectionId);
  Stream<List<Map<String, dynamic>>> watchConnections(String userId);

  /// Stores the encrypted credential blob produced by [E2eCrypto.encrypt]
  /// (or KMS-encrypted in server-key mode).
  Future<void> setEncryptedCredential(
    String userId,
    String connectionId,
    String encodedBlob,
  );
  Future<String?> getEncryptedCredential(String userId, String connectionId);

  // ----- Registered push devices (subcollection) -------------------------

  Future<void> upsertDeviceToken(
    String userId,
    String token, {
    required String platform,
    required String appVersion,
    DateTime? lastSeen,
  }) {
    throw UnimplementedError('upsertDeviceToken is not implemented');
  }

  Future<void> deleteDeviceToken(String userId, String token) {
    throw UnimplementedError('deleteDeviceToken is not implemented');
  }

  Future<List<Map<String, dynamic>>> listDeviceTokens(String userId) {
    throw UnimplementedError('listDeviceTokens is not implemented');
  }
}
