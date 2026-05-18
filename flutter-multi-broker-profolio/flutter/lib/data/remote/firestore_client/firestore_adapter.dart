// coverage:ignore-file
// Justification: thin adapter over cloud_firestore; behaviour is covered
// by Firestore emulator tests in the `firebase` module and exercised via
// the in-memory FakeFirestoreClient in the data-layer tests.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_client.dart';

/// Concrete [FirestoreClient] backed by `cloud_firestore`.
class CloudFirestoreClient implements FirestoreClient {
  CloudFirestoreClient(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _sub(String uid, String name) =>
      _userDoc(uid).collection(name);

  @override
  Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    final snap = await _userDoc(userId).get();
    return snap.data();
  }

  @override
  Future<void> setUserSettings(String userId, Map<String, dynamic> data) =>
      _userDoc(userId).set(data, SetOptions(merge: true));

  @override
  Stream<Map<String, dynamic>?> watchUserSettings(String userId) =>
      _userDoc(userId).snapshots().map((s) => s.data());

  @override
  Future<List<Map<String, dynamic>>> listManualHoldings(String userId) async {
    final snap = await _sub(userId, 'manualHoldings').get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  @override
  Future<void> upsertManualHolding(
    String userId,
    String holdingId,
    Map<String, dynamic> data,
  ) =>
      _sub(userId, 'manualHoldings')
          .doc(holdingId)
          .set(data, SetOptions(merge: true));

  @override
  Future<void> deleteManualHolding(String userId, String holdingId) =>
      _sub(userId, 'manualHoldings').doc(holdingId).delete();

  @override
  Stream<List<Map<String, dynamic>>> watchManualHoldings(String userId) =>
      _sub(userId, 'manualHoldings').snapshots().map(
            (s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
          );

  @override
  Future<List<Map<String, dynamic>>> listAlerts(String userId) async {
    final snap = await _sub(userId, 'alerts').get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  @override
  Future<void> upsertAlert(
    String userId,
    String alertId,
    Map<String, dynamic> data,
  ) =>
      _sub(userId, 'alerts').doc(alertId).set(data, SetOptions(merge: true));

  @override
  Future<void> deleteAlert(String userId, String alertId) =>
      _sub(userId, 'alerts').doc(alertId).delete();

  @override
  Stream<List<Map<String, dynamic>>> watchAlerts(String userId) =>
      _sub(userId, 'alerts').snapshots().map(
            (s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
          );

  @override
  Future<List<Map<String, dynamic>>> listConnections(String userId) async {
    final snap = await _sub(userId, 'connections').get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  @override
  Future<void> upsertConnection(
    String userId,
    String connectionId,
    Map<String, dynamic> data,
  ) =>
      _sub(userId, 'connections')
          .doc(connectionId)
          .set(data, SetOptions(merge: true));

  @override
  Future<void> deleteConnection(String userId, String connectionId) =>
      _sub(userId, 'connections').doc(connectionId).delete();

  @override
  Stream<List<Map<String, dynamic>>> watchConnections(String userId) =>
      _sub(userId, 'connections').snapshots().map(
            (s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
          );

  @override
  Future<void> setEncryptedCredential(
    String userId,
    String connectionId,
    String encodedBlob,
  ) =>
      _sub(userId, 'connections').doc(connectionId).set(
        <String, dynamic>{'encryptedBlob': encodedBlob},
        SetOptions(merge: true),
      );

  @override
  Future<String?> getEncryptedCredential(
    String userId,
    String connectionId,
  ) async {
    final snap = await _sub(userId, 'connections').doc(connectionId).get();
    final data = snap.data();
    return data == null ? null : data['encryptedBlob'] as String?;
  }

  @override
  Future<void> upsertDeviceToken(
    String userId,
    String token, {
    required String platform,
    required String appVersion,
    DateTime? lastSeen,
  }) {
    return _sub(userId, 'devices').doc(token).set(
      <String, dynamic>{
        'platform': platform,
        'appVersion': appVersion,
        'lastSeen': Timestamp.fromDate(
          (lastSeen ?? DateTime.now()).toUtc(),
        ),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteDeviceToken(String userId, String token) {
    return _sub(userId, 'devices').doc(token).delete();
  }

  @override
  Future<List<Map<String, dynamic>>> listDeviceTokens(String userId) async {
    final snap = await _sub(userId, 'devices').get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }
}
