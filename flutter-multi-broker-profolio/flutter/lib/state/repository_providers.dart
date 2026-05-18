import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/local/secure_storage/secure_storage_adapter.dart';
import '../data/local/secure_storage/secure_store.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/firebase_auth_adapter.dart';
import '../domain/domain.dart';

Never _missing(String name) => throw UnimplementedError(
      '$name is not bound. Override this provider in ProviderScope.',
    );

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

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => _missing('settingsRepositoryProvider'),
);

final connectionsRepositoryProvider = Provider<ConnectionsRepository>(
  (ref) => _missing('connectionsRepositoryProvider'),
);

final portfolioRepositoryProvider = Provider<PortfolioRepository>(
  (ref) => _missing('portfolioRepositoryProvider'),
);

final quotesRepositoryProvider = Provider<QuotesRepository>(
  (ref) => _missing('quotesRepositoryProvider'),
);

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => _missing('transactionsRepositoryProvider'),
);

final alertsRepositoryProvider = Provider<AlertsRepository>(
  (ref) => _missing('alertsRepositoryProvider'),
);

final manualHoldingsRepositoryProvider = Provider<ManualHoldingsRepository>(
  (ref) => _missing('manualHoldingsRepositoryProvider'),
);

final fxRepositoryProvider = Provider<FxRepository>(
  (ref) => _missing('fxRepositoryProvider'),
);
