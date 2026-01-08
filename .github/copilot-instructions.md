# Copilot Instructions for flutter_apns

## Project Overview
`flutter_apns` is a unified push notification plugin providing **native APNS (iOS)** and **Firebase Cloud Messaging (Android)** through a consistent API. It abstracts platform differences for receiving and handling push notifications.

**Architecture**: Dart API → iOS (APNS) / Android (FCM) → Apple/Firebase Servers

## Core API

### Initialization & Configuration
```dart
import 'package:flutter_apns/flutter_apns.dart';

final PushConnector connector = createPushConnector();

connector.configure(
  onLaunch: (Map<String, dynamic> message) async {
    // App launched from terminated state
  },
  onResume: (Map<String, dynamic> message) async {
    // App brought to foreground from background
  },
  onMessage: (Map<String, dynamic> message) async {
    // App in foreground
  },
  onBackgroundMessage: myBackgroundMessageHandler, // Optional, top-level function
);

// Request permissions (iOS: user prompt, Android: auto-granted)
connector.requestNotificationPermissions();
```

### Token Management
```dart
// Listen for token updates
connector.token.addListener(() {
  if (connector.token.value != null) {
    sendTokenToBackend(connector.token.value!);
  }
});

// Or get directly
final token = await connector.getToken();
```

### Badge Count (iOS Only)
```dart
connector.setNotificationBadge(count: 5);  // Set badge
connector.setNotificationBadge(count: 0);  // Clear badge
```

### Message Payload Structure
```dart
Map<String, dynamic> message = {
  'notification': {'title': 'Title', 'body': 'Message'},
  'data': {'userId': '123', 'customField': 'value'},
  'messageId': 'id', // FCM only
};
```

### Background Message Handler
```dart
// Top-level function (not in a class)
@pragma('vm:entry-point')
Future<void> myBackgroundMessageHandler(RemoteMessage message) async {
  print('Background: ${message.data}');
  // Perform lightweight background work (database updates, cache)
  // Avoid heavy processing - has strict time limits
}
```

## Platform Differences

| Feature | iOS (APNS) | Android (FCM) |
|---------|-----------|---------------|
| Permission | User prompt required | Auto-granted |
| Badge | Manual management | Handled by system |
| Background | Requires `content_available` | Automatic |
| Notification Icon | Uses app icon | Custom drawable |
| Token Format | Long hex string | Base64 string |

## Common Issues & Solutions

### Token is Null
- **iOS**: Check APNS certificates/keys configured
- **iOS**: Ensure `UNUserNotificationCenter.delegate` set in AppDelegate
- **Android**: Verify `google-services.json` in `android/app/`
- **Both**: Call `requestNotificationPermissions()` first

### onLaunch Not Called
- Ensure notification has `data` payload (not just `notification`)
- Verify handler registered before app initialization completes

### Badge Not Updating (iOS)
- Call `connector.setNotificationBadge(count: n)` after processing
- Clear when user views content: `setNotificationBadge(count: 0)`

### Background Messages Not Received
- **iOS**: Enable Background Modes → Remote Notifications in Xcode
- **Android**: Check device battery optimization settings
- Verify payload: `"content_available": true` (iOS) or `"priority": "high"` (Android)

## Required Payload Documentation

Document the notification payload structure your app expects:

```dart
/// Expected notification payload structure:
/// ```json
/// {
///   "notification": {"title": "New Message", "body": "You have 3 new messages"},
///   "data": {
///     "type": "chat",           // Required: notification type
///   }
/// }
/// ```
```

## Testing Strategy

- **iOS**: Physical device only (simulator lacks APNS)
- **Android**: Emulator works with Google Play Services
- Use Firebase Console → Cloud Messaging for test notifications
- Test states: foreground, background, terminated

## Key Files Reference

- `lib/flutter_apns.dart`: Main plugin export
- `lib/src/connector.dart`: Push connector interface
- Dependencies: `firebase_messaging` (Android), Native APNS (iOS)
