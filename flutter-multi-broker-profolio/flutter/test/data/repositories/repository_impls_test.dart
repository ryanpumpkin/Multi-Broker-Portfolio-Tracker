import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:multi_broker_portfolio/data/data.dart';
import 'package:multi_broker_portfolio/data/repositories/wrapped_credentials_builder.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';

void main() {
  group('Repository impls', () {
    test('AuthRepositoryImpl delegates auth operations', () async {
      final ds = InMemoryAuthDataSource();
      final repo = AuthRepositoryImpl(ds);
      expect(await repo.currentUser(), isNull);

      final created = await repo.signUp(email: 'u@example.com', password: 'pw');
      expect(created.email, 'u@example.com');
      expect((await repo.currentUser())?.uid, created.uid);

      final watched = <AuthUser?>[];
      final sub = repo.watchUser().listen(watched.add);
      await repo.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      await ds.dispose();

      expect(watched, isNotEmpty);
      expect(watched.last, isNull);
    });

    test('ManualHoldingsRepositoryImpl CRUD', () async {
      final fs = InMemoryFirestoreClient();
      final repo = ManualHoldingsRepositoryImpl(firestore: fs, userId: 'u1');
      const h = ManualHolding(
        id: 'm1',
        label: 'Cash',
        assetClass: AssetClass.cash,
        quantity: 1,
        valueCurrency: 'USD',
        valueAmount: 1000,
      );
      await repo.create(h);
      expect((await repo.list()).single.id, 'm1');

      final updated = h.copyWith(valueAmount: 1200);
      await repo.update(updated);
      expect((await repo.list()).single.valueAmount, 1200);
      await repo.delete('m1');
      expect(await repo.list(), isEmpty);
    });

    test('AlertsRepositoryImpl CRUD + evaluateLocal', () async {
      final fs = InMemoryFirestoreClient();
      final repo = AlertsRepositoryImpl(firestore: fs, userId: 'u1');
      const alert = Alert(
        id: 'a1',
        kind: AlertKind.priceAbove,
        scope: AlertScope.symbol('AAPL'),
        threshold: 100,
        active: true,
      );
      await repo.create(alert);
      final list = await repo.list();
      expect(list, hasLength(1));
      expect(
        repo.evaluateLocal(
          list.single,
          quote: PriceQuote(
            symbol: 'AAPL',
            price: 110,
            currency: 'USD',
            timestamp: DateTime.utc(2026),
          ),
        ),
        isTrue,
      );
      await repo.update(alert.copyWith(active: false));
      expect((await repo.list()).single.active, isFalse);
      await repo.delete('a1');
      expect(await repo.list(), isEmpty);
    });

    test('SettingsRepositoryImpl reads defaults and writes local-first',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = SettingsRepositoryImpl(
        db: db,
        firestore: _FailingFirestoreClient(),
        userId: 'u1',
      );
      expect(await repo.getThemeMode(), AppThemeMode.system);
      expect(await repo.getBaseCurrency(), 'USD');
      expect(await repo.getCurrencyMode(), CurrencyMode.base);

      final events = <void>[];
      final sub = repo.watchChanges().listen(events.add);
      await repo.setThemeMode(AppThemeMode.dark);
      await repo.setLocale('zh_Hant');
      await repo.setBaseCurrency('HKD');
      await repo.setCurrencyMode(CurrencyMode.native);
      await repo.setLocale(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(await repo.getThemeMode(), AppThemeMode.dark);
      expect(await repo.getLocale(), isNull);
      expect(await repo.getBaseCurrency(), 'HKD');
      expect(await repo.getCurrencyMode(), CurrencyMode.native);
      expect(events, isNotEmpty);
      await repo.dispose();
      await db.close();
    });

    test('ConnectionsRepositoryImpl uses Firestore and falls back to cache',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      final fs = InMemoryFirestoreClient();
      final repo =
          ConnectionsRepositoryImpl(db: db, firestore: fs, userId: 'u1');
      final created = await repo.add(
        const Connection(
          id: 'c1',
          kind: ConnectionKind.longbridge,
          label: 'LB',
          status: ConnectionStatus.ok,
          credentialMode: CredentialMode.e2e,
        ),
      );
      expect(created.id, 'c1');
      expect((await repo.list()).single.kind, ConnectionKind.longbridge);

      final updated = await repo.updateMode('c1', CredentialMode.serverKey);
      expect(updated.credentialMode, CredentialMode.serverKey);

      final cachedRepo = ConnectionsRepositoryImpl(
        db: db,
        firestore: _FailingFirestoreClient(),
        userId: 'u1',
      );
      final cachedList = await cachedRepo.list();
      expect(cachedList, isNotEmpty);

      await repo.remove('c1');
      expect(await repo.list(), isEmpty);
      await db.close();
    });

    test('FxRepositoryImpl serves network then cached fallback and watchRates',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      var fail = false;
      final backend = _backendFromMock((req) async {
        if (fail) return http.Response('{"message":"down"}', 503);
        expect(req.url.path, '/v1/fx');
        return http.Response(
          jsonEncode({
            'base': 'USD',
            'quote': 'HKD',
            'rate': 7.8,
            'timestamp': DateTime.utc(2026).toIso8601String(),
          }),
          200,
        );
      });
      final repo = FxRepositoryImpl(db: db, backend: backend);
      final seen = <FxRate>[];
      final sub =
          repo.watchRates([(base: 'USD', quote: 'HKD')]).listen(seen.add);

      final first = await repo.getRate(base: 'USD', quote: 'HKD');
      expect(first?.rate, 7.8);
      fail = true;
      final cached = await repo.getRate(base: 'USD', quote: 'HKD');
      expect(cached?.rate, 7.8);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(seen, isNotEmpty);
      await sub.cancel();
      await repo.dispose();
      await db.close();
    });

    test('TransactionsRepositoryImpl serves network then cached fallback',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      var fail = false;
      final backend = _backendFromMock((_) async {
        if (fail) return http.Response('{"message":"down"}', 502);
        return http.Response(
          jsonEncode([
            {
              'id': 't1',
              'sourceId': 'ibkr',
              'time': DateTime.utc(2026).toIso8601String(),
              'type': 'buy',
              'symbol': 'AAPL',
              'quantity': 1,
              'price': 100,
              'currency': 'USD',
              'fee': 1,
            },
          ]),
          200,
        );
      });
      final repo = TransactionsRepositoryImpl(
        db: db,
        backend: backend,
        connections: const _StaticConnectionsRepository(<Connection>[]),
        wrappedCredentialsBuilder: _NoopWrappedCredentialsBuilder(),
      );
      final list1 = await repo.list(
        sourceId: 'ibkr',
        range: DateRange(
          start: DateTime.utc(2025),
          end: DateTime.utc(2027),
        ),
      );
      expect(list1, hasLength(1));
      fail = true;
      final list2 = await repo.list(sourceId: 'ibkr');
      expect(list2, hasLength(1));
      expect(list2.single.id, 't1');
      await db.close();
    });

    test('PortfolioRepositoryImpl serves network and falls back to cache',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      var fail = false;
      final backend = _backendFromMock((_) async {
        if (fail) return http.Response('{"message":"down"}', 500);
        return http.Response(
          jsonEncode({
            'asOf': DateTime.utc(2026).toIso8601String(),
            'baseCurrency': 'USD',
            'positions': [
              {
                'sourceId': 'ibkr',
                'symbol': 'AAPL',
                'name': 'Apple',
                'assetClass': 'equity',
                'quantity': 1,
                'avgCost': 100,
                'currentPrice': 120,
                'currency': 'USD',
                'marketValue': 120,
                'unrealizedPnl': 20,
              },
            ],
            'cashBalances': const <Map<String, dynamic>>[],
            'totalsBySource': {'ibkr': 120},
            'totalsByCurrency': {'USD': 120},
            'totalBaseValue': 120,
            'totalUnrealizedPnlBase': 20,
          }),
          200,
        );
      });
      final repo = PortfolioRepositoryImpl(
        db: db,
        backend: backend,
        connections: const _StaticConnectionsRepository(<Connection>[]),
        wrappedCredentialsBuilder: _NoopWrappedCredentialsBuilder(),
      );

      final fresh = await repo.getSnapshot(baseCurrency: 'USD');
      expect(fresh.positions, hasLength(1));
      fail = true;
      final cached = await repo.getSnapshot(baseCurrency: 'USD');
      expect(cached.positions, isNotEmpty);

      await repo.dispose();
      await db.close();
    });

    test('PortfolioRepositoryImpl forwards wrapped credential headers',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      late http.Request seen;
      final backend = _backendFromMock((req) async {
        seen = req;
        return http.Response(
          jsonEncode({
            'asOf': DateTime.utc(2026).toIso8601String(),
            'baseCurrency': 'USD',
            'positions': const <Map<String, dynamic>>[],
            'cashBalances': const <Map<String, dynamic>>[],
            'totalsBySource': const <String, double>{},
            'totalsByCurrency': const <String, double>{},
            'totalBaseValue': 0,
            'totalUnrealizedPnlBase': 0,
          }),
          200,
        );
      });
      final repo = PortfolioRepositoryImpl(
        db: db,
        backend: backend,
        connections: const _StaticConnectionsRepository(<Connection>[
          Connection(
            id: 'c1',
            kind: ConnectionKind.longbridge,
            label: 'LB',
            status: ConnectionStatus.ok,
            credentialMode: CredentialMode.e2e,
          ),
        ]),
        wrappedCredentialsBuilder: _FixedWrappedCredentialsBuilder(
          tokens: const <String, String>{'c1': 'wrapped-token'},
          keyBytes: const <int>[1, 2, 3],
        ),
      );

      await repo.getSnapshot(baseCurrency: 'USD');

      expect(
        seen.headers[BackendClient.mbpCredsHeader],
        isNotNull,
      );
      expect(
        seen.headers[BackendClient.mbpCredsKeyHeader],
        base64Encode(const <int>[1, 2, 3]),
      );
      await repo.dispose();
      await db.close();
    });

    test('PortfolioRepositoryImpl surfaces wrapped credential build errors',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      final backend = _backendFromMock((_) async {
        return http.Response(
          jsonEncode({
            'asOf': DateTime.utc(2026).toIso8601String(),
            'baseCurrency': 'USD',
            'positions': const <Map<String, dynamic>>[],
            'cashBalances': const <Map<String, dynamic>>[],
            'source_health': const <Map<String, String>>[
              <String, String>{
                'source_id': 'ibkr',
                'status': 'ok',
              },
            ],
            'totalsBySource': const <String, double>{},
            'totalsByCurrency': const <String, double>{},
            'totalBaseValue': 0,
            'totalUnrealizedPnlBase': 0,
          }),
          200,
        );
      });
      final repo = PortfolioRepositoryImpl(
        db: db,
        backend: backend,
        connections: const _StaticConnectionsRepository(<Connection>[
          Connection(
            id: 'c1',
            kind: ConnectionKind.longbridge,
            label: 'LB',
            status: ConnectionStatus.ok,
            credentialMode: CredentialMode.e2e,
          ),
        ]),
        wrappedCredentialsBuilder: _FixedWrappedCredentialsBuilder(
          tokens: const <String, String>{},
          errors: const <String, String>{
            'c1': 'Unable to prepare credentials',
          },
        ),
      );

      final snapshot = await repo.getSnapshot(baseCurrency: 'USD');

      expect(snapshot.sourceHealth, hasLength(2));
      expect(snapshot.sourceHealth[0].sourceId, 'ibkr');
      expect(snapshot.sourceHealth[0].status, ConnectionStatus.ok);
      expect(snapshot.sourceHealth[1].sourceId, 'c1');
      expect(snapshot.sourceHealth[1].status, ConnectionStatus.error);
      expect(snapshot.sourceHealth[1].code, 'credential_wrap_failed');
      expect(snapshot.sourceHealth[1].message, 'Unable to prepare credentials');
      await repo.dispose();
      await db.close();
    });

    test('QuotesRepositoryImpl maps stream payloads and disposes source',
        () async {
      final fake = _FakeQuotesStream();
      final repo = QuotesRepositoryImpl(streamFactory: () => fake);
      final out = <PriceQuote>[];
      final sub = repo.streamQuotes(['AAPL']).listen(out.add);
      fake.emit({
        'symbol': 'AAPL',
        'price': 123,
        'currency': 'USD',
        'timestamp': DateTime.utc(2026).toIso8601String(),
      });
      fake.emit({'bad': 'payload'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(fake.lastSubscribed, ['AAPL']);
      expect(out, hasLength(1));
      expect(out.single.symbol, 'AAPL');
      expect(fake.disposed, isTrue);
    });

    test('TransactionsRepositoryImpl forwards wrapped credential headers',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      late http.Request seen;
      final backend = _backendFromMock((req) async {
        seen = req;
        return http.Response('[]', 200);
      });
      final repo = TransactionsRepositoryImpl(
        db: db,
        backend: backend,
        connections: const _StaticConnectionsRepository(<Connection>[
          Connection(
            id: 'c1',
            kind: ConnectionKind.binance,
            label: 'BN',
            status: ConnectionStatus.ok,
            credentialMode: CredentialMode.e2e,
          ),
        ]),
        wrappedCredentialsBuilder: _FixedWrappedCredentialsBuilder(
          tokens: const <String, String>{'c1': 'wrapped-token'},
          keyBytes: const <int>[9, 8, 7],
        ),
      );

      await repo.list();
      expect(seen.headers[BackendClient.mbpCredsHeader], isNotNull);
      expect(
        seen.headers[BackendClient.mbpCredsKeyHeader],
        base64Encode(const <int>[9, 8, 7]),
      );
      await db.close();
    });
  });
}

