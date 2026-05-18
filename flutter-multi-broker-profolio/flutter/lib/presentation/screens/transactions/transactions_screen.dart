import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/domain.dart';
import '../../../router/app_router.dart';
import '../../../state/state.dart';
import '../../widgets/widgets.dart';
import '../shared/presentation_scaffold.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _sourceId;
  TransactionType? _type;

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final connections = ref.watch(connectionsProvider).value?.connections ??
        const <Connection>[];

    return PresentationScaffold(
      selectedRoute: AppRoutes.transactions,
      title: 'Transactions',
      actions: [
        IconButton(
          tooltip: 'Export',
          icon: const Icon(Icons.download_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export started (placeholder).')),
            );
          },
        ),
      ],
      body: transactions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorBanner(
          error: error,
          onRetry: () => ref.read(transactionsProvider.notifier).refresh(),
        ),
        data: (state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        key: const Key('transactions_source_filter'),
                        initialValue: _sourceId,
                        decoration: const InputDecoration(labelText: 'Source'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All'),
                          ),
                          ...connections.map(
                            (c) => DropdownMenuItem<String?>(
                              value: c.id,
                              child: Text(c.label),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _sourceId = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<TransactionType?>(
                        key: const Key('transactions_type_filter'),
                        initialValue: _type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: [
                          const DropdownMenuItem<TransactionType?>(
                            value: null,
                            child: Text('All'),
                          ),
                          ...TransactionType.values.map(
                            (type) => DropdownMenuItem<TransactionType?>(
                              value: type,
                              child: Text(type.name),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _type = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        ref.read(transactionsProvider.notifier).applyFilters(
                              sourceId: _sourceId,
                              type: _type,
                            );
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.items.isEmpty
                    ? const EmptyState(title: 'No transactions found')
                    : ListView.builder(
                        itemCount: state.items.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.items.length) {
                            return Center(
                              child: TextButton(
                                onPressed: () {
                                  ref
                                      .read(transactionsProvider.notifier)
                                      .loadNextPage();
                                },
                                child: const Text('Load more'),
                              ),
                            );
                          }
                          final tx = state.items[index];
                          return ListTile(
                            title: Text(
                              tx.symbol.isEmpty ? tx.type.name : tx.symbol,
                            ),
                            subtitle: Text('${tx.type.name} · ${tx.sourceId}'),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                CurrencyAmount(
                                  amount: tx.cashImpact,
                                  currency: tx.currency,
                                ),
                                Text(
                                  '${tx.time.toLocal()}'.split('.').first,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
