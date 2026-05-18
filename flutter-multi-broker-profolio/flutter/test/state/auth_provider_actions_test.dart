import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_broker_portfolio/data/repositories/auth_repository_impl.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';
import 'package:multi_broker_portfolio/state/auth_provider.dart';
import 'package:multi_broker_portfolio/state/notifications_provider.dart';
import 'package:multi_broker_portfolio/state/repository_providers.dart';

void main() {
  group('AuthController extra actions', () {
    test('sendPasswordResetEmail delegates when capability is present',
        () async {
      final repo = _CapableAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          notificationLifecycleProvider.overrideWithValue(
            _NoopNotificationLifecycle(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authProvider.notifier)
          .sendPasswordResetEmail(email: 'reset@example.com');
      expect(repo.lastResetEmail, 'reset@example.com');
    });

    test('sendPasswordResetEmail throws when capability is missing', () async {
      final repo = _SimpleAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          notificationLifecycleProvider.overrideWithValue(
            _NoopNotificationLifecycle(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        () => container
            .read(authProvider.notifier)
            .sendPasswordResetEmail(email: 'reset@example.com'),
        throwsUnsupportedError,
      );
    });

    test('social sign-in updates provider state', () async {
      final repo = _CapableAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          notificationLifecycleProvider.overrideWithValue(
            _NoopNotificationLifecycle(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final google =
          await container.read(authProvider.notifier).signInWithGoogle();
      expect(google.email, 'google@example.com');
      expect(container.read(authProvider).value?.email, 'google@example.com');

      final apple =
          await container.read(authProvider.notifier).signInWithApple();
      expect(apple.email, 'apple@example.com');
      expect(container.read(authProvider).value?.email, 'apple@example.com');
    });

    test('social sign-in throws when capability is missing', () async {
      final repo = _SimpleAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          notificationLifecycleProvider.overrideWithValue(
            _NoopNotificationLifecycle(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        () => container.read(authProvider.notifier).signInWithGoogle(),
        throwsUnsupportedError,
      );
      await expectLater(
        () => container.read(authProvider.notifier).signInWithApple(),
        throwsUnsupportedError,
      );
    });
  });
}

class _NoopNotificationLifecycle implements NotificationLifecycle {
  @override
  Future<void> ensureInitializedForUser(String userId) async {}

  @override
  Future<void> onBeforeSignOut() async {}

  @override
  Future<void> onFirstAlertCreateAttempt() async {}
}

class _SimpleAuthRepository implements AuthRepository {
  AuthUser? _user;
  final StreamController<AuthUser?> _ctrl =
      StreamController<AuthUser?>.broadcast();

  @override
  Future<AuthUser?> currentUser() async => _user;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    _user = AuthUser(uid: 'uid', email: email);
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _ctrl.add(null);
  }

  @override
  Future<AuthUser> signUp({required String email, required String password}) =>
      signIn(email: email, password: password);

  @override
  Stream<AuthUser?> watchUser() async* {
    yield _user;
    yield* _ctrl.stream;
  }
}

class _CapableAuthRepository extends _SimpleAuthRepository
    implements AuthRepositoryRecovery, AuthRepositorySocialSignIn {
  String? lastResetEmail;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    lastResetEmail = email;
  }

  @override
  Future<AuthUser> signInWithApple() =>
      signIn(email: 'apple@example.com', password: 'x');

  @override
  Future<AuthUser> signInWithGoogle() =>
      signIn(email: 'google@example.com', password: 'x');
}
