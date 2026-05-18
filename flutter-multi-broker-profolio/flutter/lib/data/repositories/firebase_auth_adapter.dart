// coverage:ignore-file
// Justification: thin adapter over firebase_auth; covered by manual QA on
// a real device.
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/domain.dart';
import 'auth_repository_impl.dart';

class FirebaseAuthAdapter implements AuthDataSource {
  FirebaseAuthAdapter(this._auth);

  final FirebaseAuth _auth;

  AuthUser? _map(User? u) => u == null
      ? null
      : AuthUser(
          uid: u.uid,
          email: u.email ?? '',
          displayName: u.displayName,
        );

  @override
  Future<AuthUser?> currentUser() async => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> userChanges() => _auth.userChanges().map(_map);

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _map(cred.user)!;
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user != null) {
      await user.sendEmailVerification();
    }
    return _map(user)!;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() => _auth.signOut();
}
