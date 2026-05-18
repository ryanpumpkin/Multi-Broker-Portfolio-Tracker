import '../repositories/fx_repository.dart';

/// Converts a monetary value into the configured base currency.
///
/// If [fromCurrency] equals [baseCurrency], returns [value] unchanged.
/// Otherwise consults [FxRepository.getRate]; if no rate is available,
/// returns null so callers can render a "—" placeholder.
class ConvertToBaseCurrency {
  const ConvertToBaseCurrency(this._fx);

  final FxRepository _fx;

  Future<double?> call({
    required double value,
    required String fromCurrency,
    required String baseCurrency,
  }) async {
    if (fromCurrency == baseCurrency) return value;
    final rate = await _fx.getRate(base: fromCurrency, quote: baseCurrency);
    if (rate == null) return null;
    return value * rate.rate;
  }
}
