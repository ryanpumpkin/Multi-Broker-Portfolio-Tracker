import 'connection.dart';

/// Health status for one upstream source during an aggregated refresh.
class SourceHealth {
  const SourceHealth({
    required this.sourceId,
    required this.status,
    this.code,
    this.message,
  });

  final String sourceId;
  final ConnectionStatus status;
  final String? code;
  final String? message;

  SourceHealth copyWith({
    String? sourceId,
    ConnectionStatus? status,
    String? code,
    String? message,
  }) {
    return SourceHealth(
      sourceId: sourceId ?? this.sourceId,
      status: status ?? this.status,
      code: code ?? this.code,
      message: message ?? this.message,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceHealth &&
          runtimeType == other.runtimeType &&
          sourceId == other.sourceId &&
          status == other.status &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(sourceId, status, code, message);

  @override
  String toString() =>
      'SourceHealth(sourceId: $sourceId, status: ${status.name}, code: $code)';
}
