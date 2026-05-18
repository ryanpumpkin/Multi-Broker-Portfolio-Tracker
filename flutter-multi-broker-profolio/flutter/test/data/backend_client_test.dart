import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:multi_broker_portfolio/data/data.dart';

void main() {
  BackendClient buildClient({
    required Future<String?> Function() tokenProvider,
    required MockClient httpClient,
  }) {
    return BackendClient(
      config: BackendConfig(baseUrl: Uri.parse('https://api.example.com/v1')),
      tokenProvider: tokenProvider,
      httpClient: httpClient,
    );
  }

  test('attaches Authorization header', () async {
    late http.Request captured;
    final client = buildClient(
      tokenProvider: () async => 'id-token',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response('[]', 200);
      }),
    );

    await client.listConnections();
    expect(captured.headers['authorization'], 'Bearer id-token');
  });

  test('throws 401 when token is missing for auth-required endpoints', () async {
    final client = buildClient(
      tokenProvider: () async => null,
      httpClient: MockClient((_) async => http.Response('[]', 200)),
    );

    expect(
      client.listAlerts,
      throwsA(
        isA<BackendException>()
            .having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('parses partial failures from 207 response', () async {
    final client = buildClient(
      tokenProvider: () async => 't',
      httpClient: MockClient((_) async {
        return http.Response(
          '{"errors":[{"sourceId":"ibkr","code":"timeout","message":"slow"}]}',
          207,
        );
      }),
    );

    expect(
      () => client.getPortfolioSnapshot(baseCurrency: 'USD'),
      throwsA(
        isA<BackendException>()
            .having((e) => e.statusCode, 'statusCode', 207)
            .having((e) => e.partialFailures.length, 'partials', 1),
      ),
    );
  });

  test('builds WebSocket stream URL with scheme/token/symbols', () async {
    final client = buildClient(
      tokenProvider: () async => 'token-1',
      httpClient: MockClient((_) async => http.Response('[]', 200)),
    );

    final url = await client.quotesStreamUrl(symbols: ['AAPL', 'TSLA']);
    expect(url.scheme, 'wss');
    expect(url.path, '/v1/quotes/stream');
    expect(url.queryParameters['token'], 'token-1');
    expect(url.queryParameters['symbols'], 'AAPL,TSLA');
  });
}
