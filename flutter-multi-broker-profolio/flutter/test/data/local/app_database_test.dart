import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/data/local/database/app_database.dart';

void main() {
  group('AppDatabase', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion is 1', () {
      expect(db.schemaVersion, 1);
    });

    test('upsertPositions inserts and replaces', () async {
      await db.upsertPositions([
        PositionsCacheCompanion.insert(
          sourceId: 'lb',
          symbol: 'AAPL',
          name: 'Apple',
          assetClass: 'stock',
          quantity: 1,
          avgCost: 100,
          currentPrice: 150,
          currency: 'USD',
          marketValue: 150,
          unrealizedPnl: 50,
          cachedAt: DateTime.utc(2025, 1, 1),
        ),
      ]);
      var rows = await db.listPositions();
      expect(rows, hasLength(1));
      expect(rows.first.currentPrice, 150);

      // Replace
      await db.upsertPositions([
        PositionsCacheCompanion.insert(
          sourceId: 'lb',
          symbol: 'AAPL',
          name: 'Apple',
          assetClass: 'stock',
          quantity: 2,
          avgCost: 100,
          currentPrice: 175,
          currency: 'USD',
          marketValue: 350,
          unrealizedPnl: 150,
          cachedAt: DateTime.utc(2025, 1, 2),
        ),
      ]);
      rows = await db.listPositions();
      expect(rows, hasLength(1));
      expect(rows.first.currentPrice, 175);
    });

    test('listPositions filters by sourceId; clearPositions scopes', () async {
      Future<void> add(String src, String sym) => db.upsertPositions([
            PositionsCacheCompanion.insert(
              sourceId: src,
              symbol: sym,
              name: sym,
              assetClass: 'stock',
              quantity: 1,
              avgCost: 1,
              currentPrice: 2,
              currency: 'USD',
              marketValue: 2,
              unrealizedPnl: 1,
              cachedAt: DateTime.utc(2025),
            ),
          ]);
      await add('a', 'X');
      await add('a', 'Y');
      await add('b', 'X');
      expect((await db.listPositions(sourceId: 'a')).length, 2);
      expect((await db.listPositions(sourceId: 'b')).length, 1);

      await db.clearPositions(sourceId: 'a');
      expect((await db.listPositions(sourceId: 'a')), isEmpty);
      expect((await db.listPositions()).length, 1);
      await db.clearPositions();
      expect(await db.listPositions(), isEmpty);
    });

    test('transactions filter by source and date range', () async {
      Future<void> add(String id, DateTime t, String src) =>
          db.upsertTransactions([
            TransactionsCacheCompanion.insert(
              id: id,
              sourceId: src,
              time: t,
              type: 'buy',
              symbol: 'AAPL',
              quantity: 1,
              price: 1,
              currency: 'USD',
              fee: 0,
              cachedAt: DateTime.utc(2025),
            ),
          ]);
      await add('t1', DateTime.utc(2025, 1, 1), 'a');
      await add('t2', DateTime.utc(2025, 6, 1), 'a');
      await add('t3', DateTime.utc(2025, 12, 1), 'b');

      final all = await db.listTransactions();
      expect(all, hasLength(3));
      expect(all.first.id, 't3'); // desc order

      final aOnly = await db.listTransactions(sourceId: 'a');
      expect(aOnly, hasLength(2));

      final mid = await db.listTransactions(
        start: DateTime.utc(2025, 5, 1),
        end: DateTime.utc(2025, 7, 1),
      );
      expect(mid, hasLength(1));
      expect(mid.first.id, 't2');
    });

    test('fx rate upsert + get', () async {
      await db.upsertFxRate(
        FxRatesCacheCompanion.insert(
          base: 'USD',
          quote: 'HKD',
          rate: 7.8,
          timestamp: DateTime.utc(2025),
        ),
      );
      var row = await db.getFxRate(base: 'USD', quote: 'HKD');
      expect(row, isNotNull);
      expect(row!.rate, 7.8);

      await db.upsertFxRate(
        FxRatesCacheCompanion.insert(
          base: 'USD',
          quote: 'HKD',
          rate: 7.81,
          timestamp: DateTime.utc(2025, 2),
        ),
      );
      row = await db.getFxRate(base: 'USD', quote: 'HKD');
      expect(row!.rate, 7.81);

      expect(await db.getFxRate(base: 'X', quote: 'Y'), isNull);
    });

    test('quotes upsert + get', () async {
      expect(await db.getQuote('AAPL'), isNull);
      await db.upsertQuote(
        QuotesCacheCompanion.insert(
          symbol: 'AAPL',
          price: 100,
          currency: 'USD',
          timestamp: DateTime.utc(2025),
        ),
      );
      final q = await db.getQuote('AAPL');
      expect(q, isNotNull);
      expect(q!.price, 100);
    });

    test('connection meta CRUD', () async {
      await db.upsertConnection(
        ConnectionsMetaCompanion.insert(
          id: 'c1',
          kind: 'longbridge',
          label: 'My LB',
          status: 'ok',
          credentialMode: 'e2e',
          lastSyncAt: Value(DateTime.utc(2025)),
        ),
      );
      var rows = await db.listConnections();
      expect(rows, hasLength(1));
      await db.deleteConnection('c1');
      rows = await db.listConnections();
      expect(rows, isEmpty);
    });

    test('user prefs CRUD', () async {
      expect(await db.getPref('k'), isNull);
      await db.setPref('k', 'v1');
      expect(await db.getPref('k'), 'v1');
      await db.setPref('k', 'v2');
      expect(await db.getPref('k'), 'v2');
      await db.deletePref('k');
      expect(await db.getPref('k'), isNull);
    });
  });
}
