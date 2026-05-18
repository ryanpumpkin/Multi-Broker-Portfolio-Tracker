import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_broker_portfolio/app_lock/app_lock.dart';
import 'package:multi_broker_portfolio/state/app_lock_provider.dart';

void main() {
  testWidgets('blocks interaction while locked and unlocks with pin',
      (tester) async {
    final store = InMemoryAppLockStore();
    const pinHasher = Sha256PinHasher();
    final pinHash = await pinHasher.hash('1234');
    await store.writePinHash(pinHash);
    await store.writeSettings(
      const AppLockSettings(
        enabled: true,
        biometricEnabled: false,
        timeout: Duration(seconds: 30),
      ),
    );

    var taps = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockStoreProvider.overrideWithValue(store),
          appLockBiometricAuthenticatorProvider
              .overrideWithValue(_FakeBiometricAuth(false)),
        ],
        child: MaterialApp(
          home: AppLockGate(
            child: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => taps++,
                  child: const Text('Tap me'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('App locked'), findsOneWidget);

    await tester.tap(find.text('Tap me'));
    await tester.pump();
    expect(taps, 0);

    await tester.enterText(find.byKey(const Key('app_lock_pin_field')), '1234');
    await tester.tap(find.byKey(const Key('unlock_with_pin_button')));
    await tester.pumpAndSettle();

    expect(find.text('App locked'), findsNothing);

    await tester.tap(find.text('Tap me'));
    await tester.pump();
    expect(taps, 1);
  });
}

class _FakeBiometricAuth implements BiometricAuthenticator {
  _FakeBiometricAuth(this._result);

  final bool _result;

  @override
  Future<bool> authenticate({required String reason}) async => _result;

  @override
  Future<bool> isAvailable() async => true;
}
