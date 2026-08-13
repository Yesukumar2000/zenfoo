# Firebase Notifications Integration with Existing Structure

## Overview

This document describes the Firebase Cloud Messaging (FCM) notifications integration with the existing notification system in Zenfoo Partner app. The implementation leverages the existing notification architecture while adding real-time Firebase capabilities.

---

## Architecture

### System Flow

```
┌─────────────────────────────────────┐
│   Firebase Cloud Messaging (FCM)    │
│   (Remote Push Notifications)       │
└──────────────┬──────────────────────┘
               │
      ┌────────┴────────┬──────────────┐
      │                 │              │
      ▼                 ▼              ▼
  [Terminated]    [Background]   [Foreground]
  State Handler   State Handler   State Handler
      │                 │              │
      └────────┬────────┴──────────────┘
               │
               ▼
    ┌──────────────────────────────┐
    │  NotificationProvider Stream │
    │  (Real-time updates)         │
    └──────────────┬───────────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │  Awesome             │
        │  Notifications       │
        │  (Local Display)     │
        └──────────────────────┘
```

### Component Structure

```
FirebaseNotificationsService (Main Service Class)
├── initialize() - Initialize Firebase & listeners
├── _registerListeners() - Setup FCM listeners
│   ├── onBackgroundMessage() - Terminated state
│   ├── onMessage.listen() - Foreground state
│   └── onMessageOpenedApp.listen() - App opened from notification
├── getFCMToken() - Get current FCM token
├── listenToTokenRefresh() - Listen to token changes
├── notificationStream - Stream<NotificationListData>
└── foregroundNotificationStream - Stream<RemoteMessage>

NotificationRepository
├── initializeFirebaseNotifications()
├── getFirebaseNotificationStream()
├── getFCMToken()
├── listenToTokenRefresh()
├── areNotificationsEnabled()
├── enableNotifications()
└── disableNotifications()

NotificationProvider (State Management)
├── initializeFirebaseNotifications()
├── getFCMToken()
├── areNotificationsEnabled()
├── notifications List (includes Firebase notifications)
├── firebaseInitialized flag
└── _firebaseNotificationSubscription (manages stream)
```

---

## Files Created

### 1. **lib/services/firebase_notifications_service.dart**

**Purpose:** Main service class for Firebase notifications handling

**Key Features:**
- Initializes Firebase Messaging
- Registers listeners for all app states (foreground, background, terminated)
- Converts Firebase RemoteMessage to NotificationListData
- Manages notification streams for real-time updates
- Handles FCM token refresh

**Key Methods:**
```dart
Future<void> initialize()
Stream<NotificationListData> get notificationStream
Stream<RemoteMessage> get foregroundNotificationStream
Future<String?> getFCMToken()
void listenToTokenRefresh(Function(String) onTokenRefresh)
```

---

## Files Modified

### 1. **lib/repository/notification_repository.dart**

**Changes:**
- Added `FirebaseNotificationsService` instance
- Added Firebase-related methods:
  - `initializeFirebaseNotifications()` - Initialize Firebase notifications
  - `getFirebaseNotificationStream()` - Get notification stream
  - `getFCMToken()` - Get current FCM token
  - `listenToTokenRefresh()` - Listen to token changes
  - `areNotificationsEnabled()` - Check notification status
  - `enableNotifications()` - Enable notifications
  - `disableNotifications()` - Disable notifications

### 2. **lib/providers/notification_provider.dart**

**Changes:**
- Added `_firebaseInitialized` flag
- Added `_firebaseNotificationSubscription` to manage stream
- Added `initializeFirebaseNotifications()` method:
  - Initializes Firebase notifications
  - Subscribes to notification stream
  - Adds Firebase notifications to the existing notifications list
  - Sets up token refresh listener
- Added `getFCMToken()` method
- Added `areNotificationsEnabled()` method
- Added `dispose()` method to properly clean up subscriptions
- Firebase notifications are automatically prepended to the notifications list

### 3. **lib/main.dart**

**Changes:**
- Added `_initializeFirebaseNotifications()` method
- Called Firebase initialization after AwesomeNotifications in `_initializeNotifications()`
- Integrates with NotificationProvider for real-time updates

---

## Integration Points

### 1. **Notification Display Flow**

```
Firebase Notification Received
    ↓
FirebaseNotificationsService detects
    ↓
Converts to NotificationListData
    ↓
Emits to notification stream
    ↓
NotificationProvider receives
    ↓
Adds to notifications list
    ↓
Listeners (UI) notified
    ↓
Awesome Notifications displays
```

### 2. **Real-time Updates**

The Firebase notifications are streamed directly to the NotificationProvider:

```dart
_firebaseNotificationSubscription = _repository.getFirebaseNotificationStream().listen(
  (notification) {
    if (notification is NotificationListData) {
      _notifications.insert(0, notification);  // Add to top
      notifyListeners();  // Notify UI
    }
  },
);
```

### 3. **Token Management**

Automatic token refresh handling:

```dart
_repository.listenToTokenRefresh((newToken) {
  debugPrint('🔄 FCM token refreshed: $newToken');
  // FcmTokenService automatically updates backend
});
```

---

## How It Works

### Foreground (App Open)
1. Firebase receives notification
2. `onMessage.listen()` triggers
3. Service converts to `NotificationListData`
4. Emits to provider stream
5. Provider adds to `notifications` list
6. UI updates with new notification
7. Awesome Notifications also displays local notification

### Background (App Minimized)
1. Firebase receives notification
2. `onBackgroundMessageHandler` triggers
3. Service emits to stream
4. Awesome Notifications displays notification

### Terminated (App Closed)
1. Firebase receives notification
2. When app is opened, `getInitialMessage()` retrieves it
3. Service handles as notification tap
4. Notification data is available to the app

