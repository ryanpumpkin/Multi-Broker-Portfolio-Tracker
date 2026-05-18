# Notifications (FCM)

This module wires Firebase Cloud Messaging for the Flutter client.

## What it provides

- `FirebaseMessagingClient`: thin plugin adapter (`firebase_messaging`).
- `NotificationService`: permission gate, device-token registration, token-refresh sync, foreground banner/deep-link events, sign-out token cleanup.
- `LocalAlertEvaluationScheduler`: periodic client-side fallback for users whose connections are all in `e2e` mode.
- Riverpod hooks in `state/notifications_provider.dart` consumed by auth and alerts flows.

## Platform config checklist (manual)

Ownership for this module is Dart-side only. Native/web Firebase project config must be completed by developer setup:

1. iOS APNs:
   - Upload APNs auth key in Firebase Console.
   - Ensure `GoogleService-Info.plist` is present.
   - Enable `Push Notifications` + `Background Modes > Remote notifications` in Xcode.
2. Android:
   - Ensure `google-services.json` is present.
   - Ensure FCM is enabled in Firebase project.
3. Web:
   - Configure VAPID key in Firebase Cloud Messaging settings.
   - Provide Firebase web options (`firebase_options.dart`) and FCM service worker as required by your web target.

## Physical iOS validation checklist

APNs push delivery cannot be validated on the iOS simulator.

1. Install the app on a physical iOS device.
2. Sign in and create an alert (this triggers first permission prompt).
3. Confirm device token appears under `users/{uid}/devices/{token}` in Firestore.
4. Send a test push from Firebase Console with data payload containing `alertId` or `symbol`.
5. Verify:
   - Foreground: in-app banner event + local trigger history update.
   - Background/terminated: system notification appears, tapping it deep-links to alerts/positions route.
