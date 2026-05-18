import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/data/remote/firestore_client/in_memory_firestore_client.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';
import 'package:multi_broker_portfolio/notifications/notifications.dart';

void main() {
  group('NotificationService', () {
    late InMemoryFirestoreClient firestore;
    late _FakeMessagingClient messaging;
    late NotificationService service;

    setUp(() {
      firestore = InMemoryFirestoreClient();
      messaging = _FakeMessagingClient();
      service = NotificationService(
        messaging: messaging,
        tokenStore: NotificationTokenStore(
          firestore: firestore,
          appVersion: '1.0.0',
        ),
      );
    });

    tearDown(() async {
      await service.dispose();
    });

    test('registers token for user and updates on refresh', () async {
      messaging.token = 'tok-1';

      await service.startForUser('user-1');
      var devices = await firestore.listDeviceTokens('user-1');
      expect(devices.map((e) => e['id']), contains('tok-1'));

      messaging.emitTokenRefresh('tok-2');
      await Future<void>.delayed(Duration.zero);

      devices = await firestore.listDeviceTokens('user-1');
      expect(devices.map((e) => e['id']), contains('tok-2'));
      expect(devices.map((e) => e['id']), isNot(contains('tok-1')));
    });

    test('requests permission once on first alert-create attempt', () async {
      await service.startForUser('user-1');
      messaging.token = 'tok-1';

      await service.requestPermissionOnFirstAlertCreate();
      await service.requestPermissionOnFirstAlertCreate();

      expect(messaging.permissionRequests, 1);
      final devices = await firestore.listDeviceTokens('user-1');
      expect(devices.map((e) => e['id']), contains('tok-1'));
    });

    test('emits foreground banners and alert trigger ids', () async {
      await service.startForUser('user-1');

      final banners = <InAppNotificationBanner>[];
      final triggers = <String>[];
      final bannerSub = service.banners.listen(banners.add);
      final triggerSub = service.triggeredAlertIds.listen(triggers.add);
      addTearDown(bannerSub.cancel);
      addTearDown(triggerSub.cancel);

      messaging.emitForeground(
        _payload(
          title: 'Alert',
          body: 'AAPL crossed threshold',
          data: const <String, String>{'alertId': 'a1', 'symbol': 'AAPL'},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(banners.single.title, 'Alert');
      expect(banners.single.alertId, 'a1');
      expect(triggers, ['a1']);
    });

    test('emits deep links for opened and initial messages', () async {
      messaging.initialMessage = _payload(
        data: const <String, String>{'alertId': 'a1'},
      );

      final links = <NotificationRouteIntent>[];
      final sub = service.deepLinks.listen(links.add);
      addTearDown(sub.cancel);

      await service.startForUser('user-1');
      messaging.emitOpened(
        _payload(
          data: const <String, String>{'symbol': 'AAPL'},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(links.map((l) => l.location), contains('/alerts?alertId=a1'));
      expect(links.map((l) => l.location), contains('/positions?symbol=AAPL'));
    });

    test('removes active token on sign-out cleanup', () async {
      messaging.token = 'tok-1';
      await service.startForUser('user-1');

      await service.stopAndRemoveTokenForSignOut();
      final devices = await firestore.listDeviceTokens('user-1');
      expect(devices, isEmpty);
    });
  });

  group('LocalAlertEvaluationScheduler', () {
    test('evaluates active alerts when all connections are e2e', () async {
      final evaluated = <String>[];
      final scheduler = LocalAlertEvaluationScheduler(
        isE2eOnly: () async => true,
        listAlerts: () async => const <Alert>[
          Alert(
            id: 'portfolio-alert',
            kind: AlertKind.pnlPctAbove,
            scope: AlertScope.portfolio(),
            threshold: 5,
            active: true,
          ),
          Alert(
            id: 'symbol-alert',
            kind: AlertKind.priceAbove,
            scope: AlertScope.symbol('AAPL'),
            threshold: 100,
            active: true,
          ),
        ],
        loadPortfolio: () async => PortfolioSnapshot(
          asOf: DateTime.utc(2026, 1, 1),
          baseCurrency: 'USD',
          positions: const <Position>[],
          cashBalances: const <CashBalance>[],
          totalsBySource: const <String, double>{},
          totalsByCurrency: const <String, double>{},
          totalBaseValue: 100,
          totalUnrealizedPnlBase: 10,
        ),
        loadQuote: (_) async => PriceQuote(
          symbol: 'AAPL',
          price: 120,
          currency: 'USD',
          timestamp: DateTime.utc(2026, 1, 1),
        ),
        evaluateAlert: (alertId, {quote, snapshot}) async {
          evaluated.add(alertId);
          return true;
        },
      );

      await scheduler.tick();

      expect(
        evaluated,
        containsAll(<String>['portfolio-alert', 'symbol-alert']),
      );
    });

    test('skips evaluation when e2e-only mode is not active', () async {
      var called = false;
      final scheduler = LocalAlertEvaluationScheduler(
        isE2eOnly: () async => false,
        listAlerts: () async => const <Alert>[
          Alert(
            id: 'a1',
            kind: AlertKind.priceAbove,
            scope: AlertScope.symbol('AAPL'),
            threshold: 1,
            active: true,
          ),
        ],
        loadPortfolio: () async => null,
        loadQuote: (_) async => null,
        evaluateAlert: (alertId, {quote, snapshot}) async {
          called = true;
          return false;
        },
      );

      await scheduler.tick();

      expect(called, isFalse);
    });
  });
}

NotificationPayload _payload({
  String? title,
  String? body,
  Map<String, String> data = const <String, String>{},
}) {
  return NotificationPayload(
    messageId: 'm1',
    title: title,
    body: body,
    data: data,
    receivedAt: DateTime.utc(2026, 1, 1),
  );
}

class _FakeMessagingClient implements MessagingClient {
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();
  final StreamController<NotificationPayload> _foregroundController =
      StreamController<NotificationPayload>.broadcast();
  final StreamController<NotificationPayload> _openedController =
      StreamController<NotificationPayload>.broadcast();

  String? token;
  NotificationPayload? initialMessage;
  NotificationPermissionStatus permissionStatus =
      NotificationPermissionStatus.authorized;
  int permissionRequests = 0;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Stream<NotificationPayload> get onForegroundMessage =>
      _foregroundController.stream;

  @override
  Stream<NotificationPayload> get onMessageOpenedApp =>
      _openedController.stream;

  @override
  Future<void> configureForegroundPresentation() async {}

  @override
  Future<String?> getToken() async => token;

  @override
  Future<NotificationPayload?> getInitialMessage() async => initialMessage;

  @override
  Future<NotificationPermissionStatus> requestPermissionIfNeeded() async {
    permissionRequests += 1;
    return permissionStatus;
  }

  @override
  Future<void> registerBackgroundHandler() async {}

  void emitTokenRefresh(String nextToken) {
    _tokenRefreshController.add(nextToken);
  }

  void emitForeground(NotificationPayload payload) {
    _foregroundController.add(payload);
  }

  void emitOpened(NotificationPayload payload) {
    _openedController.add(payload);
  }
}
