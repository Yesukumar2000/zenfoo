// ignore_for_file: file_names

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zenfoo_partner/router/app_router.dart';
import 'package:zenfoo_partner/utils/notification_helper.dart';
import 'package:zenfoo_partner/utils/permissionHandlerBottomSheet.dart';

@pragma('vm:entry-point')
class LocalAwesomeNotification {
  static AwesomeNotifications notification = AwesomeNotifications();

  final String normalNotificationChannel = "normalNotification";
  final String soundNotificationChannel = "soundNotification";

  static LocalAwesomeNotification localNotification = LocalAwesomeNotification();

  static StreamSubscription<RemoteMessage>? foregroundStream;
  static StreamSubscription<RemoteMessage>? onMessageOpen;
  static bool isNavigating = false;

  Future<void> init(BuildContext context) async {
    disposeListeners().then((value) async {
      await requestPermission(context: context);

      await notification.initialize('resource://mipmap/ic_launcher', [
        NotificationChannel(
          channelKey: soundNotificationChannel,
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel',
          playSound: true,
          enableVibration: true,
          importance: NotificationImportance.High,
          ledColor: ColorsRes.appColor,
          soundSource: Platform.isIOS ? "order_sound.aiff" : "resource://raw/order_sound",
        ),
        NotificationChannel(
          channelKey: normalNotificationChannel,
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel',
          playSound: true,
          enableVibration: true,
          importance: NotificationImportance.High,
          ledColor: ColorsRes.appColor,
        ),
      ], debug: kDebugMode);
    });

    await registerListeners(context);

    await listenTap();
  }

  listenTap() {
    notification.setListeners(
      onDismissActionReceivedMethod: (receivedAction) async {},
      onNotificationDisplayedMethod: (receivedNotification) async {},
      onNotificationCreatedMethod: (receivedNotification) async {},
      onActionReceivedMethod: (ReceivedAction data) async {
        // Handle notification tap - navigate to delivery screen
        _handleNotificationTap(data);
      },
    );
  }

