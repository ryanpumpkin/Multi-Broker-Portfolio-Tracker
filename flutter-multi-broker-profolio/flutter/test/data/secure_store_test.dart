import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/data/data.dart';

void main() {
  test('typed secure-store accessors for pin, salt, and credentials', () async {
    final store = SecureStore(InMemoryKeyValueStore());

    await store.setPinHash('hash-1');
    expect(await store.getPinHash(), 'hash-1');
    await store.clearPinHash();
    expect(await store.getPinHash(), isNull);

    await store.setE2eSalt('salt-b64');
    expect(await store.getE2eSalt(), 'salt-b64');

    await store.setEncryptedCredential('conn-1', 'blob-1');
    await store.setEncryptedCredential('conn-2', 'blob-2');
    expect(await store.getEncryptedCredential('conn-1'), 'blob-1');
    expect(
      (await store.listCredentialConnectionIds())..sort(),
      ['conn-1', 'conn-2'],
    );

    await store.deleteEncryptedCredential('conn-1');
    expect(await store.getEncryptedCredential('conn-1'), isNull);

    await store.wipe();
    expect(await store.getE2eSalt(), isNull);
    expect(await store.listCredentialConnectionIds(), isEmpty);
  });

  test('fallback key-value store is used when primary throws', () async {
    final kv = FallbackKeyValueStore(primary: _ThrowingStore());
    final store = SecureStore(kv);

    await store.setPinHash('fallback-hash');
    expect(await store.getPinHash(), 'fallback-hash');
  });
}

class _ThrowingStore implements KeyValueStore {
  @override
  Future<void> delete(String key) async => throw StateError('primary failed');

  @override
  Future<void> deleteAll() async => throw StateError('primary failed');

  @override
  Future<String?> read(String key) async => throw StateError('primary failed');

  @override
  Future<Map<String, String>> readAll() async =>
      throw StateError('primary failed');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('primary failed');
}
