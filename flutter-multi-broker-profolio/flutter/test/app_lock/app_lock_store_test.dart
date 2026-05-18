import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/app_lock/app_lock.dart';

void main() {
  group('AppLockSettings', () {
    test('copyWith updates selected fields', () {
      const initial = AppLockSettings(
        enabled: false,
        biometricEnabled: true,
        timeout: Duration(seconds: 30),
      );

      final updated = initial.copyWith(
        enabled: true,
        biometricEnabled: false,
      );

      expect(updated.enabled, isTrue);
      expect(updated.biometricEnabled, isFalse);
      expect(updated.timeout, const Duration(seconds: 30));
    });
  });

  group('SecureAppLockStore', () {
    test('reads defaults when no keys are present', () async {
      final storage = _FakeFlutterSecureStorage();
      final store = SecureAppLockStore(storage);

      final settings = await store.readSettings();
      expect(settings.enabled, isFalse);
      expect(settings.biometricEnabled, isTrue);
      expect(settings.timeout, const Duration(seconds: 30));
    });

    test('writes and reads settings + pin hash', () async {
      final storage = _FakeFlutterSecureStorage();
      final store = SecureAppLockStore(storage);

      await store.writeSettings(
        const AppLockSettings(
          enabled: true,
          biometricEnabled: false,
          timeout: Duration(minutes: 1),
        ),
      );
      await store.writePinHash('abc');

      final settings = await store.readSettings();
      final hash = await store.readPinHash();

      expect(settings.enabled, isTrue);
      expect(settings.biometricEnabled, isFalse);
      expect(settings.timeout, const Duration(minutes: 1));
      expect(hash, 'abc');

      await store.clearPinHash();
      expect(await store.readPinHash(), isNull);
    });
  });

  group('InMemoryAppLockStore', () {
    test('stores settings and pin hash in memory', () async {
      final store = InMemoryAppLockStore();

      await store.writeSettings(
        const AppLockSettings(
          enabled: true,
          biometricEnabled: true,
          timeout: Duration(seconds: 15),
        ),
      );
      await store.writePinHash('h');

      expect((await store.readSettings()).enabled, isTrue);
      expect(await store.readPinHash(), 'h');

      await store.clearPinHash();
      expect(await store.readPinHash(), isNull);
    });
  });
}

class _FakeFlutterSecureStorage extends FlutterSecureStorage {
  _FakeFlutterSecureStorage();

  final Map<String, String> _map = <String, String>{};

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _map.remove(key);
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _map[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _map.remove(key);
      return;
    }
    _map[key] = value;
  }
}
