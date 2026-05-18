import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/data/remote/firestore_client/in_memory_firestore_client.dart';

void main() {
  group('InMemoryFirestoreClient', () {
    late InMemoryFirestoreClient fs;
    const uid = 'u1';

    setUp(() => fs = InMemoryFirestoreClient());

    test('user settings round-trip + merge + watch', () async {
      expect(await fs.getUserSettings(uid), isNull);
      await fs.setUserSettings(uid, {'theme': 'dark'});
      expect(await fs.getUserSettings(uid), {'theme': 'dark'});

      await fs.setUserSettings(uid, {'locale': 'en'});
      expect(await fs.getUserSettings(uid), {
        'theme': 'dark',
        'locale': 'en',
      });

      final stream = fs.watchUserSettings(uid);
      final emissions = <Map<String, dynamic>?>[];
      final sub = stream.listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await fs.setUserSettings(uid, {'theme': 'light'});
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await sub.cancel();
      expect(emissions, isNotEmpty);
      expect(emissions.last!['theme'], 'light');
    });

    test('manual holdings CRUD + watch', () async {
      expect(await fs.listManualHoldings(uid), isEmpty);
      await fs.upsertManualHolding(uid, 'h1', {'label': 'House'});
      await fs.upsertManualHolding(uid, 'h2', {'label': 'Cash'});
      final list = await fs.listManualHoldings(uid);
      expect(list, hasLength(2));
      expect(list.map((e) => e['id']).toSet(), {'h1', 'h2'});
      await fs.deleteManualHolding(uid, 'h1');
      expect(await fs.listManualHoldings(uid), hasLength(1));

      final emissions = <int>[];
      final sub = fs.watchManualHoldings(uid).listen((l) => emissions.add(l.length));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await fs.upsertManualHolding(uid, 'h3', {'label': 'X'});
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await sub.cancel();
      expect(emissions.last, 2);
    });

    test('alerts CRUD + watch', () async {
      await fs.upsertAlert(uid, 'a1', {'kind': 'priceAbove'});
      expect(await fs.listAlerts(uid), hasLength(1));
      await fs.deleteAlert(uid, 'a1');
      expect(await fs.listAlerts(uid), isEmpty);
      final sub = fs.watchAlerts(uid).listen((_) {});
      await sub.cancel();
    });

    test('connections + encrypted blobs', () async {
      await fs.upsertConnection(uid, 'c1', {'kind': 'longbridge'});
      expect(await fs.listConnections(uid), hasLength(1));
      await fs.setEncryptedCredential(uid, 'c1', 'BLOB');
      expect(await fs.getEncryptedCredential(uid, 'c1'), 'BLOB');
      await fs.deleteConnection(uid, 'c1');
      expect(await fs.listConnections(uid), isEmpty);
      expect(await fs.getEncryptedCredential(uid, 'c1'), isNull);
      final sub = fs.watchConnections(uid).listen((_) {});
      await sub.cancel();
    });

    test('deleting from empty collection is a no-op', () async {
      await fs.deleteManualHolding(uid, 'missing');
      await fs.deleteAlert(uid, 'missing');
      await fs.deleteConnection(uid, 'missing');
    });
  });
}
