import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auth_repository_impl.dart';
import '../domain/domain.dart';
import 'app_lock_provider.dart';
import 'credential_key_provider.dart';
import 'notifications_provider.dart';
import 'repository_providers.dart';

final authProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthUser?> {
  StreamSubscription<AuthUser?>? _subscription;

  @override
  Future<AuthUser?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    _subscription?.cancel();
    _subscription = repo.watchUser().listen(
      (user) {
        state = AsyncData(user);
      },
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );
    ref.onDispose(() => _subscription?.cancel());
    final user = await repo.currentUser();
    if (user != null) {
      await ref
          .read(notificationLifecycleProvider)
          .ensureInitializedForUser(user.uid);
    }
    return user;
  }

  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      await ref
          .read(notificationLifecycleProvider)
          .ensureInitializedForUser(user.uid);
      state = AsyncData(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password);
      await ref
          .read(notificationLifecycleProvider)
          .ensureInitializedForUser(user.uid);
      state = AsyncData(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(notificationLifecycleProvider).onBeforeSignOut();
      await ref.read(authRepositoryProvider).signOut();
      // Drop the cached app-lock + credential-key state so the next sign-in
      // re-reads from secure storage and re-derives the encryption key.
      // Without this, hasPin/isEnabled stay sticky in Riverpod and the
      // connections screen sees a stale snapshot of the previous session.
      ref.invalidate(credentialKeyProvider);
      ref.invalidate(appLockProvider);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    final repo = ref.read(authRepositoryProvider);
    if (repo is! AuthRepositoryRecovery) {
      throw UnsupportedError(
        'Password reset is not supported by the configured auth backend.',
      );
    }
    final recovery = repo as AuthRepositoryRecovery;
    await recovery.sendPasswordResetEmail(email: email);
  }

  Future<AuthUser> signInWithGoogle() async {
    final repo = ref.read(authRepositoryProvider);
    if (repo is! AuthRepositorySocialSignIn) {
      throw UnsupportedError(
        'Google sign-in is not supported by the configured auth backend.',
      );
    }
    final social = repo as AuthRepositorySocialSignIn;
    state = const AsyncLoading();
    try {
      final user = await social.signInWithGoogle();
      state = AsyncData(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<AuthUser> signInWithApple() async {
    final repo = ref.read(authRepositoryProvider);
    if (repo is! AuthRepositorySocialSignIn) {
      throw UnsupportedError(
        'Apple sign-in is not supported by the configured auth backend.',
      );
    }
    final social = repo as AuthRepositorySocialSignIn;
    state = const AsyncLoading();
    try {
      final user = await social.signInWithApple();
      state = AsyncData(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