  /// Handle notification tap and navigate to delivery screen
  /// Uses navigator key for reliable navigation even on cold app launch
  Future<void> _handleNotificationTap(ReceivedAction data) async {
    try {
      debugPrint('🔔 Notification tapped: ${data.payload}');

      // Extract order data from notification payload
      final payload = data.payload ?? {};
      final notificationType = payload['type'] ?? 'order';

      // Wait for app to fully initialize - longer delay for cold start
      // This ensures Firebase, providers, GoRouter, and all services are ready
      await Future.delayed(const Duration(milliseconds: 2000));

      // Check if navigator key is available
      if (navigatorKey.currentState == null) {
        debugPrint('⚠️ Navigator not available yet, retrying...');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Navigate based on notification type
      if (navigatorKey.currentState != null) {
        if (notificationType == 'order' && payload.containsKey('order_id')) {
          // Navigate to order acceptance screen for new orders
          debugPrint('✅ Order notification detected, navigating to order acceptance');
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/bottomNavScreen',
            (route) => false,
            arguments: {
              'tab': 'orders', // Focus on orders tab
              'order_id': payload['order_id'],
              'order_data': payload, // Pass full order data
              'from_notification': true,
            },
          );
          debugPrint('✅ Navigation initiated with order data');
        } else {
          // Navigate to home for other notifications
          debugPrint('✅ Generic notification, navigating to /bottomNavScreen');
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/bottomNavScreen',
            (route) => false,
          );
          debugPrint('✅ Navigation initiated to /bottomNavScreen');
        }
      } else {
        debugPrint('❌ Navigator still not available, navigation failed');
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  // Normal notification
  createImageNotification({required RemoteMessage data, required bool isLocked}) async {
    await notification.createNotification(
      content: NotificationContent(
        id: Random().nextInt(5000),
        color: ColorsRes.appColor,
        title: data.data["title"]/*  ?? data.notification?.title ?? '' */,
        locked: isLocked,
        payload: Map.from(data.data),
        autoDismissible: true,
        showWhen: true,
        notificationLayout: NotificationLayout.BigPicture,
        body: data.data["message"]/*  ?? data.notification?.body ?? '' */,
        wakeUpScreen: true,
        largeIcon: data.data["image"],
        bigPicture: data.data["image"],
        channelKey: normalNotificationChannel,
      ),
    );
  }

  createNotification({required RemoteMessage data, required bool isLocked}) async {
    await notification.createNotification(
      content: NotificationContent(
        id: Random().nextInt(5000),
        color: ColorsRes.appColor,
        title: data.data["title"]/*  ?? data.notification?.title ?? '' */,
        locked: isLocked,
        payload: Map.from(data.data),
        autoDismissible: true,
        showWhen: true,
        notificationLayout: NotificationLayout.Default,
        body: data.data["message"]/*  ?? data.notification?.body ?? '' */,
        wakeUpScreen: true,
        channelKey: normalNotificationChannel,
      ),
    );
  }

  // Sound notification, if new order received sound notification will be played
  createImageNotificationWithSound({required RemoteMessage data, required bool isLocked}) async {
    await notification.createNotification(
      content: NotificationContent(
        id: Random().nextInt(5000),
        color: ColorsRes.appColor,
        title: data.data["title"],
        locked: isLocked,
        payload: Map.from(data.data),
        autoDismissible: true,
        showWhen: true,
        notificationLayout: NotificationLayout.BigPicture,
        body: data.data["message"],
        wakeUpScreen: true,
        largeIcon: data.data["image"],
        bigPicture: data.data["image"],
        channelKey: soundNotificationChannel,
      ),
    );
  }

  createNotificationWithSound({required RemoteMessage data, required bool isLocked}) async {
    await notification.createNotification(
      content: NotificationContent(
        id: Random().nextInt(5000),
        color: ColorsRes.appColor,
        title: data.data["title"],
        locked: isLocked,
        payload: Map.from(data.data),
        autoDismissible: true,
        showWhen: true,
        notificationLayout: NotificationLayout.Default,
        body: data.data["message"],
        wakeUpScreen: true,
        channelKey: soundNotificationChannel,
      ),
    );
  }

  requestPermission({required BuildContext context}) async {
    PermissionStatus notificationPermissionStatus = await Permission.notification.status;

    if (notificationPermissionStatus.isPermanentlyDenied) {
      if (!Constant.session.getBoolData(SessionManager.keyPermissionNotificationHidePromptPermanently)) {
        // showModalBottomSheet(
        //   context: context,
        //   builder: (context) {
        //     return Wrap(
        //       children: [
        //         PermissionHandlerBottomSheet(
        //           titleJsonKey: notificationPermissionTitleLabel,
        //           messageJsonKey: notificationPermissionMessageLabel,
        //           sessionKeyForAskNeverShowAgain: SessionManager.keyPermissionNotificationHidePromptPermanently,
        //         ),
        //       ],
        //     );
        //   },
        // );
      }
    } else if (notificationPermissionStatus.isDenied) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      Permission.notification.request();
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onBackgroundMessageHandler(RemoteMessage data) async {
    await Firebase.initializeApp();
    if (data.notification == null){
    if (Platform.isAndroid) {
      if (data.data["sound"] == "default" || data.data["sound"] == null) {
        if (data.data["image"] == "" || data.data["image"] == null) {
          localNotification.createNotification(isLocked: false, data: data);
        } else {
          localNotification.createImageNotification(isLocked: false, data: data);
        }
      } else if (data.data["sound"] != "default") {
        if (data.data["image"] == "" || data.data["image"] == null) {
          localNotification.createNotificationWithSound(isLocked: false, data: data);
        } else {
          localNotification.createImageNotificationWithSound(isLocked: false, data: data);
        }
      }
    }
    }
  }

  static foregroundNotificationHandler() async {
    try {
      onMessageOpen = FirebaseMessaging.onMessage.listen((RemoteMessage data) {
        debugPrint('🔔 Foreground message received: ${data.data}');

        // Get title and message from data payload or notification object
        final String? title = data.data["title"] ?? data.notification?.title;
        final String? message = data.data["message"] ?? data.notification?.body;
        final String? image = data.data["image"];
        final String? sound = data.data["sound"];

        // Skip if no title or message
        if (title == null && message == null) {
          debugPrint('⚠️ Skipping notification: no title or message');
          return;
        }

        // Create a modified data map with title/message for notification display
        final modifiedData = RemoteMessage(
          data: {
            ...data.data,
            'title': title ?? '',
            'message': message ?? '',
          },
          notification: data.notification,
          messageId: data.messageId,
        );

        if (Platform.isAndroid) {
          if (sound == "default" || sound == null) {
            if (image == "" || image == null) {
              localNotification.createNotification(isLocked: false, data: modifiedData);
            } else {
              localNotification.createImageNotification(isLocked: false, data: modifiedData);
            }
          } else {
            if (image == "" || image == null) {
              localNotification.createNotificationWithSound(isLocked: false, data: modifiedData);
            } else {
              localNotification.createImageNotificationWithSound(isLocked: false, data: modifiedData);
            }
          }
        } else if (Platform.isIOS) {
          // iOS: Show notification in foreground
          if (sound == "default" || sound == null) {
            if (image == "" || image == null) {
              localNotification.createNotification(isLocked: false, data: modifiedData);
            } else {
              localNotification.createImageNotification(isLocked: false, data: modifiedData);
            }
          } else {
            if (image == "" || image == null) {
              localNotification.createNotificationWithSound(isLocked: false, data: modifiedData);
            } else {
              localNotification.createImageNotificationWithSound(isLocked: false, data: modifiedData);
            }
          }
        }

        debugPrint('✅ Foreground notification displayed');
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint("ISSUE ${e.toString()}");
      }
    }
  }

  static terminatedStateNotificationHandler() {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? data) {
      if (data == null) {
        return;
      }

      // Handle app opened from terminated state via notification tap
      // The notification tap will be handled by awesome_notifications listener
      debugPrint('📱 App opened from terminated state via notification');
    });
  }

  static registerListeners(context) async {
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await foregroundNotificationHandler();
    await terminatedStateNotificationHandler();
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessageHandler);

    if (kDebugMode) {
      debugPrint('✅ All FCM listeners registered successfully');
    }
  }

  Future disposeListeners() async {
    onMessageOpen?.cancel();
    foregroundStream?.cancel();
  }

  /// Show persistent notification for iOS when app goes to background
  static Future<void> showOnlineNotification({
    required String title,
    required String body,
  }) async {
    await notification.createNotification(
      content: NotificationContent(
        id: 9999, // Fixed ID for persistent notification
        channelKey: 'normalNotification',
        title: title,
        body: body,
        color: ColorsRes.appColor,
        locked: false,
        autoDismissible: true,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: false,
      ),
    );
  }

  /// Cancel persistent notification for iOS
  static Future<void> cancelOnlineNotification() async {
    await notification.cancel(9999);
  }
}
