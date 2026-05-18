/// The kind of external data source a [Connection] points at.
enum ConnectionKind {
  longbridge,
  ibkr,
  futu,
  binance,
  manual,
}

/// Health status of a connection.
enum ConnectionStatus {
  /// Never attempted or pending first sync.
  unknown,

  /// Last sync succeeded.
  ok,

  /// Last sync failed (auth, network, broker outage).
  error,

  /// User-disabled or token expired.
  disabled,
}

/// How the credentials for this connection are stored.
enum CredentialMode {
  /// End-to-end encrypted blob. Backend cannot decrypt; client must be
  /// online and unlocked for the backend to make broker calls.
  e2e,

  /// Server-side KMS-encrypted. Enables background sync and alert
  /// evaluation while the user is offline.
  serverKey,
}

/// A user-configured connection to a broker, exchange, or manual source.
class Connection {
  const Connection({
    required this.id,
    required this.kind,
    required this.label,
    required this.status,
    required this.credentialMode,
    this.lastSyncAt,
    this.errorMessage,
  });

  final String id;
  final ConnectionKind kind;
  final String label;
  final ConnectionStatus status;
  final CredentialMode credentialMode;
  final DateTime? lastSyncAt;
  final String? errorMessage;

  Connection copyWith({
    String? id,
    ConnectionKind? kind,
    String? label,
    ConnectionStatus? status,
    CredentialMode? credentialMode,
    DateTime? lastSyncAt,
    String? errorMessage,
  }) {
    return Connection(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      status: status ?? this.status,
      credentialMode: credentialMode ?? this.credentialMode,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Connection &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          kind == other.kind &&
          label == other.label &&
          status == other.status &&
          credentialMode == other.credentialMode &&
          lastSyncAt == other.lastSyncAt &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        id,
        kind,
        label,
        status,
        credentialMode,
        lastSyncAt,
        errorMessage,
      );

  @override
  String toString() =>
      'Connection(id: $id, kind: $kind, label: $label, status: $status)';
}
