/// Public API of the data layer.
///
/// Concrete implementations of the domain repository interfaces plus the
/// low-level primitives they compose: Drift cache, secure storage, E2E
/// crypto, and remote clients (REST + WebSocket + Firestore).
library;

export 'crypto/e2e.dart';
export 'local/database/app_database.dart';
export 'local/secure_storage/secure_store.dart';
export 'remote/backend_client/backend_client.dart';
export 'remote/backend_client/backend_config.dart';
export 'remote/backend_client/backend_exception.dart';
export 'remote/backend_client/quotes_stream.dart';
export 'remote/firestore_client/firestore_client.dart';
export 'remote/firestore_client/in_memory_firestore_client.dart';
export 'repositories/alerts_repository_impl.dart';
export 'repositories/auth_repository_impl.dart';
export 'repositories/connections_repository_impl.dart';
export 'repositories/fx_repository_impl.dart';
export 'repositories/manual_holdings_repository_impl.dart';
export 'repositories/mappers.dart';
export 'repositories/portfolio_repository_impl.dart';
export 'repositories/quotes_repository_impl.dart';
export 'repositories/settings_repository_impl.dart';
export 'repositories/transactions_repository_impl.dart';
