/// Configuration for the backend proxy service.
class BackendConfig {
  const BackendConfig({
    required this.baseUrl,
    this.wsBaseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
  });

  /// REST base URL, e.g. `https://api.example.com/v1`.
  final Uri baseUrl;

  /// Optional WebSocket base URL. If null, [baseUrl] is converted by
  /// swapping `http(s)` → `ws(s)`.
  final Uri? wsBaseUrl;

  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// Resolves the effective WS base URL.
  Uri effectiveWsBaseUrl() {
    if (wsBaseUrl != null) return wsBaseUrl!;
    final scheme = baseUrl.scheme == 'https' ? 'wss' : 'ws';
    return baseUrl.replace(scheme: scheme);
  }
}

/// Pluggable provider of a Firebase ID token (or any bearer).
///
/// Returning null means "skip the Authorization header" — only legal for
/// public endpoints (e.g. /v1/health).
typedef TokenProvider = Future<String?> Function();
