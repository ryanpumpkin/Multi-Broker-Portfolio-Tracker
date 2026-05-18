import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/data/crypto/e2e.dart';

void main() {
  group('E2eCrypto', () {
    // Use PBKDF2 with low iterations for fast tests.
    final crypto = E2eCrypto.withKdf(pbkdf2Test(iterations: 100));

    test('deriveKey is deterministic for same passphrase+salt', () async {
      final salt = E2eCrypto.generateSalt();
      final k1 = await crypto.deriveKey(passphrase: 'hunter2', salt: salt);
      final k2 = await crypto.deriveKey(passphrase: 'hunter2', salt: salt);
      expect(k1, equals(k2));
      expect(k1.length, 32);
    });

    test('deriveKey differs by passphrase', () async {
      final salt = E2eCrypto.generateSalt();
      final k1 = await crypto.deriveKey(passphrase: 'a', salt: salt);
      final k2 = await crypto.deriveKey(passphrase: 'b', salt: salt);
      expect(k1, isNot(equals(k2)));
    });

    test('deriveKey differs by salt', () async {
      final k1 = await crypto.deriveKey(
        passphrase: 'x',
        salt: E2eCrypto.generateSalt(),
      );
      final k2 = await crypto.deriveKey(
        passphrase: 'x',
        salt: E2eCrypto.generateSalt(),
      );
      expect(k1, isNot(equals(k2)));
    });

    test('encrypt/decrypt round-trips arbitrary UTF-8 strings', () async {
      final key = await crypto.deriveKey(
        passphrase: 'p',
        salt: E2eCrypto.generateSalt(),
      );
      for (final s in [
        'hello world',
        '',
        'unicode: 你好 ✓',
        '{"json": true, "n": 42}',
      ]) {
        final ct = await crypto.encrypt(s, key);
        final back = await crypto.decrypt(ct, key);
        expect(back, s);
      }
    });

    test('encrypt uses a fresh nonce on every call', () async {
      final key = await crypto.deriveKey(
        passphrase: 'p',
        salt: E2eCrypto.generateSalt(),
      );
      final a = await crypto.encrypt('same', key);
      final b = await crypto.encrypt('same', key);
      expect(a.nonce, isNot(equals(b.nonce)));
      expect(a.cipherBytes, isNot(equals(b.cipherBytes)));
    });

    test('decrypt with wrong key throws', () async {
      final salt = E2eCrypto.generateSalt();
      final k1 = await crypto.deriveKey(passphrase: 'a', salt: salt);
      final k2 = await crypto.deriveKey(passphrase: 'b', salt: salt);
      final ct = await crypto.encrypt('secret', k1);
      expect(() async => crypto.decrypt(ct, k2), throwsA(isA<Object>()));
    });

    test('Ciphertext serialises round-trip via toEncoded', () async {
      final key = await crypto.deriveKey(
        passphrase: 'p',
        salt: E2eCrypto.generateSalt(),
      );
      final ct = await crypto.encrypt('payload', key);
      final encoded = ct.toEncoded();
      expect(encoded, isA<String>());
      final parsed = Ciphertext.fromEncoded(encoded);
      expect(parsed, equals(ct));
      final back = await crypto.decrypt(parsed, key);
      expect(back, 'payload');
    });

    test('empty passphrase or salt is rejected', () async {
      expect(
        () async =>
            crypto.deriveKey(passphrase: '', salt: E2eCrypto.generateSalt()),
        throwsArgumentError,
      );
      expect(
        () async => crypto.deriveKey(passphrase: 'x', salt: const <int>[]),
        throwsArgumentError,
      );
    });

    test('wrapForBackend round-trips and embeds expiry', () async {
      final key = await crypto.deriveKey(
        passphrase: 'p',
        salt: E2eCrypto.generateSalt(),
      );
      final now = DateTime.utc(2025, 1, 1, 12, 0);
      final token = await crypto.wrapForBackend(
        plaintextCreds: 'secret-creds',
        key: key,
        now: now,
        ttl: const Duration(minutes: 5),
      );
      // Token is base64-decodable JSON
      final j =
          jsonDecode(utf8.decode(base64Decode(token))) as Map<String, dynamic>;
      expect(j['v'], 1);
      expect(j['expiresAt'], isA<int>());

      final back = await crypto.unwrapFromBackend(
        token: token,
        key: key,
        now: now.add(const Duration(seconds: 1)),
      );
      expect(back, 'secret-creds');
    });

    test('unwrapFromBackend rejects expired tokens', () async {
      final key = await crypto.deriveKey(
        passphrase: 'p',
        salt: E2eCrypto.generateSalt(),
      );
      final now = DateTime.utc(2025, 1, 1, 12, 0);
      final token = await crypto.wrapForBackend(
        plaintextCreds: 'x',
        key: key,
        now: now,
        ttl: const Duration(seconds: 1),
      );
      expect(
        () async => crypto.unwrapFromBackend(
          token: token,
          key: key,
          now: now.add(const Duration(seconds: 5)),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('unwrapFromBackend rejects malformed tokens', () async {
      final key = await crypto.deriveKey(
        passphrase: 'p',
        salt: E2eCrypto.generateSalt(),
      );
      expect(
        () async => crypto.unwrapFromBackend(token: 'not-base64!', key: key),
        throwsA(isA<FormatException>()),
      );
    });

    test('generateSalt produces a non-empty unique salt', () {
      final a = E2eCrypto.generateSalt();
      final b = E2eCrypto.generateSalt();
      expect(a.length, 16);
      expect(b.length, 16);
      expect(a, isNot(equals(b)));
    });

    test(
      'production constructor builds usable Argon2id KDF',
      () async {
        // Smoke only: don't run the expensive 19MiB Argon2id in unit tests
        // beyond a single small round-trip.
        final prod = E2eCrypto.production();
        final salt = E2eCrypto.generateSalt();
        final key = await prod.deriveKey(passphrase: 'x', salt: salt);
        final ct = await prod.encrypt('msg', key);
        expect(await prod.decrypt(ct, key), 'msg');
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    test('encryptBytes/decryptBytes round-trip raw bytes', () async {
      final key = await crypto.deriveKey(
        passphrase: 'p',
        salt: E2eCrypto.generateSalt(),
      );
      final bytes = List<int>.generate(64, (i) => i % 256);
      final ct = await crypto.encryptBytes(bytes, key);
      final back = await crypto.decryptBytes(ct, key);
      expect(back, bytes);
    });

    test('E2eKey equality and hashCode are content-based', () {
      final a = E2eKey(List<int>.filled(32, 1));
      final b = E2eKey(List<int>.filled(32, 1));
      final c = E2eKey(List<int>.filled(32, 2));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(rawKeyBytes(a), hasLength(32));
    });

    test('Ciphertext equality and hashCode are content-based', () {
      const ct = Ciphertext(
        nonce: <int>[1, 2, 3],
        cipherBytes: <int>[4, 5, 6],
        mac: <int>[7, 8, 9],
      );
      const ct2 = Ciphertext(
        nonce: <int>[1, 2, 3],
        cipherBytes: <int>[4, 5, 6],
        mac: <int>[7, 8, 9],
      );
      expect(ct, equals(ct2));
      expect(ct.hashCode, equals(ct2.hashCode));
    });
  });
}
