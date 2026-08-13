import 'dart:developer' as dev;

import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class WeeklySummaryRepository {
  final ApiService _apiService = ApiService();

  /// Get weekly summary data
  /// Parameters:
  /// - period: 'weekly'
  /// - offset: offset for navigation (0 = current week)
  Future<ApiResponse> getWeeklySummary({
    String period = 'weekly',
    int offset = 0,
  }) async {
    try {
      dev.log('🌐 Making API call to: ${AppUrl.weeklySummary}',
          name: 'WeeklySummaryRepository');

      final params = {
        'period': period,
        'offset': offset.toString(),
      };

      final response = await _apiService.get(
        AppUrl.weeklySummary,
        params: params,
      );

      dev.log('📡 API Response status: ${response.status}',
          name: 'WeeklySummaryRepository');
      dev.log('📡 API Response data type: ${response.data?.runtimeType}',
          name: 'WeeklySummaryRepository');

      return response;
    } catch (e) {
      dev.log('💥 API Error: $e', name: 'WeeklySummaryRepository');
      return ApiResponse.error(e.toString());
    }
  }
}
