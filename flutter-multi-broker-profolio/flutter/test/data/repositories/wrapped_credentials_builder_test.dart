import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/data/crypto/e2e.dart';
import 'package:multi_broker_portfolio/data/remote/firestore_client/in_memory_firestore_client.dart';
import 'package:multi_broker_portfolio/data/repositories/wrapped_credentials_builder.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';

void main() {
  group('WrappedCredentialsBuilder', () {
    final crypto = E2eCrypto.withKdf(pbkdf2Test(iterations: 1));
    final key = E2eKey(List<int>.filled(32, 7));

    test('buildForConnection decrypts blob and wraps for backend', () async {
      final firestore = InMemoryFirestoreClient();
      const userId = 'u1';
      const connectionId = 'lb-1';
      const plaintext = '{"apiKey":"k","apiSecret":"s"}';
      final encrypted = await crypto.encrypt(plaintext, key);
      await firestore.setEncryptedCredential(
        userId,
        connectionId,
        encrypted.toEncoded(),
      );
      final builder = WrappedCredentialsBuilder(
        firestore: firestore,
        userId: userId,
        readCredentialKey: () => key,
        crypto: crypto,
      );

      final wrapped = await builder.buildForConnection(connectionId);
      final unwrapped =
          await crypto.unwrapFromBackend(token: wrapped, key: key);
      expect(unwrapped, plaintext);
    });

    test('buildForConnections includes only active e2e broker connections',
        () async {
      final firestore = InMemoryFirestoreClient();
      const userId = 'u1';
      const plaintext = '{"token":"abc"}';
      final encrypted = await crypto.encrypt(plaintext, key);
      await firestore.setEncryptedCredential(
        userId,
        'c1',
        encrypted.toEncoded(),
      );

      final builder = WrappedCredentialsBuilder(
        firestore: firestore,
        userId: userId,
        readCredentialKey: () => key,
        crypto: crypto,
      );

      final result = await builder.buildForConnections(const <Connection>[
        Connection(
          id: 'c1',
          kind: ConnectionKind.longbridge,
          label: 'LB',
          status: ConnectionStatus.ok,
          credentialMode: CredentialMode.e2e,
        ),
        Connection(
          id: 'c2',
          kind: ConnectionKind.ibkr,
          label: 'IB',
          status: ConnectionStatus.ok,
          credentialMode: CredentialMode.serverKey,
        ),
        Connection(
          id: 'c3',
          kind: ConnectionKind.futu,
          label: 'Futu',
          status: ConnectionStatus.disabled,
          credentialMode: CredentialMode.e2e,
        ),
        Connection(
          id: 'c4',
          kind: ConnectionKind.manual,
          label: 'Manual',
          status: ConnectionStatus.ok,
          credentialMode: CredentialMode.e2e,
        ),
      ]);

      expect(result.tokensByConnection.keys, <String>['c1']);
      expect(result.errorsByConnection, isEmpty);
      expect(result.keyBytes, key.bytes);
    });

    test('buildForConnections returns per-connection errors when key missing',
        () async {
      final builder = WrappedCredentialsBuilder(
        firestore: InMemoryFirestoreClient(),
        userId: 'u1',
        readCredentialKey: () => null,
        crypto: crypto,
      );

      final result = await builder.buildForConnections(const <Connection>[
        Connection(
          id: 'c1',
          kind: ConnectionKind.longbridge,
          label: 'LB',
          status: ConnectionStatus.ok,
          credentialMode: CredentialMode.e2e,
        ),
      ]);

      expect(result.tokensByConnection, isEmpty);
      expect(result.errorsByConnection.keys, <String>['c1']);
      expect(
        result.errorsByConnection['c1'],
        'Credential key is not available',
      );
      expect(result.keyBytes, isNull);
    });

    test('buildForConnections sanitizes missing credential blob error',
        () async {
      final builder = WrappedCredentialsBuilder(
        firestore: InMemoryFirestoreClient(),
        userId: 'u1',
        readCredentialKey: () => key,
        crypto: crypto,
      );

      final result = await builder.buildForConnections(const <Connection>[
        Connection(
          id: 'c-missing',
          kind: ConnectionKind.longbridge,
          label: 'LB',
          status: ConnectionStatus.ok,
          credentialMode: CredentialMode.e2e,
        ),
      ]);

      expect(result.tokensByConnection, isEmpty);
      expect(
        result.errorsByConnection['c-missing'],
        'Unable to load encrypted credentials',
      );
    });

    test('buildForConnections sanitizes malformed credential blob error',
        () async {
      final firestore = InMemoryFirestoreClient();
      await firestore.setEncryptedCredential('u1', 'c-malformed', 'not-b64');
      final builder = WrappedCredentialsBuilder(
        firestore: firestore,
        userId: 'u1',
        readCredentialKey: () => key,
        crypto: crypto,
      );

      final result = await builder.buildForConnections(const <Connection>[
        Connection(
          id: 'c-malformed',
          kind: ConnectionKind.longbridge,
          label: 'LB',
          status: ConnectionStatus.ok,
          credentialMode: CredentialMode.e2e,
        ),
      ]);

      expect(result.tokensByConnection, isEmpty);
      expect(
        result.errorsByConnection['c-malformed'],
        'Stored credentials are malformed',
      );
    });
  });
}
