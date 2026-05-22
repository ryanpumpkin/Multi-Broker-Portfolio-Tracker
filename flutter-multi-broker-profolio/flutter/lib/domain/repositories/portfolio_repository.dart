import '../entities/portfolio_snapshot.dart';

/// Read access to the aggregated portfolio snapshot.
abstract class PortfolioRepository {
  /// Returns the latest aggregated snapshot in the given base currency.
  ///
  /// Hits the network. Use [getCachedSnapshot] for an immediate
  /// cache-only read that never blocks on the backend.
  Future<PortfolioSnapshot> getSnapshot({required String baseCurrency});

  /// Returns a snapshot reconstructed from the local SQLite cache. Never
  /// hits the network. Used on app launch so the dashboard can show
  /// last-known data instantly while we wait for the user to unlock
  /// their PIN (which is required for live broker calls).
  Future<PortfolioSnapshot> getCachedSnapshot({required String baseCurrency});

  /// Streams snapshot updates as underlying data refreshes.
  Stream<PortfolioSnapshot> watchSnapshot({required String baseCurrency});
}
