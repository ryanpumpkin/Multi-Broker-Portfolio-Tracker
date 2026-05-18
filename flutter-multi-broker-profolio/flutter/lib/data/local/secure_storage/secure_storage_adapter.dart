// coverage:ignore-file
// Justification: thin platform-channel adapter for flutter_secure_storage;
// behaviour is provider-tested by package authors and cannot be exercised
// in unit tests without a Flutter binding.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_store.dart';

/// [KeyValueStore] implementation backed by `flutter_secure_storage`.
///
/// On Android uses EncryptedSharedPreferences; on iOS/macOS the Keychain;
/// on web a best-effort encrypted IndexedDB blob (see package docs for
/// caveats).
class FlutterSecureStorageAdapter implements KeyValueStore {
  FlutterSecureStorageAdapter([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}
