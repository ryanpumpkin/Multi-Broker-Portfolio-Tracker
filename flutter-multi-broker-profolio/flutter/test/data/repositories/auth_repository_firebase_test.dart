import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/data/repositories/auth_repository_impl.dart';
import 'package:multi_broker_portfolio/data/repositories/firebase_auth_adapter.dart';

void main() {
  group('AuthRepositoryImpl + FirebaseAuthAdapter', () {
    test('sign-up/sign-in/sign-out and watchUser work with mock auth',
        () async {
      final mockAuth = MockFirebaseAuth();
      final cleaner = _SpyCleaner();
      final repo = AuthRepositoryImpl(
        FirebaseAuthAdapter(mockAuth),
        sessionCleaner: cleaner,
      );

      expect(await repo.currentUser(), isNull);

      final created = await repo.signUp(
        email: 'new@example.com',
        password: 'password123',
      );
      expect(created.email, 'new@example.com');

      await repo.signOut();
      expect(cleaner.called, isTrue);

      final signedIn = await repo.signIn(
        email: 'new@example.com',
        password: 'password123',
      );
      expect(signedIn.email, 'new@example.com');

      final seen = <String?>[];
      final sub = repo.watchUser().listen((u) => seen.add(u?.email));
      await repo.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(seen, isNotEmpty);
      expect(seen.last, isNull);
    });

    test('password reset delegates to firebase auth mock', () async {
      final mockAuth = MockFirebaseAuth();
      final repo = AuthRepositoryImpl(FirebaseAuthAdapter(mockAuth));

      await repo.sendPasswordResetEmail(email: 'reset@example.com');
    });
  });
}

class _SpyCleaner implements AuthSessionCleaner {
  bool called = false;

  @override
  Future<void> clear() async {
    called = true;
  }
}
