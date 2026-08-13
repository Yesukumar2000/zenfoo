import 'dart:developer' as dev;

import 'package:zenfoo_partner/models/tips_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class TipsRepository {
  final ApiService _apiService = ApiService();

  /// Get weekly tips data
  /// Parameters:
  /// - offset: offset for navigation (0 = current week, -1 = previous week, 1 = next week, etc.)
  Future<ApiResponse> getWeeklyTips({int offset = 0}) async {
    try {
      dev.log('🌐 Making API call to: ${AppUrl.weeklyTips}',
          name: 'TipsRepository');

      final params = {'offset': offset.toString()};

      final response = await _apiService.get(
        AppUrl.weeklyTips,
        params: params,
      );

      dev.log('📡 API Response status: ${response.status}',
          name: 'TipsRepository');
      dev.log('📡 API Response data type: ${response.data?.runtimeType}',
          name: 'TipsRepository');

      return response;
    } catch (e) {
      dev.log('💥 API Error: $e', name: 'TipsRepository');
      return ApiResponse.error(e.toString());
    }
  }
}
