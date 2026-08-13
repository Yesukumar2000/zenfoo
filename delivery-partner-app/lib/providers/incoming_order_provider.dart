import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:zenfoo_partner/models/incoming_order_model.dart';
import 'package:zenfoo_partner/repository/incoming_order_repository.dart';
import 'package:zenfoo_partner/services/firebase_order_service.dart';
import 'package:zenfoo_partner/services/status.dart';

class IncomingOrderProvider with ChangeNotifier {
  final IncomingOrderRepository _repository;
  final FirebaseOrderService _firebaseService;

  IncomingOrderProvider(this._repository, this._firebaseService);

  // Current incoming orders
  List<IncomingOrder> _incomingOrders = [];
  List<IncomingOrder> get incomingOrders => _incomingOrders;

  // Current accepted order (for showing in home screen)
  IncomingOrder? _currentAcceptedOrder;
  IncomingOrder? get currentAcceptedOrder => _currentAcceptedOrder;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error state
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Stream subscription
  StreamSubscription? _orderStreamSubscription;

  // Current order listener subscription (for real-time updates when Firebase adds current_order)
  StreamSubscription? _currentOrderStreamSubscription;

  // Reason the current order left this driver (admin reassignment), written by
  // the backend just before it clears current_order. Held here until a widget
  // has shown it to the driver.
  StreamSubscription? _orderEventSubscription;
  Map<String, dynamic>? _pendingOrderEvent;
  Map<String, dynamic>? get pendingOrderEvent => _pendingOrderEvent;

  // Events already shown, so a rebuild or a re-emitted snapshot cannot show the
  // same dialog twice while the delete is still in flight.
  final Set<String> _handledOrderEventKeys = {};

  /// Check if order listener is currently active
  bool get isListening => _orderStreamSubscription != null;

  /// Check if current order listener is currently active
  bool get isListeningToCurrentOrder => _currentOrderStreamSubscription != null;

  /// Start listening to Firebase for new orders
  void startListening(int deliveryBoyId) {
    debugPrint(
        '🎧 Starting Firebase order listener for delivery boy $deliveryBoyId');
    debugPrint(
        '🎧 Current subscription status: ${_orderStreamSubscription != null ? "ACTIVE" : "NULL"}');

    // Cancel existing subscription if any
    if (_orderStreamSubscription != null) {
      debugPrint('⚠️ Canceling existing subscription before starting new one');
      _orderStreamSubscription?.cancel();
    }

    _orderStreamSubscription =
        _firebaseService.listenToOrders(deliveryBoyId).listen(
      (orderIds) async {
        debugPrint('📦 Received order IDs from Firebase: $orderIds');
        debugPrint('📦 Order IDs count: ${orderIds.length}');

        // Important: Always fetch, even if empty (means orders were deleted)
        // This ensures we update the UI when orders are removed
        await _fetchOrderDetails(orderIds, deliveryBoyId);
      },
      onError: (error) {
        debugPrint('❌ Firebase stream error: $error');
        _errorMessage = 'Failed to listen for orders: ${error.toString()}';
        notifyListeners();
      },
    );

    debugPrint('✅ Firebase listener subscription created successfully');
  }

