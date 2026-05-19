import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/domain.dart';
import 'repository_providers.dart';

const int kDefaultTransactionsPageSize = 50;
const Duration kDefaultTransactionsWindow = Duration(days: 30);

final transactionsProvider =
    AsyncNotifierProvider<TransactionsController, PaginatedTransactionsState>(
  TransactionsController.new,
);

class PaginatedTransactionsState {
  const PaginatedTransactionsState({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.sourceId,
    required this.range,
    required this.type,
    required this.totalCount,
  });

  final List<Transaction> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final String? sourceId;
  final DateRange? range;
  final TransactionType? type;
  final int totalCount;
}

class TransactionsController extends AsyncNotifier<PaginatedTransactionsState> {
  List<Transaction> _allFiltered = const <Transaction>[];
  String? _sourceId;
  DateRange? _range = _defaultRange();
  TransactionType? _type;

  @override
  Future<PaginatedTransactionsState> build() {
    return _reload();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_reload);
  }

  Future<void> applyFilters({
    String? sourceId,
    DateRange? range,
    TransactionType? type,
  }) async {
    _sourceId = sourceId;
    _range = range ?? _range ?? _defaultRange();
    _type = type;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_reload);
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final nextPage = current.page + 1;
    state = AsyncData(_toState(page: nextPage));
  }

  Future<PaginatedTransactionsState> _reload() async {
    final txs = await ref.read(transactionsRepositoryProvider).list(
          sourceId: _sourceId,
          range: _range,
        );
    if (_type == null) {
      _allFiltered = txs;
    } else {
      _allFiltered = txs
          .where((transaction) => transaction.type == _type)
          .toList(growable: false);
    }
    return _toState(page: 1);
  }

  PaginatedTransactionsState _toState({required int page}) {
    final safePage = page < 1 ? 1 : page;
    final maxItems = safePage * kDefaultTransactionsPageSize;
    final visibleCount =
        maxItems > _allFiltered.length ? _allFiltered.length : maxItems;
    return PaginatedTransactionsState(
      items: List<Transaction>.unmodifiable(
        _allFiltered.take(visibleCount),
      ),
      page: safePage,
      pageSize: kDefaultTransactionsPageSize,
      hasMore: visibleCount < _allFiltered.length,
      sourceId: _sourceId,
      range: _range,
      type: _type,
      totalCount: _allFiltered.length,
    );
  }

  static DateRange _defaultRange({DateTime? now}) {
    final end = (now ?? DateTime.now()).toUtc();
    final start = end.subtract(kDefaultTransactionsWindow);
    return DateRange(start: start, end: end);
  }
}
