import 'dart:developer' as dev;

import 'package:zenfoo_partner/models/multi_order_earnings_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class MultiOrderEarningsRepository {
  final ApiService _apiService = ApiService();

  /// Get multi-order earnings data
  /// Parameters:
  /// - period: 'weekly' or 'monthly'
  /// - offset: offset for navigation (0 = current period, -1 = previous, 1 = next, etc.)
  Future<ApiResponse> getMultiOrderEarnings({
    required String period,
    int offset = 0,
  }) async {
    try {
      dev.log('🌐 Making API call to: ${AppUrl.multiOrderEarnings}',
          name: 'MultiOrderEarningsRepository');

      final params = {
        'period': period,
        'offset': offset.toString(),
      };

      final response = await _apiService.get(
        AppUrl.multiOrderEarnings,
        params: params,
      );

      dev.log('📡 API Response status: ${response.status}',
          name: 'MultiOrderEarningsRepository');
      dev.log('📡 API Response data type: ${response.data?.runtimeType}',
          name: 'MultiOrderEarningsRepository');

      return response;
    } catch (e) {
      dev.log('💥 API Error: $e', name: 'MultiOrderEarningsRepository');
      return ApiResponse.error(e.toString());
    }
  }
}
