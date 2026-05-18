import 'dart:async';

import '../../domain/domain.dart';
import '../local/secure_storage/secure_store.dart';

/// Minimal data-source contract for an auth provider. The Firebase Auth
/// adapter (in `auth_adapter.dart`) implements this.
abstract class AuthDataSource {
  Future<AuthUser?> currentUser();
  Stream<AuthUser?> userChanges();
  Future<AuthUser> signIn({required String email, required String password});
  Future<AuthUser> signUp({required String email, required String password});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();
}

abstract class SocialAuthDataSource {
  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithApple();
}

abstract class AuthSessionCleaner {
  Future<void> clear();
}

class NoopAuthSessionCleaner implements AuthSessionCleaner {
  const NoopAuthSessionCleaner();

  @override
  Future<void> clear() async {}
}

class SecureStoreAuthSessionCleaner implements AuthSessionCleaner {
  const SecureStoreAuthSessionCleaner(this._store);

  final SecureStore _store;

  @override
  Future<void> clear() => _store.wipe();
}

class CallbackAuthSessionCleaner implements AuthSessionCleaner {
  const CallbackAuthSessionCleaner(this._onClear);

  final Future<void> Function() _onClear;

  @override
  Future<void> clear() => _onClear();
}

class CompositeAuthSessionCleaner implements AuthSessionCleaner {
  const CompositeAuthSessionCleaner(this._cleaners);

  final List<AuthSessionCleaner> _cleaners;

  @override
  Future<void> clear() async {
    for (final cleaner in _cleaners) {
      await cleaner.clear();
    }
  }
}

abstract class AuthRepositoryRecovery {
  Future<void> sendPasswordResetEmail({required String email});
}

abstract class AuthRepositorySocialSignIn {
  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithApple();
}

class AuthRepositoryImpl
    implements
        AuthRepository,
        AuthRepositoryRecovery,
        AuthRepositorySocialSignIn {
  AuthRepositoryImpl(
    this._source, {
    AuthSessionCleaner sessionCleaner = const NoopAuthSessionCleaner(),
  }) : _sessionCleaner = sessionCleaner;

  final AuthDataSource _source;
  final AuthSessionCleaner _sessionCleaner;

  @override
  Future<AuthUser?> currentUser() => _source.currentUser();

  @override
  Stream<AuthUser?> watchUser() => _source.userChanges();

  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      _source.signIn(email: email, password: password);

  @override
  Future<AuthUser> signUp({required String email, required String password}) =>
      _source.signUp(email: email, password: password);

  @override
  Future<void> signOut() async {
    await _source.signOut();
    await _sessionCleaner.clear();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _source.sendPasswordResetEmail(email: email);

  @override
  Future<AuthUser> signInWithGoogle() {
    if (_source is! SocialAuthDataSource) {
      throw UnsupportedError('Google sign-in is not configured.');
    }
    final source = _source as SocialAuthDataSource;
    return source.signInWithGoogle();
  }

  @override
  Future<AuthUser> signInWithApple() {
    if (_source is! SocialAuthDataSource) {
      throw UnsupportedError('Apple sign-in is not configured.');
    }
    final source = _source as SocialAuthDataSource;
    return source.signInWithApple();
  }
}

/// In-memory [AuthDataSource] for tests.
class InMemoryAuthDataSource implements AuthDataSource {
  InMemoryAuthDataSource({AuthUser? initial}) : _user = initial {
    _ctrl.add(_user);
  }

  AuthUser? _user;
  final StreamController<AuthUser?> _ctrl =
      StreamController<AuthUser?>.broadcast();

  @override
  Future<AuthUser?> currentUser() async => _user;

  @override
  Stream<AuthUser?> userChanges() async* {
    yield _user;
    yield* _ctrl.stream;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    _user = AuthUser(uid: 'uid_$email', email: email);
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    _user = AuthUser(uid: 'uid_$email', email: email);
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> signOut() async {
    _user = null;
    _ctrl.add(null);
  }

  Future<void> dispose() => _ctrl.close();
}
