import 'dart:async';

import '../../domain/domain.dart';
import '../remote/backend_client/quotes_stream.dart';
import 'mappers.dart';

/// Concrete [QuotesRepository] backed by the backend `/quotes/stream`
/// WebSocket.
class QuotesRepositoryImpl implements QuotesRepository {
  QuotesRepositoryImpl({required this.streamFactory});

  /// Factory so the repository can lazily spin up a [QuotesStream] per
  /// subscriber (tests inject a fake that returns a controllable stream).
  final QuotesStream Function() streamFactory;

  @override
  Stream<PriceQuote> streamQuotes(List<String> symbols) {
    final qs = streamFactory();
    qs.subscribe(symbols);
    late StreamController<PriceQuote> ctrl;
    StreamSubscription<Map<String, dynamic>>? sub;
    ctrl = StreamController<PriceQuote>(
      onListen: () {
        sub = qs.stream.listen(
          (msg) {
            if (msg['symbol'] is String) {
              try {
                ctrl.add(Mappers.quoteFromJson(msg));
              } catch (_) {/* ignore malformed */}
            }
          },
          onError: ctrl.addError,
          onDone: ctrl.close,
        );
      },
      onCancel: () async {
        await sub?.cancel();
        await qs.dispose();
      },
    );
    return ctrl.stream;
  }
}
