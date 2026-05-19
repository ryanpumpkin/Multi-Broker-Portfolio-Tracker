import '../../domain/domain.dart';
import '../local/database/app_database.dart';
import '../remote/backend_client/backend_client.dart';
import '../remote/backend_client/backend_exception.dart';
import 'mappers.dart';
import 'wrapped_credentials_builder.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  TransactionsRepositoryImpl({
    required this.db,
    required this.backend,
    required this.connections,
    required this.wrappedCredentialsBuilder,
  });

  final AppDatabase db;
  final BackendClient backend;
  final ConnectionsRepository connections;
  final WrappedCredentialsBuilder wrappedCredentialsBuilder;

  @override
  Future<List<Transaction>> list({String? sourceId, DateRange? range}) async {
    try {
      final activeConnections = await connections.list();
      final wrapped = await wrappedCredentialsBuilder.buildForConnections(
        activeConnections,
      );
      final raw = await backend.getTransactions(
        sourceId: sourceId,
        start: range?.start,
        wrappedCredsByConnection: wrapped.tokensByConnection,
        wrappedCredsKeyBytes: wrapped.keyBytes,
      );
      // Backend wraps fan-out results in a PartialResult envelope:
      // {items: [...], source_health: [...]}.
      final items = raw is Map<String, dynamic>
          ? (raw['items'] as List? ?? const <dynamic>[])
          : (raw as List? ?? const <dynamic>[]);
      final list = items
          .whereType<Map<String, dynamic>>()
          .map(Mappers.transactionFromJson)
          .toList(growable: false);
      await _cache(list);
      return list;
    } on BackendException {
      // Fallback: serve from cache.
      final rows = await db.listTransactions(
        sourceId: sourceId,
        start: range?.start,
        end: range?.end,
      );
      return rows.map(_rowToTransaction).toList(growable: false);
    }
  }

  Future<void> _cache(List<Transaction> txs) async {
    final now = DateTime.now().toUtc();
    await db.upsertTransactions(
      txs.map(
        (t) => TransactionsCacheCompanion.insert(
          id: t.id,
          sourceId: t.sourceId,
          time: t.time,
          type: t.type.name,
          symbol: t.symbol,
          quantity: t.quantity,
          price: t.price,
          currency: t.currency,
          fee: t.fee,
          cachedAt: now,
        ),
      ),
    );
  }

  Transaction _rowToTransaction(TransactionRow r) => Transaction(
        id: r.id,
        sourceId: r.sourceId,
        time: r.time,
        type: TransactionType.values.firstWhere(
          (t) => t.name == r.type,
          orElse: () => TransactionType.buy,
        ),
        symbol: r.symbol,
        quantity: r.quantity,
        price: r.price,
        currency: r.currency,
        fee: r.fee,
      );
}
