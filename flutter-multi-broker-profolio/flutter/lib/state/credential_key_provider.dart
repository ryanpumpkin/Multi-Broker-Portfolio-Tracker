import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/crypto/e2e.dart';
import 'app_lock_provider.dart';

/// Holds the AES-GCM key used to encrypt broker credentials, derived from
/// the user's PIN + a per-user salt via Argon2id.
///
/// The key lives only in memory while the app is unlocked. Locking the app
/// (or restarting) clears it; the user re-enters their PIN to derive it
/// again. The PIN itself is never stored — only its SHA-256 hash for
/// unlock comparison.
final credentialKeyProvider =
    NotifierProvider<CredentialKeyController, E2eKey?>(
  CredentialKeyController.new,
);

class CredentialKeyController extends Notifier<E2eKey?> {
  @override
  E2eKey? build() {
    // Clear the key whenever the lock state flips back to locked.
    ref.listen(appLockProvider, (previous, next) {
      final wasUnlocked = previous?.valueOrNull?.isLocked == false;
      final nowLocked = next.valueOrNull?.isLocked == true;
      if (wasUnlocked && nowLocked) {
        state = null;
      }
    });
    return null;
  }

  /// Derive and cache the key from [pin]. Called by the unlock flow after
  /// the PIN has been verified against the stored hash. Generates a fresh
  /// salt on first use and persists it.
  Future<void> deriveAndCache(String pin, {E2eCrypto? cryptoForTest}) async {
    final store = ref.read(appLockStoreProvider);
    final crypto = cryptoForTest ?? E2eCrypto.production();

    var saltB64 = await store.readSalt();
    if (saltB64 == null) {
      final rng = Random.secure();
      final saltBytes =
          List<int>.generate(16, (_) => rng.nextInt(256), growable: false);
      saltB64 = base64Url.encode(saltBytes);
      await store.writeSalt(saltB64);
    }

    final salt = base64Url.decode(saltB64);
    final key = await crypto.deriveKey(passphrase: pin, salt: salt);
    state = key;
  }

  /// Manually clear the cached key (e.g. on sign-out).
  void clear() {
    state = null;
  }
}
