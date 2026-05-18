/// Thrown by [BackendClient] when an HTTP call fails.
class BackendException implements Exception {
  const BackendException({
    required this.statusCode,
    required this.message,
    this.body,
    this.partialFailures = const <PartialFailure>[],
  });

  /// HTTP status code (0 if the request never reached the server).
  final int statusCode;
  final String message;
  final String? body;

  /// Per-source partial failures, populated when the aggregator returns
  /// 207 / a JSON `errors` array. See detailed-design §7.2.
  final List<PartialFailure> partialFailures;

  bool get isNetwork => statusCode == 0;

  @override
  String toString() =>
      'BackendException($statusCode): $message'
      '${partialFailures.isEmpty ? '' : ' partials=$partialFailures'}';
}

/// A single broker / adapter failure inside an otherwise-successful
/// aggregated response.
class PartialFailure {
  const PartialFailure({
    required this.sourceId,
    required this.code,
    required this.message,
  });

  final String sourceId;
  final String code;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sourceId': sourceId,
        'code': code,
        'message': message,
      };

  factory PartialFailure.fromJson(Map<String, dynamic> json) {
    return PartialFailure(
      sourceId: json['sourceId'] as String? ?? json['source_id'] as String? ?? '',
      code: json['code'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
    );
  }

  @override
  String toString() => 'PartialFailure($sourceId/$code: $message)';
}
