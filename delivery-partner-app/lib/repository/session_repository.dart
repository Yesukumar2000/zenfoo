import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class SessionRepository {
  final ApiService _apiService = ApiService();

  /// Start a new work session
  /// Parameters:
  /// - latitude: Current latitude
  /// - longitude: Current longitude
  /// - gigBookingId: Optional gig booking ID if starting session for a specific gig
  Future<ApiResponse> startSession({
    required double latitude,
    required double longitude,
    int? gigBookingId,
  }) async {
    try {
      final response = await _apiService.post(
        AppUrl.startSession,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (gigBookingId != null) 'gig_booking_id': gigBookingId,
        },
      );

      return response; // Return ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// End the active work session
  /// Parameters:
  /// - latitude: Current latitude
  /// - longitude: Current longitude
  Future<ApiResponse> endSession({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiService.post(
        AppUrl.endSession,
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      return response; // Return ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Update current location during active session
  /// Parameters:
  /// - latitude: Current latitude
  /// - longitude: Current longitude
  Future<ApiResponse> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiService.post(
        AppUrl.updateLocation,
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      return ApiResponse.success(response);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Get today's tracking stats
  /// Returns: DailyTracking data with active session if online
  Future<ApiResponse> getTodayStats() async {
    try {
      final response = await _apiService.get(
        AppUrl.getTodayStats,
      );

      return response; // Return ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Get active session details
  /// Returns: Active Session if exists, null otherwise
  Future<ApiResponse> getActiveSession() async {
    try {
      final response = await _apiService.get(
        AppUrl.getActiveSession,
      );

      return response; // Return ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
