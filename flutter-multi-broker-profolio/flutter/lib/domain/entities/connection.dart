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
  });

  final String id;
  final ConnectionKind kind;
  final String label;
  final ConnectionStatus status;
  final CredentialMode credentialMode;

  Connection copyWith({
    String? id,
    ConnectionKind? kind,
    String? label,
    ConnectionStatus? status,
    CredentialMode? credentialMode,
  }) {
    return Connection(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      status: status ?? this.status,
      credentialMode: credentialMode ?? this.credentialMode,
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
          credentialMode == other.credentialMode;

  @override
  int get hashCode => Object.hash(id, kind, label, status, credentialMode);

  @override
  String toString() =>
      'Connection(id: $id, kind: $kind, label: $label, status: $status)';
}
