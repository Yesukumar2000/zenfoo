// ignore_for_file: file_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project/helper/generalWidgets/permissionHandlerBottomSheet.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/services/notification_sheet_service.dart';
import 'package:project/screens/ordersScreen/seller_order_chat_screen.dart';

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

    await listenTap(context);
  }

  /// Show order notification sheet for foreground notifications
  static void _showOrderNotificationSheet(RemoteMessage data) {
    try {
      final orderId = int.tryParse(data.data["orderId"] ?? '');
      if (orderId == null) {
        debugPrint('⚠️ Invalid orderId in notification data');
        return;
      }

      debugPrint('📢 Showing order notification sheet for order: $orderId');

      // Use NotificationSheetService to display the order sheet
      NotificationSheetService().showNewOrderNotification(
        orderId: orderId,
        onDismiss: () {
          debugPrint('📋 Order notification dismissed');
        },
        onOpenOrders: () {
          debugPrint('📋 Opening orders screen from notification');
        },
      );
    } catch (e) {
      debugPrint('❌ Error showing order notification sheet: $e');
    }
  }

  listenTap(BuildContext context) {
    notification.setListeners(
      onDismissActionReceivedMethod: (receivedAction) async {
        debugPrint('Notification dismissed: ${receivedAction.payload}');
      },
      onNotificationDisplayedMethod: (receivedNotification) async {
        debugPrint('Notification displayed: ${receivedNotification.payload}');
      },
      onNotificationCreatedMethod: (receivedNotification) async {
        debugPrint('Notification created: ${receivedNotification.payload}');
      },
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        debugPrint('Notification clicked: ${receivedAction.payload}');

        // Navigate to orders screen when notification is tapped
        if (receivedAction.payload != null && receivedAction.payload!.isNotEmpty) {
          // Use a small delay to ensure app is fully initialized before navigation
          Future.delayed(Duration(milliseconds: 300), () {
            _handleNotificationNavigation(receivedAction.payload!);
          });
        }
      },
    );
  }

  /// Handle navigation based on notification payload
  void _handleNotificationNavigation(Map<String, String?> payload) {
    try {
      // Get navigator context
      final navigatorContext = Constant.navigatorKay.currentContext;
      if (navigatorContext == null) {
        debugPrint('❌ Navigator context not available for notification navigation');
        return;
      }

      // Check for chat message notifications
      if (payload.containsKey('type') && payload['type'] == 'chat_message') {
        final orderId = payload['order_id'];
        final senderId = payload['sender_id'];
        final senderType = payload['sender_type'];

        if (orderId != null && orderId.isNotEmpty) {
          final orderIdInt = int.tryParse(orderId);
          if (orderIdInt != null) {
            debugPrint('💬 Opening chat for order: $orderId from $senderType (ID: $senderId)');

            // Navigate to chat screen
            Future.delayed(Duration(milliseconds: 200), () {
              Navigator.of(navigatorContext, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => SellerOrderChatScreen(
                    orderId: orderIdInt,
                    driverId: senderId != null ? int.tryParse(senderId) : null,
                    driverName: payload['title'] ?? 'Driver',
                  ),
                ),
              );
            });
            return;
          }
        }
      }
      // Check for order-related notifications (type can be 'new_order' or 'order')
      else if (payload.containsKey('type') && (payload['type'] == 'order' || payload['type'] == 'new_order')) {
        // For order notifications, show the order sheet directly
        final orderId = payload['orderId'];
        if (orderId != null && orderId.isNotEmpty) {
          final orderIdInt = int.tryParse(orderId);
          if (orderIdInt != null) {
            debugPrint('🔔 Showing order notification sheet for order: $orderId');
            NotificationSheetService().showNewOrderNotification(
              orderId: orderIdInt,
              onDismiss: () {
                debugPrint('📋 Order notification dismissed');
              },
              onOpenOrders: () {
                debugPrint('📋 Opening orders from notification tap');
              },
            );
            return;
          }
        }
      } else if (payload.containsKey('orderId')) {
        // Navigate to specific order detail
        final orderId = payload['orderId'];
        if (orderId != null && orderId.isNotEmpty) {
          Constant.navigatorKay.currentState?.pushNamed(
            '/orderDetail',
            arguments: orderId,
          );
          debugPrint('Navigating to order detail: $orderId');
        }
      } else {
        // Default navigation to home/dashboard
        Constant.navigatorKay.currentState?.pushNamed('/');
        debugPrint('Navigating to home');
      }
    } catch (e) {
      debugPrint('❌ Error handling notification navigation: $e');
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
        autoDismissible: false,
        showWhen: true,
        notificationLayout: NotificationLayout.BigPicture,
        body: data.data["message"]/*  ?? data.notification?.body ?? '' */,
        wakeUpScreen: true,
        fullScreenIntent: true,
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
        autoDismissible: false,
        showWhen: true,
        notificationLayout: NotificationLayout.Default,
        body: data.data["message"]/*  ?? data.notification?.body ?? '' */,
        wakeUpScreen: true,
        fullScreenIntent: true,
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
        autoDismissible: false,
        showWhen: true,
        notificationLayout: NotificationLayout.BigPicture,
        body: data.data["message"],
        wakeUpScreen: true,
        fullScreenIntent: true,
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
        autoDismissible: false,
        showWhen: true,
        notificationLayout: NotificationLayout.Default,
        body: data.data["message"],
        wakeUpScreen: true,
        fullScreenIntent: true,
        channelKey: soundNotificationChannel,
      ),
    );
  }

  requestPermission({required BuildContext context}) async {
    PermissionStatus notificationPermissionStatus = await Permission.notification.status;

    if (notificationPermissionStatus.isPermanentlyDenied) {
      if (!Constant.session.getBoolData(SessionManager.keyPermissionNotificationHidePromptPermanently)) {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Wrap(
              children: [
                PermissionHandlerBottomSheet(
                  titleJsonKey: notificationPermissionTitleLabel,
                  messageJsonKey: notificationPermissionMessageLabel,
                  sessionKeyForAskNeverShowAgain: SessionManager.keyPermissionNotificationHidePromptPermanently,
                ),
              ],
            );
          },
        );
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

    // Store the notification data for display when app is opened
    if (data.data.containsKey("title") && data.data.containsKey("message")) {
      // Store notification data in SharedPreferences for later display
      try {
        final prefs = await SharedPreferences.getInstance();
        final notificationJson = json.encode({
          'title': data.data["title"],
          'message': data.data["message"],
          'orderId': data.data["orderId"],
          'type': data.data["type"],
          'image': data.data["image"],
          'sound': data.data["sound"],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        await prefs.setString('pending_notification', notificationJson);
        debugPrint('💾 Pending notification stored: ${data.data["orderId"]}');

        // Set a flag to auto-launch app on next notification display
        await prefs.setBool('should_auto_launch_app', true);
        debugPrint('🚀 App auto-launch flag set');
      } catch (e) {
        debugPrint('⚠️ Error storing pending notification: $e');
      }

      // Create local notification for display in tray
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
        // Always create notification from data if it has title and message
        if (data.data.containsKey("title") && data.data.containsKey("message")) {
          debugPrint('🔔 Foreground notification received: ${data.data["orderId"]}');

          // Show order notification sheet if this is an order notification
          if (data.data.containsKey("orderId") && data.data["orderId"] != null && data.data["orderId"]!.isNotEmpty) {
            _showOrderNotificationSheet(data);
          }

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
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Foreground notification handler error: ${e.toString()}");
      }
    }
  }

  static terminatedStateNotificationHandler() {
    // Handle notification when app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? data) {
      if (data == null) {
        return;
      }

      // Store the notification data for navigation after app initialization
      if (data.data.isNotEmpty) {
        debugPrint('App opened from terminated state with notification: ${data.data}');
        // Navigation will be handled by awesome notifications listener
        // or by routes based on the payload
      }
    });

    // Also listen for when user taps notification from notification tray
    // This handles the case when app is brought to foreground
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened app: ${message.data}');
      // This is handled by awesome_notifications listener
    });
  }

  static registerListeners(context) async {
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    await foregroundNotificationHandler();
    await terminatedStateNotificationHandler();
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessageHandler);
  }

  Future disposeListeners() async {
    onMessageOpen?.cancel();
    foregroundStream?.cancel();
  }
}
