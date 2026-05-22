import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_broker_portfolio/app_lock/app_lock.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';
import 'package:multi_broker_portfolio/logging/logger.dart';
import 'package:multi_broker_portfolio/state/state.dart';

void main() {
  group('authProvider', () {
    test('exposes current user and supports sign-in/sign-out', () async {
      final repo = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          notificationLifecycleProvider.overrideWithValue(
            _NoopNotificationLifecycle(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(repo.dispose);

      expect(await container.read(authProvider.future), isNull);

      await container
          .read(authProvider.notifier)
          .signIn(email: 'u@example.com', password: 'pw');
      expect(container.read(authProvider).value?.email, 'u@example.com');

      await container.read(authProvider.notifier).signOut();
      expect(container.read(authProvider).value, isNull);
    });

    test('surfaces sign-in failures', () async {
      final repo = _FakeAuthRepository(failSignIn: true);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          notificationLifecycleProvider.overrideWithValue(
            _NoopNotificationLifecycle(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(repo.dispose);

      await expectLater(
        () => container
            .read(authProvider.notifier)
            .signIn(email: 'u@example.com', password: 'pw'),
        throwsStateError,
      );
      expect(container.read(authProvider).hasError, isTrue);
    });

    test('supports sign-up and surfaces sign-out failures', () async {
      final repo = _FakeAuthRepository(failSignOut: true);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          notificationLifecycleProvider.overrideWithValue(
            _NoopNotificationLifecycle(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(repo.dispose);

      final created = await container
          .read(authProvider.notifier)
          .signUp(email: 'u2@example.com', password: 'pw');
      expect(created.email, 'u2@example.com');

      await expectLater(
        () => container.read(authProvider.notifier).signOut(),
        throwsStateError,
      );
      expect(container.read(authProvider).hasError, isTrue);
    });
  });

  group('settingsProvider', () {
    test('loads and updates settings', () async {
      final repo = _FakeSettingsRepository();
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(repo.dispose);

      final initial = await container.read(settingsProvider.future);
      expect(initial.themeMode, AppThemeMode.system);
      expect(initial.baseCurrency, 'USD');

      await container
          .read(settingsProvider.notifier)
          .setThemeMode(AppThemeMode.dark);
      await container.read(settingsProvider.notifier).setLocale('zh-Hant');
      await container.read(settingsProvider.notifier).setBaseCurrency('HKD');
      await container
          .read(settingsProvider.notifier)
          .setCurrencyMode(CurrencyMode.native);

      final next = container.read(settingsProvider).value!;
      expect(next.themeMode, AppThemeMode.dark);
      expect(next.locale, 'zh-Hant');
      expect(next.baseCurrency, 'HKD');
      expect(next.currencyMode, CurrencyMode.native);
    });

    test('reacts to watchChanges and compares by value', () async {
      final repo = _FakeSettingsRepository();
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(repo.dispose);

      final loaded = await container.read(settingsProvider.future);
      const expected = AppSettings(
        themeMode: AppThemeMode.system,
        locale: null,
        baseCurrency: 'USD',
        currencyMode: CurrencyMode.base,
      );
      expect(loaded, equals(expected));
      expect(loaded.hashCode, expected.hashCode);

      await repo.setBaseCurrency('JPY');
      await Future<void>.delayed(Duration.zero);
      expect(container.read(settingsProvider).value?.baseCurrency, 'JPY');
    });
  });

  group('connectionsProvider', () {
    test('lists connections and computes health map', () async {
      final repo = _FakeConnectionsRepository([
        _connection(id: 'lb', status: ConnectionStatus.ok),
      ]);
      final container = ProviderContainer(
        overrides: [
          connectionsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(connectionsProvider.future);
      expect(state.connections, hasLength(1));
      expect(state.healthBySource['lb'], ConnectionStatus.ok);

      await container.read(connectionsProvider.notifier).add(
            _connection(id: 'ib', status: ConnectionStatus.error),
          );
      await container
          .read(connectionsProvider.notifier)
          .updateMode('ib', CredentialMode.serverKey);
      await container.read(connectionsProvider.notifier).remove('lb');

      final after = container.read(connectionsProvider).value!;
      expect(after.connections.map((c) => c.id), ['ib']);
      expect(after.connections.single.credentialMode, CredentialMode.serverKey);
      expect(after.healthBySource['ib'], ConnectionStatus.error);
    });

    test('refreshes and deep equality works', () async {
      final repo = _FakeConnectionsRepository([
        _connection(id: 'lb', status: ConnectionStatus.ok),
      ]);
      final container = ProviderContainer(
        overrides: [
          connectionsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(connectionsProvider.future);
      await repo.add(_connection(id: 'ib', status: ConnectionStatus.disabled));
      await container.read(connectionsProvider.notifier).refresh();

      final current = container.read(connectionsProvider).value!;
      final rebuilt = ConnectionsState.fromConnections(current.connections);
      expect(current, equals(rebuilt));
      expect(current.hashCode, rebuilt.hashCode);
      expect(current.connections, hasLength(2));
    });
  });

  group('portfolioProvider', () {
    test('returns aggregated snapshot and refreshes', () async {
      final settingsRepo = _FakeSettingsRepository();
      final portfolioRepo =
          _FakePortfolioRepository(_snapshot(base: 'USD', total: 1000));
      final manualRepo = _FakeManualHoldingsRepository([
        const ManualHolding(
          id: 'm1',
          label: 'Manual',
          assetClass: AssetClass.cash,
          quantity: 1,
          valueCurrency: 'USD',
          valueAmount: 200,
        ),
      ]);
      final fxRepo = _FakeFxRepository(const {'HKD/USD': 0.1282});
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          portfolioRepositoryProvider.overrideWithValue(portfolioRepo),
          manualHoldingsRepositoryProvider.overrideWithValue(manualRepo),
          fxRepositoryProvider.overrideWithValue(fxRepo),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(settingsRepo.dispose);

      final snapshot = await container.read(portfolioProvider.future);
      expect(snapshot.totalBaseValue, 1200);
      expect(
        snapshot.positions.where((p) => p.sourceId == 'manual'),
        hasLength(1),
      );
      // Initial load uses the cached repo path (no network call), so
      // getSnapshot has not been hit yet.
      expect(portfolioRepo.calls, 0);

      await container.read(portfolioProvider.notifier).refresh();
      // refresh() is the network path → exactly one call.
      expect(portfolioRepo.calls, 1);
    });
  });

  group('quotesProvider', () {
    test('streams per-symbol quotes', () async {
      final repo = _FakeQuotesRepository();
      final container = ProviderContainer(
        overrides: [
          quotesRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(repo.dispose);

      final updates = <AsyncValue<PriceQuote>>[];
      final sub = container.listen<AsyncValue<PriceQuote>>(
        quotesProvider('AAPL'),
        (prev, next) => updates.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      repo.emit(
        PriceQuote(
          symbol: 'AAPL',
          price: 188.1,
          currency: 'USD',
          timestamp: DateTime.utc(2026, 1, 1),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final latest = updates.last;
      expect(latest.value?.symbol, 'AAPL');
      expect(latest.value?.price, 188.1);
    });
  });

  group('transactionsProvider', () {
    test('paginates and filters transactions', () async {
      final now = DateTime.now().toUtc();
      final txs = List<Transaction>.generate(60, (i) {
        return Transaction(
          id: 't$i',
          sourceId: i.isEven ? 'lb' : 'ib',
          time: now.subtract(Duration(days: i)),
          type: i.isEven ? TransactionType.buy : TransactionType.sell,
          symbol: i.isEven ? 'AAPL' : 'TSLA',
          quantity: 1,
          price: 10,
          currency: 'USD',
          fee: 0,
        );
      });
      final repo = _FakeTransactionsRepository(txs);
      final container = ProviderContainer(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final firstPage = await container.read(transactionsProvider.future);
      expect(firstPage.totalCount, inInclusiveRange(30, 31));
      expect(firstPage.hasMore, isFalse);

      await container.read(transactionsProvider.notifier).applyFilters(
            range: DateRange(start: now.subtract(const Duration(days: 90)), end: now),
          );
      final paged = container.read(transactionsProvider).value!;
      expect(paged.items, hasLength(50));
      expect(paged.hasMore, isTrue);

      await container.read(transactionsProvider.notifier).loadNextPage();
      final secondPage = container.read(transactionsProvider).value!;
      expect(secondPage.items, hasLength(60));
      expect(secondPage.hasMore, isFalse);

      await container.read(transactionsProvider.notifier).applyFilters(
            sourceId: 'lb',
            type: TransactionType.buy,
            range: DateRange(start: now.subtract(const Duration(days: 9)), end: now),
          );
      final filtered = container.read(transactionsProvider).value!;
      expect(filtered.items.every((tx) => tx.sourceId == 'lb'), isTrue);
      expect(
        filtered.items.every((tx) => tx.type == TransactionType.buy),
        isTrue,
      );
      expect(filtered.totalCount, 5);
    });
  });

  group('alertsProvider', () {
    test('supports CRUD and trigger history', () async {
      final repo = _FakeAlertsRepository([
        const Alert(
          id: 'a1',
          kind: AlertKind.priceAbove,
          scope: AlertScope.symbol('AAPL'),
          threshold: 100,
          active: true,
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          alertsRepositoryProvider.overrideWithValue(repo),
          notificationLifecycleProvider.overrideWithValue(
            _NoopNotificationLifecycle(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(alertsProvider.future);
      expect(initial.alerts, hasLength(1));

      await container.read(alertsProvider.notifier).create(
            const Alert(
              id: 'a2',
              kind: AlertKind.pnlPctAbove,
              scope: AlertScope.portfolio(),
              threshold: 5,
              active: true,
            ),
          );
      await container.read(alertsProvider.notifier).updateAlert(
            const Alert(
              id: 'a2',
              kind: AlertKind.pnlPctAbove,
              scope: AlertScope.portfolio(),
              threshold: 6,
              active: true,
            ),
          );

      final triggered =
          await container.read(alertsProvider.notifier).evaluateAndRecord(
                'a1',
                quote: PriceQuote(
                  symbol: 'AAPL',
                  price: 120,
                  currency: 'USD',
                  timestamp: DateTime.utc(2026, 1, 1),
                ),
              );
      expect(triggered, isTrue);
      expect(
        container.read(alertsProvider).value!.triggerHistory,
        hasLength(1),
      );

      await container.read(alertsProvider.notifier).delete('a1');
      expect(
        container.read(alertsProvider).value!.alerts.map((a) => a.id),
        ['a2'],
      );

      final missing =
          await container.read(alertsProvider.notifier).evaluateAndRecord(
                'missing',
                quote: PriceQuote(
                  symbol: 'AAPL',
                  price: 10,
                  currency: 'USD',
                  timestamp: DateTime.utc(2026, 1, 1),
                ),
              );
      expect(missing, isFalse);

      await container.read(alertsProvider.notifier).refresh();
      container.read(alertsProvider.notifier).clearTriggerHistory();
      expect(container.read(alertsProvider).value!.triggerHistory, isEmpty);
    });
  });

  group('manualHoldingsProvider', () {
    test('supports CRUD operations', () async {
      final repo = _FakeManualHoldingsRepository([]);
      final container = ProviderContainer(
        overrides: [
          manualHoldingsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(manualHoldingsProvider.future);

      await container.read(manualHoldingsProvider.notifier).create(
            const ManualHolding(
              id: 'm1',
              label: 'Cash',
              assetClass: AssetClass.cash,
              quantity: 1,
              valueCurrency: 'USD',
              valueAmount: 500,
            ),
          );
      await container.read(manualHoldingsProvider.notifier).updateHolding(
            const ManualHolding(
              id: 'm1',
              label: 'Cash+',
              assetClass: AssetClass.cash,
              quantity: 1,
              valueCurrency: 'USD',
              valueAmount: 600,
            ),
          );
      await container.read(manualHoldingsProvider.notifier).delete('m1');
      await container.read(manualHoldingsProvider.notifier).refresh();

      expect(container.read(manualHoldingsProvider).value, isEmpty);
    });
  });

  group('fxProvider', () {
    test('caches lookups and updates from stream', () async {
      final repo = _FakeFxRepository(const {'USD/HKD': 7.8});
      final container = ProviderContainer(
        overrides: [
          fxRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(repo.dispose);

      final controller = container.read(fxProvider.notifier);
      final first = await controller.lookup(base: 'USD', quote: 'HKD');
      final second = await controller.lookup(base: 'USD', quote: 'HKD');

      expect(first?.rate, 7.8);
      expect(second?.rate, 7.8);
      expect(repo.getRateCalls, 1);

      controller.watchPairs(const [FxPair(base: 'USD', quote: 'HKD')]);
      repo.emit(
        FxRate(
          base: 'USD',
          quote: 'HKD',
          rate: 7.9,
          timestamp: DateTime.utc(2026, 1, 2),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(fxProvider);
      expect(state.rateFor('USD', 'HKD')?.rate, 7.9);
      expect(state.rateFor('HKD', 'USD')?.rate, closeTo(1 / 7.9, 1e-9));
    });
  });

  group('appLockProvider', () {
    test('tracks lock state and supports pin unlock + failure counting',
        () async {
      final store = InMemoryAppLockStore();
      const hasher = Sha256PinHasher();
      await store.writePinHash(await hasher.hash('1234'));
      await store.writeSettings(
        const AppLockSettings(
          enabled: true,
          biometricEnabled: false,
          timeout: Duration(seconds: 30),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          appLockStoreProvider.overrideWithValue(store),
          appLockBiometricAuthenticatorProvider
              .overrideWithValue(_FakeBiometricAuthenticator()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appLockProvider.future);
      final notifier = container.read(appLockProvider.notifier);
      expect(container.read(appLockProvider).value?.isLocked, isTrue);

      final unlocked = await notifier.unlockWithPin('1234');
      expect(unlocked, isTrue);
      expect(container.read(appLockProvider).value?.isLocked, isFalse);

      await notifier.lock();
      await notifier.unlockWithPin('0000');
      await notifier.unlockWithPin('0000');
      expect(container.read(appLockProvider).value?.failedAttempts, 2);
      expect(container.read(appLockProvider).value?.isLocked, isTrue);
    });
  });

  group('provider observers', () {
    test('enabled only in non-release builds', () {
      expect(buildProviderObservers(releaseMode: true), isEmpty);
      expect(buildProviderObservers(releaseMode: false), hasLength(1));
    });

    test('logs provider failures through AppLogger', () {
      AppLogger.instance.init();
      AppLogger.instance.clearBuffer();
      AppLogger.instance.clearSinks();

      final records = <AppLogRecord>[];
      AppLogger.instance.addSink(records.add);

      final observers = buildProviderObservers(
        logger: AppLogger.instance,
        releaseMode: false,
      );
      final container = ProviderContainer(observers: observers);
      addTearDown(container.dispose);

      final boomProvider = Provider<int>((_) => throw StateError('boom'));
      expect(() => container.read(boomProvider), throwsStateError);
      expect(records.any((r) => r.level == AppLogLevel.error), isTrue);
    });

    test('logs didUpdate provider events', () {
      AppLogger.instance.init();
      AppLogger.instance.clearBuffer();
      AppLogger.instance.clearSinks();

      final records = <AppLogRecord>[];
      AppLogger.instance.addSink(records.add);

      final observer = RiverpodLoggingObserver(AppLogger.instance);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = Provider<int>(
        (ref) => 1,
        name: 'counter',
      );
      observer.didUpdateProvider(provider, 0, 1, container);
      observer.didUpdateProvider(
        provider,
        1,
        const AsyncError<int>('oops', StackTrace.empty),
        container,
      );

      expect(records.any((r) => r.level == AppLogLevel.debug), isTrue);
      expect(records.any((r) => r.level == AppLogLevel.warning), isTrue);
    });
  });

  // Repository providers used to throw UnimplementedError stubs that the
  // caller had to override. They're now wired to real implementations
  // (SettingsRepositoryImpl, ConnectionsRepositoryImpl, etc.) that depend
  // on Firebase + Drift, so this group is obsolete. End-to-end wiring is
  // covered by presentation_smoke_test.dart and manual smoke tests.
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.failSignIn = false,
    this.failSignOut = false,
  });

  final bool failSignIn;
  final bool failSignOut;
  AuthUser? _user;
  final StreamController<AuthUser?> _ctrl =
      StreamController<AuthUser?>.broadcast();

  @override
  Future<AuthUser?> currentUser() async => _user;

  @override
  Stream<AuthUser?> watchUser() async* {
    yield _user;
    yield* _ctrl.stream;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    if (failSignIn) throw StateError('sign-in failed');
    _user = AuthUser(uid: 'uid-$email', email: email);
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<AuthUser> signUp({required String email, required String password}) {
    return signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    if (failSignOut) throw StateError('sign-out failed');
    _user = null;
    _ctrl.add(null);
  }

  Future<void> dispose() async {
    await _ctrl.close();
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  AppThemeMode _themeMode = AppThemeMode.system;
  String? _locale;
  String _baseCurrency = 'USD';
  CurrencyMode _currencyMode = CurrencyMode.base;
  final StreamController<void> _ctrl = StreamController<void>.broadcast();

  @override
  Future<AppThemeMode> getThemeMode() async => _themeMode;

  @override
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    _ctrl.add(null);
  }

  @override
  Future<String?> getLocale() async => _locale;

  @override
  Future<void> setLocale(String? locale) async {
    _locale = locale;
    _ctrl.add(null);
  }

  @override
  Future<String> getBaseCurrency() async => _baseCurrency;

  @override
  Future<void> setBaseCurrency(String currency) async {
    _baseCurrency = currency;
    _ctrl.add(null);
  }

  @override
  Future<CurrencyMode> getCurrencyMode() async => _currencyMode;

  @override
  Future<void> setCurrencyMode(CurrencyMode mode) async {
    _currencyMode = mode;
    _ctrl.add(null);
  }

  @override
  Stream<void> watchChanges() => _ctrl.stream;

  Future<void> dispose() async {
    await _ctrl.close();
  }
}

class _FakeConnectionsRepository implements ConnectionsRepository {
  _FakeConnectionsRepository(List<Connection> seed)
      : _items = List<Connection>.from(seed);

  final List<Connection> _items;

  @override
  Future<List<Connection>> list() async =>
      List<Connection>.unmodifiable(_items);

  @override
  Future<Connection> add(Connection connection) async {
    _items.add(connection);
    return connection;
  }

  @override
  Future<void> setCredentials(String connectionId, String encryptedBlob) async {}

  @override
  Future<void> remove(String connectionId) async {
    _items.removeWhere((connection) => connection.id == connectionId);
  }

  @override
  Future<Connection> updateMode(
    String connectionId,
    CredentialMode mode,
  ) async {
    final index =
        _items.indexWhere((connection) => connection.id == connectionId);
    if (index == -1) {
      final fallback = _connection(
        id: connectionId,
        status: ConnectionStatus.unknown,
        mode: mode,
      );
      _items.add(fallback);
      return fallback;
    }
    _items[index] = _items[index].copyWith(credentialMode: mode);
    return _items[index];
  }
}

class _FakePortfolioRepository implements PortfolioRepository {
  _FakePortfolioRepository(this.snapshot);

  final PortfolioSnapshot snapshot;
  int calls = 0;

  @override
  Future<PortfolioSnapshot> getSnapshot({required String baseCurrency}) async {
    calls += 1;
    return snapshot.copyWith(baseCurrency: baseCurrency);
  }

  @override
  Future<PortfolioSnapshot> getCachedSnapshot({
    required String baseCurrency,
  }) async {
    return snapshot.copyWith(baseCurrency: baseCurrency);
  }

  @override
  Stream<PortfolioSnapshot> watchSnapshot({required String baseCurrency}) {
    return Stream<PortfolioSnapshot>.value(
      snapshot.copyWith(baseCurrency: baseCurrency),
    );
  }
}

class _FakeQuotesRepository implements QuotesRepository {
  final StreamController<PriceQuote> _ctrl =
      StreamController<PriceQuote>.broadcast();

  void emit(PriceQuote quote) => _ctrl.add(quote);

  @override
  Stream<PriceQuote> streamQuotes(List<String> symbols) {
    final wanted = symbols.toSet();
    return _ctrl.stream.where((quote) => wanted.contains(quote.symbol));
  }

  Future<void> dispose() async {
    await _ctrl.close();
  }
}

class _FakeTransactionsRepository implements TransactionsRepository {
  _FakeTransactionsRepository(this._all);

  final List<Transaction> _all;

  @override
  Future<List<Transaction>> list({String? sourceId, DateRange? range}) async {
    return _all.where((tx) {
      if (sourceId != null && tx.sourceId != sourceId) return false;
      if (range != null && !range.contains(tx.time)) return false;
      return true;
    }).toList(growable: false);
  }
}

class _FakeAlertsRepository implements AlertsRepository {
  _FakeAlertsRepository(List<Alert> seed) : _items = List<Alert>.from(seed);

  final List<Alert> _items;

  @override
  Future<List<Alert>> list() async => List<Alert>.unmodifiable(_items);

  @override
  Future<Alert> create(Alert alert) async {
    _items.add(alert);
    return alert;
  }

  @override
  Future<Alert> update(Alert alert) async {
    final index = _items.indexWhere((existing) => existing.id == alert.id);
    if (index >= 0) _items[index] = alert;
    return alert;
  }

  @override
  Future<void> delete(String alertId) async {
    _items.removeWhere((alert) => alert.id == alertId);
  }

  @override
  bool evaluateLocal(
    Alert alert, {
    PriceQuote? quote,
    PortfolioSnapshot? snapshot,
  }) {
    return const EvaluateAlert().call(alert, quote: quote, snapshot: snapshot);
  }
}

class _FakeManualHoldingsRepository implements ManualHoldingsRepository {
  _FakeManualHoldingsRepository(List<ManualHolding> seed)
      : _items = List<ManualHolding>.from(seed);

  final List<ManualHolding> _items;

  @override
  Future<List<ManualHolding>> list() async =>
      List<ManualHolding>.unmodifiable(_items);

  @override
  Future<ManualHolding> create(ManualHolding holding) async {
    _items.add(holding);
    return holding;
  }

  @override
  Future<ManualHolding> update(ManualHolding holding) async {
    final index = _items.indexWhere((existing) => existing.id == holding.id);
    if (index >= 0) _items[index] = holding;
    return holding;
  }

  @override
  Future<void> delete(String holdingId) async {
    _items.removeWhere((holding) => holding.id == holdingId);
  }
}

class _FakeFxRepository implements FxRepository {
  _FakeFxRepository(Map<String, double> seed)
      : _rates = Map<String, double>.from(seed);

  final Map<String, double> _rates;
  int getRateCalls = 0;
  final StreamController<FxRate> _ctrl = StreamController<FxRate>.broadcast();

  @override
  Future<FxRate?> getRate({required String base, required String quote}) async {
    getRateCalls += 1;
    final rate = _rates['$base/$quote'];
    if (rate == null) return null;
    return FxRate(
      base: base,
      quote: quote,
      rate: rate,
      timestamp: DateTime.utc(2026, 1, 1),
    );
  }

  @override
  Stream<FxRate> watchRates(List<({String base, String quote})> pairs) {
    return _ctrl.stream.where((rate) {
      return pairs
          .any((pair) => pair.base == rate.base && pair.quote == rate.quote);
    });
  }

  void emit(FxRate rate) {
    _rates['${rate.base}/${rate.quote}'] = rate.rate;
    _ctrl.add(rate);
  }

  Future<void> dispose() async {
    await _ctrl.close();
  }
}

class _FakeBiometricAuthenticator implements BiometricAuthenticator {
  @override
  Future<bool> authenticate({required String reason}) async => false;

  @override
  Future<bool> isAvailable() async => true;
}

class _NoopNotificationLifecycle implements NotificationLifecycle {
  @override
  Future<void> ensureInitializedForUser(String userId) async {}

  @override
  Future<void> onBeforeSignOut() async {}

  @override
  Future<void> onFirstAlertCreateAttempt() async {}
}

Connection _connection({
  required String id,
  required ConnectionStatus status,
  CredentialMode mode = CredentialMode.e2e,
}) {
  return Connection(
    id: id,
    kind: ConnectionKind.longbridge,
    label: id,
    status: status,
    credentialMode: mode,
  );
}

PortfolioSnapshot _snapshot({required String base, required double total}) {
  final position = Position.computed(
    sourceId: 'lb',
    symbol: 'AAPL',
    name: 'Apple',
    assetClass: AssetClass.stock,
    quantity: 2,
    avgCost: 100,
    currentPrice: total / 2,
    currency: base,
  );
  return PortfolioSnapshot(
    asOf: DateTime.utc(2026, 1, 1),
    baseCurrency: base,
    positions: <Position>[position],
    cashBalances: const <CashBalance>[],
    totalsBySource: <String, double>{'lb': total},
    totalsByCurrency: <String, double>{base: total},
    totalBaseValue: total,
    totalUnrealizedPnlBase: position.unrealizedPnl,
  );
}
