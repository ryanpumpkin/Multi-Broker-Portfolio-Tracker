import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/data/remote/firestore_client/in_memory_firestore_client.dart';

void main() {
  test('in-memory firestore persists device tokens per user', () async {
    final firestore = InMemoryFirestoreClient();

    await firestore.upsertDeviceToken(
      'u1',
      'token-1',
      platform: 'ios',
      appVersion: '1.0.0',
    );
    await firestore.upsertDeviceToken(
      'u1',
      'token-2',
      platform: 'android',
      appVersion: '1.0.0',
    );

    final beforeDelete = await firestore.listDeviceTokens('u1');
    expect(
      beforeDelete.map((item) => item['id']),
      containsAll(['token-1', 'token-2']),
    );

    await firestore.deleteDeviceToken('u1', 'token-1');

    final afterDelete = await firestore.listDeviceTokens('u1');
    expect(afterDelete.map((item) => item['id']), ['token-2']);
  });
}
