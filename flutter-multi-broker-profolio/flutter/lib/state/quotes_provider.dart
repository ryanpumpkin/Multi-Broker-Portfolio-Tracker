import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/domain.dart';
import 'repository_providers.dart';

final quotesProvider = StreamProvider.family<PriceQuote, String>((ref, symbol) {
  return ref.watch(quotesRepositoryProvider).streamQuotes([symbol]).where(
    (quote) => quote.symbol == symbol,
  );
});
