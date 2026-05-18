import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';
import 'backend_exception.dart';

/// Minimal REST client for the backend proxy service.
///
/// Attaches the Firebase ID token from [tokenProvider] on every call and
/// surfaces aggregator partial failures via [BackendException].
class BackendClient {
  BackendClient({
    required this.config,
    required this.tokenProvider,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final BackendConfig config;
  final TokenProvider tokenProvider;
  final http.Client _http;

  Future<void> close() async {
    _http.close();
  }

  static const String mbpCredsHeader = 'X-MBP-Creds';
  static const String mbpCredsKeyHeader = 'X-MBP-Creds-Key';

  // ------------- REST helpers --------------------------------------------

  Future<Map<String, String>> _headers({
    bool requireAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final token = await tokenProvider();
    if (requireAuth && (token == null || token.isEmpty)) {
      throw const BackendException(
        statusCode: 401,
        message: 'Missing auth token',
      );
    }
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (extraHeaders != null) ...extraHeaders,
    };
  }

  Uri _u(String path, [Map<String, dynamic>? query]) {
    final base = config.baseUrl;
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final joined = path.startsWith('/') ? '$basePath$path' : '$basePath/$path';
    final q = query?.map(
      (k, v) => MapEntry(k, v == null ? '' : v.toString()),
    );
    return base.replace(
      path: joined,
      queryParameters: q?.isEmpty ?? true ? null : q,
    );
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool requireAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = await _headers(
      requireAuth: requireAuth,
      extraHeaders: extraHeaders,
    );
    final url = _u(path, query);
    http.Response resp;
    try {
      switch (method) {
        case 'GET':
          resp = await _http.get(url, headers: headers).timeout(
                config.receiveTimeout,
              );
        case 'DELETE':
          resp = await _http.delete(url, headers: headers).timeout(
                config.receiveTimeout,
              );
        case 'POST':
          resp = await _http
              .post(
                url,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(config.receiveTimeout);
        case 'PUT':
          resp = await _http
              .put(
                url,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(config.receiveTimeout);
        case 'PATCH':
          resp = await _http
              .patch(
                url,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(config.receiveTimeout);
        default:
          throw ArgumentError.value(method, 'method', 'unsupported');
      }
    } on TimeoutException catch (e) {
      throw BackendException(
        statusCode: 0,
        message: 'Request timed out: $e',
      );
    } catch (e) {
      throw BackendException(statusCode: 0, message: 'Network error: $e');
    }

    final code = resp.statusCode;
    final text = resp.body;
    dynamic decoded;
    if (text.isNotEmpty) {
      try {
        decoded = jsonDecode(text);
      } catch (_) {
        decoded = null;
      }
    }

    if (code < 200 || code >= 300) {
      List<PartialFailure> partials = const [];
      String message = 'HTTP $code';
      if (decoded is Map) {
        final m = decoded.cast<String, dynamic>();
        if (m['message'] is String) message = m['message'] as String;
        if (m['errors'] is List) {
          partials = (m['errors'] as List)
              .whereType<Map<String, dynamic>>()
              .map(PartialFailure.fromJson)
              .toList(growable: false);
        }
      }
      throw BackendException(
        statusCode: code,
        message: message,
        body: text,
        partialFailures: partials,
      );
    }

    // 207-style success with partial failures embedded in payload
    if (decoded is Map &&
        decoded['errors'] is List &&
        (decoded['errors'] as List).isNotEmpty &&
        code == 207) {
      final partials = (decoded['errors'] as List)
          .whereType<Map<String, dynamic>>()
          .map(PartialFailure.fromJson)
          .toList(growable: false);
      throw BackendException(
        statusCode: 207,
        message: 'Partial failure',
        body: text,
        partialFailures: partials,
      );
    }

    return decoded;
  }

  Map<String, String>? _credentialHeaders({
    Map<String, String>? wrappedCredsByConnection,
    List<int>? wrappedCredsKeyBytes,
  }) {
    final creds = wrappedCredsByConnection ?? const <String, String>{};
    if (creds.isEmpty) return null;
    return <String, String>{
      mbpCredsHeader: base64Encode(utf8.encode(jsonEncode(creds))),
      if (wrappedCredsKeyBytes != null && wrappedCredsKeyBytes.isNotEmpty)
        mbpCredsKeyHeader: base64Encode(wrappedCredsKeyBytes),
    };
  }

  // ------------- Endpoints -----------------------------------------------

  Future<dynamic> listConnections() => _send('GET', '/connections');

  Future<dynamic> createConnection(Map<String, dynamic> payload) =>
      _send('POST', '/connections', body: payload);

  Future<dynamic> deleteConnection(String id) =>
      _send('DELETE', '/connections/$id');

  Future<dynamic> updateConnectionMode(String id, String mode) =>
      _send('PATCH', '/connections/$id', body: <String, dynamic>{'mode': mode});

  Future<dynamic> getPortfolioSnapshot({
    required String baseCurrency,
    Map<String, String>? wrappedCredsByConnection,
    List<int>? wrappedCredsKeyBytes,
  }) =>
      _send(
        'GET',
        '/portfolio/snapshot',
        query: <String, dynamic>{'base': baseCurrency},
        extraHeaders: _credentialHeaders(
          wrappedCredsByConnection: wrappedCredsByConnection,
          wrappedCredsKeyBytes: wrappedCredsKeyBytes,
        ),
      );

  Future<dynamic> getPositions({
    String? sourceId,
    Map<String, String>? wrappedCredsByConnection,
    List<int>? wrappedCredsKeyBytes,
  }) =>
      _send(
        'GET',
        '/positions',
        query:
            sourceId == null ? null : <String, dynamic>{'sourceId': sourceId},
        extraHeaders: _credentialHeaders(
          wrappedCredsByConnection: wrappedCredsByConnection,
          wrappedCredsKeyBytes: wrappedCredsKeyBytes,
        ),
      );

  Future<dynamic> getTransactions({
    String? sourceId,
    DateTime? start,
    DateTime? end,
    Map<String, String>? wrappedCredsByConnection,
    List<int>? wrappedCredsKeyBytes,
  }) {
    final q = <String, dynamic>{};
    if (sourceId != null) q['sourceId'] = sourceId;
    if (start != null) q['start'] = start.toUtc().toIso8601String();
    if (end != null) q['end'] = end.toUtc().toIso8601String();
    return _send(
      'GET',
      '/transactions',
      query: q.isEmpty ? null : q,
      extraHeaders: _credentialHeaders(
        wrappedCredsByConnection: wrappedCredsByConnection,
        wrappedCredsKeyBytes: wrappedCredsKeyBytes,
      ),
    );
  }

  Future<dynamic> getBalances({
    String? sourceId,
    Map<String, String>? wrappedCredsByConnection,
    List<int>? wrappedCredsKeyBytes,
  }) =>
      _send(
        'GET',
        '/balances',
        query:
            sourceId == null ? null : <String, dynamic>{'sourceId': sourceId},
        extraHeaders: _credentialHeaders(
          wrappedCredsByConnection: wrappedCredsByConnection,
          wrappedCredsKeyBytes: wrappedCredsKeyBytes,
        ),
      );

  Future<dynamic> getFxRate({required String base, required String quote}) =>
      _send(
        'GET',
        '/fx',
        query: <String, dynamic>{'base': base, 'quote': quote},
      );

  Future<dynamic> listAlerts() => _send('GET', '/alerts');

  Future<dynamic> createAlert(Map<String, dynamic> payload) =>
      _send('POST', '/alerts', body: payload);

  Future<dynamic> updateAlert(String id, Map<String, dynamic> payload) =>
      _send('PUT', '/alerts/$id', body: payload);

  Future<dynamic> deleteAlert(String id) => _send('DELETE', '/alerts/$id');

  /// Builds the WebSocket URL for `/v1/quotes/stream`. Token is appended as
  /// a query parameter because browsers cannot set Authorization headers
  /// on the WS handshake.
  Future<Uri> quotesStreamUrl({Iterable<String>? symbols}) async {
    final token = await tokenProvider();
    final wsBase = config.effectiveWsBaseUrl();
    final basePath = wsBase.path.endsWith('/')
        ? wsBase.path.substring(0, wsBase.path.length - 1)
        : wsBase.path;
    final q = <String, String>{
      if (token != null && token.isNotEmpty) 'token': token,
      if (symbols != null && symbols.isNotEmpty) 'symbols': symbols.join(','),
    };
    return wsBase.replace(
      path: '$basePath/quotes/stream',
      queryParameters: q.isEmpty ? null : q,
    );
  }
}
