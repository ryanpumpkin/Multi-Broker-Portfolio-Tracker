import 'dart:async';

import '../domain/domain.dart';
import 'messaging_client.dart';
import 'notification_models.dart';
import 'token_store.dart';

typedef ActiveAlertsLoader = Future<List<Alert>> Function();
typedef PortfolioLoader = Future<PortfolioSnapshot?> Function();
typedef QuoteLoader = Future<PriceQuote?> Function(String symbol);
typedef AlertEvaluator = Future<bool> Function(
  String alertId, {
  PriceQuote? quote,
  PortfolioSnapshot? snapshot,
});
typedef E2eOnlyDetector = Future<bool> Function();

class LocalAlertEvaluationScheduler {
  LocalAlertEvaluationScheduler({
    required this.isE2eOnly,
    required this.listAlerts,
    required this.loadPortfolio,
    required this.loadQuote,
    required this.evaluateAlert,
    this.interval = const Duration(minutes: 5),
  });

  final E2eOnlyDetector isE2eOnly;
  final ActiveAlertsLoader listAlerts;
  final PortfolioLoader loadPortfolio;
  final QuoteLoader loadQuote;
  final AlertEvaluator evaluateAlert;
  final Duration interval;

  Timer? _timer;

  Future<void> start() async {
    final enabled = await isE2eOnly();
    if (!enabled) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(
      interval,
      (_) => unawaited(tick()),
    );
    await tick();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> tick() async {
    if (!await isE2eOnly()) return;

    final alerts = await listAlerts();
    if (alerts.isEmpty) return;

    PortfolioSnapshot? snapshot;

    for (final alert in alerts) {
      if (!alert.active) continue;

      if (alert.scope.isPortfolio) {
        snapshot ??= await loadPortfolio();
        if (snapshot == null) continue;
        await evaluateAlert(
          alert.id,
          snapshot: snapshot,
        );
        continue;
      }

      final symbol = alert.scope.symbol;
      if (symbol == null || symbol.isEmpty) continue;
      final quote = await loadQuote(symbol);
      if (quote == null) continue;
      await evaluateAlert(
        alert.id,
        quote: quote,
      );
    }
  }
}

class NotificationService {
  NotificationService({
    required MessagingClient messaging,
    required NotificationTokenStore tokenStore,
    LocalAlertEvaluationScheduler? localEvaluationScheduler,
  })  : _messaging = messaging,
        _tokenStore = tokenStore,
        _localEvaluationScheduler = localEvaluationScheduler;

  final MessagingClient _messaging;
  final NotificationTokenStore _tokenStore;
  final LocalAlertEvaluationScheduler? _localEvaluationScheduler;

  final StreamController<InAppNotificationBanner> _bannersController =
      StreamController<InAppNotificationBanner>.broadcast();
  final StreamController<NotificationRouteIntent> _deepLinkController =
      StreamController<NotificationRouteIntent>.broadcast();
  final StreamController<String> _alertTriggeredController =
      StreamController<String>.broadcast();

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<NotificationPayload>? _foregroundSub;
  StreamSubscription<NotificationPayload>? _openedAppSub;

  String? _activeUserId;
  String? _activeToken;
  bool _requestedPermission = false;

  Stream<InAppNotificationBanner> get banners => _bannersController.stream;
  Stream<NotificationRouteIntent> get deepLinks => _deepLinkController.stream;
  Stream<String> get triggeredAlertIds => _alertTriggeredController.stream;

  Future<void> startForUser(String userId) async {
    _activeUserId = userId;
    await _messaging.registerBackgroundHandler();
    await _messaging.configureForegroundPresentation();

    await _localEvaluationScheduler?.start();

    _tokenRefreshSub ??= _messaging.onTokenRefresh.listen(
      (token) async {
        final uid = _activeUserId;
        if (uid == null) return;
        final oldToken = _activeToken;
        if (oldToken != null && oldToken.isNotEmpty && oldToken != token) {
          await _tokenStore.removeToken(uid, oldToken);
        }
        _activeToken = token;
        await _tokenStore.saveToken(uid, token);
      },
    );

    _foregroundSub ??= _messaging.onForegroundMessage.listen(
      _handleForegroundMessage,
    );
    _openedAppSub ??= _messaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleOpenedMessage(initial);
    }

    await _syncTokenIfAvailable();
  }

  Future<void> requestPermissionOnFirstAlertCreate() async {
    if (_requestedPermission) return;
    _requestedPermission = true;

    final status = await _messaging.requestPermissionIfNeeded();
    if (!status.isGranted) return;
    await _syncTokenIfAvailable();
  }

  Future<void> stopAndRemoveTokenForSignOut() async {
    await _localEvaluationScheduler?.stop();

    final uid = _activeUserId;
    final token = _activeToken;
    if (uid != null && token != null && token.isNotEmpty) {
      await _tokenStore.removeToken(uid, token);
    }

    _activeUserId = null;
    _activeToken = null;
    _requestedPermission = false;

    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();

    _tokenRefreshSub = null;
    _foregroundSub = null;
    _openedAppSub = null;
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();
    await _localEvaluationScheduler?.stop();

    await _bannersController.close();
    await _deepLinkController.close();
    await _alertTriggeredController.close();
  }

  Future<void> _syncTokenIfAvailable() async {
    final uid = _activeUserId;
    if (uid == null) return;
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    _activeToken = token;
    await _tokenStore.saveToken(uid, token);
  }

  void _handleForegroundMessage(NotificationPayload payload) {
    _bannersController.add(
      InAppNotificationBanner(
        title: payload.title ?? 'Alert triggered',
        body: payload.body ?? 'A portfolio alert was triggered.',
        alertId: payload.alertId,
        symbol: payload.symbol,
      ),
    );

    final alertId = payload.alertId;
    if (alertId != null && alertId.isNotEmpty) {
      _alertTriggeredController.add(alertId);
    }
  }

  void _handleOpenedMessage(NotificationPayload payload) {
    final intent = payload.toRouteIntent();
    if (intent == null) return;
    _deepLinkController.add(intent);
  }
}