BackendClient _backendFromMock(
  Future<http.Response> Function(http.Request request) handler,
) {
  return BackendClient(
    config: BackendConfig(baseUrl: Uri.parse('https://api.example.com/v1')),
    tokenProvider: () async => 't',
    httpClient: MockClient(handler),
  );
}

class _FailingFirestoreClient implements FirestoreClient {
  @override
  Future<void> deleteAlert(String userId, String alertId) =>
      Future<void>.error(StateError('offline'));

  @override
  Future<void> deleteConnection(String userId, String connectionId) =>
      Future<void>.error(StateError('offline'));

  @override
  Future<void> deleteManualHolding(String userId, String holdingId) =>
      Future<void>.error(StateError('offline'));

  @override
  Future<String?> getEncryptedCredential(String userId, String connectionId) =>
      Future<String?>.error(StateError('offline'));

  @override
  Future<Map<String, dynamic>?> getUserSettings(String userId) =>
      Future<Map<String, dynamic>?>.error(StateError('offline'));

  @override
  Future<List<Map<String, dynamic>>> listAlerts(String userId) =>
      Future<List<Map<String, dynamic>>>.error(StateError('offline'));

  @override
  Future<List<Map<String, dynamic>>> listConnections(String userId) =>
      Future<List<Map<String, dynamic>>>.error(StateError('offline'));

