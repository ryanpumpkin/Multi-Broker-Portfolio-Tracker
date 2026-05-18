import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/data/data.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('upserts and filters cached positions by source', () async {
    final now = DateTime.utc(2026, 1, 1);
    await db.upsertPositions([
      PositionsCacheCompanion.insert(
        sourceId: 'ibkr',
        symbol: 'AAPL',
        name: 'Apple',
        assetClass: 'equity',
        quantity: 1,
        avgCost: 100,
        currentPrice: 120,
        currency: 'USD',
        marketValue: 120,
        unrealizedPnl: 20,
        cachedAt: now,
      ),
      PositionsCacheCompanion.insert(
        sourceId: 'binance',
        symbol: 'BTC',
        name: 'Bitcoin',
        assetClass: 'crypto',
        quantity: 0.2,
        avgCost: 30000,
        currentPrice: 32000,
        currency: 'USD',
        marketValue: 6400,
        unrealizedPnl: 400,
        cachedAt: now,
      ),
    ]);

    final ibkrOnly = await db.listPositions(sourceId: 'ibkr');
    expect(ibkrOnly, hasLength(1));
    expect(ibkrOnly.single.symbol, 'AAPL');

    final all = await db.listPositions();
    expect(all, hasLength(2));
  });

  test('listTransactions applies source and range filters in desc order', () async {
    final t0 = DateTime.utc(2026, 1, 1, 0);
    await db.upsertTransactions([
      TransactionsCacheCompanion.insert(
        id: 't1',
        sourceId: 'ibkr',
        time: t0,
        type: 'buy',
        symbol: 'AAPL',
        quantity: 1,
        price: 100,
        currency: 'USD',
        fee: 1,
        cachedAt: t0,
      ),
      TransactionsCacheCompanion.insert(
        id: 't2',
        sourceId: 'ibkr',
        time: t0.add(const Duration(hours: 1)),
        type: 'sell',
        symbol: 'AAPL',
        quantity: 1,
        price: 120,
        currency: 'USD',
        fee: 1,
        cachedAt: t0,
      ),
      TransactionsCacheCompanion.insert(
        id: 't3',
        sourceId: 'binance',
        time: t0.add(const Duration(hours: 2)),
        type: 'buy',
        symbol: 'BTC',
        quantity: 0.1,
        price: 30000,
        currency: 'USD',
        fee: 0,
        cachedAt: t0,
      ),
    ]);

    final rows = await db.listTransactions(
      sourceId: 'ibkr',
      start: t0.add(const Duration(minutes: 30)),
      end: t0.add(const Duration(hours: 2)),
    );
    expect(rows.map((e) => e.id), ['t2']);
  });

  test('round-trips fx, quote, connection metadata and preferences', () async {
    final now = DateTime.utc(2026, 1, 1);
    await db.upsertFxRate(
      FxRatesCacheCompanion.insert(
        base: 'USD',
        quote: 'HKD',
        rate: 7.8,
        timestamp: now,
      ),
    );
    await db.upsertQuote(
      QuotesCacheCompanion.insert(
        symbol: 'AAPL',
        price: 180,
        currency: 'USD',
        timestamp: now,
      ),
    );
    await db.upsertConnection(
      ConnectionsMetaCompanion.insert(
        id: 'c1',
        kind: 'ibkr',
        label: 'IBKR',
        status: 'ok',
        credentialMode: 'e2e',
      ),
    );
    await db.setPref('baseCurrency', 'USD');

    final fx = await db.getFxRate(base: 'USD', quote: 'HKD');
    final quote = await db.getQuote('AAPL');
    final conns = await db.listConnections();
    final pref = await db.getPref('baseCurrency');

    expect(fx?.rate, 7.8);
    expect(quote?.price, 180);
    expect(conns.single.id, 'c1');
    expect(pref, 'USD');
  });
}