  /// Fetch order details from API
  Future<void> _fetchOrderDetails(List<int> orderIds, int deliveryBoyId) async {
    if (orderIds.isEmpty) {
      // If no orders in Firebase, clear local list
      if (_incomingOrders.isNotEmpty) {
        debugPrint('🗑️ No orders in Firebase - clearing local list');
        _incomingOrders.clear();
        notifyListeners();
      }
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('📡 Fetching order details from API for orderIds: $orderIds');
      final response = await _repository.getOrderDetails(orderIds);

      if (response.status == ApiStatus.success && response.data != null) {
        final newOrders = response.data!;

        // Priority ordering for what the driver is offered first:
        //   1. Zenfoo-store orders come before non-Zenfoo orders.
        //   2. Within each group, the nearest order (shortest route distance) comes first.
        // The driver dialog always picks `incomingOrders.first`, so this controls
        // which order is shown/offered first.
        newOrders.sort((a, b) {
          if (a.hasZenfooStore != b.hasZenfooStore) {
            return a.hasZenfooStore ? -1 : 1; // Zenfoo orders first
          }
          return a.totalRouteDistanceKm
              .compareTo(b.totalRouteDistanceKm); // nearest first
        });

        // Track which orders were deleted (present in local list but not in new list)
        final deletedOrderIds = _incomingOrders
            .where((order) => !newOrders.any((o) => o.orderId == order.orderId))
            .map((order) => order.orderId)
            .toList();

        if (deletedOrderIds.isNotEmpty) {
          debugPrint('🗑️ Orders deleted: $deletedOrderIds');
        }

        _incomingOrders = newOrders;
        _errorMessage = null;
        debugPrint(
            '✅ Successfully fetched ${_incomingOrders.length} order(s) from API');
        debugPrint(
            '📋 First order ID: ${_incomingOrders.isNotEmpty ? _incomingOrders.first.orderId : 'N/A'}');
      } else {
        _errorMessage = response.message ?? 'Failed to fetch order details';
        debugPrint('❌ API response failed: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      debugPrint('❌ Exception fetching order details: $e');
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  /// Accept an order
  Future<bool> acceptOrder({
    required int orderId,
    required int deliveryBoyId,
    required double driverLat,
    required double driverLng,
  }) async {
    debugPrint('✅ Accepting order $orderId...');

    try {
      // Find the order in the local list
      final order = _incomingOrders.firstWhere(
        (o) => o.orderId == orderId,
        orElse: () => throw Exception('Order not found'),
      );

      final response = await _repository.acceptOrder(
        orderId,
        lat: driverLat,
        lon: driverLng,
      );

      if (response.status == ApiStatus.success) {
        // 1. Remove from local list FIRST to prevent dialog showing again
        _incomingOrders.removeWhere((order) => order.orderId == orderId);
        debugPrint('📭 Removed order $orderId from incoming orders list');

        // 2. Mark as processed BEFORE Firebase operations to prevent duplicate processing
        _firebaseService.markOrderAsProcessed(orderId);
        debugPrint('✅ Order $orderId marked as processed');

        // 3. Remove the order ID from Firebase
        await _firebaseService.removeOrderFromFirebase(deliveryBoyId, orderId);

        // 4. Save accepted order details with driver location to Firebase
        await _firebaseService.saveAcceptedOrder(
          deliveryBoyId: deliveryBoyId,
          orderId: orderId,
          driverLat: driverLat,
          driverLng: driverLng,
          orderDetails: _orderToMap(order),
        );

        // 5. Set as current accepted order for UI
        _currentAcceptedOrder = order;

        // 6. Stop listening for new orders since we have an active order
        stopListening();

        notifyListeners();
        debugPrint('✅ Order $orderId accepted successfully');
        debugPrint(
            '📍 Saved to Firebase with driver location: ($driverLat, $driverLng)');
        debugPrint(
            '🛑 Stopped listening for new orders (driver is on an order)');
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to accept order';
        debugPrint('❌ Failed to accept order: $_errorMessage');

        // Another driver won the race (or the offer expired). Drop it locally so
        // the popup closes right away instead of waiting for Firestore to catch up.
        if (_isDeadOffer(response.message)) {
          debugPrint('🏁 Offer for order $orderId is no longer available - dropping it');
          _incomingOrders.removeWhere((order) => order.orderId == orderId);
          _firebaseService.markOrderAsProcessed(orderId);
          await _firebaseService.removeOrderIdFromFirebase(deliveryBoyId, orderId);
        }

        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error accepting order: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ Exception accepting order: $e');
      return false;
    }
  }

  /// True when the accept/reject API says this offer can no longer be taken —
  /// another driver already accepted it, the offer expired, or the order moved on.
  /// In every case the order must disappear from this driver's screen.
  bool _isDeadOffer(String? message) {
    if (message == null) return false;

    final text = message.toLowerCase();
    return text.contains('already assigned') ||
        text.contains('was not notified') ||
        text.contains('cannot be accepted');
  }

  /// Reject an order
  Future<bool> rejectOrder(int orderId, int deliveryBoyId) async {
    debugPrint('❌ Rejecting order $orderId...');

    try {
      final response = await _repository.rejectOrder(orderId);

      if (response.status == ApiStatus.success) {
        // 1. Remove from local list FIRST to prevent dialog showing again
        _incomingOrders.removeWhere((order) => order.orderId == orderId);
        debugPrint('📭 Removed order $orderId from incoming orders list');

        // 2. Mark as processed BEFORE Firebase operations to prevent duplicate processing
        _firebaseService.markOrderAsProcessed(orderId);
        debugPrint('✅ Order $orderId marked as processed');

        // 3. Remove the order ID from Firebase
        await _firebaseService.removeOrderFromFirebase(deliveryBoyId, orderId);

        // 4. Add to rejected orders array in Firebase
        await _firebaseService.addRejectedOrder(
          deliveryBoyId: deliveryBoyId,
          orderId: orderId,
        );

        notifyListeners();
        debugPrint('❌ Order $orderId rejected successfully');
        debugPrint('📝 Added to rejected orders list in Firebase');
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to reject order';
        notifyListeners();
        debugPrint('❌ Failed to reject order: $_errorMessage');
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error rejecting order: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ Exception rejecting order: $e');
      return false;
    }
  }

  /// Notify backend that order was cancelled
  Future<bool> cancelOrder(int orderId) async {
    return await _repository.cancelOrder(orderId);
  }

  /// Convert IncomingOrder to Map for Firebase storage
  Map<String, dynamic> _orderToMap(IncomingOrder order) {
    return {
      'order_id': order.orderId,
      'order_type': order.orderType,
      'delivery_tip': order.deliveryTip,
      'total_order_value': order.totalOrderValue,
      'total_route_distance_km': order.totalRouteDistanceKm,
      'multi_order_bonus': order.multiOrderBonus,
      'delivery_charge': order.deliveryCharge,
      'driver': {
        'latitude': order.driver.latitude,
        'longitude': order.driver.longitude,
      },
      'customer': {
        if (order.customer.id != null) 'id': order.customer.id,
        'name': order.customer.name,
        'mobile': order.customer.mobile,
        'address': order.customer.address,
        'latitude': order.customer.latitude,
        'longitude': order.customer.longitude,
      },
      'sellers_visit_order': order.sellersVisitOrder
          .map((seller) => {
                if (seller.sellerId != null) 'seller_id': seller.sellerId,
                if (seller.storeId != null) 'store_id': seller.storeId,
                'store_name': seller.storeName,
                'seller_address': seller.sellerAddress,
                if (seller.sellerPhoneNumber != null)
                  'seller_phone_number': seller.sellerPhoneNumber,
                'latitude': seller.latitude,
                'longitude': seller.longitude,
                'distance_from_previous_km': seller.distanceFromPreviousKm,
                'is_zenfoo_store': seller.isZenfooStore,
                if (seller.isHandoffPoint) 'is_handoff_point': true,
              })
          .toList(),
    };
  }

  /// Get current accepted order from Firebase on app start
  Future<IncomingOrder?> getCurrentAcceptedOrder(int deliveryBoyId) async {
    debugPrint('📦 Checking for current accepted order...');

    try {
      final currentOrderData =
          await _firebaseService.getCurrentOrder(deliveryBoyId);

      if (currentOrderData != null) {
        // Safely extract order_details with null checks
        final orderDetails = currentOrderData['order_details'];

        if (orderDetails != null && orderDetails is Map<String, dynamic>) {
          try {
            final order = IncomingOrder.fromJson(orderDetails);

            // Store in state for UI access
            _currentAcceptedOrder = order;
            notifyListeners();

            debugPrint('✅ Found current accepted order: ${order.orderId}');
            return order;
          } catch (e) {
            debugPrint('❌ Error parsing current accepted order: $e');
            debugPrint('📄 Raw order_details: $orderDetails');
            return null;
          }
        } else {
          // Check for direct order_id (flat structure)
          if (currentOrderData.containsKey('order_id')) {
            try {
              debugPrint(
                  '🔄 Attempting to parse currentOrderData directly (fallback)...');
              final order = IncomingOrder.fromJson(currentOrderData);
              _currentAcceptedOrder = order;
              notifyListeners();
              debugPrint(
                  '✅ (Fallback) Found current accepted order: ${order.orderId}');
              return order;
            } catch (e) {
              debugPrint('❌ Fallback parsing failed: $e');
            }
          }

          // Check if it's just location data
          if (currentOrderData.containsKey('driver_location') &&
              !currentOrderData.containsKey('order_details')) {
            debugPrint(
                'ℹ️ Current order contains only driver_location - treating as no active order');
            _currentAcceptedOrder = null;
            return null;
          }

          debugPrint(
              '⚠️ Invalid order_details format in getCurrentAcceptedOrder');
          debugPrint('📄 Raw current_order data: $currentOrderData');

          _currentAcceptedOrder = null;
          return null;
        }
      }

      _currentAcceptedOrder = null;
      debugPrint('📭 No current accepted order found');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting current accepted order: $e');
      _currentAcceptedOrder = null;
      return null;
    }
  }

  /// Listen to Firebase for real-time current_order updates
  /// This is called on home screen to detect when Firebase adds current_order
  void startListeningToCurrentOrder(int deliveryBoyId) {
    debugPrint('🎧 Starting listener for current_order updates...');

    try {
      // Cancel existing subscription if any
      if (_currentOrderStreamSubscription != null) {
        debugPrint('⚠️ Canceling existing current order subscription');
        _currentOrderStreamSubscription?.cancel();
      }

      _currentOrderStreamSubscription =
          _firebaseService.listenToCurrentOrder(deliveryBoyId).listen(
        (orderData) {
          if (orderData != null) {
            debugPrint('📦 Received current_order update from Firebase');
            final orderDetailsData = orderData['order_details'];

            if (orderDetailsData != null &&
                orderDetailsData is Map<String, dynamic>) {
              try {
                final order = IncomingOrder.fromJson(orderDetailsData);
                _currentAcceptedOrder = order;
                notifyListeners();
                debugPrint(
                    '✅ Current order updated in home screen: ${order.orderId}');
              } catch (e) {
                debugPrint('❌ Error parsing order_details: $e');
                debugPrint('📄 Raw order_details data: $orderDetailsData');
              }
            } else {
              // Fallback: Try to parse the parent object if order_details is missing

              // CRITICAL FIX: explicit check for order_id to distinguish
              // between a flat order object and a just-location update
              if (orderData.containsKey('order_id')) {
                debugPrint(
                    '⚠️ Invalid or missing order_details in Firebase data, but found order_id');
                debugPrint(
                    '� Attempting to parse current_order directly (fallback)...');

                try {
                  final order = IncomingOrder.fromJson(orderData);
                  _currentAcceptedOrder = order;
                  notifyListeners();
                  debugPrint(
                      '✅ (Fallback) Parsed current_order directly: ${order.orderId}');
                  return;
                } catch (e) {
                  debugPrint('❌ Fallback parsing failed: $e');
                }
              } else {
                // It's likely just a location update or some other non-order data
                // Do NOT treat this as an error or a cleared order
                debugPrint(
                    'ℹ️ Ignoring current_order update - no order_id found (likely just location update)');
                debugPrint('📄 Data keys: ${orderData.keys.toList()}');
                // Do not set _currentAcceptedOrder to null here, keep existing state
                return;
              }

              // Only clear if we genuinely failed to parse what looked like an order
              // or if we decide this state implies no order.
              // But for safety, if we're unsure, better to not clear existing state?
              // Actually, if we are listening to a stream, and we get a document that
              // DOES NOT have an order... it implies there is no order?
              // BUT: The log said: "Raw current_order data: {driver_location: ...}"
              // This update REPLACED the previous content? Or is it a merge?
              // Firestore snapshots return the WHOLE document data for that field.
              // So if the field is just {driver_location: ...}, then there is NO order.

              _currentAcceptedOrder = null;
              notifyListeners();
            }
          } else {
            debugPrint('📭 Current order cleared');
            _currentAcceptedOrder = null;
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('❌ Error listening to current order: $error');
        },
      );

      debugPrint('✅ Current order listener started');

      // Shares this listener's lifecycle - started and stopped together.
      _startListeningToOrderEvents(deliveryBoyId);
    } catch (e) {
      debugPrint('❌ Error starting current order listener: $e');
    }
  }

  /// Listen for the reason an order left this driver.
  ///
  /// Kept separate from the current_order listener: an order can also disappear
  /// because the driver completed it, and only the backend knows which case it
  /// is. No event on the document means stay silent.
  void _startListeningToOrderEvents(int deliveryBoyId) {
    try {
      _orderEventSubscription?.cancel();

      _orderEventSubscription =
          _firebaseService.listenToLastOrderEvent(deliveryBoyId).listen(
        (event) {
          if (event == null) return;

          // created_at is part of the key so a second reassignment of the same
          // order is still shown.
          final key = '${event['order_id']}:${event['created_at']}';
          if (_handledOrderEventKeys.contains(key)) return;

          _handledOrderEventKeys.add(key);
          _pendingOrderEvent = event;
          notifyListeners();

          debugPrint('📣 Order event received: ${event['type']} '
              'for order ${event['order_id']}');
        },
        onError: (error) {
          debugPrint('❌ Error listening to order events: $error');
        },
      );
    } catch (e) {
      debugPrint('❌ Error starting order event listener: $e');
    }
  }

  /// Called once the driver has been shown the event. Drops it locally and
  /// deletes it from Firestore so it is not replayed on the next app start.
  Future<void> consumeOrderEvent(int deliveryBoyId) async {
    if (_pendingOrderEvent == null) return;

    _pendingOrderEvent = null;
    notifyListeners();

    await _firebaseService.clearLastOrderEvent(deliveryBoyId);
  }

  /// Stop listening to current order updates
  void stopListeningToCurrentOrder() {
    _currentOrderStreamSubscription?.cancel();
    _currentOrderStreamSubscription = null;
    _orderEventSubscription?.cancel();
    _orderEventSubscription = null;
    debugPrint('🛑 Current order listener stopped');
  }

  /// Clear current accepted order (when order is completed or cancelled)
  Future<void> clearCurrentAcceptedOrder(int deliveryBoyId) async {
    await _firebaseService.clearCurrentOrder(deliveryBoyId);
    _currentAcceptedOrder = null;
    notifyListeners();
    debugPrint('🗑️ Current accepted order cleared');
  }

  /// Set current accepted order (after accepting)
  void setCurrentAcceptedOrder(IncomingOrder order) {
    _currentAcceptedOrder = order;
    notifyListeners();
    debugPrint('📦 Current accepted order set: ${order.orderId}');
  }

  /// Stop listening to Firebase
  void stopListening() {
    debugPrint('🛑 Stopping Firebase order listener');
    _orderStreamSubscription?.cancel();
    _orderStreamSubscription = null;
    _incomingOrders.clear();
    _firebaseService.clearProcessedOrders();
    notifyListeners();
  }

  /// Clear all orders (useful when going offline)
  void clearOrders() {
    _incomingOrders.clear();
    _errorMessage = null;
    _firebaseService.clearProcessedOrders();
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    stopListeningToCurrentOrder();
    _firebaseService.dispose();
    super.dispose();
  }
}
