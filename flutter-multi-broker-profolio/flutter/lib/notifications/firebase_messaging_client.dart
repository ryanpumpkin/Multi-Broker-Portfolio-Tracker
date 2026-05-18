// coverage:ignore-file
// Justification: thin plugin adapter; behaviour is exercised via fake-based
// NotificationService tests and validated on-device with Firebase config.
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'messaging_client.dart';
import 'notification_models.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // System notifications for background/terminated states are rendered by FCM
  // when the message includes a notification payload. This hook enables
  // data-message handling and background isolate startup.
}

class FirebaseMessagingClient implements MessagingClient {
  FirebaseMessagingClient({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<NotificationPayload> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(_fromRemoteMessage);

  @override
  Stream<NotificationPayload> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(_fromRemoteMessage);

  @override
  Future<NotificationPermissionStatus> requestPermissionIfNeeded() async {
    final current = await _messaging.getNotificationSettings();
    if (current.authorizationStatus != AuthorizationStatus.notDetermined) {
      return _mapAuthorization(current.authorizationStatus);
    }

    final requested = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return _mapAuthorization(requested.authorizationStatus);
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<NotificationPayload?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) return null;
    return _fromRemoteMessage(message);
  }

  @override
  Future<void> configureForegroundPresentation() async {
    if (kIsWeb) return;
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @override
  Future<void> registerBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static NotificationPermissionStatus _mapAuthorization(
    AuthorizationStatus status,
  ) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return NotificationPermissionStatus.authorized;
      case AuthorizationStatus.provisional:
        return NotificationPermissionStatus.provisional;
      case AuthorizationStatus.denied:
        return NotificationPermissionStatus.denied;
      case AuthorizationStatus.notDetermined:
        return NotificationPermissionStatus.notDetermined;
    }
  }

  static NotificationPayload _fromRemoteMessage(RemoteMessage message) {
    return NotificationPayload(
      messageId: message.messageId,
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
      receivedAt: DateTime.now().toUtc(),
    );
  }
}
