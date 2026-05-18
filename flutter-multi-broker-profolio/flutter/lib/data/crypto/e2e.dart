/// End-to-end credential crypto: Argon2id KDF + AES-GCM.
///
/// Pure-Dart (works on web, mobile, desktop). The user passphrase is never
/// stored; only a per-user random salt is persisted in secure storage. The
/// derived master key encrypts per-connection credential blobs that are
/// then safe to store in Firestore.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// A symmetric key derived from a passphrase + salt.
///
/// Wraps the raw bytes; callers should not need to look inside.
class E2eKey {
  const E2eKey(this.bytes);

  /// Raw key bytes (32 bytes for AES-256).
  final List<int> bytes;

  /// Length in bytes.
  int get length => bytes.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is E2eKey &&
          runtimeType == other.runtimeType &&
          _constTimeEquals(bytes, other.bytes);

  @override
  int get hashCode => Object.hashAll(bytes);
}

/// AES-GCM ciphertext envelope.
///
/// Stored as a compact base64-encoded JSON string by [Ciphertext.toEncoded].
class Ciphertext {
  const Ciphertext({
    required this.nonce,
    required this.cipherBytes,
    required this.mac,
  });

  /// Parses a string produced by [toEncoded].
  factory Ciphertext.fromEncoded(String encoded) {
    final raw = utf8.decode(base64Decode(encoded));
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return Ciphertext(
      nonce: base64Decode(m['n']! as String),
      cipherBytes: base64Decode(m['c']! as String),
      mac: base64Decode(m['m']! as String),
    );
  }

  final List<int> nonce;
  final List<int> cipherBytes;
  final List<int> mac;

  /// Serialises as a single base64 string suitable for Firestore.
  String toEncoded() {
    final json = jsonEncode(<String, String>{
      'n': base64Encode(nonce),
      'c': base64Encode(cipherBytes),
      'm': base64Encode(mac),
    });
    return base64Encode(utf8.encode(json));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ciphertext &&
          runtimeType == other.runtimeType &&
          _listEq(nonce, other.nonce) &&
          _listEq(cipherBytes, other.cipherBytes) &&
          _listEq(mac, other.mac);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(nonce),
        Object.hashAll(cipherBytes),
        Object.hashAll(mac),
      );
}

/// End-to-end crypto primitives.
///
/// Construct with [E2eCrypto.production] for the real Argon2id KDF or
/// [E2eCrypto.withKdf] in tests to inject a faster KDF.
class E2eCrypto {
  /// Production constructor: Argon2id with sane defaults.
  ///
  /// - memory: 19 MiB · iterations: 2 · parallelism: 1 · 32-byte key
  ///
  /// Parameters chosen per OWASP 2023 guidance; trade-off between mobile
  /// CPU constraints and resistance to GPU attacks.
  E2eCrypto.production()
      : _kdf = Argon2id(
          memory: 19 * 1024,
          parallelism: 1,
          iterations: 2,
          hashLength: 32,
        ),
        _aes = AesGcm.with256bits();

  /// Test constructor — accepts any [KdfAlgorithm] for fast unit tests
  /// (e.g. PBKDF2 with low iterations).
  E2eCrypto.withKdf(KdfAlgorithm kdf)
      : _kdf = kdf,
        _aes = AesGcm.with256bits();

  final KdfAlgorithm _kdf;
  final AesGcm _aes;

  /// Generates a fresh 16-byte random salt suitable for [deriveKey].
  static List<int> generateSalt({int length = 16}) {
    if (length <= 0) {
      throw ArgumentError.value(length, 'length', 'must be > 0');
    }
    final rng = Random.secure();
    return List<int>.generate(length, (_) => rng.nextInt(256), growable: false);
  }

