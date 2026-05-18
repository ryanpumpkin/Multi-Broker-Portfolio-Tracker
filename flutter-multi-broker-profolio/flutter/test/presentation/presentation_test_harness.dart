import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_broker_portfolio/app_lock/app_lock.dart';
import 'package:multi_broker_portfolio/data/crypto/e2e.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';
import 'package:multi_broker_portfolio/state/app_lock_provider.dart';
import 'package:multi_broker_portfolio/state/credential_key_provider.dart';
import 'package:multi_broker_portfolio/state/repository_providers.dart';

List<Override> buildPresentationTestOverrides() {
  return [
    authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
    connectionsRepositoryProvider
        .overrideWithValue(_FakeConnectionsRepository()),
    portfolioRepositoryProvider.overrideWithValue(_FakePortfolioRepository()),
    quotesRepositoryProvider.overrideWithValue(_FakeQuotesRepository()),
    transactionsRepositoryProvider
        .overrideWithValue(_FakeTransactionsRepository()),
    alertsRepositoryProvider.overrideWithValue(_FakeAlertsRepository()),
    manualHoldingsRepositoryProvider
        .overrideWithValue(_FakeManualHoldingsRepository()),
    fxRepositoryProvider.overrideWithValue(_FakeFxRepository()),
  ];
}

/// Overrides that bypass the credential-encryption gate so widget tests
/// can open the Add Connection dialog without setting up app-lock first.
/// Apply via the optional `overrides` parameter of [wrapForTest].
List<Override> buildAppLockUnlockedOverrides() {
  return [
    appLockProvider.overrideWith(_FakeAppLockController.new),
    credentialKeyProvider
        .overrideWith(_FakeCredentialKeyController.new),
  ];
}

class _FakeAppLockController extends AppLockController {
  @override
  Future<AppLockState> build() async {
    return const AppLockState(
      isEnabled: false,
      biometricEnabled: false,
      timeout: Duration(seconds: 30),
      isLocked: false,
      hasPin: true,
      failedAttempts: 0,
    );
  }
}

class _FakeCredentialKeyController extends CredentialKeyController {
  @override
  E2eKey? build() => E2eKey(List<int>.filled(32, 0));
}

Widget wrapForTest(
  Widget child, {
  List<Override> overrides = const <Override>[],
  Size? surfaceSize,
}) {
  final allOverrides = <Override>[
    ...buildPresentationTestOverrides(),
    ...overrides,
  ];

  final app = ProviderScope(
    overrides: allOverrides,
    child: MaterialApp(home: child),
  );

  if (surfaceSize == null) {
    return app;
  }

  return MediaQuery(
    data: MediaQueryData(size: surfaceSize),
    child: SizedBox(
      width: surfaceSize.width,
      height: surfaceSize.height,
      child: app,
    ),
  );
}

class _FakeAuthRepository implements AuthRepository {
  AuthUser? _user = const AuthUser(uid: 'u1', email: 'demo@example.com');

  @override
  Future<AuthUser?> currentUser() async => _user;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    _user = AuthUser(uid: 'u-$email', email: email);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }

  @override
  Future<AuthUser> signUp({required String email, required String password}) {
    return signIn(email: email, password: password);
  }

  @override
  Stream<AuthUser?> watchUser() async* {
    yield _user;
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  AppThemeMode _themeMode = AppThemeMode.system;
  String? _locale;
  String _baseCurrency = 'USD';
  CurrencyMode _currencyMode = CurrencyMode.base;

  @override
  Future<String> getBaseCurrency() async => _baseCurrency;

  @override
  Future<CurrencyMode> getCurrencyMode() async => _currencyMode;

  @override
  Future<String?> getLocale() async => _locale;

  @override
  Future<AppThemeMode> getThemeMode() async => _themeMode;

  @override
  Future<void> setBaseCurrency(String currency) async {
    _baseCurrency = currency;
  }

  @override
  Future<void> setCurrencyMode(CurrencyMode mode) async {
    _currencyMode = mode;
  }

  @override
  Future<void> setLocale(String? locale) async {
    _locale = locale;
  }

  @override
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
  }

  @override
  Stream<void> watchChanges() => const Stream<void>.empty();
}

class _FakeConnectionsRepository implements ConnectionsRepository {
  final List<Connection> _connections = [
    const Connection(
      id: 'lb',
      kind: ConnectionKind.longbridge,
      label: 'LongBridge',
      status: ConnectionStatus.ok,
      credentialMode: CredentialMode.e2e,
    ),
    const Connection(
      id: 'bn',
      kind: ConnectionKind.binance,
      label: 'Binance',
      status: ConnectionStatus.unknown,
      credentialMode: CredentialMode.serverKey,
    ),
  ];

  @override
  Future<Connection> add(Connection connection) async {
    _connections.add(connection);
    return connection;
  }

  @override
  Future<void> setCredentials(String connectionId, String encryptedBlob) async {}


  @override
  Future<List<Connection>> list() async =>
      List<Connection>.unmodifiable(_connections);

  @override
  Future<void> remove(String connectionId) async {
    _connections.removeWhere((c) => c.id == connectionId);
  }

  @override
  Future<Connection> updateMode(
    String connectionId,
    CredentialMode mode,
  ) async {
    final index = _connections.indexWhere((c) => c.id == connectionId);
    if (index < 0) {
      throw StateError('missing connection');
    }
    _connections[index] = _connections[index].copyWith(credentialMode: mode);
    return _connections[index];
  }
}

