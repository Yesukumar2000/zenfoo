import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/notification.dart';

@pragma('vm:entry-point')
Future<void> onBackgroundMessageHandler(RemoteMessage message) async {
  debugPrint('🔔 Background notification received');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}

class FirebaseNotificationsService {
  static final FirebaseNotificationsService _instance =
      FirebaseNotificationsService._internal();

  factory FirebaseNotificationsService() {
    return _instance;
  }

  FirebaseNotificationsService._internal();

  late final FirebaseMessaging _firebaseMessaging;

  // Stream controllers for notifications
  final _notificationStream = StreamController<NotificationListData>.broadcast();
  final _foregroundNotificationStream = StreamController<RemoteMessage>.broadcast();

  Stream<NotificationListData> get notificationStream => _notificationStream.stream;
  Stream<RemoteMessage> get foregroundNotificationStream => _foregroundNotificationStream.stream;

  /// Initialize Firebase Notifications
  Future<void> initialize() async {
    _firebaseMessaging = FirebaseMessaging.instance;

    // Request permission for notifications
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');

    // Enable auto-init
    await _firebaseMessaging.setAutoInitEnabled(true);

    // Register all listeners
    _registerListeners();

    // Get initial message if app was terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔔 App opened from notification (terminated state)');
      _handleNotificationTap(initialMessage);
    }

    debugPrint('✅ Firebase Notifications initialized');
  }

  /// Register all notification listeners
  void _registerListeners() {
    // 1. Background message handler
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessageHandler);

    // 2. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Foreground notification received');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');

      // Emit to foreground stream
      _foregroundNotificationStream.add(message);

      // Convert to NotificationListData and emit
      if (message.notification != null) {
        final notification = _convertRemoteMessageToNotification(message);
        _notificationStream.add(notification);
      }
    });

    // 3. App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notification opened app');
      _handleNotificationTap(message);
    });
  }

  /// Convert RemoteMessage to NotificationListData
  NotificationListData _convertRemoteMessageToNotification(RemoteMessage message) {
    return NotificationListData(
      id: int.tryParse(message.messageId ?? '0') ?? 0,
      name: message.notification?.title ?? 'Notification',
      subtitle: message.notification?.body ?? '',
      type: message.data['type'] ?? 'default',
      typeId: int.tryParse(message.data['type_id'] ?? '0'),
      imageUrl: message.notification?.android?.imageUrl ??
          message.data['image_url'],
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] ?? 'default';
    final id = message.data['id'] ?? message.data['type_id'] ?? '';

    debugPrint('📍 Handling notification tap: type=$type, id=$id');

    // Emit the notification to be handled by listeners
    if (message.notification != null) {
      final notification = _convertRemoteMessageToNotification(message);
      _notificationStream.add(notification);
    }
  }

  /// Get current FCM token
  Future<String?> getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Listen to token refresh
  void listenToTokenRefresh(Function(String) onTokenRefresh) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      onTokenRefresh(newToken);
    });
  }

  /// Enable notifications
  Future<void> enableNotifications() async {
    await _firebaseMessaging.setAutoInitEnabled(true);
    debugPrint('✅ Notifications enabled');
  }

  /// Disable notifications
  Future<void> disableNotifications() async {
    await _firebaseMessaging.setAutoInitEnabled(false);
    debugPrint('❌ Notifications disabled');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Dispose resources
  void dispose() {
    _notificationStream.close();
    _foregroundNotificationStream.close();
  }
}
