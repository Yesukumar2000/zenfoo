import 'dart:convert';
import 'dart:developer' as dev;

import 'package:zenfoo_partner/models/performance_earnings_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class PerformanceRepository {
  final ApiService _apiService = ApiService();

  /// Get performance and earnings data
  /// Parameters:
  /// - period: 'daily', 'weekly', or 'monthly' (default: 'daily')
  /// - offset: offset for navigation (0 = current, -1 = previous, 1 = next, etc.)
  /// - date: specific date (format: YYYY-MM-DD) - used when offset is not provided
  /// - fromDate: start date for range queries (format: YYYY-MM-DD)
  /// - toDate: end date for range queries (format: YYYY-MM-DD)
  Future<ApiResponse> getPerformanceEarnings({
    String period = 'daily',
    int? offset,
    String? date,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      dev.log('🌐 Making API call to: ${AppUrl.performanceEarnings}',
          name: 'PerformanceRepository');

      final params = {'period': period};

      // Use offset if provided, otherwise use date-based parameters
      if (offset != null) {
        params['offset'] = offset.toString();
        dev.log('📊 Using offset: $offset', name: 'PerformanceRepository');
      } else {
        if (date != null) params['date'] = date;
        if (fromDate != null) params['from_date'] = fromDate;
        if (toDate != null) params['to_date'] = toDate;
      }

      final response = await _apiService.get(
        AppUrl.performanceEarnings,
        params: params,
      );

      dev.log('📡 API Response status: ${response.status}',
          name: 'PerformanceRepository');
      dev.log('📡 API Response data type: ${response.data?.runtimeType}',
          name: 'PerformanceRepository');

      if (response.data != null) {
        dev.log('📡 API Response data: ${jsonEncode(response.data)}',
            name: 'PerformanceRepository');
      }

      return response;
    } catch (e) {
      dev.log('💥 API Error: $e', name: 'PerformanceRepository');
      return ApiResponse.error(e.toString());
    }
  }
}