  @override
  Future<List<Map<String, dynamic>>> listDeviceTokens(String userId) =>
      Future<List<Map<String, dynamic>>>.error(StateError('offline'));

  @override
  Future<List<Map<String, dynamic>>> listManualHoldings(String userId) =>
      Future<List<Map<String, dynamic>>>.error(StateError('offline'));

  @override
  Future<void> setEncryptedCredential(
    String userId,
    String connectionId,
    String encodedBlob,
  ) =>
      Future<void>.error(StateError('offline'));

  @override
  Future<void> setUserSettings(String userId, Map<String, dynamic> data) =>
      Future<void>.error(StateError('offline'));

  @override
  Future<void> upsertAlert(
    String userId,
    String alertId,
    Map<String, dynamic> data,
  ) =>
      Future<void>.error(StateError('offline'));

  @override
  Future<void> upsertConnection(
    String userId,
    String connectionId,
    Map<String, dynamic> data,
  ) =>
      Future<void>.error(StateError('offline'));

  @override
  Future<void> upsertDeviceToken(
    String userId,
    String token, {
    required String platform,
    required String appVersion,
    DateTime? lastSeen,
  }) =>
      Future<void>.error(StateError('offline'));

  @override
  Future<void> upsertManualHolding(
    String userId,
    String holdingId,
    Map<String, dynamic> data,
  ) =>
      Future<void>.error(StateError('offline'));

