import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'backend_client.dart';

/// Factory for opening a [WebSocketChannel]. Tests inject a fake.
typedef WebSocketChannelFactory = WebSocketChannel Function(Uri url);

/// Subscribes to live price quotes via the backend's WebSocket stream.
///
/// Auto-reconnects with exponential backoff and re-sends the current
/// subscription on every reconnect.
class QuotesStream {
  QuotesStream({
    required this.client,
    WebSocketChannelFactory? channelFactory,
    this.initialBackoff = const Duration(milliseconds: 500),
    this.maxBackoff = const Duration(seconds: 30),
    this.maxReconnectAttempts,
  }) : _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final BackendClient client;
  final WebSocketChannelFactory _channelFactory;
  final Duration initialBackoff;
  final Duration maxBackoff;

  /// If null, reconnects forever. If set, stops after this many
  /// consecutive failures and emits an error.
  final int? maxReconnectAttempts;

  final Set<String> _symbols = <String>{};
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  StreamController<Map<String, dynamic>>? _out;
  bool _closed = false;
  int _attempts = 0;
  Timer? _reconnectTimer;

  /// The stream of decoded JSON message maps. One controller per
  /// [QuotesStream] instance; do not call [stream] twice for different
  /// subscribers — use a broadcast adapter at a higher layer if needed.
  Stream<Map<String, dynamic>> get stream {
    _out ??= StreamController<Map<String, dynamic>>(
      onListen: _connect,
      onCancel: dispose,
    );
    return _out!.stream;
  }

  /// Replaces the active symbol subscription. Re-sends to the server if
  /// already connected.
  void subscribe(Iterable<String> symbols) {
    _symbols
      ..clear()
      ..addAll(symbols);
    _sendSubscription();
  }

  /// Adds [symbols] to the current subscription.
  void addSymbols(Iterable<String> symbols) {
    _symbols.addAll(symbols);
    _sendSubscription();
  }

  /// Removes [symbols] from the current subscription.
  void removeSymbols(Iterable<String> symbols) {
    _symbols.removeAll(symbols);
    _sendSubscription();
  }

  Future<void> dispose() async {
    _closed = true;
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    await _out?.close();
    _channel = null;
    _sub = null;
    _out = null;
  }

  // ----------------------------------------------------------------------

  Future<void> _connect() async {
    if (_closed) return;
    try {
      final url = await client.quotesStreamUrl(symbols: _symbols);
      final ch = _channelFactory(url);
      _channel = ch;
      _sendSubscription();
      _sub = ch.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );
    } catch (e) {
      _onError(e);
    }
  }

  void _onMessage(dynamic event) {
    // A received frame means the connection is healthy; reset backoff state.
    _attempts = 0;
    if (_out == null || _out!.isClosed) return;
    if (event is String) {
      try {
        final decoded = jsonDecode(event);
        if (decoded is Map<String, dynamic>) {
          _out!.add(decoded);
        }
      } catch (_) {
        // ignore malformed messages
      }
    } else if (event is List<int>) {
      try {
        final decoded = jsonDecode(utf8.decode(event));
        if (decoded is Map<String, dynamic>) _out!.add(decoded);
      } catch (_) {/* ignore */}
    }
  }

  void _onError(Object err) {
    _scheduleReconnect();
  }

  void _onDone() {
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_closed) return;
    _attempts += 1;
    if (maxReconnectAttempts != null && _attempts > maxReconnectAttempts!) {
      _out?.addError(
        StateError(
          'WebSocket reconnect attempts exhausted ($_attempts)',
        ),
      );
      return;
    }
    final ms = (initialBackoff.inMilliseconds * (1 << (_attempts - 1)))
        .clamp(0, maxBackoff.inMilliseconds);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: ms), _connect);
  }

  void _sendSubscription() {
    final ch = _channel;
    if (ch == null) return;
    final msg = jsonEncode(<String, dynamic>{
      'op': 'subscribe',
      'symbols': _symbols.toList(growable: false),
    });
    try {
      ch.sink.add(msg);
    } catch (_) {
      // sink closed — reconnect path will handle.
    }
  }
}
