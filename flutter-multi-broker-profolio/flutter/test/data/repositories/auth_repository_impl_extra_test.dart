import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/data/repositories/auth_repository_impl.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';

void main() {
  group('AuthRepositoryImpl capabilities', () {
    test('password reset delegates to source', () async {
      final source = _SpyAuthDataSource();
      final repo = AuthRepositoryImpl(source);

      await repo.sendPasswordResetEmail(email: 'reset@example.com');
      expect(source.lastResetEmail, 'reset@example.com');
    });

    test('sign out runs all cleaners', () async {
      final source = _SpyAuthDataSource();
      final a = _SpyCleaner();
      final b = _SpyCleaner();
      final repo = AuthRepositoryImpl(
        source,
        sessionCleaner: CompositeAuthSessionCleaner([a, b]),
      );

      await repo.signOut();

      expect(source.signOutCalls, 1);
      expect(a.calls, 1);
      expect(b.calls, 1);
    });

    test('social sign-in throws when source is not social-capable', () async {
      final repo = AuthRepositoryImpl(_SpyAuthDataSource());

      expect(repo.signInWithGoogle, throwsUnsupportedError);
      expect(repo.signInWithApple, throwsUnsupportedError);
    });

    test('social sign-in delegates when source supports it', () async {
      final repo = AuthRepositoryImpl(_SocialAuthDataSource());

      final google = await repo.signInWithGoogle();
      final apple = await repo.signInWithApple();

      expect(google.email, 'google@example.com');
      expect(apple.email, 'apple@example.com');
    });

    test('in-memory data source sign-in/out updates current user', () async {
      final source = InMemoryAuthDataSource();
      final user = await source.signIn(email: 'u@example.com', password: 'pw');
      expect(user.email, 'u@example.com');
      expect((await source.currentUser())?.email, 'u@example.com');
      await source.signOut();
      expect(await source.currentUser(), isNull);
      await source.dispose();
    });
  });
}

class _SpyAuthDataSource implements AuthDataSource {
  String? lastResetEmail;
  int signOutCalls = 0;
  AuthUser? _user;
  final StreamController<AuthUser?> _ctrl =
      StreamController<AuthUser?>.broadcast();

  @override
  Future<AuthUser?> currentUser() async => _user;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    lastResetEmail = email;
  }

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
    signOutCalls += 1;
    _user = null;
    _ctrl.add(null);
  }

  @override
  Future<AuthUser> signUp({required String email, required String password}) =>
      signIn(email: email, password: password);

  @override
  Stream<AuthUser?> userChanges() async* {
    yield _user;
    yield* _ctrl.stream;
  }
}

class _SocialAuthDataSource extends _SpyAuthDataSource
    implements SocialAuthDataSource {
  @override
  Future<AuthUser> signInWithApple() async =>
      const AuthUser(uid: 'apple', email: 'apple@example.com');

  @override
  Future<AuthUser> signInWithGoogle() async =>
      const AuthUser(uid: 'google', email: 'google@example.com');
}

class _SpyCleaner implements AuthSessionCleaner {
  int calls = 0;

  @override
  Future<void> clear() async {
    calls += 1;
  }
}
