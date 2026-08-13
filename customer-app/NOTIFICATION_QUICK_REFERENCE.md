# Notification Implementation - Quick Reference

## 📋 Quick Setup Checklist

- [ ] Add dependencies to `pubspec.yaml`
- [ ] Create Firebase project
- [ ] Download `google-services.json` (Android)
- [ ] Download `GoogleService-Info.plist` (iOS)
- [ ] Create `firebase_options.dart` with credentials
- [ ] Create `awsomeNotification.dart` service class
- [ ] Initialize Firebase in `main.dart`
- [ ] Register FCM token on login
- [ ] Create notification models
- [ ] Create repositories for API calls
- [ ] Create notification provider
- [ ] Create notification UI screens
- [ ] Test on device

---

## 🔧 Essential Code Snippets

### 1. Initialize Notifications (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AwesomeNotificationHelper.initializeAwesomeNotification();
  await AwesomeNotificationHelper.registerListeners();

  runApp(const MyApp());
}
```

### 2. Request Permissions

```dart
Future<void> _requestNotificationPermission() async {
  await AwesomeNotificationHelper.requestPermission(context);
}
```

### 3. Get and Register FCM Token

```dart
Future<void> _registerFCMToken() async {
  final token = await AwesomeNotificationHelper.getFCMToken();

  // Send to backend
  await registerTokenAPI(
    fcmToken: token,
    platform: defaultTargetPlatform == TargetPlatform.android
      ? 'android'
      : 'ios',
  );
}
```

### 4. Create Notification Manually

```dart
await AwesomeNotificationHelper.createNotification(
  title: 'Order Confirmed',
  body: 'Your order #123 is confirmed',
  payload: {
    'type': 'order',
    'id': '123',
    'imageUrl': 'https://example.com/image.png',
  },
);
```

### 5. Handle Notification Tap

```dart
// Automatically handled in awsomeNotification.dart
// Navigation is automatic based on notification type

// Notification types:
// - 'product' → Product detail screen
// - 'order' → Order tracking screen
// - 'category' → Category screen
// - 'url' → External URL
// - 'default' → Notification list screen
```

---

## 📱 Notification States

### Foreground (App Open)
- User sees notification in status bar
- Can tap to open app
- Handled by `onMessage` listener

### Background (App Minimized)
- Notification shows in status bar
- Handled by `onBackgroundMessage` handler
- App brought to foreground on tap

### Terminated (App Closed)
- Notification shows in status bar
- Handled by `getInitialMessage()`
- App launched on notification tap

---

## 🔑 FCM Token Management

```dart
// Save token
final token = await FirebaseMessaging.instance.getToken();
await SessionManager.saveFCMToken(token);

// Retrieve token
final token = await SessionManager.getFCMToken();

// Clear token on logout
await SessionManager.clearFCMToken();
```

---

## 🎨 Notification Payload Structure

```dart
{
  'type': 'product',        // notification type
  'id': '123',              // resource ID
  'title': 'New Product',   // notification title
  'message': 'Check this',  // notification body
  'imageUrl': 'https://...', // image URL
  'linkUrl': 'https://...'  // external link
}
```

---

## 📊 API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/notifications` | GET | Get notifications list |
| `/notifications/{id}` | POST | Mark as read |
| `/notifications/{id}` | DELETE | Delete notification |
| `/fcm-token` | POST | Register FCM token |
| `/logout` | POST | Send FCM token |
| `/mail_settings` | GET | Get settings |
| `/mail_settings/save` | POST | Update settings |

---

## 🚨 Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| "No token available" | FCM not initialized | Initialize Firebase first |
| "Permission denied" | User rejected permission | Request at runtime (Android 13+) |
| "Notification not showing" | Channel not configured | Initialize AwesomeNotifications |
| "App crashes on background message" | No error handling | Add try-catch in handler |
| "Duplicate notifications" | Multiple handlers | Use `isNavigating` flag |
| "Image not loading" | Invalid URL or HTTP | Use HTTPS URLs |

---

## 📲 Testing Notifications

### Firebase Console Test
1. Go to Firebase Console → Cloud Messaging
2. Create new campaign
3. Fill title, body
4. Target your app
5. Schedule for now
6. Send

### Curl Command (Server)
```bash
curl -X POST \
  https://fcm.googleapis.com/v1/projects/PROJECT_ID/messages:send \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "FCM_TOKEN",
      "notification": {
        "title": "Test",
        "body": "Test message"
      },
      "data": {
        "type": "product",
        "id": "123"
      }
    }
  }'
```

---

## 🔐 Permissions Required

### Android
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### iOS
- Enable "Push Notifications" capability in Xcode
- Enable "Remote notifications" in Background Modes
- Enable "Background fetch" in Background Modes

---

## 📦 Dependencies

