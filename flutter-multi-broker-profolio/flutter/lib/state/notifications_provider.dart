import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/firestore_client/firestore_adapter.dart';
import '../data/remote/firestore_client/firestore_client.dart';
import '../domain/domain.dart';
import '../notifications/notifications.dart';
import 'alerts_provider.dart';
import 'connections_provider.dart';
import 'portfolio_provider.dart';
import 'quotes_provider.dart';

final notificationFirestoreClientProvider = Provider<FirestoreClient>(
  (ref) => CloudFirestoreClient(FirebaseFirestore.instance),
);

final messagingClientProvider = Provider<MessagingClient>(
  (ref) => FirebaseMessagingClient(),
);

final notificationTokenStoreProvider = Provider<NotificationTokenStore>(
  (ref) => NotificationTokenStore(
    firestore: ref.watch(notificationFirestoreClientProvider),
  ),
);

final localAlertEvaluationSchedulerProvider =
    Provider<LocalAlertEvaluationScheduler>(
  (ref) {
    return LocalAlertEvaluationScheduler(
      isE2eOnly: () async {
        final state = await ref.read(connectionsProvider.future);
        final connections = state.connections;
        if (connections.isEmpty) return false;
        return connections.every(
          (connection) => connection.credentialMode == CredentialMode.e2e,
        );
      },
      listAlerts: () async {
        final state = await ref.read(alertsProvider.future);
        return state.alerts;
      },
      loadPortfolio: () async {
        return ref.read(portfolioProvider.future);
      },
      loadQuote: (symbol) async {
        try {
          return await ref.read(quotesProvider(symbol).future);
        } catch (_) {
          return null;
        }
      },
      evaluateAlert: (
        alertId, {
        PriceQuote? quote,
        PortfolioSnapshot? snapshot,
      }) {
        return ref.read(alertsProvider.notifier).evaluateAndRecord(
              alertId,
              quote: quote,
              snapshot: snapshot,
            );
      },
    );
  },
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) {
    final service = NotificationService(
      messaging: ref.watch(messagingClientProvider),
      tokenStore: ref.watch(notificationTokenStoreProvider),
      localEvaluationScheduler:
          ref.watch(localAlertEvaluationSchedulerProvider),
    );
    ref.onDispose(() => unawaited(service.dispose()));
    return service;
  },
);

final notificationLifecycleProvider = Provider<NotificationLifecycle>(
  ProviderBackedNotificationLifecycle.new,
);

final inAppNotificationBannersProvider =
    StreamProvider<InAppNotificationBanner>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.banners;
});

final notificationDeepLinkProvider =
    StreamProvider<NotificationRouteIntent>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.deepLinks;
});

abstract class NotificationLifecycle {
  Future<void> ensureInitializedForUser(String userId);
  Future<void> onFirstAlertCreateAttempt();
  Future<void> onBeforeSignOut();
}

class ProviderBackedNotificationLifecycle implements NotificationLifecycle {
  ProviderBackedNotificationLifecycle(this.ref) {
    _triggeredAlertSub = ref
        .read(notificationServiceProvider)
        .triggeredAlertIds
        .listen((alertId) {
      unawaited(
        ref.read(alertsProvider.notifier).recordRemoteTrigger(alertId),
      );
    });

    ref.onDispose(() {
      unawaited(_triggeredAlertSub?.cancel());
    });
  }

  final Ref ref;
  StreamSubscription<String>? _triggeredAlertSub;

  @override
  Future<void> ensureInitializedForUser(String userId) async {
    try {
      await ref.read(notificationServiceProvider).startForUser(userId);
    } catch (_) {
      // Firebase config may be absent in unit-test and local-dev contexts.
      // The app still functions without push registration.
    }
  }

  @override
  Future<void> onFirstAlertCreateAttempt() async {
    try {
      await ref
          .read(notificationServiceProvider)
          .requestPermissionOnFirstAlertCreate();
    } catch (_) {
      // Keep alert creation functional even if FCM is not configured.
    }
  }

  @override
  Future<void> onBeforeSignOut() async {
    try {
      await ref
          .read(notificationServiceProvider)
          .stopAndRemoveTokenForSignOut();
    } catch (_) {
      // Sign-out should not be blocked by notification cleanup failures.
    }
  }
}
