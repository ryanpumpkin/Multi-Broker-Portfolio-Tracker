import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_lock_settings.dart';

abstract class AppLockStore {
  Future<AppLockSettings> readSettings();
  Future<void> writeSettings(AppLockSettings settings);
  Future<String?> readPinHash();
  Future<void> writePinHash(String hash);
  Future<void> clearPinHash();

  /// Per-user salt used to derive the E2E credential-encryption key from
  /// the PIN. Returns base64url-encoded bytes, or null if no salt is
  /// stored yet. Generated once on first PIN setup and never rotated.
  Future<String?> readSalt();
  Future<void> writeSalt(String saltB64);
}

class SecureAppLockStore implements AppLockStore {
  /// Construct with an optional [userScope] (typically the Firebase uid) so
  /// PIN + salt + settings are stored under per-account keys. When null,
  /// falls back to the legacy unscoped keys — used only in tests and during
  /// the brief window before the user has signed in.
  SecureAppLockStore([FlutterSecureStorage? storage, String? userScope])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _scope = userScope;

  final FlutterSecureStorage _storage;
  final String? _scope;

  String _key(String suffix) =>
      _scope == null ? 'app_lock.$suffix' : 'app_lock.$_scope.$suffix';

  @override
  Future<AppLockSettings> readSettings() async {
    final enabled = await _storage.read(key: _key('enabled'));
    final biometric = await _storage.read(key: _key('biometric_enabled'));
    final timeout = await _storage.read(key: _key('timeout_seconds'));
    return AppLockSettings(
      enabled: enabled == null ? false : enabled == 'true',
      biometricEnabled: biometric == null ? true : biometric == 'true',
      timeout: Duration(
        seconds: int.tryParse(timeout ?? '') ?? 30,
      ),
    );
  }

  @override
  Future<void> writeSettings(AppLockSettings settings) async {
    await _storage.write(
      key: _key('enabled'),
      value: settings.enabled.toString(),
    );
    await _storage.write(
      key: _key('biometric_enabled'),
      value: settings.biometricEnabled.toString(),
    );
    await _storage.write(
      key: _key('timeout_seconds'),
      value: settings.timeout.inSeconds.toString(),
    );
  }

  @override
  Future<String?> readPinHash() => _storage.read(key: _key('pin_hash'));

  @override
  Future<void> writePinHash(String hash) =>
      _storage.write(key: _key('pin_hash'), value: hash);

  @override
  Future<void> clearPinHash() => _storage.delete(key: _key('pin_hash'));

  @override
  Future<String?> readSalt() => _storage.read(key: _key('salt'));

  @override
  Future<void> writeSalt(String saltB64) =>
      _storage.write(key: _key('salt'), value: saltB64);
}

class InMemoryAppLockStore implements AppLockStore {
  AppLockSettings _settings = const AppLockSettings(
    enabled: false,
    biometricEnabled: true,
    timeout: Duration(seconds: 30),
  );
  String? _pinHash;
  String? _salt;

  @override
  Future<void> clearPinHash() async {
    _pinHash = null;
  }

  @override
  Future<String?> readPinHash() async => _pinHash;

  @override
  Future<AppLockSettings> readSettings() async => _settings;

  @override
  Future<void> writePinHash(String hash) async {
    _pinHash = hash;
  }

  @override
  Future<void> writeSettings(AppLockSettings settings) async {
    _settings = settings;
  }

  @override
  Future<String?> readSalt() async => _salt;

  @override
  Future<void> writeSalt(String saltB64) async {
    _salt = saltB64;
  }
}
