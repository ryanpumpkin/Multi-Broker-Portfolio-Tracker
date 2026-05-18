import 'notification_models.dart';

enum NotificationPermissionStatus {
  authorized,
  provisional,
  denied,
  notDetermined,
}

extension NotificationPermissionStatusX on NotificationPermissionStatus {
  bool get isGranted =>
      this == NotificationPermissionStatus.authorized ||
      this == NotificationPermissionStatus.provisional;
}

abstract class MessagingClient {
  Stream<String> get onTokenRefresh;
  Stream<NotificationPayload> get onForegroundMessage;
  Stream<NotificationPayload> get onMessageOpenedApp;

  Future<NotificationPermissionStatus> requestPermissionIfNeeded();
  Future<String?> getToken();
  Future<NotificationPayload?> getInitialMessage();
  Future<void> configureForegroundPresentation();
  Future<void> registerBackgroundHandler();
}
