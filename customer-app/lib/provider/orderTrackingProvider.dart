import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/deliveryBoyOrder.dart';
import 'package:project/helper/utils/deliveryTrackingService.dart';

enum OrderTrackingState {
  initial,
  loading,
  loaded,
  error,
}

class SellerLocation {
  final String sellerId;
  final String sellerName;
  final double latitude;
  final double longitude;

  SellerLocation({
    required this.sellerId,
    required this.sellerName,
    required this.latitude,
    required this.longitude,
  });
}

class OrderTrackingProvider extends ChangeNotifier {
  // ============ EXISTING STATE ============
  OrderTrackingState trackingState = OrderTrackingState.initial;
  String message = '';
  List<Order> activeOrders = [];
  int currentOrderIndex = 0;
  bool hasActiveOrders = false;

  // For map tracking
  double? deliveryBoyLatitude;
  double? deliveryBoyLongitude;

  // Seller locations (extracted from order items)
  List<SellerLocation> sellerLocations = [];

  // ============ FIREBASE REAL-TIME TRACKING STATE ============
  StreamSubscription<DeliveryBoyOrder?>? _firebaseSubscription;
  bool _isFirebaseActive = false;
  DeliveryBoyOrder? _firebaseData;
  String? _firebaseError;
  final DeliveryTrackingService _trackingService = DeliveryTrackingService();

  // Lifecycle management
  bool _isDisposed = false;
  Timer? _locationUpdateDebounce;

  // ============ PUBLIC GETTERS ============

  // Get current active order based on index
  Order? get currentActiveOrder =>
      activeOrders.isNotEmpty ? activeOrders[currentOrderIndex] : null;

  // Firebase state getters
  bool get isFirebaseActive => _isFirebaseActive;
  DeliveryBoyOrder? get firebaseData => _firebaseData;
  DeliveryProgress? get deliveryProgress => _firebaseData?.deliveryProgress;
  String? get firebaseError => _firebaseError;

  // Real-time location with Firebase priority
  double? get realTimeDeliveryBoyLatitude {
    if (_isFirebaseActive &&
        _firebaseData?.driverLocation?.latitude != null &&
        _firebaseData!.driverLocation!.latitude != 0.0) {
      return _firebaseData!.driverLocation!.latitude;
    }
    return deliveryBoyLatitude; // Fallback to API
  }

  double? get realTimeDeliveryBoyLongitude {
    if (_isFirebaseActive &&
        _firebaseData?.driverLocation?.longitude != null &&
        _firebaseData!.driverLocation!.longitude != 0.0) {
      return _firebaseData!.driverLocation!.longitude;
    }
    return deliveryBoyLongitude; // Fallback to API
  }

  // Last location update timestamp
  DateTime? get lastLocationUpdate => _firebaseData?.driverLocation?.updatedAt;

