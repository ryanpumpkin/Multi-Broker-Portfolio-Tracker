import 'dart:async';

import '../../domain/domain.dart';
import '../local/database/app_database.dart';
import '../remote/backend_client/backend_client.dart';
import '../remote/backend_client/backend_exception.dart';
import 'mappers.dart';

/// Repository implementation for the aggregated portfolio snapshot.
///
/// Strategy (detailed-design §3.4):
/// - cache-first read: returns the latest snapshot built from Drift while
///   kicking off a network refresh.
/// - on refresh, writes new positions into Drift (server-wins).
/// - [watchSnapshot] re-emits whenever a successful refresh lands.
class PortfolioRepositoryImpl implements PortfolioRepository {
  PortfolioRepositoryImpl({
    required this.db,
    required this.backend,
  });

  final AppDatabase db;
  final BackendClient backend;

  final StreamController<PortfolioSnapshot> _ctrl =
      StreamController<PortfolioSnapshot>.broadcast();

  Future<void> dispose() async {
    await _ctrl.close();
  }

  @override
  Future<PortfolioSnapshot> getSnapshot({required String baseCurrency}) async {
    try {
      final json = await backend.getPortfolioSnapshot(baseCurrency: baseCurrency)
          as Map<String, dynamic>;
      final snap = Mappers.snapshotFromJson(json);
      await _cachePositions(snap);
      _ctrl.add(snap);
      return snap;
    } on BackendException {
      // Fall back to cached positions; construct a partial snapshot.
      return _buildSnapshotFromCache(baseCurrency);
    }
  }

  @override
  Stream<PortfolioSnapshot> watchSnapshot({required String baseCurrency}) async* {
    // Emit cached value first for instant UI.
    yield await _buildSnapshotFromCache(baseCurrency);
    // Fire-and-forget refresh.
    unawaited(
      getSnapshot(baseCurrency: baseCurrency).catchError(
        (Object _) => _buildSnapshotFromCache(baseCurrency),
      ),
    );
    yield* _ctrl.stream.where((s) => s.baseCurrency == baseCurrency);
  }

  Future<void> _cachePositions(PortfolioSnapshot s) async {
    final rows = s.positions.map(
      (p) => PositionsCacheCompanion.insert(
        sourceId: p.sourceId,
        symbol: p.symbol,
        name: p.name,
        assetClass: p.assetClass.name,
        quantity: p.quantity,
        avgCost: p.avgCost,
        currentPrice: p.currentPrice,
        currency: p.currency,
        marketValue: p.marketValue,
        unrealizedPnl: p.unrealizedPnl,
        cachedAt: DateTime.now().toUtc(),
      ),
    );
    await db.upsertPositions(rows);
  }

  Future<PortfolioSnapshot> _buildSnapshotFromCache(String baseCurrency) async {
    final rows = await db.listPositions();
    final positions = rows
        .map(
          (r) => Position(
            sourceId: r.sourceId,
            symbol: r.symbol,
            name: r.name,
            assetClass: Mappers.assetClassFromString(r.assetClass),
            quantity: r.quantity,
            avgCost: r.avgCost,
            currentPrice: r.currentPrice,
            currency: r.currency,
            marketValue: r.marketValue,
            unrealizedPnl: r.unrealizedPnl,
          ),
        )
        .toList(growable: false);

    final totalsByCurrency = <String, double>{};
    final totalsBySource = <String, double>{};
    double total = 0.0;
    double pnl = 0.0;
    for (final p in positions) {
      totalsByCurrency.update(
        p.currency,
        (v) => v + p.marketValue,
        ifAbsent: () => p.marketValue,
      );
      totalsBySource.update(
        p.sourceId,
        (v) => v + p.marketValue,
        ifAbsent: () => p.marketValue,
      );
      total += p.marketValue;
      pnl += p.unrealizedPnl;
    }
    return PortfolioSnapshot(
      asOf: DateTime.now().toUtc(),
      baseCurrency: baseCurrency,
      positions: positions,
      cashBalances: const [],
      totalsBySource: totalsBySource,
      totalsByCurrency: totalsByCurrency,
      totalBaseValue: total,
      totalUnrealizedPnlBase: pnl,
    );
  }
}
