import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/domain.dart';
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
    return repo.currentUser();
  }

  Future<AuthUser> signIn(
      {required String email, required String password,}) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      state = AsyncData(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<AuthUser> signUp(
      {required String email, required String password,}) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password);
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
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
