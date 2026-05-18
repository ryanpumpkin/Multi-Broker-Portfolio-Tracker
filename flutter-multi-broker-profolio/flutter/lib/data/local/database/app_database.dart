import 'package:drift/drift.dart';

import 'connection/connection.dart' as db_connection;
import 'tables.dart';

part 'app_database.g.dart';

/// Application-wide Drift database.
///
/// Schema version 1: initial release.
@DriftDatabase(
  tables: [
    PositionsCache,
    TransactionsCache,
    FxRatesCache,
    QuotesCache,
    ConnectionsMeta,
    UserPrefs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the platform-default database connection.
  factory AppDatabase.open({
    String filename = 'app.sqlite',
    String webWorkerPath = 'drift_db_worker.dart.js',
  }) {
    return AppDatabase(
      db_connection.openDatabaseConnection(
        filename: filename,
        webWorkerPath: webWorkerPath,
      ),
    );
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // No upgrades yet — first release.
        },
      );

  // ---------------- Positions --------------------------------------------

  Future<void> upsertPositions(Iterable<PositionsCacheCompanion> rows) async {
    await batch((b) {
      b.insertAll(
        positionsCache,
        rows.toList(growable: false),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<List<PositionRow>> listPositions({String? sourceId}) {
    final q = select(positionsCache);
    if (sourceId != null) {
      q.where((t) => t.sourceId.equals(sourceId));
    }
    return q.get();
  }

  Future<void> clearPositions({String? sourceId}) async {
    final d = delete(positionsCache);
    if (sourceId != null) {
      d.where((t) => t.sourceId.equals(sourceId));
    }
    await d.go();
  }

  // ---------------- Transactions -----------------------------------------

  Future<void> upsertTransactions(
    Iterable<TransactionsCacheCompanion> rows,
  ) async {
    await batch((b) {
      b.insertAll(
        transactionsCache,
        rows.toList(growable: false),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<List<TransactionRow>> listTransactions({
    String? sourceId,
    DateTime? start,
    DateTime? end,
  }) {
    final q = select(transactionsCache);
    if (sourceId != null) {
      q.where((t) => t.sourceId.equals(sourceId));
    }
    if (start != null) {
      q.where((t) => t.time.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      q.where((t) => t.time.isSmallerOrEqualValue(end));
    }
    q.orderBy([
      (t) => OrderingTerm(expression: t.time, mode: OrderingMode.desc),
    ]);
    return q.get();
  }

  // ---------------- FX rates ---------------------------------------------

  Future<void> upsertFxRate(FxRatesCacheCompanion row) =>
      into(fxRatesCache).insert(row, mode: InsertMode.insertOrReplace);

  Future<FxRateRow?> getFxRate({required String base, required String quote}) {
    return (select(fxRatesCache)
          ..where((t) => t.base.equals(base) & t.quote.equals(quote)))
        .getSingleOrNull();
  }

  // ---------------- Quotes -----------------------------------------------

  Future<void> upsertQuote(QuotesCacheCompanion row) =>
      into(quotesCache).insert(row, mode: InsertMode.insertOrReplace);

  Future<QuoteRow?> getQuote(String symbol) =>
      (select(quotesCache)..where((t) => t.symbol.equals(symbol)))
          .getSingleOrNull();

  // ---------------- Connections meta -------------------------------------

  Future<void> upsertConnection(ConnectionsMetaCompanion row) =>
      into(connectionsMeta).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> deleteConnection(String id) =>
      (delete(connectionsMeta)..where((t) => t.id.equals(id))).go();

  Future<List<ConnectionMetaRow>> listConnections() =>
      select(connectionsMeta).get();

  // ---------------- User prefs -------------------------------------------

  Future<String?> getPref(String key) async {
    final row = await (select(userPrefs)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setPref(String key, String value) => into(userPrefs).insert(
        UserPrefsCompanion.insert(key: key, value: value),
        mode: InsertMode.insertOrReplace,
      );

  Future<void> deletePref(String key) =>
      (delete(userPrefs)..where((t) => t.key.equals(key))).go();
}
