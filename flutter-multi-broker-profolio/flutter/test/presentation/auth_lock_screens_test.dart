import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_broker_portfolio/app_lock/app_lock.dart';
import 'package:multi_broker_portfolio/data/repositories/auth_repository_impl.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';
import 'package:multi_broker_portfolio/presentation/auth/password_reset_screen.dart';
import 'package:multi_broker_portfolio/presentation/auth/sign_in_screen.dart';
import 'package:multi_broker_portfolio/presentation/auth/sign_up_screen.dart';
import 'package:multi_broker_portfolio/presentation/lock/app_lock_settings_section.dart';
import 'package:multi_broker_portfolio/presentation/lock/pin_setup_screen.dart';
import 'package:multi_broker_portfolio/state/app_lock_provider.dart';
import 'package:multi_broker_portfolio/state/repository_providers.dart';

void main() {
  testWidgets('SignInScreen submits email/password', (tester) async {
    final repo = _FakeAuthRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: SignInScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('sign_in_email')),
      'u@example.com',
    );
    await tester.enterText(find.byKey(const Key('sign_in_password')), 'pw');
    await tester.tap(find.byKey(const Key('sign_in_submit')));
    await tester.pumpAndSettle();

    expect(repo.lastSignInEmail, 'u@example.com');
  });

  testWidgets('SignUpScreen submits and shows verification message',
      (tester) async {
    final repo = _FakeAuthRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: SignUpScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('sign_up_email')),
      'new@example.com',
    );
    await tester.enterText(find.byKey(const Key('sign_up_password')), 'pw');
    await tester.tap(find.byKey(const Key('sign_up_submit')));
    await tester.pumpAndSettle();

    expect(repo.lastSignUpEmail, 'new@example.com');
  });

  testWidgets('PasswordResetScreen submits reset email', (tester) async {
    final repo = _FakeAuthRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: PasswordResetScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('password_reset_email')),
      'reset@example.com',
    );
    await tester.tap(find.byKey(const Key('password_reset_submit')));
    await tester.pumpAndSettle();

    expect(repo.lastResetEmail, 'reset@example.com');
    expect(find.text('Password reset email sent.'), findsOneWidget);
  });

  testWidgets('PinSetupScreen stores pin hash in secure store abstraction',
      (tester) async {
    final store = InMemoryAppLockStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockStoreProvider.overrideWithValue(store),
          appLockBiometricAuthenticatorProvider
              .overrideWithValue(_FakeBiometricAuth()),
        ],
        child: const MaterialApp(home: PinSetupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('pin_setup_pin')), '1234');
    await tester.enterText(
      find.byKey(const Key('pin_setup_confirm_pin')),
      '1234',
    );
    await tester.tap(find.byKey(const Key('pin_setup_submit')));
    await tester.pumpAndSettle();

    expect(await store.readPinHash(), isNotNull);
    expect(find.text('PIN saved.'), findsOneWidget);
  });

  testWidgets('AppLockSettingsSection toggles enable lock', (tester) async {
    final store = InMemoryAppLockStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockStoreProvider.overrideWithValue(store),
          appLockBiometricAuthenticatorProvider
              .overrideWithValue(_FakeBiometricAuth()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AppLockSettingsSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lock_enabled_toggle')), findsOneWidget);
    await tester.tap(find.byKey(const Key('lock_enabled_toggle')));
    await tester.pumpAndSettle();

    final tile = tester.widget<SwitchListTile>(
      find.byKey(const Key('lock_enabled_toggle')),
    );
    expect(tile.value, isTrue);
  });
}

class _FakeAuthRepo
    implements
        AuthRepository,
        AuthRepositoryRecovery,
        AuthRepositorySocialSignIn {
  String? lastSignInEmail;
  String? lastSignUpEmail;
  String? lastResetEmail;
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
    lastSignInEmail = email;
    _user = AuthUser(uid: 'id-$email', email: email);
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<AuthUser> signInWithApple() =>
      signIn(email: 'apple@example.com', password: 'x');

  @override
  Future<AuthUser> signInWithGoogle() =>
      signIn(email: 'google@example.com', password: 'x');

  @override
  Future<void> signOut() async {
    _user = null;
    _ctrl.add(null);
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    lastSignUpEmail = email;
    return signIn(email: email, password: password);
  }

  @override
  Stream<AuthUser?> watchUser() async* {
    yield _user;
    yield* _ctrl.stream;
  }
}

class _FakeBiometricAuth implements BiometricAuthenticator {
  @override
  Future<bool> authenticate({required String reason}) async => true;

  @override
  Future<bool> isAvailable() async => true;
}
