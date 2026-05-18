import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/domain.dart';
import 'repository_providers.dart';
import 'settings_provider.dart';

final getAggregatedPortfolioProvider = Provider<GetAggregatedPortfolio>((ref) {
  return GetAggregatedPortfolio(
    portfolio: ref.watch(portfolioRepositoryProvider),
    fx: ref.watch(fxRepositoryProvider),
    manualHoldings: ref.watch(manualHoldingsRepositoryProvider),
  );
});

final portfolioProvider =
    AsyncNotifierProvider<PortfolioController, PortfolioSnapshot>(
  PortfolioController.new,
);

class PortfolioController extends AsyncNotifier<PortfolioSnapshot> {
  late String _baseCurrency;

  @override
  Future<PortfolioSnapshot> build() async {
    final settings = await ref.watch(settingsProvider.future);
    _baseCurrency = settings.baseCurrency;
    return ref
        .read(getAggregatedPortfolioProvider)
        .call(baseCurrency: _baseCurrency);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(getAggregatedPortfolioProvider)
          .call(baseCurrency: _baseCurrency),
    );
  }
}
