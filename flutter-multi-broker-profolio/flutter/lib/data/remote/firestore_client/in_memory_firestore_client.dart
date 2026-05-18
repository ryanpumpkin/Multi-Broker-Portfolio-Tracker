import 'dart:async';

import 'firestore_client.dart';

/// In-memory [FirestoreClient] used by unit tests and as a transient
/// fallback when offline (the real client is preferred).
class InMemoryFirestoreClient implements FirestoreClient {
  final Map<String, Map<String, dynamic>> _settings = {};
  final Map<String, Map<String, Map<String, dynamic>>> _holdings = {};
  final Map<String, Map<String, Map<String, dynamic>>> _alerts = {};
  final Map<String, Map<String, Map<String, dynamic>>> _connections = {};
  final Map<String, Map<String, Map<String, dynamic>>> _devices = {};

  final Map<String, StreamController<Map<String, dynamic>?>> _settingsCtrls =
      {};
  final Map<String, StreamController<List<Map<String, dynamic>>>>
      _holdingsCtrls = {};
  final Map<String, StreamController<List<Map<String, dynamic>>>> _alertsCtrls =
      {};
  final Map<String, StreamController<List<Map<String, dynamic>>>>
      _connectionsCtrls = {};
  final Map<String, StreamController<List<Map<String, dynamic>>>>
      _devicesCtrls = {};

  StreamController<T> _ctrl<T>(
    Map<String, StreamController<T>> map,
    String key,
  ) =>
      map.putIfAbsent(key, () => StreamController<T>.broadcast());

  List<Map<String, dynamic>> _withId(Map<String, Map<String, dynamic>> coll) =>
      coll.entries
          .map((e) => <String, dynamic>{...e.value, 'id': e.key})
          .toList(growable: false);

  // --- settings ---------------------------------------------------------

  @override
  Future<Map<String, dynamic>?> getUserSettings(String userId) async =>
      _settings[userId] == null
          ? null
          : Map<String, dynamic>.from(_settings[userId]!);

  @override
  Future<void> setUserSettings(String userId, Map<String, dynamic> data) async {
    final current = _settings[userId] ?? <String, dynamic>{};
    final merged = <String, dynamic>{...current, ...data};
    _settings[userId] = merged;
    _ctrl(_settingsCtrls, userId).add(Map<String, dynamic>.from(merged));
  }

  @override
  Stream<Map<String, dynamic>?> watchUserSettings(String userId) async* {
    yield await getUserSettings(userId);
    yield* _ctrl(_settingsCtrls, userId).stream;
  }

  // --- manual holdings --------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> listManualHoldings(String userId) async =>
      _withId(_holdings[userId] ?? const {});

  @override
  Future<void> upsertManualHolding(
    String userId,
    String holdingId,
    Map<String, dynamic> data,
  ) async {
    final coll = _holdings.putIfAbsent(userId, () => {});
    coll[holdingId] = <String, dynamic>{...?coll[holdingId], ...data};
    _ctrl(_holdingsCtrls, userId).add(_withId(coll));
  }

  @override
  Future<void> deleteManualHolding(String userId, String holdingId) async {
    final coll = _holdings[userId];
    if (coll == null) return;
    coll.remove(holdingId);
    _ctrl(_holdingsCtrls, userId).add(_withId(coll));
  }

  @override
  Stream<List<Map<String, dynamic>>> watchManualHoldings(String userId) async* {
    yield await listManualHoldings(userId);
    yield* _ctrl(_holdingsCtrls, userId).stream;
  }

  // --- alerts ------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> listAlerts(String userId) async =>
      _withId(_alerts[userId] ?? const {});

  @override
  Future<void> upsertAlert(
    String userId,
    String alertId,
    Map<String, dynamic> data,
  ) async {
    final coll = _alerts.putIfAbsent(userId, () => {});
    coll[alertId] = <String, dynamic>{...?coll[alertId], ...data};
    _ctrl(_alertsCtrls, userId).add(_withId(coll));
  }

  @override
  Future<void> deleteAlert(String userId, String alertId) async {
    final coll = _alerts[userId];
    if (coll == null) return;
    coll.remove(alertId);
    _ctrl(_alertsCtrls, userId).add(_withId(coll));
  }

  @override
  Stream<List<Map<String, dynamic>>> watchAlerts(String userId) async* {
    yield await listAlerts(userId);
    yield* _ctrl(_alertsCtrls, userId).stream;
  }

  // --- connections + credentials ----------------------------------------

  @override
  Future<List<Map<String, dynamic>>> listConnections(String userId) async =>
      _withId(_connections[userId] ?? const {});

  @override
  Future<void> upsertConnection(
    String userId,
    String connectionId,
    Map<String, dynamic> data,
  ) async {
    final coll = _connections.putIfAbsent(userId, () => {});
    coll[connectionId] = <String, dynamic>{...?coll[connectionId], ...data};
    _ctrl(_connectionsCtrls, userId).add(_withId(coll));
  }

  @override
  Future<void> deleteConnection(String userId, String connectionId) async {
    final coll = _connections[userId];
    if (coll == null) return;
    coll.remove(connectionId);
    _ctrl(_connectionsCtrls, userId).add(_withId(coll));
  }

  @override
  Stream<List<Map<String, dynamic>>> watchConnections(String userId) async* {
    yield await listConnections(userId);
    yield* _ctrl(_connectionsCtrls, userId).stream;
  }

  @override
  Future<void> setEncryptedCredential(
    String userId,
    String connectionId,
    String encodedBlob,
  ) async {
    final coll = _connections.putIfAbsent(userId, () => {});
    coll[connectionId] = <String, dynamic>{
      ...?coll[connectionId],
      'encryptedBlob': encodedBlob,
    };
    _ctrl(_connectionsCtrls, userId).add(_withId(coll));
  }

  @override
  Future<String?> getEncryptedCredential(
    String userId,
    String connectionId,
  ) async {
    return _connections[userId]?[connectionId]?['encryptedBlob'] as String?;
  }

  @override
  Future<void> upsertDeviceToken(
    String userId,
    String token, {
    required String platform,
    required String appVersion,
    DateTime? lastSeen,
  }) async {
    final coll = _devices.putIfAbsent(userId, () => {});
    coll[token] = <String, dynamic>{
      ...?coll[token],
      'platform': platform,
      'appVersion': appVersion,
      'lastSeen': (lastSeen ?? DateTime.now()).toUtc().toIso8601String(),
    };
    _ctrl(_devicesCtrls, userId).add(_withId(coll));
  }

  @override
  Future<void> deleteDeviceToken(String userId, String token) async {
    final coll = _devices[userId];
    if (coll == null) return;
    coll.remove(token);
    _ctrl(_devicesCtrls, userId).add(_withId(coll));
  }

  @override
  Future<List<Map<String, dynamic>>> listDeviceTokens(String userId) async {
    return _withId(_devices[userId] ?? const {});
  }
}
