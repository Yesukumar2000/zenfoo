import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:project/services/firebase_eta_service.dart';

/// Provider for managing ETA state across the app
/// Handles Firebase real-time listeners and exposes ETA data to UI
class EtaProvider extends ChangeNotifier {
  final FirebaseEtaService _etaService = FirebaseEtaService();

  // Map to store ETA data for each order
  final Map<int, OrderEta?> _orderEtaMap = {};

  // Map to manage active stream subscriptions
  final Map<int, StreamSubscription<OrderEta?>> _etaSubscriptions = {};

  /// Get ETA for a specific order
  /// Returns null if ETA hasn't been loaded yet
  OrderEta? getOrderEta(int orderId) {
    return _orderEtaMap[orderId];
  }

  /// Start listening to real-time ETA updates for an order
  /// Automatically starts listening and notifies listeners on changes
  void listenToOrderEta(int orderId) {
    // Cancel existing subscription if any
    _etaSubscriptions[orderId]?.cancel();

    _etaSubscriptions[orderId] = _etaService
        .listenToOrderEta(orderId: orderId)
        .listen((eta) {
      _orderEtaMap[orderId] = eta;
      notifyListeners();
    }, onError: (error) {
      debugPrint('❌ Error listening to ETA for order $orderId: $error');
      _orderEtaMap[orderId] = null;
      notifyListeners();
    });
  }

  /// Stop listening to ETA updates for an order
  void stopListeningToOrderEta(int orderId) {
    _etaSubscriptions[orderId]?.cancel();
    _etaSubscriptions.remove(orderId);
    _orderEtaMap.remove(orderId);
    // Don't call notifyListeners() during dispose to avoid widget tree locked error
  }

  /// Set initial ETA for an order
  /// [orderId] - The order ID
  /// [etaMinutes] - Preparation time in minutes
  /// [sellerCount] - Number of sellers (default 1)
  Future<bool> setEta({
    required int orderId,
    required int etaMinutes,
    int sellerCount = 1,
  }) async {
    return await _etaService.setEta(
      orderId: orderId,
      etaMinutes: etaMinutes,
      sellerCount: sellerCount,
    );
  }

  /// Update ETA with adjustment
  /// Calculates from current remaining time and applies adjustment divided by seller_count
  /// [orderId] - The order ID
  /// [adjustmentMinutes] - Minutes to add (positive) or subtract (negative)
  /// [sellerCount] - Number of sellers (overrides Firebase value if provided)
  Future<bool> updateEta({
    required int orderId,
    required int adjustmentMinutes,
    int? sellerCount,
  }) async {
    return await _etaService.updateEta(
      orderId: orderId,
      adjustmentMinutes: adjustmentMinutes,
      sellerCount: sellerCount,
    );
  }

  /// Reduce ETA when order is marked as prepared
  /// Reduces Firebase eta by API's remaining prep time / seller_count
  /// [orderId] - The order ID
  /// [apiPrepTime] - Current prep time from API (in minutes)
  /// [sellerCount] - Number of sellers (overrides Firebase value if provided)
  Future<bool> reduceEtaOnPrepared({
    required int orderId,
    required int apiPrepTime,
    int? sellerCount,
  }) async {
    return await _etaService.reducePreparedEta(
      orderId: orderId,
      apiPrepTime: apiPrepTime,
      sellerCount: sellerCount,
    );
  }

  /// Check if ETA exists and has data for an order
  bool hasEta(int orderId) {
    return _orderEtaMap.containsKey(orderId) && _orderEtaMap[orderId] != null;
  }

  /// Get remaining minutes for an order
  /// Returns 0 if ETA not found
  int getRemainingMinutes(int orderId) {
    return _orderEtaMap[orderId]?.remainingMinutes ?? 0;
  }

  /// Get remaining duration for an order
  Duration getRemainingDuration(int orderId) {
    return _orderEtaMap[orderId]?.remainingDuration ?? Duration.zero;
  }

  /// Check if ETA is expired for an order
  bool isExpired(int orderId) {
    return _orderEtaMap[orderId]?.isExpired ?? false;
  }

  /// Check if ETA is urgent (5 minutes or less) for an order
  bool isUrgent(int orderId) {
    return _orderEtaMap[orderId]?.isUrgent ?? false;
  }

  @override
  void dispose() {
    // Cancel all active subscriptions
    for (var subscription in _etaSubscriptions.values) {
      subscription.cancel();
    }
    _etaSubscriptions.clear();
    _orderEtaMap.clear();
    super.dispose();
  }
}
