import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_broker_portfolio/app_lock/app_lock.dart';
import 'package:multi_broker_portfolio/state/app_lock_provider.dart';

void main() {
  group('appLockProvider', () {
    test('stores PIN hash and unlocks with valid pin', () async {
      final store = InMemoryAppLockStore();
      final now = _FakeNow(DateTime.utc(2026, 1, 1, 0, 0, 0));
      final container = ProviderContainer(
        overrides: [
          appLockStoreProvider.overrideWithValue(store),
          appLockBiometricAuthenticatorProvider
              .overrideWithValue(_FakeBiometricAuth(false)),
          appLockNowProvider.overrideWithValue(now.call),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appLockProvider.future);
      await container.read(appLockProvider.notifier).setEnabled(true);
      await container
          .read(appLockProvider.notifier)
          .setPin(pin: '1234', confirmPin: '1234');

      final bad =
          await container.read(appLockProvider.notifier).unlockWithPin('0000');
      expect(bad, isFalse);

      final ok =
          await container.read(appLockProvider.notifier).unlockWithPin('1234');
      expect(ok, isTrue);
      expect(container.read(appLockProvider).value?.isLocked, isFalse);
    });

    test('applies backoff after repeated failed attempts', () async {
      final store = InMemoryAppLockStore();
      final now = _FakeNow(DateTime.utc(2026, 1, 1, 0, 0, 0));
      final container = ProviderContainer(
        overrides: [
          appLockStoreProvider.overrideWithValue(store),
          appLockBiometricAuthenticatorProvider
              .overrideWithValue(_FakeBiometricAuth(false)),
          appLockNowProvider.overrideWithValue(now.call),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appLockProvider.future);
      await container.read(appLockProvider.notifier).setEnabled(true);
      await container
          .read(appLockProvider.notifier)
          .setPin(pin: '1234', confirmPin: '1234');

      await container.read(appLockProvider.notifier).unlockWithPin('0000');
      await container.read(appLockProvider.notifier).unlockWithPin('0000');
      await container.read(appLockProvider.notifier).unlockWithPin('0000');

      final state = container.read(appLockProvider).value!;
      expect(state.failedAttempts, 3);
      expect(state.backoffUntil, isNotNull);

      final blocked =
          await container.read(appLockProvider.notifier).unlockWithPin('1234');
      expect(blocked, isFalse);

      now.advance(const Duration(seconds: 2));
      final unlocked =
          await container.read(appLockProvider.notifier).unlockWithPin('1234');
      expect(unlocked, isTrue);
    });

    test('auto-locks when resumed after timeout', () async {
      final store = InMemoryAppLockStore();
      final now = _FakeNow(DateTime.utc(2026, 1, 1, 0, 0, 0));
      final container = ProviderContainer(
        overrides: [
          appLockStoreProvider.overrideWithValue(store),
          appLockBiometricAuthenticatorProvider
              .overrideWithValue(_FakeBiometricAuth(true)),
          appLockNowProvider.overrideWithValue(now.call),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appLockProvider.future);
      await container.read(appLockProvider.notifier).setEnabled(true);
      await container
          .read(appLockProvider.notifier)
          .setTimeout(const Duration(seconds: 30));
      await container
          .read(appLockProvider.notifier)
          .setPin(pin: '1234', confirmPin: '1234');
      await container.read(appLockProvider.notifier).unlockWithPin('1234');

      expect(container.read(appLockProvider).value?.isLocked, isFalse);

      await container
          .read(appLockProvider.notifier)
          .handleLifecycleChange(AppLifecycleState.paused);
      now.advance(const Duration(seconds: 31));
      await container
          .read(appLockProvider.notifier)
          .handleLifecycleChange(AppLifecycleState.resumed);

      expect(container.read(appLockProvider).value?.isLocked, isTrue);
    });

    test('unlocks with biometrics when enabled', () async {
      final store = InMemoryAppLockStore();
      final container = ProviderContainer(
        overrides: [
          appLockStoreProvider.overrideWithValue(store),
          appLockBiometricAuthenticatorProvider
              .overrideWithValue(_FakeBiometricAuth(true)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appLockProvider.future);
      await container.read(appLockProvider.notifier).setEnabled(true);

      final unlocked =
          await container.read(appLockProvider.notifier).unlockWithBiometrics();
      expect(unlocked, isTrue);
      expect(container.read(appLockProvider).value?.isLocked, isFalse);
    });
  });
}

class _FakeBiometricAuth implements BiometricAuthenticator {
  _FakeBiometricAuth(this._result);

  final bool _result;

  @override
  Future<bool> authenticate({required String reason}) async => _result;

  @override
  Future<bool> isAvailable() async => true;
}

class _FakeNow {
  _FakeNow(this._now);

  DateTime _now;

  DateTime call() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}
