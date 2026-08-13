import 'dart:developer' as dev;

import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class GigRepository {
  final ApiService _apiService = ApiService();

  /// Get available gigs for a specific date
  /// Parameters:
  /// - date: YYYY-MM-DD format (optional, defaults to today)
  /// - gigType: morning, afternoon, evening, night (optional)
  Future<ApiResponse> getAvailableGigs({
    String? date,
    String? gigType,
  }) async {
    try {
      Map<String, dynamic> params = {};
      if (date != null) params['date'] = date;
      if (gigType != null) params['gig_type'] = gigType;

      final response = await _apiService.get(
        AppUrl.getAvailableGigs,
        params: params,
      );

      return response; // Return ApiResponse directly, don't wrap it again
    } catch (e, s) {
      dev.log('📦 Error in getAvailableGigs: $e',
          name: 'GigRepository', error: e, stackTrace: s);
      return ApiResponse.error(e.toString());
    }
  }

  /// Get details of a specific gig slot
  /// Parameters:
  /// - slotId: The gig slot ID
  Future<ApiResponse> getGigDetails({required int slotId}) async {
    try {
      final response = await _apiService.get(
        AppUrl.getGigDetails,
        params: {'slot_id': slotId},
      );

      return response; // Return ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Book gig slots (supports both single and multiple slots)
  /// Parameters:
  /// - slotIds: List of gig slot IDs to book (new format)
  /// - slotId: Single gig slot ID to book (old format, for backward compatibility)
  Future<ApiResponse> bookGig({
    List<int>? slotIds,
    int? slotId,
  }) async {
    try {
      // Use new bulk booking format if slotIds provided, otherwise fall back to single
      final data = slotIds != null && slotIds.isNotEmpty
          ? {'gig_slot_ids': slotIds}
          : {'gig_slot_id': slotId};

      final response = await _apiService.post(
        AppUrl.bookGig,
        data: data,
      );

      return response; // Return ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Get all bookings for the current delivery boy
  /// Parameters:
  /// - status: booked, active, completed, cancelled (optional)
  /// - fromDate: YYYY-MM-DD format (optional)
  /// - toDate: YYYY-MM-DD format (optional)
  Future<ApiResponse> getMyBookings({
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      Map<String, dynamic> params = {};
      if (status != null) params['status'] = status;
      if (fromDate != null) params['from_date'] = fromDate;
      if (toDate != null) params['to_date'] = toDate;

      final response = await _apiService.get(
        AppUrl.getMyBookings,
        params: params,
      );

      return response; // Return ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Cancel a gig booking
  /// Parameters:
  /// - bookingId: The booking ID to cancel
  /// - reason: Cancellation reason (optional)
  Future<ApiResponse> cancelBooking({
    required int bookingId,
    String? reason,
  }) async {
    try {
      final response = await _apiService.post(
        AppUrl.cancelBooking,
        data: {
          'booking_id': bookingId,
          if (reason != null) 'cancel_reason': reason,
        },
      );

      return response; // Return ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Complete a gig with final stats
  /// Parameters:
  /// - bookingId: The booking ID to complete
  /// - actualEarnings: Final earnings amount
  /// - ordersDelivered: Number of orders delivered
  /// - distanceCoveredKm: Distance covered in kilometers
  Future<ApiResponse> completeGig({
    required int bookingId,
    required double actualEarnings,
    required int ordersDelivered,
    required double distanceCoveredKm,
  }) async {
    try {
      final response = await _apiService.post(
        AppUrl.completeGig,
        data: {
          'booking_id': bookingId,
          'actual_earnings': actualEarnings,
          'orders_delivered': ordersDelivered,
          'distance_covered_km': distanceCoveredKm,
        },
      );

      return response; // Return ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Get gig history with filters
  /// Parameters:
  /// - fromDate: YYYY-MM-DD format (optional)
  /// - toDate: YYYY-MM-DD format (optional)
  /// - page: Page number for pagination (optional)
  /// - limit: Number of records per page (optional)
  Future<ApiResponse> getGigHistory({
    String? fromDate,
    String? toDate,
    int? page,
    int? limit,
  }) async {
    try {
      Map<String, dynamic> params = {};
      if (fromDate != null) params['from_date'] = fromDate;
      if (toDate != null) params['to_date'] = toDate;
      if (page != null) params['page'] = page;
      if (limit != null) params['limit'] = limit;

      final response = await _apiService.get(
        AppUrl.getGigHistory,
        params: params,
      );

      return response; // Return ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