---

## Using Firebase Notifications

### Initialize in App Startup

Already integrated in `main.dart`:
```dart
// In _initializeNotifications method
_initializeFirebaseNotifications(context);
```

### Get FCM Token

```dart
final notificationProvider = context.read<NotificationProvider>();
final token = await notificationProvider.getFCMToken();
```

### Listen to Real-time Notifications

The `NotificationProvider.notifications` list automatically includes Firebase notifications:

```dart
Consumer<NotificationProvider>(
  builder: (context, provider, _) {
    return ListView.builder(
      itemCount: provider.notifications.length,
      itemBuilder: (context, index) {
        final notification = provider.notifications[index];
        // Display notification
      },
    );
  },
);
```

### Check if Notifications are Enabled

```dart
final isEnabled = await notificationProvider.areNotificationsEnabled();
```

---

## Backend Integration

### Send Notification from Backend

**Node.js Example:**
```javascript
const admin = require('firebase-admin');

async function sendNotification(fcmToken, title, body, data) {
  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body,
    },
    data: data,
    android: {
      priority: 'high',
    },
    apns: {
      headers: {
        'apns-priority': '10',
      },
    },
  };

  const response = await admin.messaging().send(message);
  console.log('Notification sent:', response);
}

// Usage
sendNotification(
  'user_fcm_token',
  'Order Confirmed',
  'Your order #123 has been confirmed',
  {
    type: 'order',
    id: '123',
    image_url: 'https://example.com/image.png',
  }
);
```

**Python Example:**
```python
from firebase_admin import messaging

def send_notification(fcm_token, title, body, data):
    message = messaging.Message(
        token=fcm_token,
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=data,
    )

    response = messaging.send(message)
    print(f'Notification sent: {response}')
```

---

## Notification Payload Structure

When sending notifications from backend, use this structure:

```json
{
  "token": "fcm_token_here",
  "notification": {
    "title": "Order Confirmed",
    "body": "Your order #123 has been confirmed"
  },
  "data": {
    "type": "order",
    "id": "123",
    "type_id": "123",
    "image_url": "https://example.com/image.png"
  }
}
```

**Mapping to NotificationListData:**
- `notification.title` → `name`
- `notification.body` → `subtitle`
- `data.type` → `type`
- `data.type_id` → `typeId`
- `data.image_url` → `imageUrl`

---

## Testing Firebase Notifications

### 1. Using Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Send test message to specific FCM token
3. Check logs: `flutter logs | grep "Firebase"`

### 2. Using cURL

```bash
curl -X POST \
  https://fcm.googleapis.com/v1/projects/zenfoo-4860d/messages:send \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "YOUR_FCM_TOKEN",
      "notification": {
        "title": "Test",
        "body": "Test message"
      },
      "data": {
        "type": "order",
        "id": "123"
      }
    }
  }'
```

### 3. Logging

All Firebase operations are logged with prefixes:
- 🔔 - Notification events
- 📱 - Token operations
- 🔄 - Token refresh
- ✅ - Success
- ❌ - Errors
- 📍 - Navigation

Enable debug logging in Firebase service:
```dart
debugPrint('🔔 Foreground notification received');
```

---

## Troubleshooting

### Issue 1: Notifications Not Appearing

**Solution:**
1. Verify FCM token is registered with backend
2. Check Firebase rules allow messages
3. Check app has notification permissions
4. Test with Firebase Console

### Issue 2: Duplicate Notifications

**Solution:**
- Firebase notifications are deduplicated by ID
- Awesome Notifications handler also validates
- Check backend isn't sending duplicates

### Issue 3: Token Not Updating

**Solution:**
- `listenToTokenRefresh()` is automatic
- Token refresh is handled by FcmTokenService
- Check network connectivity

### Issue 4: Background Notifications Not Working

**Solution:**
- Ensure `onBackgroundMessageHandler` is marked with `@pragma('vm:entry-point')`
- Check AndroidManifest.xml permissions
- Test with Firebase Console

---

## Performance Considerations

### Stream Management
- Subscriptions are properly cleaned up in `dispose()`
- Only one stream subscription per provider instance
- Stream broadcasts allow multiple listeners

### Memory Management
- Notifications list grows with pagination (20 per load)
- Old notifications are kept in memory (as per existing design)
- Firebase service is a singleton to prevent multiple instances

### Network Efficiency
- Firebase handles compression and optimization
- Token refresh is lazy (only when token changes)
- No polling; all notifications are push-based

---

## Security Considerations

1. **FCM Token Management:**
   - Tokens are sent to backend via `/api/delivery-boy/update-fcm-token`
   - Tokens are updated automatically on refresh
   - Tokens are stored locally for reference

2. **Notification Data:**
   - All notification data comes from Firebase
   - Backend validates notification sending
   - Notification type restricts navigation

3. **Permissions:**
   - User can disable notifications at OS level
   - App requests runtime permissions for Android 13+
   - iOS permissions via Info.plist

---

## Summary

The Firebase notifications integration:

✅ **Seamlessly integrates** with existing NotificationProvider
✅ **Real-time updates** through notification streams
✅ **Automatic token management** via FcmTokenService
✅ **Works in all app states** (foreground, background, terminated)
✅ **No breaking changes** to existing notification system
✅ **Backward compatible** with existing API endpoints
✅ **Production ready** with error handling and logging
✅ **Easy to test** with Firebase Console or cURL

The system automatically:
- Receives Firebase notifications
- Converts them to NotificationListData
- Adds them to the notifications list in real-time
- Displays them via Awesome Notifications
- Manages FCM tokens
- Handles all app states

No additional configuration is needed beyond the existing Firebase setup already in the codebase.
