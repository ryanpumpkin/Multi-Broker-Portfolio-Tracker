import '../entities/portfolio_snapshot.dart';

/// Read access to the aggregated portfolio snapshot.
abstract class PortfolioRepository {
  /// Returns the latest aggregated snapshot in the given base currency.
  Future<PortfolioSnapshot> getSnapshot({required String baseCurrency});

  /// Streams snapshot updates as underlying data refreshes.
  Stream<PortfolioSnapshot> watchSnapshot({required String baseCurrency});
}