  @override
  Future<void> deleteDeviceToken(String userId, String token) =>
      Future<void>.error(StateError('offline'));

  @override
  Stream<List<Map<String, dynamic>>> watchAlerts(String userId) =>
      const Stream<List<Map<String, dynamic>>>.empty();

  @override
  Stream<List<Map<String, dynamic>>> watchConnections(String userId) =>
      const Stream<List<Map<String, dynamic>>>.empty();

  @override
  Stream<List<Map<String, dynamic>>> watchManualHoldings(String userId) =>
      const Stream<List<Map<String, dynamic>>>.empty();

  @override
  Stream<Map<String, dynamic>?> watchUserSettings(String userId) =>
      const Stream<Map<String, dynamic>?>.empty();
}

class _StaticConnectionsRepository implements ConnectionsRepository {
  const _StaticConnectionsRepository(this.items);

  final List<Connection> items;

  @override
  Future<Connection> add(Connection connection) {
    throw UnimplementedError();
  }

  @override
  Future<List<Connection>> list() async => items;

  @override
  Future<void> remove(String connectionId) {
    throw UnimplementedError();
  }

  @override
  Future<void> setCredentials(String connectionId, String encryptedBlob) {
    throw UnimplementedError();
  }

  @override
  Future<Connection> updateMode(String connectionId, CredentialMode mode) {
    throw UnimplementedError();
  }
}

