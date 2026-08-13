import 'dart:developer' as dev;

import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class WeatherRepository {
  final ApiService _apiService = ApiService();

  /// Check rain status at the driver's current coordinates
  Future<ApiResponse> checkRain({
    required double latitude,
    required double longitude,
  }) async {
    try {
      dev.log('🌐 Making API call to: ${AppUrl.weatherRainCheck}',
          name: 'WeatherRepository');

      final response = await _apiService.post(
        AppUrl.weatherRainCheck,
        data: {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
        },
        // Weather is a silent background check - never toast, never logout
        isToast: false,
        isErrorToast: false,
        skipLogout: true,
      );

      dev.log('📡 API Response status: ${response.status}',
          name: 'WeatherRepository');

      return response;
    } catch (e) {
      dev.log('💥 API Error: $e', name: 'WeatherRepository');
      return ApiResponse.error(e.toString());
    }
  }
}
