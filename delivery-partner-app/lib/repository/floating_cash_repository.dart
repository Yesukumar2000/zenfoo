import 'dart:developer' as dev;

import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class FloatingCashRepository {
  final ApiService _apiService = ApiService();

  /// Get floating cash data
  /// Parameters:
  /// - period: 'daily', 'weekly', or 'monthly'
  /// - offset: offset for navigation (0 = current, -1 = previous, 1 = next, etc.)
  Future<ApiResponse> getFloatingCash({
    String period = 'weekly',
    int offset = 0,
  }) async {
    try {
      dev.log('🌐 Making API call to: ${AppUrl.floatingCash}',
          name: 'FloatingCashRepository');

      final params = {
        'period': period,
        'offset': offset.toString(),
      };

      final response = await _apiService.get(
        AppUrl.floatingCash,
        params: params,
      );

      dev.log('📡 API Response status: ${response.status}',
          name: 'FloatingCashRepository');
      dev.log('📡 API Response data type: ${response.data?.runtimeType}',
          name: 'FloatingCashRepository');

      return response;
    } catch (e) {
      dev.log('💥 API Error: $e', name: 'FloatingCashRepository');
      return ApiResponse.error(e.toString());
    }
  }
}
