import 'package:flutter/foundation.dart';

import '../data/remote/firestore_client/firestore_client.dart';

class NotificationTokenStore {
  NotificationTokenStore({
    required this.firestore,
    this.appVersion = 'unknown',
  });

  final FirestoreClient firestore;
  final String appVersion;

  Future<void> saveToken(String userId, String token) {
    return firestore.upsertDeviceToken(
      userId,
      token,
      platform: _platformName(),
      appVersion: appVersion,
      lastSeen: DateTime.now().toUtc(),
    );
  }

  Future<void> removeToken(String userId, String token) {
    return firestore.deleteDeviceToken(userId, token);
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
