import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database/app_database.dart';
import '../data/local/secure_storage/secure_storage_adapter.dart';
import '../data/local/secure_storage/secure_store.dart';
import '../data/remote/backend_client/backend_client.dart';
import '../data/remote/backend_client/backend_config.dart';
import '../data/remote/backend_client/quotes_stream.dart';
import '../data/remote/firestore_client/firestore_adapter.dart';
import '../data/remote/firestore_client/firestore_client.dart';
import '../data/repositories/alerts_repository_impl.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/connections_repository_impl.dart';
import '../data/repositories/firebase_auth_adapter.dart';
import '../data/repositories/fx_repository_impl.dart';
import '../data/repositories/manual_holdings_repository_impl.dart';
import '../data/repositories/portfolio_repository_impl.dart';
import '../data/repositories/quotes_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/repositories/transactions_repository_impl.dart';
import '../data/repositories/wrapped_credentials_builder.dart';
import '../domain/domain.dart';
import 'credential_key_provider.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

/// Opens (or re-uses) the Drift SQLite database. Disposed with the container.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

/// Thin wrapper around cloud_firestore.
final firestoreClientProvider = Provider<FirestoreClient>(
  (ref) => CloudFirestoreClient(FirebaseFirestore.instance),
);

/// Resolves the Firebase ID token for the current user.
TokenProvider _makeTokenProvider() => () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return user.getIdToken();
    };

/// REST + WebSocket client pointed at the backend proxy service.
///
/// The base URL defaults to `http://localhost:8000/v1` for local dev;
/// override via the `BACKEND_BASE_URL` env var in your `.env` / app config.
final backendClientProvider = Provider<BackendClient>((ref) {
  const baseUrlStr = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8000/v1',
  );
  final client = BackendClient(
    config: BackendConfig(baseUrl: Uri.parse(baseUrlStr)),
    tokenProvider: _makeTokenProvider(),
  );
  ref.onDispose(client.close);
  return client;
});

/// Emits the current signed-in user's UID, or null when signed out.
final currentUserIdProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) => user?.uid);
});

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) {
    final secureStore = SecureStore(
      FallbackKeyValueStore(primary: FlutterSecureStorageAdapter()),
    );
    return AuthRepositoryImpl(
      FirebaseAuthAdapter(FirebaseAuth.instance),
      sessionCleaner: CompositeAuthSessionCleaner([
        SecureStoreAuthSessionCleaner(secureStore),
      ]),
    );
  },
);

// ---------------------------------------------------------------------------
// Repository providers — concrete implementations
// ---------------------------------------------------------------------------

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider).valueOrNull ?? '';
  final repo = SettingsRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    firestore: ref.watch(firestoreClientProvider),
    userId: userId,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final connectionsRepositoryProvider = Provider<ConnectionsRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider).valueOrNull ?? '';
  return ConnectionsRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    firestore: ref.watch(firestoreClientProvider),
    userId: userId,
  );
});

final wrappedCredentialsBuilderProvider = Provider<WrappedCredentialsBuilder>(
  (ref) {
    final userId = ref.watch(currentUserIdProvider).valueOrNull ?? '';
    return WrappedCredentialsBuilder(
      firestore: ref.watch(firestoreClientProvider),
      userId: userId,
      readCredentialKey: () => ref.read(credentialKeyProvider),
    );
  },
);

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  final repo = PortfolioRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    backend: ref.watch(backendClientProvider),
    connections: ref.watch(connectionsRepositoryProvider),
    wrappedCredentialsBuilder: ref.watch(wrappedCredentialsBuilderProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final quotesRepositoryProvider = Provider<QuotesRepository>((ref) {
  final backend = ref.watch(backendClientProvider);
  return QuotesRepositoryImpl(
    streamFactory: () => QuotesStream(client: backend),
  );
});

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    backend: ref.watch(backendClientProvider),
    connections: ref.watch(connectionsRepositoryProvider),
    wrappedCredentialsBuilder: ref.watch(wrappedCredentialsBuilderProvider),
  );
});

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider).valueOrNull ?? '';
  return AlertsRepositoryImpl(
    firestore: ref.watch(firestoreClientProvider),
    userId: userId,
  );
});

final manualHoldingsRepositoryProvider =
    Provider<ManualHoldingsRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider).valueOrNull ?? '';
  return ManualHoldingsRepositoryImpl(
    firestore: ref.watch(firestoreClientProvider),
    userId: userId,
  );
});

final fxRepositoryProvider = Provider<FxRepository>((ref) {
  final repo = FxRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    backend: ref.watch(backendClientProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});
