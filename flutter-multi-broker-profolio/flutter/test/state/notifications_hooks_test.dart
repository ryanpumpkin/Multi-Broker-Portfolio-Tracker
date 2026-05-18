import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';
import 'package:multi_broker_portfolio/state/alerts_provider.dart';
import 'package:multi_broker_portfolio/state/auth_provider.dart';
import 'package:multi_broker_portfolio/state/notifications_provider.dart';
import 'package:multi_broker_portfolio/state/repository_providers.dart';

void main() {
  test('authProvider invokes notification lifecycle on sign-in/sign-out',
      () async {
    final authRepo = _AuthRepo();
    final lifecycle = _FakeNotificationLifecycle();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        notificationLifecycleProvider.overrideWithValue(lifecycle),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authProvider.notifier)
        .signIn(email: 'a@example.com', password: 'pw');
    await container.read(authProvider.notifier).signOut();

    expect(lifecycle.initializedUserIds, ['uid-a@example.com']);
    expect(lifecycle.signOutCalls, 1);
  });

  test('alertsProvider requests permission on first create attempt', () async {
    final lifecycle = _FakeNotificationLifecycle();
    final alertsRepo = _AlertsRepo();
    final container = ProviderContainer(
      overrides: [
        alertsRepositoryProvider.overrideWithValue(alertsRepo),
        notificationLifecycleProvider.overrideWithValue(lifecycle),
      ],
    );
    addTearDown(container.dispose);

    await container.read(alertsProvider.future);

    await container.read(alertsProvider.notifier).create(
          const Alert(
            id: 'a1',
            kind: AlertKind.priceAbove,
            scope: AlertScope.symbol('AAPL'),
            threshold: 100,
            active: true,
          ),
        );

    expect(lifecycle.firstAlertCreateCalls, 1);
  });
}

class _FakeNotificationLifecycle implements NotificationLifecycle {
  final List<String> initializedUserIds = <String>[];
  int firstAlertCreateCalls = 0;
  int signOutCalls = 0;

  @override
  Future<void> ensureInitializedForUser(String userId) async {
    initializedUserIds.add(userId);
  }

  @override
  Future<void> onBeforeSignOut() async {
    signOutCalls += 1;
  }

  @override
  Future<void> onFirstAlertCreateAttempt() async {
    firstAlertCreateCalls += 1;
  }
}

class _AuthRepo implements AuthRepository {
  AuthUser? _user;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  Future<AuthUser?> currentUser() async => _user;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    _user = AuthUser(uid: 'uid-$email', email: email);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<AuthUser> signUp({required String email, required String password}) {
    return signIn(email: email, password: password);
  }

  @override
  Stream<AuthUser?> watchUser() async* {
    yield _user;
    yield* _controller.stream;
  }
}

class _AlertsRepo implements AlertsRepository {
  final List<Alert> _items = <Alert>[];

  @override
  Future<Alert> create(Alert alert) async {
    _items.add(alert);
    return alert;
  }

  @override
  Future<void> delete(String alertId) async {
    _items.removeWhere((item) => item.id == alertId);
  }

  @override
  bool evaluateLocal(
    Alert alert, {
    PriceQuote? quote,
    PortfolioSnapshot? snapshot,
  }) {
    return false;
  }

  @override
  Future<List<Alert>> list() async => List<Alert>.unmodifiable(_items);

  @override
  Future<Alert> update(Alert alert) async {
    final index = _items.indexWhere((item) => item.id == alert.id);
    if (index >= 0) _items[index] = alert;
    return alert;
  }
}
