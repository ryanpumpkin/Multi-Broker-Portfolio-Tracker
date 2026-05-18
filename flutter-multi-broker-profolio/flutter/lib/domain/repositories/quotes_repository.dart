import '../entities/price_quote.dart';

/// Streams live price quotes for a set of symbols.
abstract class QuotesRepository {
  Stream<PriceQuote> streamQuotes(List<String> symbols);
}
