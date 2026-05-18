import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/data/data.dart';

void main() {
  final crypto = E2eCrypto.withKdf(pbkdf2Test(iterations: 2));

  test('derive + encrypt/decrypt roundtrip', () async {
    final key = await crypto.deriveKey(
      passphrase: 'passphrase',
      salt: E2eCrypto.generateSalt(),
    );
    final ct = await crypto.encrypt('secret', key);
    final plain = await crypto.decrypt(ct, key);
    expect(plain, 'secret');
  });

  test('wrapForBackend + unwrapFromBackend roundtrip', () async {
    final key = await crypto.deriveKey(
      passphrase: 'pw',
      salt: E2eCrypto.generateSalt(),
    );
    final token = await crypto.wrapForBackend(
      plaintextCreds: '{"apiKey":"k"}',
      key: key,
      now: DateTime.utc(2026, 1, 1),
      ttl: const Duration(minutes: 1),
    );
    final plain = await crypto.unwrapFromBackend(
      token: token,
      key: key,
      now: DateTime.utc(2026, 1, 1, 0, 0, 30),
    );
    expect(plain, '{"apiKey":"k"}');
  });

  test('unwrapFromBackend rejects expired token', () async {
    final key = await crypto.deriveKey(
      passphrase: 'pw',
      salt: E2eCrypto.generateSalt(),
    );
    final token = await crypto.wrapForBackend(
      plaintextCreds: 'x',
      key: key,
      now: DateTime.utc(2026, 1, 1),
      ttl: const Duration(seconds: 5),
    );
    expect(
      () => crypto.unwrapFromBackend(
        token: token,
        key: key,
        now: DateTime.utc(2026, 1, 1, 0, 0, 6),
      ),
      throwsFormatException,
    );
  });
}
