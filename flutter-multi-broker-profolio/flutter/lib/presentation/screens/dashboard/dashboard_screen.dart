import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';
import '../../../state/state.dart';
import '../../widgets/widgets.dart';
import '../shared/presentation_scaffold.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    final connections = ref.watch(connectionsProvider);

    return PresentationScaffold(
      selectedRoute: AppRoutes.dashboard,
      title: 'Dashboard',
      actions: [
        IconButton(
          key: const Key('dashboard_refresh_button'),
          tooltip: 'Refresh',
          icon: portfolio.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          onPressed: portfolio.isLoading
              ? null
              : () => ref.read(portfolioProvider.notifier).refresh(),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () => ref.read(portfolioProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (portfolio.hasError)
              ErrorBanner(
                error: portfolio.error!,
                onRetry: () => ref.read(portfolioProvider.notifier).refresh(),
              ),
            if (portfolio.isLoading) ...[
              const LoadingShimmer(height: 110),
              const SizedBox(height: 12),
              const LoadingShimmer(height: 110),
            ] else if (portfolio.value case final data?) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total portfolio value'),
                      const SizedBox(height: 4),
                      CurrencyAmount(
                        key: const Key('dashboard_total_value'),
                        amount: data.totalBaseValue,
                        currency: data.baseCurrency,
                        baseCurrency: data.baseCurrency,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      PnlBadge(
                        key: const Key('dashboard_total_pnl'),
                        amount: data.totalUnrealizedPnlBase,
                        currency: data.baseCurrency,
                        percent: data.totalBaseValue == 0
                            ? 0
                            : 100 *
                                (data.totalUnrealizedPnlBase /
                                    data.totalBaseValue),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AllocationDonut(
                allocations: _toPercentages(data.totalsByCurrency),
              ),
            ] else
              const EmptyState(title: 'No portfolio data yet'),
            const SizedBox(height: 14),
            Text(
              'Sources',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (connections.value case final state?)
              ...state.connections.map((c) => SourceTile(connection: c))
            else
              const EmptyState(title: 'No connections configured'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Open positions'),
                  onPressed: () => context.go(AppRoutes.positions),
                ),
                ActionChip(
                  label: const Text('View charts'),
                  onPressed: () => context.go(AppRoutes.charts),
                ),
                ActionChip(
                  label: const Text('Manage alerts'),
                  onPressed: () => context.go(AppRoutes.alerts),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _toPercentages(Map<String, double> map) {
    if (map.isEmpty) {
      return const {'N/A': 100};
    }
    final total = map.values.fold<double>(0, (a, b) => a + b);
    if (total == 0) {
      return map.map((k, v) => MapEntry(k, 0));
    }
    return map.map((key, value) => MapEntry(key, 100 * value / total));
  }
}