  // Fetch all active orders
  Future<void> fetchActiveOrder({
    required BuildContext context,
  }) async {
    trackingState = OrderTrackingState.loading;
    notifyListeners();

    try {
      Map<String, String> params = {
        ApiAndParams.type: ApiAndParams.active, // Active orders
        ApiAndParams.limit: '10', // Get up to 10 active orders
        ApiAndParams.offset: '0',
      };

      Map<String, dynamic> getData =
          await fetchOrders(context: context, params: params);

      if (getData[ApiAndParams.status].toString() == "1") {
        List ordersList = getData['data'] as List;
        if (ordersList.isNotEmpty) {
          activeOrders = ordersList
              .map((e) => Order.fromJson(Map.from(e ?? {})))
              .where((order) {
            // Only include orders that should be tracked
            String status = order.activeStatus ?? '1';
            return ['1', '2', '3', '4', '5'].contains(status);
          }).toList();

          hasActiveOrders = activeOrders.isNotEmpty;
          currentOrderIndex = 0;

          // Extract delivery boy location for current order if available
          if (currentActiveOrder?.latitude != null &&
              currentActiveOrder?.longitude != null) {
            deliveryBoyLatitude =
                double.tryParse(currentActiveOrder!.latitude!);
            deliveryBoyLongitude =
                double.tryParse(currentActiveOrder!.longitude!);
          }
        } else {
          hasActiveOrders = false;
          activeOrders = [];
        }
        trackingState = OrderTrackingState.loaded;
        notifyListeners();

        // Start Firebase tracking after API load completes
        await startFirebaseTracking();
      } else {
        hasActiveOrders = false;
        activeOrders = [];
        trackingState = OrderTrackingState.loaded;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      trackingState = OrderTrackingState.error;
      hasActiveOrders = false;
      activeOrders = [];
      notifyListeners();
    }
  }

  // Navigate to next order
  void nextOrder() {
    if (activeOrders.isNotEmpty &&
        currentOrderIndex < activeOrders.length - 1) {
      currentOrderIndex++;
      _updateDeliveryBoyLocation();
      notifyListeners();

      // Restart Firebase tracking for new order
      startFirebaseTracking();
    }
  }

  // Navigate to previous order
  void previousOrder() {
    if (currentOrderIndex > 0) {
      currentOrderIndex--;
      _updateDeliveryBoyLocation();
      notifyListeners();

      // Restart Firebase tracking for new order
      startFirebaseTracking();
    }
  }

  // Set specific order index
  void setOrderIndex(int index) {
    if (index >= 0 && index < activeOrders.length) {
      currentOrderIndex = index;
      _updateDeliveryBoyLocation();
      notifyListeners();

      // Restart Firebase tracking for new order
      startFirebaseTracking();
    }
  }

  // Update delivery boy location and seller locations based on current order
  void _updateDeliveryBoyLocation() {
    if (currentActiveOrder?.latitude != null &&
        currentActiveOrder?.longitude != null) {
      deliveryBoyLatitude = double.tryParse(currentActiveOrder!.latitude!);
      deliveryBoyLongitude = double.tryParse(currentActiveOrder!.longitude!);
    } else {
      deliveryBoyLatitude = null;
      deliveryBoyLongitude = null;
    }

    // Extract unique seller locations from order items
    _extractSellerLocations();
  }

  // Extract unique seller locations from current order's grouped_by_store structure
  void _extractSellerLocations() {
    sellerLocations.clear();

    if (currentActiveOrder?.groupedByStore == null ||
        currentActiveOrder!.groupedByStore!.isEmpty) {
      return;
    }

    // Use a map to track unique sellers by sellerId
    Map<String, SellerLocation> uniqueSellers = {};

    for (var store in currentActiveOrder!.groupedByStore!) {
      if (store.sellers != null) {
        for (var seller in store.sellers!) {
          if (seller.sellerId != null && seller.hasValidLocation()) {
            double lat = seller.getLatitude()!;
            double lng = seller.getLongitude()!;

            // Add to unique sellers map (will overwrite if same sellerId)
            uniqueSellers[seller.sellerId.toString()] = SellerLocation(
              sellerId: seller.sellerId.toString(),
              sellerName: seller.sellerName ?? 'Seller',
              latitude: lat,
              longitude: lng,
            );
          }
        }
      }
    }

    sellerLocations = uniqueSellers.values.toList();
  }

  // Get order status text
  String getOrderStatusText() {
    if (currentActiveOrder == null) return '';

    String status = currentActiveOrder!.activeStatus ?? '1';
    switch (status) {
      case '1':
        return 'Order Placed';
      case '2':
        return 'Processing';
      case '3':
        return 'Out for Delivery';
      case '4':
        return 'Delivered';
      case '5':
        return 'Cancelled';
      default:
        return 'Preparing';
    }
  }

  // Get order status color
  Color getOrderStatusColor() {
    if (currentActiveOrder == null) return const Color(0xFF9AC444);

    String status = currentActiveOrder!.activeStatus ?? '1';
    switch (status) {
      case '1':
        return const Color(0xFF2196F3); // Blue - Placed
      case '2':
        return const Color(0xFFFF9800); // Orange - Processing
      case '3':
        return const Color(0xFF9AC444); // Green - Out for delivery
      case '4':
        return const Color(0xFF4CAF50); // Dark Green - Delivered
      case '5':
        return const Color(0xFFE53E3E); // Red - Cancelled
      default:
        return const Color(0xFF9AC444);
    }
  }

  // Check if order should show overlay (only for active orders)
  bool shouldShowOverlay() {
    return hasActiveOrders && activeOrders.isNotEmpty;
  }

  // Update order (when coming from detail screen)
  void updateCurrentOrder(Order order) {
    // Find and update the order in the list
    int index = activeOrders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      activeOrders[index] = order;
      if (currentOrderIndex == index) {
        _updateDeliveryBoyLocation();
        // Restart Firebase tracking if delivery boy changed
        startFirebaseTracking();
      }
    } else {
      // Add new order if not found
      activeOrders.insert(0, order);
      currentOrderIndex = 0;
      _updateDeliveryBoyLocation();
      // Start Firebase tracking for new order
      startFirebaseTracking();
    }
    hasActiveOrders = activeOrders.isNotEmpty;
    notifyListeners();
  }

