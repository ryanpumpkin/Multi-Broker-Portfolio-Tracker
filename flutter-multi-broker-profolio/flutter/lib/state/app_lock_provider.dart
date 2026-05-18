import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLockProvider = NotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);

class AppLockState {
  const AppLockState({
    required this.isLocked,
    required this.failedAttempts,
    this.lastFailedAt,
  });

  final bool isLocked;
  final int failedAttempts;
  final DateTime? lastFailedAt;

  AppLockState copyWith({
    bool? isLocked,
    int? failedAttempts,
    Object? lastFailedAt = _unset,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lastFailedAt: identical(lastFailedAt, _unset)
          ? this.lastFailedAt
          : lastFailedAt as DateTime?,
    );
  }

  static const Object _unset = Object();
}

class AppLockController extends Notifier<AppLockState> {
  @override
  AppLockState build() {
    return const AppLockState(
      isLocked: true,
      failedAttempts: 0,
    );
  }

  void lock() {
    state = state.copyWith(isLocked: true);
  }

  void unlock() {
    state = state.copyWith(
      isLocked: false,
      failedAttempts: 0,
      lastFailedAt: null,
    );
  }

  void registerFailedAttempt() {
    state = state.copyWith(
      isLocked: true,
      failedAttempts: state.failedAttempts + 1,
      lastFailedAt: DateTime.now().toUtc(),
    );
  }

  void resetAttempts() {
    state = state.copyWith(
      failedAttempts: 0,
      lastFailedAt: null,
    );
  }
}
