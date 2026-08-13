import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class LanguageRepository {
  final ApiService _apiService = ApiService();

  /// Get list of available languages
  Future<ApiResponse> getAvailableLanguages({
    required Map<String, dynamic> params,
  }) async {
    try {
      final response = await _apiService.get(
        AppUrl.systemLanguages,
        params: params,
        isToast: false,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to fetch languages: $e');
    }
  }

  /// Get language translations by ID
  Future<ApiResponse> getLanguageData({
    required Map<String, dynamic> params,
  }) async {
    try {
      final response = await _apiService.get(
        AppUrl.systemLanguages,
        params: params,
        isToast: false,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to fetch language data: $e');
    }
  }
}