```yaml
firebase_core: ^4.0.0
firebase_messaging: ^16.0.0
awesome_notifications: ^0.10.1
permission_handler: ^12.0.1
http: ^1.1.0
shared_preferences: ^2.2.0
url_launcher: ^6.2.0
provider: ^6.0.0
```

---

## 🎯 Notification Types & Routes

```dart
switch (notificationType) {
  case 'product':
    // Navigate to product detail
    // Screen: ProductDetailScreen
    // Argument: product_id

  case 'order':
    // Navigate to order tracking
    // Screen: OrderTrackingScreen
    // Argument: order_id

  case 'category':
    // Navigate to category products
    // Screen: CategoryProductsScreen
    // Argument: category_id

  case 'url':
    // Launch external URL
    // launchUrl(Uri.parse(link_url))

  default:
    // Navigate to notification list
    // Screen: NotificationListScreen
}
```

---

## 💾 Session Manager Keys

```dart
static const String keyFCMToken = 'keyFCMToken';
static const String keyPermissionNotificationHidePromptPermanently =
  'keyPermissionNotificationHidePromptPermanently';
```

---

## 🔄 Notification Flow Chart

```
User sends notification via backend
            ↓
Firebase Cloud Messaging
            ↓
    ┌───────┴────────┬──────────┐
    │                │          │
Foreground      Background   Terminated
    │                │          │
    ↓                ↓          ↓
onMessage    onBackground  getInitial
             Message        Message
    │                │          │
    └────┬───────────┴──────────┘
         │
         ↓
Create Local Notification
(AwesomeNotifications)
         │
         ↓
User Taps Notification
         │
         ↓
onActionNotificationMethod()
         │
         ↓
Extract Type & ID
         │
         ↓
Navigate to Screen
```

---

## 📝 Notification Model

```dart
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final String typeId;
  final String? imageUrl;
  final String? linkUrl;
  final bool isRead;
  final DateTime createdAt;
}
```

---

## 🧪 Debug Logs

```dart
// Enable debug logging
await AwesomeNotifications().initialize(
  null,
  [NotificationChannel(...)],
  debug: true,
);

// Check logs
flutter logs | grep "Notification"
flutter logs | grep "FCM"
```

---

## 🔗 Useful Links

- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Setup](https://firebase.flutter.dev/)
- [Awesome Notifications Pub](https://pub.dev/packages/awesome_notifications)
- [Firebase Console](https://console.firebase.google.com)
- [Android Firebase Setup](https://developer.android.com/build/releases/gradle-plugin-com-android-tools-build-gradle)
- [iOS Firebase Setup](https://firebase.google.com/docs/ios/setup)

---

## ✅ Implementation Checklist

### Phase 1: Setup
- [ ] Firebase project created
- [ ] Configuration files downloaded
- [ ] Dependencies added
- [ ] firebase_options.dart created

### Phase 2: Core Implementation
- [ ] awsomeNotification.dart service class
- [ ] Firebase initialization in main.dart
- [ ] Listener registration
- [ ] Permission request flow

### Phase 3: Backend Integration
- [ ] FCM token registration API
- [ ] Notification list API
- [ ] Notification settings API
- [ ] Session token management

### Phase 4: UI & Navigation
- [ ] Notification models created
- [ ] Notification repository
- [ ] Notification provider
- [ ] Notification list screen
- [ ] Notification settings screen

### Phase 5: Testing & Deployment
- [ ] Foreground notification test
- [ ] Background notification test
- [ ] Terminated state test
- [ ] Image notification test
- [ ] Navigation test
- [ ] Production deployment

---

## 🎁 Bonus: Notification Settings API

```dart
// Get user notification preferences
Future<void> getSettings() async {
  final response = await http.get(
    Uri.parse('$baseUrl/mail_settings'),
    headers: {'Authorization': 'Bearer $token'},
  );
  // Returns notification preferences per order status
}

// Update notification preferences
Future<void> updateSettings({
  required List<String> orderStatusIds,
  required List<bool> mailStatuses,
  required List<bool> mobileStatuses,
  required List<bool> smsStatuses,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/mail_settings/save'),
    headers: {'Authorization': 'Bearer $token'},
    body: {
      'status_ids': orderStatusIds.join(','),
      'mail_statuses': mailStatuses.join(','),
      'mobile_statuses': mobileStatuses.join(','),
      'sms_statuses': smsStatuses.join(','),
    },
  );
}
```

---

## 📞 Support

For issues or questions:
1. Check [Flutter Firebase documentation](https://firebase.flutter.dev/)
2. Review [Awesome Notifications documentation](https://pub.dev/documentation/awesome_notifications/latest/)
3. Check common issues section in main guide
4. Enable debug logging and check logs
5. Test with Firebase Console

---

**Last Updated:** 2026-02-04
**Version:** 1.0
**Status:** Production Ready ✅