  /// Derives a 32-byte master key from [passphrase] and [salt].
  Future<E2eKey> deriveKey({
    required String passphrase,
    required List<int> salt,
  }) async {
    if (passphrase.isEmpty) {
      throw ArgumentError.value(passphrase, 'passphrase', 'must not be empty');
    }
    if (salt.isEmpty) {
      throw ArgumentError.value(salt, 'salt', 'must not be empty');
    }
    final secret = SecretKey(utf8.encode(passphrase));
    final derived = await _kdf.deriveKey(secretKey: secret, nonce: salt);
    final bytes = await derived.extractBytes();
    return E2eKey(bytes);
  }

  /// Encrypts UTF-8 [plaintext] with AES-GCM. A fresh 12-byte nonce is
  /// generated for every call.
  Future<Ciphertext> encrypt(String plaintext, E2eKey key) async {
    return encryptBytes(utf8.encode(plaintext), key);
  }

  /// Encrypts raw bytes.
  Future<Ciphertext> encryptBytes(List<int> plaintext, E2eKey key) async {
    final nonce = _aes.newNonce();
    final secretKey = SecretKey(key.bytes);
    final box = await _aes.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );
    return Ciphertext(
      nonce: box.nonce,
      cipherBytes: box.cipherText,
      mac: box.mac.bytes,
    );
  }

  /// Decrypts and returns the UTF-8 plaintext. Throws if the MAC fails.
  Future<String> decrypt(Ciphertext ct, E2eKey key) async {
    final bytes = await decryptBytes(ct, key);
    return utf8.decode(bytes);
  }

  /// Decrypts and returns raw bytes.
  Future<List<int>> decryptBytes(Ciphertext ct, E2eKey key) async {
    final secretKey = SecretKey(key.bytes);
    final box = SecretBox(
      ct.cipherBytes,
      nonce: ct.nonce,
      mac: Mac(ct.mac),
    );
    return _aes.decrypt(box, secretKey: secretKey);
  }

  /// Produces a short-lived wrapper for the backend in E2E mode.
  ///
  /// The wire format is a base64-encoded JSON payload containing the
  /// freshly re-encrypted credential blob plus a millisecond `expiresAt`.
  /// The backend uses it once and drops it; see detailed-design §4.6.
  Future<String> wrapForBackend({
    required String plaintextCreds,
    required E2eKey key,
    Duration ttl = const Duration(minutes: 2),
    DateTime? now,
  }) async {
    final ct = await encrypt(plaintextCreds, key);
    final exp = (now ?? DateTime.now().toUtc()).add(ttl);
    final payload = <String, dynamic>{
      'v': 1,
      'expiresAt': exp.toUtc().millisecondsSinceEpoch,
      'ct': ct.toEncoded(),
    };
    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  /// Inverse of [wrapForBackend]; throws [FormatException] if the token is
  /// expired or malformed.
  Future<String> unwrapFromBackend({
    required String token,
    required E2eKey key,
    DateTime? now,
  }) async {
    Map<String, dynamic> payload;
    try {
      payload =
          jsonDecode(utf8.decode(base64Decode(token))) as Map<String, dynamic>;
    } on FormatException {
      rethrow;
    } catch (e) {
      throw const FormatException('Malformed wrap token');
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      payload['expiresAt']! as int,
      isUtc: true,
    );
    final at = now ?? DateTime.now().toUtc();
    if (at.isAfter(expiresAt)) {
      throw const FormatException('Expired wrap token');
    }
    final ct = Ciphertext.fromEncoded(payload['ct']! as String);
    return decrypt(ct, key);
  }
}

bool _constTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

bool _listEq(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Re-export for callers that want to construct test KDFs without
/// depending on `package:cryptography` directly.
typedef Kdf = KdfAlgorithm;

/// Convenience factory: PBKDF2-HMAC-SHA256 with the given iteration count.
/// Useful in unit tests as a faster substitute for Argon2id.
KdfAlgorithm pbkdf2Test({int iterations = 1000, int bits = 256}) {
  return Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: bits,
  );
}

/// Convenience: build a key directly from raw bytes (testing/dev only).
Uint8List rawKeyBytes(E2eKey k) => Uint8List.fromList(k.bytes);
