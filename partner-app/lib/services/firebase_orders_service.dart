import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:project/helper/utils/soundService.dart';
import 'package:project/models/new_order.dart' as new_order;
import 'package:project/services/notification_sheet_service.dart';

class FirebaseOrdersService {
  static final FirebaseOrdersService _instance = FirebaseOrdersService._internal();

  factory FirebaseOrdersService() {
    return _instance;
  }

  FirebaseOrdersService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _ordersSubscription;

  /// List to track existing order IDs to detect new orders
  final Set<int> _existingOrderIds = {};

  /// Flag to track if this is the first snapshot (we skip new order detection on first load)
  bool _isFirstSnapshot = true;

  /// Listen to real-time changes in seller orders
  /// Returns a stream of order lists that update whenever Firebase data changes
  /// Reads from the 'orders' map field in the seller_orders document
  Stream<List<new_order.OrderData>> listenToSellerOrders({
    required int sellerId,
    void Function(List<int>)? onNewOrders,
  }) {
    return _firestore
        .collection('seller_orders')
        .doc(sellerId.toString())
        .snapshots()
        .map((snapshot) {
      final orders = <new_order.OrderData>[];
      final newOrderIds = <int>[];
      final newOrdersData = <int, new_order.OrderData>{};

      // Check if document exists and has orders map field
      if (!snapshot.exists) {
        debugPrint('⚠️ Seller document does not exist');
        return [];
      }

      final data = snapshot.data();
      if (data == null) {
        debugPrint('⚠️ Seller document data is null');
        return [];
      }

      // Get the orders map from the document
      final ordersMap = data['orders'] as Map<String, dynamic>?;
      if (ordersMap == null || ordersMap.isEmpty) {
        // No orders yet, just return empty list
        return [];
      }

      // Parse each order from the map
      ordersMap.forEach((key, value) {
        try {
          if (value is! Map<String, dynamic>) return;

          final orderData = value;

          // Parse order data from Firebase map
          final order = new_order.OrderData(
            orderId: orderData['order_id']?.toInt() ?? 0,
            status: [orderData['status'] ?? 'pending'],
            activeStatus: orderData['status'] ?? 'pending',
            createdAt: orderData['created_at'] ?? '',
            updatedAt: orderData['updated_at'] ?? '',
            otp: int.tryParse(orderData['otp']?.toString() ?? ''),
            mobile: orderData['mobile']?.toString(),
            address: orderData['address']?.toString(),
          );

          orders.add(order);
        } catch (e) {
          debugPrint('Error parsing Firebase order from map: $e');
        }
      });

      // On first snapshot, just populate the existing IDs without triggering notifications
      if (_isFirstSnapshot) {
        debugPrint('📥 Firebase listener: First snapshot - tracking ${orders.length} existing orders');
        _existingOrderIds.addAll(orders.map((o) => o.orderId ?? 0).toSet());
        _isFirstSnapshot = false;
      } else {
        // On subsequent snapshots, detect actual new orders
        for (final order in orders) {
          if (!_existingOrderIds.contains(order.orderId)) {
            newOrderIds.add(order.orderId ?? 0);
            newOrdersData[order.orderId ?? 0] = order;
          }
        }
        _existingOrderIds.addAll(newOrderIds);

        // Trigger callback for new orders and play sound
        if (newOrderIds.isNotEmpty) {
          debugPrint('🆕 New orders detected from Firebase: $newOrderIds');
          onNewOrders?.call(newOrderIds);

          // Play sound for new orders
          _playNewOrderSound();

          // Show notification sheet for each new order (with Firebase data)
          for (final orderId in newOrderIds) {
            _showNotificationSheet(orderId, newOrdersData[orderId]);
          }
        }
      }

      return orders;
    });
  }

  /// Listen to a specific order's updates
  Stream<new_order.OrderData?> listenToOrder({
    required int sellerId,
    required int orderId,
  }) {
    return _firestore
        .collection('seller_orders')
        .doc(sellerId.toString())
        .collection('orders')
        .doc('order_$orderId')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;

      final data = snapshot.data()!;
      return new_order.OrderData(
        orderId: data['order_id']?.toInt() ?? 0,
        status: [data['status'] ?? 'pending'],
        activeStatus: data['status'] ?? 'pending',
        createdAt: data['created_at'] ?? '',
        updatedAt: data['updated_at'] ?? '',
        otp: data['otp']?.toInt(),
      );
    });
  }

  /// Get initial orders data without listening (for initial load)
  Future<List<new_order.OrderData>> getInitialOrders({
    required int sellerId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('seller_orders')
          .doc(sellerId.toString())
          .collection('orders')
          .orderBy('created_at', descending: true)
          .get();

      final orders = <new_order.OrderData>[];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();

          final order = new_order.OrderData(
            orderId: data['order_id']?.toInt() ?? 0,
            status: [data['status'] ?? 'pending'],
            activeStatus: data['status'] ?? 'pending',
            createdAt: data['created_at'] ?? '',
            updatedAt: data['updated_at'] ?? '',
            otp: data['otp']?.toInt(),
          );

          orders.add(order);
          _existingOrderIds.add(order.orderId ?? 0);
        } catch (e) {
          debugPrint('Error parsing Firebase order: $e');
        }
      }

      return orders;
    } catch (e) {
      debugPrint('Error fetching initial orders from Firebase: $e');
      return [];
    }
  }

  /// Update order status in Firebase
  Future<bool> updateOrderStatus({
    required int sellerId,
    required int orderId,
    required String newStatus,
  }) async {
    try {
      await _firestore
          .collection('seller_orders')
          .doc(sellerId.toString())
          .collection('orders')
          .doc('order_$orderId')
          .update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating order status in Firebase: $e');
      return false;
    }
  }

  /// Cancel the listening stream
  void dispose() {
    _ordersSubscription?.cancel();
    _existingOrderIds.clear();
  }

  /// Reset the existing order IDs tracker
  void resetTracker() {
    _existingOrderIds.clear();
    _isFirstSnapshot = true;
  }

  /// Play sound for new orders
  void _playNewOrderSound() {
    try {
      SoundService().playOrderSound();
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }

  /// Show notification sheet for new order
  void _showNotificationSheet(int orderId, new_order.OrderData? firebaseOrderData) {
    try {
      NotificationSheetService().showNewOrderNotification(
        orderId: orderId,
        firebaseOrderData: firebaseOrderData,
        onDismiss: () {
          debugPrint('✅ Notification sheet dismissed for order $orderId');
        },
        onOpenOrders: () {
          debugPrint('📋 Opening orders screen for order $orderId');
          // Navigation will be handled by the sheet's callback
        },
      );
    } catch (e) {
      debugPrint('Error showing notification sheet: $e');
    }
  }
}
