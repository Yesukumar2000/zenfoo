import 'package:flutter/material.dart';
import 'package:project/helper/widgets/new_order_notification_sheet.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/new_order.dart' as api;
import 'package:project/screens/mainScreen/bottom_nav_provider.dart';
import 'package:project/screens/mainScreen/main_tab_scaffold.dart';
import 'package:project/services/firebase_orders_service.dart';
import 'package:project/provider/new_orders_provider.dart';

/// Service to show new order notification bottom sheet
/// This service handles displaying the notification sheet across any screen
class NotificationSheetService {
  static final NotificationSheetService _instance =
      NotificationSheetService._internal();

  factory NotificationSheetService() {
    return _instance;
  }

  NotificationSheetService._internal();

  /// Show new order notification sheet
  /// Fetches full order details from API for complete information including items and products
  Future<void> showNewOrderNotification({
    required int orderId,
    api.OrderData? firebaseOrderData,
    required VoidCallback onDismiss,
    required VoidCallback onOpenOrders,
  }) async {
    try {
      // Get navigator context first
      final navigatorContext = Constant.navigatorKay.currentContext;
      if (navigatorContext == null) {
        debugPrint(
            '❌ Navigator context not available for showing notification sheet');
        return;
      }

      late api.OrderData orderData;

      // Fetch specific order details from API with order_id parameter
      debugPrint('📋 Fetching order details from API for order ID: $orderId');

      try {
        await navigatorContext.read<NewOrdersProvider>().getOrders(
              context: navigatorContext,
              params: {'order_id': orderId.toString()},
              silentLoading: true,
              reset: true,
            );

        debugPrint('📋 API Response received for order $orderId');

        // Try to get order from provider's list
        final provider = navigatorContext.read<NewOrdersProvider>();
        api.OrderData? foundOrder;

        if (provider.ordersList.isNotEmpty) {
          try {
            for (var order in provider.ordersList) {
              if (order.orderId == orderId) {
                foundOrder = order;
                break;
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error searching order in provider list: $e');
          }
        }

        if (foundOrder != null) {
          orderData = foundOrder;
          debugPrint('✅ Order data fetched successfully for order $orderId');
        } else {
          throw Exception('Order not found in provider list');
        }
      } catch (apiError) {
        debugPrint('⚠️ API fetch error: $apiError');
        // Fallback to Firebase data if API fetch fails
        if (firebaseOrderData != null) {
          debugPrint('⚠️ Using Firebase data for order $orderId');
          orderData = firebaseOrderData;
        } else {
          debugPrint(
              '❌ No order data found from API or Firebase for order ID: $orderId');
          return;
        }
      }

      // Show the bottom sheet
      _showBottomSheet(
        context: navigatorContext,
        orderData: orderData,
        onDismiss: onDismiss,
        onOpenOrders: onOpenOrders,
      );
    } catch (e) {
      debugPrint('❌ Error showing new order notification: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }
  }

  /// Display the bottom sheet with order details
  void _showBottomSheet({
    required BuildContext context,
    required api.OrderData orderData,
    required VoidCallback onDismiss,
    required VoidCallback onOpenOrders,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return NewOrderNotificationSheet(
          orderData: orderData,
          onClose: onDismiss,
          onTapOpenOrders: () {
            // Close the bottom sheet first
            Navigator.pop(sheetContext);
            // Then navigate to orders screen using the original context
            _navigateToOrdersScreen(context);
          },
        );
      },
    );
  }

  /// Navigate to the orders screen (tab 2 in MainTabScaffold)
  void _navigateToOrdersScreen(BuildContext context) {
    try {
      // Use a small delay to ensure the bottom sheet is fully closed
      Future.delayed(Duration(milliseconds: 100), () {
        try {
          // Create a BottomNavProvider instance to control the navigation
          final navProvider = BottomNavProvider();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => MultiProvider(
                providers: [
                  ChangeNotifierProvider<BottomNavProvider>.value(
                    value: navProvider,
                  ),
                ],
                child: MainTabScaffold(),
              ),
            ),
            (route) => false,
          );

          // After a brief delay, select the Orders tab
          Future.delayed(Duration(milliseconds: 300), () {
            try {
              navProvider.select(2); // 2 = Orders tab in MainTabScaffold
              debugPrint('📋 Successfully navigated to Orders tab (index 2)');
            } catch (e) {
              debugPrint('⚠️ Could not select Orders tab: $e');
            }
          });

          // Reset Firebase listener tracking when entering Orders screen
          _resetFirebaseTracking();
        } catch (e) {
          debugPrint('❌ Error navigating to orders screen: $e');
        }
      });
    } catch (e) {
      debugPrint('❌ Error in navigation flow: $e');
    }
  }

  /// Reset Firebase listener tracking when entering Orders screen
  void _resetFirebaseTracking() {
    try {
      final firebaseOrdersService = FirebaseOrdersService();
      firebaseOrdersService.resetTracker();
      debugPrint(
          '🔄 Firebase listener tracker reset - cleared existing orders');
    } catch (e) {
      debugPrint('⚠️ Error resetting Firebase tracker: $e');
    }
  }
}
