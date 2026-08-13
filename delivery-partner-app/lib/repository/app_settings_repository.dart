import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class AppSettingsRepository {
  final ApiService _apiService = ApiService();

  /// Fetch app settings from the backend
  /// Returns decoded settings data as a Map
  Future<Map<String, dynamic>?> getAppSettings({
    required Map<String, dynamic> params,
  }) async {
    try {
      final response = await _apiService.get(
        AppUrl.appSettings,
        params: params,
      );

      // Check if response is successful
      if (response.status == ApiStatus.success && response.data != null) {
        final Map<String, dynamic> responseData = response.data;

        // Check if settings data exists
        if (responseData['data'] == null) {
          debugPrint('⚠️ App Settings: No data in response');
          return null;
        }

        // Decode base64 encoded settings
        List<int> decodedBytes = base64.decode(responseData['data'].toString());
        String decodedString = utf8.decode(decodedBytes);
        Map<String, dynamic> decodedSettings = json.decode(decodedString);

        debugPrint('✅ App Settings: Successfully fetched and decoded');
        return decodedSettings;
      }

      debugPrint('⚠️ App Settings: Failed with status ${response.status}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching app settings: $e');
      return null;
    }
  }
}
