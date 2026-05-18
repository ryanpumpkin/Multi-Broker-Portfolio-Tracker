import '../router/app_router.dart';

class NotificationRouteIntent {
  const NotificationRouteIntent({
    required this.path,
    this.queryParameters = const <String, String>{},
  });

  final String path;
  final Map<String, String> queryParameters;

  String get location =>
      Uri(path: path, queryParameters: queryParameters).toString();
}

class NotificationPayload {
  const NotificationPayload({
    required this.data,
    required this.receivedAt,
    this.messageId,
    this.title,
    this.body,
  });

  final String? messageId;
  final String? title;
  final String? body;
  final Map<String, String> data;
  final DateTime receivedAt;

  String? get alertId => data['alertId'];
  String? get symbol => data['symbol'];

  NotificationRouteIntent? toRouteIntent() {
    if (alertId != null && alertId!.isNotEmpty) {
      return NotificationRouteIntent(
        path: AppRoutes.alerts,
        queryParameters: <String, String>{'alertId': alertId!},
      );
    }
    if (symbol != null && symbol!.isNotEmpty) {
      return NotificationRouteIntent(
        path: AppRoutes.positions,
        queryParameters: <String, String>{'symbol': symbol!},
      );
    }
    return null;
  }
}

class InAppNotificationBanner {
  const InAppNotificationBanner({
    required this.title,
    required this.body,
    this.alertId,
    this.symbol,
  });

  final String title;
  final String body;
  final String? alertId;
  final String? symbol;
}
