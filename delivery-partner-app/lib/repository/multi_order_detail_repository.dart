import 'dart:developer' as dev;

import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class MultiOrderDetailRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse> getMultiOrderDetail({required int orderId}) async {
    try {
      dev.log('🌐 Making API call to: ${AppUrl.multiOrderDetail}?order_id=$orderId',
          name: 'MultiOrderDetailRepository');

      final response = await _apiService.get(
        AppUrl.multiOrderDetail,
        params: {'order_id': orderId.toString()},
      );

      dev.log('📡 API Response status: ${response.status}',
          name: 'MultiOrderDetailRepository');

      return response;
    } catch (e) {
      dev.log('💥 API Error: $e', name: 'MultiOrderDetailRepository');
      return ApiResponse.error(e.toString());
    }
  }
}