class _FakePortfolioRepository implements PortfolioRepository {
  @override
  Future<PortfolioSnapshot> getSnapshot({required String baseCurrency}) async {
    return PortfolioSnapshot(
      asOf: DateTime.utc(2026, 1, 1),
      baseCurrency: baseCurrency,
      positions: const [
        Position(
          sourceId: 'lb',
          symbol: 'AAPL',
          name: 'Apple',
          assetClass: AssetClass.stock,
          quantity: 5,
          avgCost: 100,
          currentPrice: 120,
          currency: 'USD',
          marketValue: 600,
          unrealizedPnl: 100,
        ),
        Position(
          sourceId: 'bn',
          symbol: 'BTC',
          name: 'Bitcoin',
          assetClass: AssetClass.crypto,
          quantity: 0.05,
          avgCost: 30000,
          currentPrice: 40000,
          currency: 'USD',
          marketValue: 2000,
          unrealizedPnl: 500,
        ),
      ],
      cashBalances: const [],
      totalsBySource: const {'lb': 600, 'bn': 2000},
      totalsByCurrency: const {'USD': 2600},
      totalBaseValue: 2600,
      totalUnrealizedPnlBase: 600,
    );
  }

  @override
  Stream<PortfolioSnapshot> watchSnapshot({
    required String baseCurrency,
  }) async* {
    yield await getSnapshot(baseCurrency: baseCurrency);
  }
}

class _FakeQuotesRepository implements QuotesRepository {
  @override
  Stream<PriceQuote> streamQuotes(List<String> symbols) async* {
    for (final symbol in symbols) {
      yield PriceQuote(
        symbol: symbol,
        price: 100,
        currency: 'USD',
        timestamp: DateTime.utc(2026, 1, 1),
      );
    }
  }
}

class _FakeTransactionsRepository implements TransactionsRepository {
  @override
  Future<List<Transaction>> list({String? sourceId, DateRange? range}) async {
    final base = [
      Transaction(
        id: 't1',
        sourceId: 'lb',
        time: DateTime.utc(2026, 1, 2),
        type: TransactionType.buy,
        symbol: 'AAPL',
        quantity: 1,
        price: 100,
        currency: 'USD',
        fee: 1,
      ),
      Transaction(
        id: 't2',
        sourceId: 'bn',
        time: DateTime.utc(2026, 1, 1),
        type: TransactionType.sell,
        symbol: 'BTC',
        quantity: 0.01,
        price: 30000,
        currency: 'USD',
        fee: 2,
      ),
    ];

    return base.where((t) {
      final sourceOk = sourceId == null || t.sourceId == sourceId;
      final rangeOk = range == null || range.contains(t.time);
      return sourceOk && rangeOk;
    }).toList(growable: false);
  }
}

class _FakeAlertsRepository implements AlertsRepository {
  final List<Alert> _alerts = [
    const Alert(
      id: 'a1',
      kind: AlertKind.priceAbove,
      scope: AlertScope.symbol('AAPL'),
      threshold: 120,
      active: true,
    ),
  ];

  @override
  Future<Alert> create(Alert alert) async {
    _alerts.add(alert);
    return alert;
  }

  @override
  Future<void> delete(String alertId) async {
    _alerts.removeWhere((a) => a.id == alertId);
  }

  @override
  bool evaluateLocal(
    Alert alert, {
    PriceQuote? quote,
    PortfolioSnapshot? snapshot,
  }) {
    if (!alert.active) return false;
    switch (alert.kind) {
      case AlertKind.priceAbove:
        return (quote?.price ?? double.negativeInfinity) > alert.threshold;
      case AlertKind.priceBelow:
        return (quote?.price ?? double.infinity) < alert.threshold;
      case AlertKind.pnlPctAbove:
        if (snapshot == null || snapshot.totalBaseValue == 0) return false;
        return (100 *
                snapshot.totalUnrealizedPnlBase /
                snapshot.totalBaseValue) >
            alert.threshold;
      case AlertKind.pnlPctBelow:
        if (snapshot == null || snapshot.totalBaseValue == 0) return false;
        return (100 *
                snapshot.totalUnrealizedPnlBase /
                snapshot.totalBaseValue) <
            alert.threshold;
    }
  }

  @override
  Future<List<Alert>> list() async => List<Alert>.unmodifiable(_alerts);

  @override
  Future<Alert> update(Alert alert) async {
    final idx = _alerts.indexWhere((a) => a.id == alert.id);
    if (idx >= 0) {
      _alerts[idx] = alert;
    }
    return alert;
  }
}

class _FakeManualHoldingsRepository implements ManualHoldingsRepository {
  final List<ManualHolding> _items = [];

  @override
  Future<ManualHolding> create(ManualHolding holding) async {
    _items.add(holding);
    return holding;
  }

  @override
  Future<void> delete(String holdingId) async {
    _items.removeWhere((h) => h.id == holdingId);
  }

  @override
  Future<List<ManualHolding>> list() async =>
      List<ManualHolding>.unmodifiable(_items);

  @override
  Future<ManualHolding> update(ManualHolding holding) async {
    final idx = _items.indexWhere((h) => h.id == holding.id);
    if (idx >= 0) {
      _items[idx] = holding;
    }
    return holding;
  }
}

class _FakeFxRepository implements FxRepository {
  @override
  Future<FxRate?> getRate({required String base, required String quote}) async {
    if (base == quote) {
      return FxRate(
        base: base,
        quote: quote,
        rate: 1,
        timestamp: DateTime.utc(2026, 1, 1),
      );
    }
    return null;
  }

  @override
  Stream<FxRate> watchRates(List<({String base, String quote})> pairs) {
    return const Stream<FxRate>.empty();
  }
}
