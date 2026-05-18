// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:multi_broker_portfolio/data/remote/backend_client/backend_client.dart';
import 'package:multi_broker_portfolio/data/remote/backend_client/backend_config.dart';
import 'package:multi_broker_portfolio/data/remote/backend_client/quotes_stream.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Minimal in-memory channel for testing.
class FakeChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  FakeChannel() {
    _sink = _FakeSink(_outgoing);
  }

  final StreamController<dynamic> _incoming =
      StreamController<dynamic>.broadcast();
  final List<Object?> _outgoing = [];
  late final _FakeSink _sink;

  void push(Object event) => _incoming.add(event);
  void closeRemote() => _incoming.close();

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  // Unused parts of the interface.
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
  @override
  String? get protocol => null;
  @override
  Future<void> get ready => Future<void>.value();
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this._outgoing);
  final List<Object?> _outgoing;

  @override
  void add(Object? data) => _outgoing.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<dynamic> addStream(Stream<Object?> stream) async {
    await for (final e in stream) {
      _outgoing.add(e);
    }
  }

  @override
  Future<dynamic> close([int? closeCode, String? closeReason]) async {}

  @override
  Future<dynamic> get done => Future<void>.value();
}

void main() {
  final cfg = BackendConfig(baseUrl: Uri.parse('https://api.test/v1'));
  final mockHttp = MockClient((_) async => http.Response('{}', 200));
  BackendClient buildClient() => BackendClient(
        config: cfg,
        tokenProvider: () async => 'tok',
        httpClient: mockHttp,
      );

  test('subscribe sends op + symbols to socket', () async {
    final fake = FakeChannel();
    final qs = QuotesStream(
      client: buildClient(),
      channelFactory: (_) => fake,
      initialBackoff: const Duration(milliseconds: 1),
    );
    final received = <Map<String, dynamic>>[];
    final sub = qs.stream.listen(received.add);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    qs.subscribe(['AAPL']);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // Outgoing should include the subscribe op
    final out = fake._outgoing
        .whereType<String>()
        .map((s) => jsonDecode(s) as Map<String, dynamic>)
        .toList();
    expect(out.any((m) => m['op'] == 'subscribe'), isTrue);
    expect(out.last['symbols'], contains('AAPL'));

    // Incoming message is decoded
    fake.push(jsonEncode({'symbol': 'AAPL', 'price': 100, 'currency': 'USD'}));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(received, hasLength(1));
    expect(received.first['symbol'], 'AAPL');

    await sub.cancel();
    await qs.dispose();
  });

  test('addSymbols / removeSymbols mutate active set', () async {
    final fake = FakeChannel();
    final qs = QuotesStream(
      client: buildClient(),
      channelFactory: (_) => fake,
    );
    final sub = qs.stream.listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    qs.subscribe(['A']);
    qs.addSymbols(['B', 'C']);
    qs.removeSymbols(['A']);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final last =
        jsonDecode(fake._outgoing.last! as String) as Map<String, dynamic>;
    expect((last['symbols'] as List).toSet(), {'B', 'C'});

    await sub.cancel();
    await qs.dispose();
  });

  test('reconnects after onDone using backoff', () async {
    var calls = 0;
    final channels = <FakeChannel>[];
    final qs = QuotesStream(
      client: buildClient(),
      channelFactory: (_) {
        calls += 1;
        final c = FakeChannel();
        channels.add(c);
        return c;
      },
      initialBackoff: const Duration(milliseconds: 1),
      maxBackoff: const Duration(milliseconds: 5),
    );
    final sub = qs.stream.listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 1);
    channels.first.closeRemote();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, greaterThanOrEqualTo(2));
    await sub.cancel();
    await qs.dispose();
  });

  test('exhausts maxReconnectAttempts and emits error', () async {
    final qs = QuotesStream(
      client: buildClient(),
      channelFactory: (_) {
        final c = FakeChannel();
        // Schedule immediate close
        Future<void>.microtask(() => c.closeRemote());
        return c;
      },
      initialBackoff: const Duration(milliseconds: 1),
      maxBackoff: const Duration(milliseconds: 1),
      maxReconnectAttempts: 2,
    );
    final errors = <Object>[];
    final sub = qs.stream.listen(
      (_) {},
      onError: errors.add,
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(errors, isNotEmpty);
    await sub.cancel();
    await qs.dispose();
  });

  test('malformed incoming messages are silently dropped', () async {
    final fake = FakeChannel();
    final qs = QuotesStream(
      client: buildClient(),
      channelFactory: (_) => fake,
    );
    final received = <Map<String, dynamic>>[];
    final sub = qs.stream.listen(received.add);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    fake.push('not json');
    fake.push(utf8.encode(jsonEncode({'symbol': 'A', 'price': 1})));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(received, hasLength(1));
    expect(received.first['symbol'], 'A');
    await sub.cancel();
    await qs.dispose();
  });
}
