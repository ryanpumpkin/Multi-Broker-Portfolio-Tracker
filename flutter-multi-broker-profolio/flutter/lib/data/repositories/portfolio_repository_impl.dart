import 'dart:async';

import '../../domain/domain.dart';
import '../local/database/app_database.dart';
import '../remote/backend_client/backend_client.dart';
import '../remote/backend_client/backend_exception.dart';
import 'mappers.dart';
import 'wrapped_credentials_builder.dart';

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
    required this.connections,
    required this.wrappedCredentialsBuilder,
  });

  final AppDatabase db;
  final BackendClient backend;
  final ConnectionsRepository connections;
  final WrappedCredentialsBuilder wrappedCredentialsBuilder;

  final StreamController<PortfolioSnapshot> _ctrl =
      StreamController<PortfolioSnapshot>.broadcast();

  Future<void> dispose() async {
    await _ctrl.close();
  }

  @override
  Future<PortfolioSnapshot> getSnapshot({required String baseCurrency}) async {
    try {
      final activeConnections = await connections.list();
      final wrapped = await wrappedCredentialsBuilder.buildForConnections(
        activeConnections,
      );
      // If we have e2e connections but no usable wrapped tokens (the
      // credential key wasn't in memory yet), refuse to hit the backend
      // — otherwise it returns source_health=down for every connection,
      // overwriting whatever we had on screen. Return the cached
      // snapshot instead, leaving the UI in its last good state.
      final hasActiveE2e = activeConnections.any(
        (c) =>
            c.credentialMode == CredentialMode.e2e &&
            c.status != ConnectionStatus.disabled &&
            c.kind != ConnectionKind.manual,
      );
      if (hasActiveE2e && wrapped.tokensByConnection.isEmpty) {
        final cached = await _buildSnapshotFromCache(baseCurrency);
        // Attach the wrap errors to source_health so the UI can show
        // "PIN required" instead of a confused empty state.
        final wrapErrors = wrapped.errorsByConnection.entries
            .map(
              (e) => SourceHealth(
                sourceId: e.key,
                status: ConnectionStatus.error,
                code: 'credential_wrap_failed',
                message: e.value,
              ),
            )
            .toList(growable: false);
        return cached.copyWith(
          sourceHealth: <SourceHealth>[
            ...cached.sourceHealth,
            ...wrapErrors,
          ],
        );
      }
      final json = await backend.getPortfolioSnapshot(
        baseCurrency: baseCurrency,
        wrappedCredsByConnection: wrapped.tokensByConnection,
        wrappedCredsKeyBytes: wrapped.keyBytes,
      ) as Map<String, dynamic>;
      if (wrapped.errorsByConnection.isNotEmpty) {
        json['sourceHealth'] = <Map<String, dynamic>>[
          ..._readSourceHealth(json),
          ...wrapped.errorsByConnection.entries.map(
            (entry) => <String, dynamic>{
              'sourceId': entry.key,
              'status': 'error',
              'code': 'credential_wrap_failed',
              'message': entry.value,
            },
          ),
        ];
      }
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
  Future<PortfolioSnapshot> getCachedSnapshot({
    required String baseCurrency,
  }) {
    return _buildSnapshotFromCache(baseCurrency);
  }

  @override
  Stream<PortfolioSnapshot> watchSnapshot({
    required String baseCurrency,
  }) async* {
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

  List<Map<String, dynamic>> _readSourceHealth(Map<String, dynamic> payload) {
    final fromCamel = payload['sourceHealth'];
    final fromSnake = payload['source_health'];
    final raw = fromCamel ?? fromSnake;
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}
