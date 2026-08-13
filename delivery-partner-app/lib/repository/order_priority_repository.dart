import 'package:zenfoo_partner/models/order_priority_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class OrderPriorityRepository {
  final ApiService _apiService = ApiService();

  /// Get order priority settings
  Future<OrderPriorityResponse> getOrderPriority() async {
    try {
      final response = await _apiService.get(
        AppUrls.getOrderPriority,
      );

      if (response.status == ApiStatus.success) {
        return OrderPriorityResponse.fromJson(response.data);
      } else {
        throw Exception(response.message ?? 'Failed to fetch order priority');
      }
    } catch (e, stackTrace) {
      throw Exception('Error fetching order priority: $e\n$stackTrace');
    }
  }

  /// Update order priority
  Future<UpdateOrderPriorityResponse> updateOrderPriority(
      int ordersPriority) async {
    try {
      final response = await _apiService.post(
        AppUrls.updateOrderPriority,
        data: {'orders_priority': ordersPriority},
      );

      if (response.status == ApiStatus.success) {
        return UpdateOrderPriorityResponse.fromJson(response.data);
      } else {
        throw Exception(response.message ?? 'Failed to update order priority');
      }
    } catch (e, stackTrace) {
      throw Exception('Error updating order priority: $e\n$stackTrace');
    }
  }
}
