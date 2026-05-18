import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_lock/app_lock.dart';

final appLockStoreProvider = Provider<AppLockStore>(
  (ref) => SecureAppLockStore(),
);

final appLockPinHasherProvider = Provider<PinHasher>(
  (ref) => const Sha256PinHasher(),
);

final appLockBiometricAuthenticatorProvider = Provider<BiometricAuthenticator>(
  (ref) => LocalAuthBiometricAuthenticator(),
);

final appLockNowProvider = Provider<DateTime Function()>(
  (ref) => () => DateTime.now().toUtc(),
);

final appLockProvider = AsyncNotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);

class AppLockState {
  const AppLockState({
    required this.isEnabled,
    required this.biometricEnabled,
    required this.timeout,
    required this.isLocked,
    required this.hasPin,
    required this.failedAttempts,
    this.backoffUntil,
    this.backgroundedAt,
  });

  final bool isEnabled;
  final bool biometricEnabled;
  final Duration timeout;
  final bool isLocked;
  final bool hasPin;
  final int failedAttempts;
  final DateTime? backoffUntil;
  final DateTime? backgroundedAt;

  AppLockState copyWith({
    bool? isEnabled,
    bool? biometricEnabled,
    Duration? timeout,
    bool? isLocked,
    bool? hasPin,
    int? failedAttempts,
    Object? backoffUntil = _unset,
    Object? backgroundedAt = _unset,
  }) {
    return AppLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      timeout: timeout ?? this.timeout,
      isLocked: isLocked ?? this.isLocked,
      hasPin: hasPin ?? this.hasPin,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      backoffUntil: identical(backoffUntil, _unset)
          ? this.backoffUntil
          : backoffUntil as DateTime?,
      backgroundedAt: identical(backgroundedAt, _unset)
          ? this.backgroundedAt
          : backgroundedAt as DateTime?,
    );
  }

  static const Object _unset = Object();
}

class AppLockController extends AsyncNotifier<AppLockState> {
  AppLockStore get _store => ref.read(appLockStoreProvider);
  PinHasher get _hasher => ref.read(appLockPinHasherProvider);
  BiometricAuthenticator get _biometric =>
      ref.read(appLockBiometricAuthenticatorProvider);
  DateTime Function() get _now => ref.read(appLockNowProvider);

  @override
  Future<AppLockState> build() async {
    final settings = await _store.readSettings();
    final hasPin = (await _store.readPinHash()) != null;
    return AppLockState(
      isEnabled: settings.enabled,
      biometricEnabled: settings.biometricEnabled,
      timeout: settings.timeout,
      isLocked: settings.enabled,
      hasPin: hasPin,
      failedAttempts: 0,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final current = await future;
    final next = current.copyWith(
      isEnabled: enabled,
      isLocked: enabled ? current.isLocked : false,
      failedAttempts: enabled ? current.failedAttempts : 0,
      backoffUntil: enabled ? current.backoffUntil : null,
    );
    await _persistSettings(next);
    state = AsyncData(next);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final current = await future;
    final next = current.copyWith(biometricEnabled: enabled);
    await _persistSettings(next);
    state = AsyncData(next);
  }

  Future<void> setTimeout(Duration timeout) async {
    final current = await future;
    final next = current.copyWith(timeout: timeout);
    await _persistSettings(next);
    state = AsyncData(next);
  }

  Future<void> setPin({
    required String pin,
    required String confirmPin,
  }) async {
    if (pin != confirmPin) {
      throw ArgumentError('PIN and confirmation do not match.');
    }
    if (!_isValidPin(pin)) {
      throw ArgumentError('PIN must be 4-8 digits.');
    }
    final hash = await _hasher.hash(pin);
    await _store.writePinHash(hash);
    final current = await future;
    state = AsyncData(current.copyWith(hasPin: true));
  }

  Future<bool> unlockWithPin(String pin) async {
    final current = await future;
    if (!current.isEnabled || _inBackoff(current)) {
      return false;
    }
    final storedHash = await _store.readPinHash();
    if (storedHash == null) {
      return false;
    }
    final pinHash = await _hasher.hash(pin);
    if (pinHash == storedHash) {
      state = AsyncData(
        current.copyWith(
          isLocked: false,
          failedAttempts: 0,
          backoffUntil: null,
        ),
      );
      return true;
    }
    state = AsyncData(_withFailedAttempt(current));
    return false;
  }

  Future<bool> unlockWithBiometrics() async {
    final current = await future;
    if (!current.isEnabled ||
        !current.biometricEnabled ||
        _inBackoff(current)) {
      return false;
    }
    final available = await _biometric.isAvailable();
    if (!available) {
      return false;
    }
    final unlocked = await _biometric.authenticate(
      reason: 'Unlock Multi-Broker Portfolio',
    );
    if (unlocked) {
      state = AsyncData(
        current.copyWith(
          isLocked: false,
          failedAttempts: 0,
          backoffUntil: null,
        ),
      );
      return true;
    }
    state = AsyncData(_withFailedAttempt(current));
    return false;
  }

  Future<void> lock() async {
    final current = await future;
    if (!current.isEnabled) return;
    state = AsyncData(current.copyWith(isLocked: true));
  }

  Future<void> clearPin() async {
    await _store.clearPinHash();
    final current = await future;
    state = AsyncData(current.copyWith(hasPin: false));
  }

  Future<void> handleLifecycleChange(AppLifecycleState lifecycle) async {
    final current = await future;
    if (lifecycle == AppLifecycleState.resumed) {
      final bgAt = current.backgroundedAt;
      if (bgAt == null || !current.isEnabled) {
        state = AsyncData(current.copyWith(backgroundedAt: null));
        return;
      }
      final elapsed = _now().difference(bgAt);
      final shouldLock = elapsed >= current.timeout;
      state = AsyncData(
        current.copyWith(
          backgroundedAt: null,
          isLocked: shouldLock ? true : current.isLocked,
        ),
      );
      return;
    }
    state = AsyncData(current.copyWith(backgroundedAt: _now()));
  }

  AppLockState _withFailedAttempt(AppLockState current) {
    final attempts = current.failedAttempts + 1;
    final delay = _backoffDelay(attempts);
    return current.copyWith(
      isLocked: true,
      failedAttempts: attempts,
      backoffUntil: delay == Duration.zero ? null : _now().add(delay),
    );
  }

  bool _inBackoff(AppLockState state) {
    final until = state.backoffUntil;
    if (until == null) return false;
    return _now().isBefore(until);
  }

  Duration _backoffDelay(int failedAttempts) {
    if (failedAttempts < 3) {
      return Duration.zero;
    }
    final seconds = min(300, 1 << (failedAttempts - 3));
    return Duration(seconds: seconds);
  }

  bool _isValidPin(String pin) {
    if (pin.length < 4 || pin.length > 8) return false;
    return RegExp(r'^\d+$').hasMatch(pin);
  }

  Future<void> _persistSettings(AppLockState state) {
    return _store.writeSettings(
      AppLockSettings(
        enabled: state.isEnabled,
        biometricEnabled: state.biometricEnabled,
        timeout: state.timeout,
      ),
    );
  }
}
