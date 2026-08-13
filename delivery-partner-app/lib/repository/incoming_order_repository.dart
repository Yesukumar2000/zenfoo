import 'package:flutter/foundation.dart';
import 'package:zenfoo_partner/models/incoming_order_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class IncomingOrderRepository {
  final ApiService _apiService;

  IncomingOrderRepository(this._apiService);

  /// Fetch order details by order IDs
  /// API: /api/delivery-boy/orders/seller-locations?order_ids=109,110
  Future<ApiResponse<List<IncomingOrder>>> getOrderDetails(
      List<int> orderIds) async {
    try {
      if (orderIds.isEmpty) {
        return ApiResponse.error('No order IDs provided');
      }

      // Join order IDs with comma
      final orderIdsParam = orderIds.join(',');

      final response = await _apiService.get(
        AppUrls.getorderDetails,
        params: {'order_ids': orderIdsParam},
      );

      if (response.status == ApiStatus.success && response.data != null) {
        final orderResponse = IncomingOrderResponse.fromJson(response.data);

        if (orderResponse.status == 1) {
          return ApiResponse.success(orderResponse.data);
        } else {
          return ApiResponse.error(orderResponse.message);
        }
      }

      return ApiResponse.error(response.message ?? 'Failed to fetch order details');
    } catch (e) {
      return ApiResponse.error('Error fetching order details: ${e.toString()}');
    }
  }

  /// Accept an order
  Future<ApiResponse<void>> acceptOrder(
    int orderId, {
    double? lat,
    double? lon,
  }) async {
    try {
      final data = <String, dynamic>{
        'order_id': orderId,
      };
      if (lat != null) data['lat'] = lat;
      if (lon != null) data['lon'] = lon;

      final response = await _apiService.post(
        AppUrls.acceptOrder,
        data: data,
      );

      if (response.status == ApiStatus.success) {
        return ApiResponse.success(null);
      }

      return ApiResponse.error(response.message ?? 'Failed to accept order');
    } catch (e) {
      return ApiResponse.error('Error accepting order: ${e.toString()}');
    }
  }

  /// Reject an order
  Future<ApiResponse<void>> rejectOrder(int orderId) async {
    try {
      final response = await _apiService.post(
        AppUrls.rejectOrder,
        data: {},
      );

      if (response.status == ApiStatus.success) {
        return ApiResponse.success(null);
      }

      return ApiResponse.error(response.message ?? 'Failed to reject order');
    } catch (e) {
      return ApiResponse.error('Error rejecting order: ${e.toString()}');
    }
  }

  /// Notify backend that order was cancelled/rejected
  Future<bool> cancelOrder(int orderId) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📡 [cancelOrder] Calling API');
      debugPrint('📡 [cancelOrder] URL: ${AppUrl.orderCancelled}');
      debugPrint('📡 [cancelOrder] Method: POST | Body: {order_id: $orderId}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await _apiService.post(
        AppUrl.orderCancelled,
        data: {'order_id': orderId},
      );

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📡 [cancelOrder] Response received');
      debugPrint('📡 [cancelOrder] ApiStatus: ${response.status}');
      debugPrint('📡 [cancelOrder] Message: ${response.message}');
      debugPrint('📡 [cancelOrder] Data: ${response.data}');
      debugPrint('📡 [cancelOrder] Success: ${response.status == ApiStatus.success}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return response.status == ApiStatus.success;
    } catch (e, st) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ [cancelOrder] Exception: $e');
      debugPrint('❌ [cancelOrder] StackTrace: $st');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return false;
    }
  }

  /// Fetch seller-specific order details with items and OTP
  /// API: /api/delivery-boy/orders/seller-details?order_id=109&seller_id=37
  Future<ApiResponse<IncomingOrder>> getSellerOrderDetails(
    int orderId,
    int sellerId,
  ) async {
    try {
      if (orderId <= 0 || sellerId <= 0) {
        return ApiResponse.error('Invalid order ID or seller ID');
      }

      final response = await _apiService.get(
        AppUrls.getOrderSellerData,
        params: {
          'order_id': orderId.toString(),
          'seller_id': sellerId.toString(),
        },
      );

      if (response.status == ApiStatus.success && response.data != null) {
        final jsonData = response.data as Map<String, dynamic>;
        final status = jsonData['status'] ?? 0;
        final message = jsonData['message'] ?? '';

        if (status == 1) {
          final orderData = jsonData['data'] as Map<String, dynamic>;
          final order = IncomingOrder.fromJson(orderData);
          return ApiResponse.success(order);
        } else {
          return ApiResponse.error(message);
        }
      }

      return ApiResponse.error(response.message ?? 'Failed to fetch seller order details');
    } catch (e) {
      return ApiResponse.error('Error fetching seller order details: ${e.toString()}');
    }
  }
}
