/// Typed facade over OS-secure key/value storage.
///
/// This file is platform-agnostic: it depends only on a small
/// [KeyValueStore] interface. The concrete `flutter_secure_storage`
/// adapter lives in `secure_storage_adapter.dart` and is excluded from
/// coverage because it is just platform-channel glue.
library;

/// A minimal key/value store backing [SecureStore].
///
/// Async because the underlying platform calls (keychain, KeyStore) are
/// async. Implementations must persist data across process restarts on
/// supported platforms; on web, persistence is best-effort.
abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<Map<String, String>> readAll();
}

/// Wraps a primary secure store with a fallback (typically in-memory).
///
/// Intended for web environments where secure storage can fail at runtime
/// (e.g. restricted private-browsing modes). On any primary-store exception,
/// operations transparently retry against [fallback].
class FallbackKeyValueStore implements KeyValueStore {
  FallbackKeyValueStore({
    required this.primary,
    KeyValueStore? fallback,
  }) : fallback = fallback ?? InMemoryKeyValueStore();

  final KeyValueStore primary;
  final KeyValueStore fallback;

  Future<T> _withFallback<T>(
    Future<T> Function(KeyValueStore store) run,
  ) async {
    try {
      return await run(primary);
    } catch (_) {
      return run(fallback);
    }
  }

  @override
  Future<void> delete(String key) => _withFallback((s) => s.delete(key));

  @override
  Future<void> deleteAll() => _withFallback((s) => s.deleteAll());

  @override
  Future<String?> read(String key) => _withFallback((s) => s.read(key));

  @override
  Future<Map<String, String>> readAll() => _withFallback((s) => s.readAll());

  @override
  Future<void> write(String key, String value) =>
      _withFallback((s) => s.write(key, value));
}

/// In-memory [KeyValueStore] used by tests and as a web fallback when
/// `flutter_secure_storage` cannot persist (e.g. private-tab browsers).
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _map = <String, String>{};

  @override
  Future<void> delete(String key) async => _map.remove(key);

  @override
  Future<void> deleteAll() async => _map.clear();

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<Map<String, String>> readAll() async => Map.unmodifiable(_map);

  @override
  Future<void> write(String key, String value) async => _map[key] = value;
}

/// Strongly-typed access to the secrets this app stores.
///
/// Key namespacing is centralised here so callers cannot accidentally
/// collide. Use the typed getters / setters; do not bypass this class.
class SecureStore {
  SecureStore(this._kv);

  final KeyValueStore _kv;

  // --- App-lock PIN hash ---------------------------------------------------

  static const String _kPinHash = 'app_lock.pin_hash';

  Future<String?> getPinHash() => _kv.read(_kPinHash);
  Future<void> setPinHash(String hash) => _kv.write(_kPinHash, hash);
  Future<void> clearPinHash() => _kv.delete(_kPinHash);

  // --- E2E master-key salt -------------------------------------------------

  static const String _kE2eSalt = 'e2e.master_key_salt';

  /// Returns the persisted Argon2id salt, or null if none has been
  /// initialised yet.
  Future<String?> getE2eSalt() => _kv.read(_kE2eSalt);

  /// Persists [saltBase64]. Implementations should treat this as
  /// effectively immutable per user.
  Future<void> setE2eSalt(String saltBase64) =>
      _kv.write(_kE2eSalt, saltBase64);

  // --- Per-connection credential blobs ------------------------------------

  static const String _kCredPrefix = 'cred.';

  String _credKey(String connectionId) => '$_kCredPrefix$connectionId';

  Future<String?> getEncryptedCredential(String connectionId) =>
      _kv.read(_credKey(connectionId));

  Future<void> setEncryptedCredential(String connectionId, String blob) =>
      _kv.write(_credKey(connectionId), blob);

  Future<void> deleteEncryptedCredential(String connectionId) =>
      _kv.delete(_credKey(connectionId));

  /// Lists all known connection IDs that have a cached credential.
  Future<List<String>> listCredentialConnectionIds() async {
    final all = await _kv.readAll();
    return all.keys
        .where((k) => k.startsWith(_kCredPrefix))
        .map((k) => k.substring(_kCredPrefix.length))
        .toList(growable: false);
  }

  /// Wipes everything this app put in secure storage. Used on sign-out.
  Future<void> wipe() => _kv.deleteAll();
}
