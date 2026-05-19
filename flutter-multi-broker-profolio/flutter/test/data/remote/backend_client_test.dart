import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:multi_broker_portfolio/data/remote/backend_client/backend_client.dart';
import 'package:multi_broker_portfolio/data/remote/backend_client/backend_config.dart';
import 'package:multi_broker_portfolio/data/remote/backend_client/backend_exception.dart';

void main() {
  group('BackendClient', () {
    final config = BackendConfig(baseUrl: Uri.parse('https://api.test/v1'));
    Future<String?> tokenOk() async => 'tok';
    Future<String?> tokenNull() async => null;

    BackendClient build(MockClient client, {bool nullToken = false}) {
      return BackendClient(
        config: config,
        tokenProvider: nullToken ? tokenNull : tokenOk,
        httpClient: client,
      );
    }

    test('attaches bearer token and JSON content-type', () async {
      late http.Request seen;
      final c = MockClient((req) async {
        seen = req;
        return http.Response(
          '{}',
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });
      final client = build(c);
      await client.listConnections();
      expect(seen.headers['Authorization'], 'Bearer tok');
      expect(seen.headers['Content-Type'], 'application/json');
      expect(seen.url.path, '/v1/connections');
    });

    test('encodes wrapped credential headers for portfolio call', () async {
      late http.Request seen;
      final c = MockClient((req) async {
        seen = req;
        return http.Response('{}', 200);
      });
      final client = build(c);
      await client.getPortfolioSnapshot(
        baseCurrency: 'USD',
        wrappedCredsByConnection: const <String, String>{'c1': 'token-1'},
        wrappedCredsKeyBytes: const <int>[1, 2, 3],
      );
      final credsHeader = seen.headers[BackendClient.mbpCredsHeader];
      expect(credsHeader, isNotNull);
      expect(
        utf8.decode(base64Decode(credsHeader!)),
        '{"c1":"token-1"}',
      );
      expect(
        seen.headers[BackendClient.mbpCredsKeyHeader],
        base64Encode(const <int>[1, 2, 3]),
      );
    });

    test(
        'encodes wrapped credential headers for positions/transactions/balances',
        () async {
      final seen = <String, http.Request>{};
      final c = MockClient((req) async {
        seen[req.url.path] = req;
        return http.Response('[]', 200);
      });
      final client = build(c);
      const creds = <String, String>{'c1': 'token-1'};

      await client.getPositions(
        wrappedCredsByConnection: creds,
        wrappedCredsKeyBytes: const <int>[9, 9],
      );
      await client.getTransactions(
        wrappedCredsByConnection: creds,
        wrappedCredsKeyBytes: const <int>[9, 9],
      );
      await client.getBalances(
        wrappedCredsByConnection: creds,
        wrappedCredsKeyBytes: const <int>[9, 9],
      );

      for (final path in <String>[
        '/v1/positions',
        '/v1/transactions',
        '/v1/balances',
      ]) {
        final req = seen[path];
        expect(req, isNotNull, reason: 'missing request for $path');
        expect(req!.headers[BackendClient.mbpCredsHeader], isNotNull);
        expect(
          req.headers[BackendClient.mbpCredsKeyHeader],
          base64Encode(const <int>[9, 9]),
        );
      }
    });

    test('throws 401 when token provider returns null', () async {
      final c = MockClient((_) async => http.Response('', 200));
      final client = build(c, nullToken: true);
      expect(
        () async => client.listConnections(),
        throwsA(
          isA<BackendException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });

    test('parses error body into message', () async {
      final c = MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'broker down'}),
          502,
        ),
      );
      final client = build(c);
      try {
        await client.listConnections();
        fail('expected throw');
      } on BackendException catch (e) {
        expect(e.statusCode, 502);
        expect(e.message, 'broker down');
      }
    });

    test('captures partial failures on HTTP 207', () async {
      final c = MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object?>{
            'data': <Object?>[],
            'errors': <Map<String, String>>[
              <String, String>{
                'sourceId': 'ibkr',
                'code': 'timeout',
                'message': 'oops',
              },
            ],
          }),
          207,
        ),
      );
      final client = build(c);
      try {
        await client.getPortfolioSnapshot(baseCurrency: 'USD');
        fail('expected throw');
      } on BackendException catch (e) {
        expect(e.statusCode, 207);
        expect(e.partialFailures, hasLength(1));
        expect(e.partialFailures.first.sourceId, 'ibkr');
        expect(e.partialFailures.first.code, 'timeout');
      }
    });

    test('returns decoded JSON on 2xx', () async {
      final c = MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object?>{
            'baseCurrency': 'USD',
            'positions': <Object?>[],
          }),
          200,
        ),
      );
      final client = build(c);
      final result =
          await client.getPortfolioSnapshot(baseCurrency: 'USD') as Map;
      expect(result['baseCurrency'], 'USD');
    });

    test('wraps network errors as statusCode 0', () async {
      final c = MockClient((_) async => throw Exception('boom'));
      final client = build(c);
      try {
        await client.listConnections();
        fail('expected throw');
      } on BackendException catch (e) {
        expect(e.statusCode, 0);
        expect(e.isNetwork, isTrue);
      }
    });

    test('builds query params for filtered endpoints', () async {
      late Uri seenUrl;
      final c = MockClient((req) async {
        seenUrl = req.url;
        return http.Response('[]', 200);
      });
      final client = build(c);
      await client.getTransactions(
        sourceId: 'lb',
        start: DateTime.utc(2025, 1, 1),
        limit: 200,
      );
      expect(seenUrl.queryParameters['source'], 'lb');
      expect(seenUrl.queryParameters['since'], '2025-01-01T00:00:00.000Z');
      expect(seenUrl.queryParameters['limit'], '200');
    });

    test('CRUD endpoints use correct HTTP verbs', () async {
      final calls = <String>[];
      final c = MockClient((req) async {
        calls.add('${req.method} ${req.url.path}');
        return http.Response('{}', 200);
      });
      final client = build(c);
      await client.createConnection({'kind': 'longbridge'});
      await client.updateConnectionMode('c1', 'e2e');
      await client.deleteConnection('c1');
      await client.createAlert({'kind': 'priceAbove'});
      await client.updateAlert('a1', {'active': true});
      await client.deleteAlert('a1');
      await client.getPositions(sourceId: 'lb');
      await client.getBalances();
      await client.getFxRate(base: 'USD', quote: 'HKD');
      await client.listAlerts();

      expect(calls, contains('POST /v1/connections'));
      expect(calls, contains('PATCH /v1/connections/c1'));
      expect(calls, contains('DELETE /v1/connections/c1'));
      expect(calls, contains('POST /v1/alerts'));
      expect(calls, contains('PUT /v1/alerts/a1'));
      expect(calls, contains('DELETE /v1/alerts/a1'));
      expect(calls, contains('GET /v1/positions'));
      expect(calls, contains('GET /v1/balances'));
      expect(calls, contains('GET /v1/fx'));
      expect(calls, contains('GET /v1/alerts'));
    });

    test(
      'quotesStreamUrl swaps scheme and appends token + symbols',
      () async {
        final c = MockClient((_) async => http.Response('{}', 200));
        final client = build(c);
        final url = await client.quotesStreamUrl(symbols: ['AAPL', 'GOOG']);
        expect(url.scheme, 'wss');
        expect(url.path, '/v1/quotes/stream');
        expect(url.queryParameters['token'], 'tok');
        expect(url.queryParameters['symbols'], 'AAPL,GOOG');
      },
    );

    test('BackendConfig effectiveWsBaseUrl converts http to ws', () {
      final cfg = BackendConfig(baseUrl: Uri.parse('http://h.local/v1'));
      expect(cfg.effectiveWsBaseUrl().scheme, 'ws');

      final cfg2 = BackendConfig(
        baseUrl: Uri.parse('http://h.local/v1'),
        wsBaseUrl: Uri.parse('wss://override.local/v1'),
      );
      expect(cfg2.effectiveWsBaseUrl().host, 'override.local');
    });

    test('PartialFailure serialises symmetrically', () {
      const p = PartialFailure(sourceId: 's', code: 'c', message: 'm');
      final j = p.toJson();
      final back = PartialFailure.fromJson(j);
      expect(back.sourceId, 's');
      expect(back.code, 'c');
      expect(back.message, 'm');
      expect(p.toString(), contains('s/c'));
    });

    test('close() releases the underlying http.Client', () async {
      final c = MockClient((_) async => http.Response('{}', 200));
      final client = build(c);
      await client.close(); // smoke; just ensures no exception
    });
  });
}