  // Clear active orders
  void clearActiveOrder() {
    activeOrders = [];
    currentOrderIndex = 0;
    hasActiveOrders = false;
    deliveryBoyLatitude = null;
    deliveryBoyLongitude = null;
    notifyListeners();
  }

  // Refresh tracking data
  Future<void> refreshTracking({required BuildContext context}) async {
    await fetchActiveOrder(context: context);
  }

  // ============ FIREBASE REAL-TIME TRACKING METHODS ============

  /// Start Firebase real-time listener for current order
  Future<void> startFirebaseTracking() async {
    debugPrint('🔥 [Provider] startFirebaseTracking() called');
    debugPrint(
        '🔥 [Provider] Order: ${currentActiveOrder?.id}, Disposed: $_isDisposed');

    if (_isDisposed || currentActiveOrder == null) {
      debugPrint('⚠️ [Provider] Disposed or no order, stopping Firebase');
      await _stopFirebaseTracking();
      return;
    }

    final deliveryBoyId = currentActiveOrder!.deliveryBoyId;
    debugPrint('🔥 [Provider] Delivery boy ID: $deliveryBoyId');

    if (deliveryBoyId == null ||
        deliveryBoyId.isEmpty ||
        deliveryBoyId == 'null') {
      debugPrint('❌ [Provider] Invalid delivery boy ID, stopping Firebase');
      await _stopFirebaseTracking();
      return;
    }

    // Avoid restarting if already tracking same order
    if (_isFirebaseActive && _firebaseData?.orderId == currentActiveOrder!.id) {
      debugPrint('✅ [Provider] Already tracking this order, skipping restart');
      return;
    }

    // Clean up existing subscription
    await _firebaseSubscription?.cancel();

    try {
      debugPrint('🔥 [Provider] Checking Firebase availability...');
      // Check Firebase availability with timeout
      final isAvailable = await _trackingService
          .isFirestoreAvailable()
          .timeout(const Duration(seconds: 10));

      if (!isAvailable) {
        debugPrint('❌ [Provider] Firebase service unavailable');
        _isFirebaseActive = false;
        _firebaseError = 'Firebase service unavailable';
        notifyListeners();
        return;
      }

      debugPrint(
          '✅ [Provider] Firebase available, starting listener for $deliveryBoyId');
      // Start listening to Firebase stream
      _firebaseSubscription =
          _trackingService.listenToDeliveryTracking(deliveryBoyId).listen(
                _handleFirebaseUpdate,
                onError: _handleFirebaseError,
                cancelOnError: false,
              );
      debugPrint('✅ [Provider] Firebase listener started');
    } catch (e) {
      debugPrint('❌ [Provider] Error starting Firebase: $e');
      _isFirebaseActive = false;
      _firebaseError = 'Failed to start tracking: $e';
      notifyListeners();
    }
  }

