import '../entities/fx_rate.dart';

/// Read access to FX rates.
abstract class FxRepository {
  /// Returns the current rate to convert 1 unit of [base] into [quote].
  ///
  /// Implementations may return a cached value if a fresh fetch is not
  /// possible. Returns `null` if no rate is available for the pair.
  Future<FxRate?> getRate({required String base, required String quote});

  /// Streams rate updates for the given pairs.
  ///
  /// [pairs] is a list of `(base, quote)` tuples expressed as 2-element
  /// records. The stream emits whenever any pair is refreshed.
  Stream<FxRate> watchRates(List<({String base, String quote})> pairs);
}