class _NoopWrappedCredentialsBuilder extends WrappedCredentialsBuilder {
  _NoopWrappedCredentialsBuilder()
      : super(
          firestore: InMemoryFirestoreClient(),
          userId: 'u1',
          readCredentialKey: () => null,
          crypto: E2eCrypto.withKdf(pbkdf2Test(iterations: 1)),
        );

  @override
  Future<WrappedCredentialsBuildResult> buildForConnections(
    Iterable<Connection> connections,
  ) async {
    return const WrappedCredentialsBuildResult(
      tokensByConnection: <String, String>{},
      errorsByConnection: <String, String>{},
    );
  }
}

class _FixedWrappedCredentialsBuilder extends WrappedCredentialsBuilder {
  _FixedWrappedCredentialsBuilder({
    required this.tokens,
    this.errors = const <String, String>{},
    this.keyBytes = const <int>[],
  }) : super(
          firestore: InMemoryFirestoreClient(),
          userId: 'u1',
          readCredentialKey: () => null,
          crypto: E2eCrypto.withKdf(pbkdf2Test(iterations: 1)),
        );

  final Map<String, String> tokens;
  final Map<String, String> errors;
  final List<int> keyBytes;

  @override
  Future<WrappedCredentialsBuildResult> buildForConnections(
    Iterable<Connection> connections,
  ) async {
    return WrappedCredentialsBuildResult(
      tokensByConnection: tokens,
      errorsByConnection: errors,
      keyBytes: keyBytes,
    );
  }
}

class _FakeQuotesStream implements QuotesStream {
  final StreamController<Map<String, dynamic>> _ctrl =
      StreamController<Map<String, dynamic>>.broadcast();

  List<String> lastSubscribed = const [];
  bool disposed = false;

  void emit(Map<String, dynamic> msg) => _ctrl.add(msg);

  @override
  void addSymbols(Iterable<String> symbols) {}

  @override
  BackendClient get client =>
      _backendFromMock((_) async => http.Response('', 200));

  @override
  QuotesHandshakeProvider? get handshakeProvider => null;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _ctrl.close();
  }

  @override
  Duration get initialBackoff => const Duration(milliseconds: 1);

  @override
  int? get maxReconnectAttempts => null;

  @override
  Duration get maxBackoff => const Duration(milliseconds: 1);

  @override
  void removeSymbols(Iterable<String> symbols) {}

  @override
  Stream<Map<String, dynamic>> get stream => _ctrl.stream;

  @override
  void subscribe(Iterable<String> symbols) {
    lastSubscribed = symbols.toList(growable: false);
  }
}