  /// Handle Firebase data updates with debouncing
  void _handleFirebaseUpdate(DeliveryBoyOrder? firebaseData) {
    debugPrint(
        '📡 [Provider] Firebase update received: ${firebaseData?.orderId}');
    if (_isDisposed) {
      debugPrint('❌ [Provider] Disposed, ignoring update');
      return;
    }

    // Cancel previous debounce
    _locationUpdateDebounce?.cancel();

    // Debounce to prevent excessive rebuilds
    _locationUpdateDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_isDisposed) return;

      final hadData = _firebaseData != null;
      _firebaseData = firebaseData;
      _isFirebaseActive = firebaseData != null;
      _firebaseError = null;

      debugPrint(
          '✅ [Provider] Update applied - Active: $_isFirebaseActive, Location: ${firebaseData?.driverLocation}');

      // Only notify if meaningful change
      if (firebaseData != null || hadData) {
        notifyListeners();
      }
    });
  }

  /// Handle Firebase stream errors
  void _handleFirebaseError(dynamic error) {
    if (_isDisposed) return;

    _isFirebaseActive = false;
    _firebaseError = 'Tracking error: $error';

    // Don't clear data immediately - keep last known location
    notifyListeners();
  }

  /// Stop Firebase tracking and cleanup
  Future<void> _stopFirebaseTracking() async {
    _locationUpdateDebounce?.cancel();
    await _firebaseSubscription?.cancel();

    _firebaseSubscription = null;
    _isFirebaseActive = false;
    _firebaseData = null;
    _firebaseError = null;

    notifyListeners();
  }

  // ============ RATING SUBMISSION METHODS ============

  /// Submit driver rating
  Future<bool> submitDriverRating({
    required int orderId,
    required int rating,
    String? review,
    required BuildContext context,
  }) async {
    try {
      final response = await ratingDriver(
        orderId: orderId,
        rating: rating,
        review: review,
        context: context,
      );

      if (response[ApiAndParams.status].toString() == "1") {
        return true;
      } else {
        showMessage(
          context,
          response[ApiAndParams.message] ?? "Failed to submit driver rating",
          MessageType.error,
        );
        return false;
      }
    } catch (e) {
      showMessage(
        context,
        "Error submitting driver rating: ${e.toString()}",
        MessageType.error,
      );
      return false;
    }
  }

  /// Submit seller rating
  Future<bool> submitSellerRating({
    required int orderId,
    required int storeId,
    required int rating,
    String? review,
    required BuildContext context,
  }) async {
    try {
      final response = await ratingSeller(
        orderId: orderId,
        storeId: storeId,
        rating: rating,
        review: review,
        context: context,
      );

      if (response[ApiAndParams.status].toString() == "1") {
        return true;
      } else {
        showMessage(
          context,
          response[ApiAndParams.message] ?? "Failed to submit seller rating",
          MessageType.error,
        );
        return false;
      }
    } catch (e) {
      showMessage(
        context,
        "Error submitting seller rating: ${e.toString()}",
        MessageType.error,
      );
      return false;
    }
  }

  /// Submit product rating
  Future<bool> submitProductRating({
    required int orderId,
    required int productId,
    required int rating,
    String? review,
    required BuildContext context,
  }) async {
    try {
      final response = await ratingProduct(
        orderId: orderId,
        productId: productId,
        rating: rating,
        review: review,
        context: context,
      );

      if (response[ApiAndParams.status].toString() == "1") {
        return true;
      } else {
        showMessage(
          context,
          response[ApiAndParams.message] ?? "Failed to submit product rating",
          MessageType.error,
        );
        return false;
      }
    } catch (e) {
      showMessage(
        context,
        "Error submitting product rating: ${e.toString()}",
        MessageType.error,
      );
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    await _stopFirebaseTracking();
    super.dispose();
  }
}
