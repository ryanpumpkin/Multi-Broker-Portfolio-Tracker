/// A minimal authenticated user identity exposed to the domain layer.
///
/// Concrete auth providers (Firebase, etc.) live in the data layer and map
/// their SDK types into this shape.
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
  });

  final String uid;
  final String email;
  final String? displayName;

  AuthUser copyWith({String? uid, String? email, String? displayName}) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(uid, email, displayName);

  @override
  String toString() =>
      'AuthUser(uid: $uid, email: $email, displayName: $displayName)';
}

/// Account-level authentication contract.
abstract class AuthRepository {
  /// The current signed-in user, or null if signed out.
  Future<AuthUser?> currentUser();

  /// Emits the latest [AuthUser] (or null) whenever the auth state changes.
  Stream<AuthUser?> watchUser();

  Future<AuthUser> signIn({required String email, required String password});

  Future<AuthUser> signUp({required String email, required String password});

  Future<void> signOut();
}
