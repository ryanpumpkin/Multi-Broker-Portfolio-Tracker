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
  SecureAppLockStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _kEnabled = 'app_lock.enabled';
  static const _kBiometricEnabled = 'app_lock.biometric_enabled';
  static const _kTimeoutSeconds = 'app_lock.timeout_seconds';
  static const _kPinHash = 'app_lock.pin_hash';
  static const _kSalt = 'app_lock.salt';

  @override
  Future<AppLockSettings> readSettings() async {
    final enabled = await _storage.read(key: _kEnabled);
    final biometric = await _storage.read(key: _kBiometricEnabled);
    final timeout = await _storage.read(key: _kTimeoutSeconds);
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
    await _storage.write(key: _kEnabled, value: settings.enabled.toString());
    await _storage.write(
      key: _kBiometricEnabled,
      value: settings.biometricEnabled.toString(),
    );
    await _storage.write(
      key: _kTimeoutSeconds,
      value: settings.timeout.inSeconds.toString(),
    );
  }

  @override
  Future<String?> readPinHash() => _storage.read(key: _kPinHash);

  @override
  Future<void> writePinHash(String hash) => _storage.write(
        key: _kPinHash,
        value: hash,
      );

  @override
  Future<void> clearPinHash() => _storage.delete(key: _kPinHash);

  @override
  Future<String?> readSalt() => _storage.read(key: _kSalt);

  @override
  Future<void> writeSalt(String saltB64) =>
      _storage.write(key: _kSalt, value: saltB64);
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
