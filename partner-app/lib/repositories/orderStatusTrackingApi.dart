import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/generalMethods.dart' as GeneralMethods;

class OrderStatusTrackingRepository {
  // Fetch orders with status tracking
  Future<Map<String, dynamic>> getOrderStatusTracking({
    String? orderStatus,
    String? fromDate,
    String? toDate,
    String? date,
    String? orderId,
    String? search,
  }) async {
    try {
      Map<String, String> params = {};

      if (orderStatus != null && orderStatus.isNotEmpty) {
        params[ApiAndParams.orderStatus] = orderStatus;
      }
      if (fromDate != null && fromDate.isNotEmpty) {
        params[ApiAndParams.fromDate] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        params[ApiAndParams.toDate] = toDate;
      }
      if (date != null && date.isNotEmpty) {
        params[ApiAndParams.date] = date;
      }
      if (orderId != null && orderId.isNotEmpty) {
        params[ApiAndParams.orderId] = orderId;
      }
      if (search != null && search.isNotEmpty) {
        params[ApiAndParams.search] = search;
      }

      var response = await GeneralMethods.sendApiRequest(
        apiName: ApiAndParams.apiOrdersStatusTracking,
        params: params,
        isPost: false,
      );

      return json.decode(response);
    } catch (e) {
      throw Exception('Failed to fetch order status tracking: $e');
    }
  }

  // Get order statistics by status
  Future<Map<String, dynamic>> getOrderStatistics({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      Map<String, String> params = {};

      if (fromDate != null && fromDate.isNotEmpty) {
        params[ApiAndParams.fromDate] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        params[ApiAndParams.toDate] = toDate;
      }

      var response = await GeneralMethods.sendApiRequest(
        apiName: 'orders/status-tracking',
        params: params,
        isPost: false,
      );

      return json.decode(response);
    } catch (e) {
      throw Exception('Failed to fetch order statistics: $e');
    }
  }
}
