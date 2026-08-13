import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  Set<int> _processedOrders = {}; // Track processed orders to avoid duplicates

  /// Listen to Firestore for new orders for a specific delivery boy
  /// Path: delivery_boys/{deliveryBoyId}
  /// Expects a field called 'orders' with an order ID value
  /// Emits ALL current orders whenever the orders list changes (additions or deletions)
  Stream<List<int>> listenToOrders(int deliveryBoyId) {
    final controller = StreamController<List<int>>.broadcast();
    var isFirstEmission = true; // Track if this is the first emission

    try {
      debugPrint('🔥 Firestore: Creating document reference...');
      final deliveryBoyDoc =
          _firestore.collection('delivery_boys').doc(deliveryBoyId.toString());

      debugPrint(
          '🔥 Firestore: Setting up listener at path: delivery_boys/$deliveryBoyId');
      debugPrint('🔥 Firestore: Starting snapshots listener...');

      _orderSubscription = deliveryBoyDoc.snapshots().listen(
        (DocumentSnapshot snapshot) {
          try {
            if (snapshot.exists) {
              final data = snapshot.data() as Map<String, dynamic>?;

              if (data != null && data.containsKey('orders')) {
                final ordersValue = data['orders'];
                debugPrint(
                    '📄 Raw orders field value: $ordersValue (type: ${ordersValue.runtimeType})');

                final orderIds = <int>[];

                // Handle different data types for orders field
                if (ordersValue is int) {
                  orderIds.add(ordersValue);
                } else if (ordersValue is String) {
                  final orderId = int.tryParse(ordersValue);
                  if (orderId != null) {
                    orderIds.add(orderId);
                  }
                } else if (ordersValue is List) {
                  // Handle array of order IDs
                  for (var item in ordersValue) {
                    if (item is int) {
                      orderIds.add(item);
                    } else if (item is String) {
                      final orderId = int.tryParse(item);
                      if (orderId != null) {
                        orderIds.add(orderId);
                      }
                    }
                  }
                } else if (ordersValue is Map) {
                  // Handle map of order IDs
                  ordersValue.forEach((key, value) {
                    if (value is int) {
                      orderIds.add(value);
                    } else if (value is String) {
                      final orderId = int.tryParse(value);
                      if (orderId != null) {
                        orderIds.add(orderId);
                      }
                    } else {
                      // Fallback: If value is not a simple ID (e.g., it's a Map/Object),
                      // check if the KEY itself is the order ID
                      if (key is String) {
                        final orderId = int.tryParse(key);
                        if (orderId != null) {
                          debugPrint('💡 Found order ID in Map key: $orderId');
                          orderIds.add(orderId);
                        }
                      }
                    }
                  });
                }

                // Emit on every change (first emission and subsequent updates)
                // This ensures new orders are detected when added to Firebase
                if (isFirstEmission) {
                  debugPrint(
                      '📢 First emission - emitting current orders: ${orderIds.isEmpty ? "NONE" : orderIds}');
                  isFirstEmission = false;
                } else {
                  debugPrint(
                      '📢 Order update detected - emitting orders: ${orderIds.isEmpty ? "NONE" : orderIds}');
                }
                controller.add(orderIds);
              } else {
                debugPrint('📭 No "orders" field found in document');
                // Emit empty list on every emission (including first)
                if (isFirstEmission) {
                  debugPrint(
                      '📢 First emission - no orders field, emitting empty list');
                  isFirstEmission = false;
                } else {
                  debugPrint('📢 Orders field removed - emitting empty list');
                }
                if (data != null) {
                  debugPrint(
                      '📄 Available keys in document: ${data.keys.toList()}');
                } else {
                  debugPrint('📄 Document data is null');
                }
                controller.add([]);
              }
            } else {
              debugPrint(
                  '📭 No document found for delivery boy $deliveryBoyId');
              // Emit empty list on every emission (including first)
              if (isFirstEmission) {
                debugPrint(
                    '📢 First emission - document not found, emitting empty list');
                isFirstEmission = false;
              } else {
                debugPrint(
                    '📢 Document no longer exists - emitting empty list');
              }
              controller.add([]);
            }
          } catch (e) {
            debugPrint('❌ Error processing Firestore data: $e');
            controller.addError(e);
          }
        },
        onError: (error) {
          debugPrint('❌ Firestore listener error: $error');
          controller.addError(error);
        },
      );

      debugPrint('✅ Firestore listener subscription created successfully');
    } catch (e) {
      debugPrint('❌ Error setting up Firestore listener: $e');
      controller.addError(e);
    }

    return controller.stream;
  }

  /// Mark an order as processed (accepted or rejected)
  void markOrderAsProcessed(int orderId) {
    _processedOrders.add(orderId);
    debugPrint('✅ Order $orderId marked as processed');
  }

  /// Clear processed orders cache (useful when driver goes offline/online)
  void clearProcessedOrders() {
    _processedOrders.clear();
    debugPrint('🗑️ Processed orders cache cleared');
  }

  /// Remove order from Firestore after acceptance/rejection
  /// This will remove the 'orders' field from the delivery boy document
  Future<void> removeOrderFromFirebase(int deliveryBoyId, int orderId) async {
    try {
      final deliveryBoyDoc =
          _firestore.collection('delivery_boys').doc(deliveryBoyId.toString());

      // Remove the 'orders' field or update it
      await deliveryBoyDoc.update({
        'orders': FieldValue.delete(),
      });

      debugPrint(
          '🗑️ Order $orderId removed from Firestore (deleted orders field)');
    } catch (e) {
      debugPrint('❌ Error removing order from Firestore: $e');
    }
  }

  /// Remove a single order id from the delivery boy's `orders` map.
  ///
  /// Unlike [removeOrderFromFirebase] this keeps any other pending offers intact,
  /// so it is the right call when one offer dies (another driver accepted it,
  /// the offer expired) while the driver is still free to take the rest.
  Future<void> removeOrderIdFromFirebase(int deliveryBoyId, int orderId) async {
    try {
      await _firestore
          .collection('delivery_boys')
          .doc(deliveryBoyId.toString())
          .update({'orders.$orderId': FieldValue.delete()});

      debugPrint('🗑️ Order $orderId removed from Firestore orders map');
    } catch (e) {
      debugPrint('❌ Error removing order $orderId from Firestore: $e');
    }
  }

  /// Save accepted order details to Firebase
  /// This stores the current order details and delivery boy location
  Future<void> saveAcceptedOrder({
    required int deliveryBoyId,
    required int orderId,
    required double driverLat,
    required double driverLng,
    required Map<String, dynamic> orderDetails,
  }) async {
    try {
      final deliveryBoyDoc =
          _firestore.collection('delivery_boys').doc(deliveryBoyId.toString());

      // Save current order details with driver location
      await deliveryBoyDoc.set({
        'current_order': {
          'order_id': orderId,
          'accepted_at': FieldValue.serverTimestamp(),
          'driver_location': {
            'latitude': driverLat,
            'longitude': driverLng,
            'updated_at': FieldValue.serverTimestamp(),
          },
          'order_details': orderDetails,
        },
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Accepted order $orderId saved to Firestore');
      debugPrint('📍 Driver location: ($driverLat, $driverLng)');
    } catch (e) {
      debugPrint('❌ Error saving accepted order to Firestore: $e');
    }
  }

  /// Add rejected order ID to rejected orders array
  Future<void> addRejectedOrder({
    required int deliveryBoyId,
    required int orderId,
  }) async {
    try {
      final deliveryBoyDoc =
          _firestore.collection('delivery_boys').doc(deliveryBoyId.toString());

      // Add order ID to rejected_orders array
      await deliveryBoyDoc.set({
        'rejected_orders': FieldValue.arrayUnion([orderId]),
        'last_rejected_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('❌ Order $orderId added to rejected orders list');
    } catch (e) {
      debugPrint('❌ Error adding rejected order to Firestore: $e');
    }
  }

  /// Get current accepted order from Firebase
  Future<Map<String, dynamic>?> getCurrentOrder(int deliveryBoyId) async {
    try {
      debugPrint('🔍 Checking Firestore for delivery boy: $deliveryBoyId');

      final deliveryBoyDoc =
          _firestore.collection('delivery_boys').doc(deliveryBoyId.toString());

      final snapshot = await deliveryBoyDoc.get();

      if (!snapshot.exists) {
        debugPrint('❌ Delivery boy document does not exist');
        return null;
      }

      final data = snapshot.data();

      if (data == null) {
        debugPrint('⚠️ Document data is null');
        return null;
      }

      // An order assigned by admin (including an emergency driver change) only
      // ever writes current_order - there is no 'orders' entry for it - so this
      // must be checked first, otherwise a restart loses the ongoing order.
      final currentOrder = data['current_order'];
      if (currentOrder is Map) {
        debugPrint('📦 Found current_order in Firestore');
        return Map<String, dynamic>.from(currentOrder);
      }

      // Fallback: the 'orders' map holds pending offers, keyed by order id.
      final ordersValue = data['orders'];

      if (ordersValue is! Map) {
        debugPrint('📭 No orders field found in Firestore');
        debugPrint('📄 Available keys in document: ${data.keys.toList()}');
        return null;
      }

      final ordersMap = Map<String, dynamic>.from(ordersValue);

      if (ordersMap.isEmpty) {
        debugPrint('📭 Orders map is empty');
        return null;
      }

      // Convert order IDs and take FIRST one (as per your senior logic)
      final orderIds = ordersMap.keys
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e != 0)
          .toList()
        ..sort();

      final activeOrderId = orderIds.first;

      debugPrint('📦 Active order ID resolved: $activeOrderId');

      // Return in same format your existing code expects
      return {"order_id": activeOrderId};
    } catch (e) {
      debugPrint('❌ Error getting current order from Firestore: $e');
      return null;
    }
  }

  /// Listen to Firebase for real-time current_order updates
  /// Returns a stream of current order data or null when cleared
  Stream<Map<String, dynamic>?> listenToCurrentOrder(int deliveryBoyId) {
    return FirebaseFirestore.instance
        .collection('delivery_boys')
        .doc(deliveryBoyId.toString())
        .snapshots()
        .map((DocumentSnapshot snapshot) {
      try {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>?;

          // The backend clears an order by writing current_order: null (not by
          // deleting the field), so check the value - a containsKey() check
          // followed by a cast throws on the cleared document.
          final currentOrder = data?['current_order'];
          if (currentOrder is Map) {
            final orderMap = Map<String, dynamic>.from(currentOrder);
            debugPrint(
                '📦 Current order update received: ${orderMap['order_details']?['order_id'] ?? 'unknown'}');
            return orderMap;
          } else {
            debugPrint('📭 Current order cleared in Firebase');
            return null;
          }
        } else {
          debugPrint('❌ Delivery boy document does not exist');
          return null;
        }
      } catch (e) {
        debugPrint('❌ Error processing current order snapshot: $e');
        rethrow;
      }
    });
  }

  /// Listen for the reason an order left this driver (admin reassignment).
  ///
  /// The backend writes `last_order_event` just before it clears current_order,
  /// so the app can explain the order disappearing instead of silently dropping
  /// the driver back to home. Separate from listenToCurrentOrder so the existing
  /// order flow is untouched.
  Stream<Map<String, dynamic>?> listenToLastOrderEvent(int deliveryBoyId) {
    return FirebaseFirestore.instance
        .collection('delivery_boys')
        .doc(deliveryBoyId.toString())
        .snapshots()
        .map((DocumentSnapshot snapshot) {
      try {
        if (!snapshot.exists) return null;

        final data = snapshot.data() as Map<String, dynamic>?;
        final event = data?['last_order_event'];

        if (event is Map) {
          return Map<String, dynamic>.from(event);
        }
        return null;
      } catch (e) {
        debugPrint('❌ Error processing last_order_event snapshot: $e');
        return null;
      }
    });
  }

  /// Delete the event once the driver has been shown it, so it is not replayed
  /// on the next app start.
  Future<void> clearLastOrderEvent(int deliveryBoyId) async {
    try {
      final deliveryBoyDoc =
          _firestore.collection('delivery_boys').doc(deliveryBoyId.toString());

      await deliveryBoyDoc.update({
        'last_order_event': FieldValue.delete(),
      });

      debugPrint('🗑️ last_order_event cleared from Firestore');
    } catch (e) {
      debugPrint('❌ Error clearing last_order_event from Firestore: $e');
    }
  }

  /// Clear current order from Firebase (when order is completed)
  Future<void> clearCurrentOrder(int deliveryBoyId) async {
    try {
      final deliveryBoyDoc =
          _firestore.collection('delivery_boys').doc(deliveryBoyId.toString());

      await deliveryBoyDoc.update({
        'current_order': FieldValue.delete(),
      });

      debugPrint('🗑️ Current order cleared from Firestore');
    } catch (e) {
      debugPrint('❌ Error clearing current order from Firestore: $e');
    }
  }

  /// Update driver location in current order
  /// This is called periodically when driver moves (distance-based)
  Future<void> updateDriverLocation({
    required int deliveryBoyId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final deliveryBoyDoc =
          _firestore.collection('delivery_boys').doc(deliveryBoyId.toString());

      await deliveryBoyDoc.set({
        'current_order': {
          'driver_location': {
            'latitude': latitude,
            'longitude': longitude,
            'updated_at': FieldValue.serverTimestamp(),
          },
        },
      }, SetOptions(merge: true));

      debugPrint('📍 Driver location updated: ($latitude, $longitude)');
    } catch (e) {
      debugPrint('❌ Error updating driver location: $e');
    }
  }

  /// Update delivery progress in Firebase
  /// Stores current step index and step statuses
  Future<void> updateDeliveryProgress({
    required int deliveryBoyId,
    required int currentStep,
    required List<String>
        stepStatuses, // ['notStarted', 'inProgress', 'completed']
  }) async {
    try {
      final deliveryBoyDoc =
          _firestore.collection('delivery_boys').doc(deliveryBoyId.toString());

      await deliveryBoyDoc.set({
        'current_order': {
          'delivery_progress': {
            'current_step': currentStep,
            'step_statuses': stepStatuses,
            'updated_at': FieldValue.serverTimestamp(),
          },
        },
      }, SetOptions(merge: true));

      debugPrint(
          '✅ Delivery progress updated: step $currentStep, statuses: $stepStatuses');
    } catch (e) {
      debugPrint('❌ Error updating delivery progress: $e');
    }
  }

  /// Get delivery progress from Firebase
  Future<Map<String, dynamic>?> getDeliveryProgress(int deliveryBoyId) async {
    try {
      final deliveryBoyDoc =
          _firestore.collection('delivery_boys').doc(deliveryBoyId.toString());

      final snapshot = await deliveryBoyDoc.get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null &&
            data.containsKey('current_order') &&
            data['current_order'] is Map &&
            (data['current_order'] as Map).containsKey('delivery_progress')) {
          debugPrint('📦 Found delivery progress in Firestore');
          return data['current_order']['delivery_progress']
              as Map<String, dynamic>;
        }
      }

      debugPrint('📭 No delivery progress found in Firestore');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting delivery progress from Firestore: $e');
      return null;
    }
  }

  /// Update order_eta document with delivery boy order status fields
  Future<void> updateOrderEtaWithDeliveryBoyStatus({
    required int orderId,
    required int deliveryBoyId,
    required String orderStatus,
    required String orderStatusDesc,
    String? sellerName,
  }) async {
    try {
      final orderEtaDoc =
          _firestore.collection('order_eta').doc(orderId.toString());

      await orderEtaDoc.set({
        'delivery_boy_id': deliveryBoyId,
        'driver_order_status': orderStatus,
        'driver_order_status_desc': orderStatusDesc,
        if (sellerName != null) 'seller_name': sellerName,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
          '✅ Order ETA updated with delivery boy status for order $orderId: $orderStatus - $orderStatusDesc');
    } catch (e) {
      debugPrint('❌ Error updating order ETA with delivery boy status: $e');
    }
  }

  /// Update order status when partner reaches pickup/delivery location
  Future<void> updateOrderStatusReached({
    required int orderId,
    required int deliveryBoyId,
    required String type, // 'reached_pickup' or 'reached_delivery'
    required String sellerName,
  }) async {
    try {
      final orderEtaDoc =
          _firestore.collection('order_eta').doc(orderId.toString());

      final orderStatus = type == 'reached_pickup'
          ? 'Reached to $sellerName'
          : 'Reached your location';
      final orderStatusDesc = type == 'reached_pickup'
          ? 'Your order has reached $sellerName.'
          : 'Your order has reached your location.';

      final updateData = {
        'driver_order_status': orderStatus,
        'driver_order_status_desc': orderStatusDesc,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Add is_checkout flag when reached to customer location (not pickup)
      if (type == 'reached_delivery') {
        updateData['is_checkout'] = 1;
        debugPrint('🔥 Firebase: Added is_checkout=1 to order ETA');
      }

      await orderEtaDoc.set(updateData, SetOptions(merge: true));

      debugPrint(
          '✅ Order $orderId status updated: $orderStatus - $orderStatusDesc');
    } catch (e) {
      debugPrint('❌ Error updating reached status: $e');
    }
  }

  /// Update order status when items are picked from seller
  Future<void> updateOrderStatusPickedUp({
    required int orderId,
    required int deliveryBoyId,
    required String sellerName,
    required String? nextSellerName,
  }) async {
    try {
      final orderEtaDoc =
          _firestore.collection('order_eta').doc(orderId.toString());

      const orderStatus = 'Order Picked up by Delivery';
      final orderStatusDesc = nextSellerName != null
          ? 'Arriving from $sellerName'
          : 'Order collected from $sellerName';

      await orderEtaDoc.set({
        'driver_order_status': orderStatus,
        'driver_order_status_desc': orderStatusDesc,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
          '✅ Order $orderId status updated: $orderStatus - $orderStatusDesc');
    } catch (e) {
      debugPrint('❌ Error updating picked up status: $e');
    }
  }

  /// Update order status when heading to next location
  Future<void> updateOrderStatusHeadingTo({
    required int orderId,
    required int deliveryBoyId,
    required String fromSellerName,
    required String toSellerName,
  }) async {
    try {
      final orderEtaDoc =
          _firestore.collection('order_eta').doc(orderId.toString());

      const orderStatus = 'On The Way';
      final orderStatusDesc =
          'Arriving from $fromSellerName\nYour order is arriving from $fromSellerName.';

      await orderEtaDoc.set({
        'driver_order_status': orderStatus,
        'driver_order_status_desc': orderStatusDesc,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
          '✅ Order $orderId status updated: $orderStatus - $orderStatusDesc');
    } catch (e) {
      debugPrint('❌ Error updating heading to status: $e');
    }
  }

  /// Update order status when heading to customer
  Future<void> updateOrderStatusHeadingToCustomer({
    required int orderId,
    required int deliveryBoyId,
    required String lastSellerName,
  }) async {
    try {
      final orderEtaDoc =
          _firestore.collection('order_eta').doc(orderId.toString());

      final orderStatus = 'Arriving from $lastSellerName';
      const orderStatusDesc = 'Partner is on the way to you';

      await orderEtaDoc.set({
        'driver_order_status': orderStatus,
        'driver_order_status_desc': orderStatusDesc,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
          '✅ Order $orderId status updated: $orderStatus - $orderStatusDesc');
    } catch (e) {
      debugPrint('❌ Error updating heading to customer status: $e');
    }
  }

  /// Update order status when partner is about to reach customer
  Future<void> updateOrderStatusAboutToArrive({
    required int orderId,
    required int deliveryBoyId,
  }) async {
    try {
      final orderEtaDoc =
          _firestore.collection('order_eta').doc(orderId.toString());

      const orderStatus = 'Reached your location';
      const orderStatusDesc = 'Your order has reached your location.';

      await orderEtaDoc.set({
        'driver_order_status': orderStatus,
        'driver_order_status_desc': orderStatusDesc,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
          '✅ Order $orderId status updated: $orderStatus - $orderStatusDesc');
    } catch (e) {
      debugPrint('❌ Error updating about to arrive status: $e');
    }
  }

  /// Update order status for checkout (review items before delivery completion)
  Future<void> updateOrderStatusCheckout({
    required int orderId,
    required int deliveryBoyId,
  }) async {
    try {
      final orderEtaDoc =
          _firestore.collection('order_eta').doc(orderId.toString());

      const orderStatus = 'Check Out Items';
      const orderStatusDesc = 'Please review and check out your items.';

      await orderEtaDoc.set({
        'driver_order_status': orderStatus,
        'driver_order_status_desc': orderStatusDesc,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
          '✅ Order $orderId status updated: $orderStatus - $orderStatusDesc');
    } catch (e) {
      debugPrint('❌ Error updating checkout status: $e');
    }
  }

  /// Update order status to delivered
  Future<void> updateOrderStatusDelivered({
    required int orderId,
    required int deliveryBoyId,
  }) async {
    try {
      final orderEtaDoc =
          _firestore.collection('order_eta').doc(orderId.toString());

      const orderStatus = 'Delivered';
      const orderStatusDesc = 'Order delivered successfully';

      await orderEtaDoc.set({
        'driver_order_status': orderStatus,
        'driver_order_status_desc': orderStatusDesc,
        'created': 1,
        'is_delivered': 1,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
          '✅ Order $orderId status updated: $orderStatus - $orderStatusDesc');
    } catch (e) {
      debugPrint('❌ Error updating delivered status: $e');
    }
  }

  /// Stop listening to Firestore
  void dispose() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
    _processedOrders.clear();
    debugPrint('🛑 Firestore order listener disposed');
  }
}
