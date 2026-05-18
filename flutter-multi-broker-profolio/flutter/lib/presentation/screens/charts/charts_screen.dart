import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/app_router.dart';
import '../../../state/state.dart';
import '../../widgets/widgets.dart';
import '../shared/presentation_scaffold.dart';

class ChartsScreen extends ConsumerWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);

    return PresentationScaffold(
      selectedRoute: AppRoutes.charts,
      title: 'Charts',
      body: portfolio.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorBanner(
          error: error,
          onRetry: () => ref.read(portfolioProvider.notifier).refresh(),
        ),
        data: (snapshot) {
          final valuePoints = List<ChartPoint>.generate(20, (index) {
            final base = snapshot.totalBaseValue;
            return ChartPoint(index.toDouble(), base * (0.95 + index * 0.004));
          });
          final pnlPoints = List<ChartPoint>.generate(20, (index) {
            final base = snapshot.totalUnrealizedPnlBase;
            return ChartPoint(
              index.toDouble(),
              base + (math.sin(index / 3) * 200),
            );
          });
          final total =
              snapshot.totalsByCurrency.values.fold<double>(0, (a, b) => a + b);
          final allocation = total == 0
              ? const {'N/A': 100.0}
              : snapshot.totalsByCurrency.map(
                  (k, v) => MapEntry(k, 100 * v / total),
                );

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Portfolio value'),
                    Tab(text: 'P&L'),
                    Tab(text: 'Allocation'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          LineChartCard(
                            title: 'Portfolio value (${snapshot.baseCurrency})',
                            points: valuePoints,
                          ),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          LineChartCard(
                            title: 'Unrealized P&L (${snapshot.baseCurrency})',
                            color: Theme.of(context).colorScheme.tertiary,
                            points: pnlPoints,
                          ),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [AllocationDonut(allocations: allocation)],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
