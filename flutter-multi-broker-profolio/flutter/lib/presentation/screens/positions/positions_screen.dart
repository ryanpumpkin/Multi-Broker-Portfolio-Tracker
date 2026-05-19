import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/domain.dart';
import '../../../router/app_router.dart';
import '../../../state/quotes_provider.dart';
import '../../../state/state.dart';
import '../../widgets/widgets.dart';
import '../shared/presentation_scaffold.dart';

enum PositionSort { symbol, marketValue, unrealizedPnl }

class PositionsScreen extends ConsumerStatefulWidget {
  const PositionsScreen({super.key});

  @override
  ConsumerState<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends ConsumerState<PositionsScreen> {
  PositionSort _sort = PositionSort.marketValue;
  String? _sourceFilter;
  Position? _selected;

  @override
  Widget build(BuildContext context) {
    final portfolioAsync = ref.watch(portfolioProvider);

    return PresentationScaffold(
      selectedRoute: AppRoutes.positions,
      title: 'Positions',
      body: portfolioAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorBanner(
          error: error,
          onRetry: () => ref.read(portfolioProvider.notifier).refresh(),
        ),
        data: (snapshot) {
          final positions = _sortedAndFiltered(snapshot.positions);
          if (positions.isEmpty) {
            return const EmptyState(title: 'No positions to show');
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final list = Column(
                children: [
                  _filters(snapshot),
                  Expanded(
                    child: ListView.separated(
                      itemCount: positions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final position = positions[index];
                        return _LivePositionRow(
                          key: Key('position_${position.symbol}'),
                          position: position,
                          baseCurrency: snapshot.baseCurrency,
                          onTap: () {
                            setState(() => _selected = position);
                            if (constraints.maxWidth < 900) {
                              _showDetailSheet(context, position);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              );

              if (constraints.maxWidth < 900) {
                return list;
              }

              return Row(
                children: [
                  Expanded(flex: 3, child: list),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 2,
                    child: _selected == null
                        ? const EmptyState(
                            title: 'Select a position',
                            message: 'Tap a row to inspect details.',
                          )
                        : _detailPanel(_selected!),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _filters(PortfolioSnapshot snapshot) {
    final sourceIds = snapshot.positions.map((p) => p.sourceId).toSet().toList()
      ..sort();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<PositionSort>(
              key: const Key('positions_sort_dropdown'),
              initialValue: _sort,
              decoration: const InputDecoration(labelText: 'Sort by'),
              items: const [
                DropdownMenuItem(
                  value: PositionSort.marketValue,
                  child: Text('Market value'),
                ),
                DropdownMenuItem(
                  value: PositionSort.unrealizedPnl,
                  child: Text('Unrealized P&L'),
                ),
                DropdownMenuItem(
                  value: PositionSort.symbol,
                  child: Text('Symbol'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sort = value);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String?>(
              key: const Key('positions_source_filter'),
              initialValue: _sourceFilter,
              decoration: const InputDecoration(labelText: 'Source'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All'),
                ),
                ...sourceIds.map(
                  (id) => DropdownMenuItem<String?>(
                    value: id,
                    child: Text(id),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _sourceFilter = value),
            ),
          ),
        ],
      ),
    );
  }

  List<Position> _sortedAndFiltered(List<Position> positions) {
    var list = positions.toList(growable: false);
    if (_sourceFilter != null) {
      list = list.where((p) => p.sourceId == _sourceFilter).toList();
    }

    switch (_sort) {
      case PositionSort.symbol:
        list.sort((a, b) => a.symbol.compareTo(b.symbol));
      case PositionSort.marketValue:
        list.sort((a, b) => b.marketValue.compareTo(a.marketValue));
      case PositionSort.unrealizedPnl:
        list.sort((a, b) => b.unrealizedPnl.compareTo(a.unrealizedPnl));
    }
    return list;
  }

  Future<void> _showDetailSheet(BuildContext context, Position position) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => SizedBox(height: 260, child: _detailPanel(position)),
    );
  }

  Widget _detailPanel(Position position) {
    return Consumer(
      builder: (context, ref, _) {
        final liveQuoteAsync = ref.watch(quotesProvider(position.symbol));
        final livePrice =
            liveQuoteAsync.valueOrNull?.price ?? position.currentPrice;
        final liveMarketValue = position.quantity * livePrice;
        final livePnl = (livePrice - position.avgCost) * position.quantity;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(position.symbol, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(position.name),
              const SizedBox(height: 12),
              Text('Quantity: ${position.quantity}'),
              Text('Avg cost: ${position.avgCost} ${position.currency}'),
              Text('Current price: $livePrice ${position.currency}'),
              const SizedBox(height: 10),
              PnlBadge(
                amount: livePnl,
                currency: position.currency,
                percent: liveMarketValue == 0
                    ? 0
                    : 100 * (livePnl / liveMarketValue),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A [PositionRow] that overlays a live quote price from [quotesProvider]
/// when available, falling back to [position.currentPrice] until the stream
/// delivers its first tick.
class _LivePositionRow extends ConsumerWidget {
  const _LivePositionRow({
    required this.position,
    this.baseCurrency,
    this.onTap,
    super.key,
  });

  final Position position;
  final String? baseCurrency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveQuoteAsync = ref.watch(quotesProvider(position.symbol));
    final livePrice =
        liveQuoteAsync.valueOrNull?.price ?? position.currentPrice;

    // Recompute market value and P&L from the live price so the row reflects
    // the streaming tick rather than the last snapshot value.
    final liveMarketValue = position.quantity * livePrice;
    final livePnl = (livePrice - position.avgCost) * position.quantity;

    final livePosition = position.copyWith(
      currentPrice: livePrice,
      marketValue: liveMarketValue,
      unrealizedPnl: livePnl,
    );

    return PositionRow(
      position: livePosition,
      baseCurrency: baseCurrency,
      onTap: onTap,
    );
  }
}
