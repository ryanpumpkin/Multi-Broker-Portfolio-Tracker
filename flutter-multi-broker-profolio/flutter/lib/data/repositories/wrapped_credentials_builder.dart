import '../../domain/domain.dart';
import '../crypto/e2e.dart';
import '../remote/firestore_client/firestore_client.dart';

typedef CredentialKeyReader = E2eKey? Function();

/// Result of building wrapped credentials for a snapshot request.
class WrappedCredentialsBuildResult {
  const WrappedCredentialsBuildResult({
    required this.tokensByConnection,
    required this.errorsByConnection,
    this.keyBytes,
  });

  final Map<String, String> tokensByConnection;
  final Map<String, String> errorsByConnection;
  final List<int>? keyBytes;

  bool get hasWrappedTokens => tokensByConnection.isNotEmpty;
}

/// Builds short-lived backend credential wrappers for active E2E connections.
class WrappedCredentialsBuilder {
  WrappedCredentialsBuilder({
    required this.firestore,
    required this.userId,
    required this.readCredentialKey,
    E2eCrypto? crypto,
  }) : _crypto = crypto ?? E2eCrypto.production();

  final FirestoreClient firestore;
  final String userId;
  final CredentialKeyReader readCredentialKey;
  final E2eCrypto _crypto;

  /// Builds one wrapped token for [connectionId].
  Future<String> buildForConnection(String connectionId) async {
    final key = readCredentialKey();
    if (key == null) {
      throw StateError('Credential key is not available');
    }
    final encryptedBlob = await firestore.getEncryptedCredential(
      userId,
      connectionId,
    );
    if (encryptedBlob == null || encryptedBlob.isEmpty) {
      throw StateError('Missing encrypted credential blob for $connectionId');
    }
    final plaintext = await _crypto.decrypt(
      Ciphertext.fromEncoded(encryptedBlob),
      key,
    );
    return _crypto.wrapForBackend(plaintextCreds: plaintext, key: key);
  }

  /// Builds wrapped tokens for every active E2E connection.
  Future<WrappedCredentialsBuildResult> buildForConnections(
    Iterable<Connection> connections,
  ) async {
    final active = connections
        .where(
          (connection) =>
              connection.credentialMode == CredentialMode.e2e &&
              connection.status != ConnectionStatus.disabled &&
              connection.kind != ConnectionKind.manual,
        )
        .toList(growable: false);

    if (active.isEmpty) {
      return const WrappedCredentialsBuildResult(
        tokensByConnection: <String, String>{},
        errorsByConnection: <String, String>{},
      );
    }

    final key = readCredentialKey();
    if (key == null) {
      return WrappedCredentialsBuildResult(
        tokensByConnection: const <String, String>{},
        errorsByConnection: <String, String>{
          for (final connection in active)
            connection.id: 'Credential key is not available',
        },
      );
    }

    final tokens = <String, String>{};
    final errors = <String, String>{};
    for (final connection in active) {
      try {
        tokens[connection.id] = await buildForConnection(connection.id);
      } on StateError {
        errors[connection.id] = 'Unable to load encrypted credentials';
      } on FormatException {
        errors[connection.id] = 'Stored credentials are malformed';
      } catch (e) {
        errors[connection.id] = 'Unable to prepare credentials: $e';
      }
    }

    return WrappedCredentialsBuildResult(
      tokensByConnection: Map<String, String>.unmodifiable(tokens),
      errorsByConnection: Map<String, String>.unmodifiable(errors),
      keyBytes: List<int>.unmodifiable(key.bytes),
    );
  }
}
