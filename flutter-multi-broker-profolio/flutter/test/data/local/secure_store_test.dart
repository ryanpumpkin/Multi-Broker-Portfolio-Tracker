import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/data/local/secure_storage/secure_store.dart';

void main() {
  group('SecureStore', () {
    late InMemoryKeyValueStore kv;
    late SecureStore store;

    setUp(() {
      kv = InMemoryKeyValueStore();
      store = SecureStore(kv);
    });

    test('round-trips PIN hash', () async {
      expect(await store.getPinHash(), isNull);
      await store.setPinHash('hashed');
      expect(await store.getPinHash(), 'hashed');
      await store.clearPinHash();
      expect(await store.getPinHash(), isNull);
    });

    test('round-trips E2E salt', () async {
      expect(await store.getE2eSalt(), isNull);
      await store.setE2eSalt('AAAA');
      expect(await store.getE2eSalt(), 'AAAA');
    });

    test('per-connection credential blobs are namespaced', () async {
      await store.setEncryptedCredential('a', 'blob_a');
      await store.setEncryptedCredential('b', 'blob_b');
      expect(await store.getEncryptedCredential('a'), 'blob_a');
      expect(await store.getEncryptedCredential('b'), 'blob_b');
      expect(
        (await store.listCredentialConnectionIds()).toSet(),
        {'a', 'b'},
      );
      await store.deleteEncryptedCredential('a');
      expect(await store.getEncryptedCredential('a'), isNull);
      expect(
        (await store.listCredentialConnectionIds()).toSet(),
        {'b'},
      );
    });

    test('wipe clears all entries', () async {
      await store.setPinHash('h');
      await store.setE2eSalt('s');
      await store.setEncryptedCredential('x', 'b');
      await store.wipe();
      expect(await store.getPinHash(), isNull);
      expect(await store.getE2eSalt(), isNull);
      expect(await store.getEncryptedCredential('x'), isNull);
    });

    test('InMemoryKeyValueStore CRUD', () async {
      await kv.write('k', 'v');
      expect(await kv.read('k'), 'v');
      expect((await kv.readAll())['k'], 'v');
      await kv.delete('k');
      expect(await kv.read('k'), isNull);
      await kv.write('a', '1');
      await kv.deleteAll();
      expect(await kv.read('a'), isNull);
    });

    test('FallbackKeyValueStore uses fallback when primary throws', () async {
      final failing = _FailingStore();
      final fallback = InMemoryKeyValueStore();
      final resilient = FallbackKeyValueStore(
        primary: failing,
        fallback: fallback,
      );
      await resilient.write('k', 'v');
      expect(await resilient.read('k'), 'v');
      expect((await resilient.readAll())['k'], 'v');
      await resilient.delete('k');
      expect(await resilient.read('k'), isNull);
    });
  });
}

class _FailingStore implements KeyValueStore {
  @override
  Future<void> delete(String key) async => throw StateError('nope');

  @override
  Future<void> deleteAll() async => throw StateError('nope');

  @override
  Future<String?> read(String key) async => throw StateError('nope');

  @override
  Future<Map<String, String>> readAll() async => throw StateError('nope');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('nope');
}
