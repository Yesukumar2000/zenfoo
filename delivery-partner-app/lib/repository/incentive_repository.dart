import 'dart:convert';
import 'dart:developer' as dev;

import 'package:zenfoo_partner/models/all_offers_response_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class IncentiveRepository {
  final ApiService _apiService = ApiService();

  /// Get all active incentive offers
  /// Returns: List of active IncentiveOffer with user's progress
  Future<ApiResponse> getActiveOffers() async {
    // try {
    dev.log('🌐 Making API call to: ${AppUrl.getActiveOffers}',
        name: 'IncentiveRepository');

    final response = await _apiService.get(
      AppUrl.getActiveOffers,
    );

    dev.log('📡 API Response status: ${response.status}',
        name: 'IncentiveRepository');
    dev.log('📡 API Response data type: ${response.data?.runtimeType}',
        name: 'IncentiveRepository');

    if (response.data != null) {
      dev.log('📡 API Response data: ${jsonEncode(response.data)}',
          name: 'IncentiveRepository');
    }

    return response; // Return the ApiResponse directly, don't wrap it again
    // } catch (e, stackTrace) {
    //   dev.log('💥 API Error: $e', name: 'IncentiveRepository');
    //   dev.log('Stack trace: $stackTrace', name: 'IncentiveRepository');
    //   return ApiResponse.error(e.toString());
    // }
  }

  /// Get details of a specific offer
  /// Parameters:
  /// - offerId: The offer ID
  Future<ApiResponse> getOfferDetails({required int offerId}) async {
    try {
      final response = await _apiService.get(
        AppUrl.getOfferDetails,
        params: {'offer_id': offerId},
      );

      return response; // Return the ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Get user's progress for a specific offer
  /// Parameters:
  /// - offerId: The offer ID
  Future<ApiResponse> getMyOfferProgress({required int offerId}) async {
    try {
      final response = await _apiService.get(
        AppUrl.getMyOfferProgress,
        params: {'offer_id': offerId},
      );

      return response; // Return the ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Get all offers (active + expired)
  /// Parameters:
  /// - includeExpired: Include expired offers (default: false)
  Future<ApiResponse> getAllOffers({bool includeExpired = false}) async {
    try {
      final response = await _apiService.get(
        AppUrl.getAllOffers,
        params: {'include_expired': includeExpired ? 1 : 0},
      );

      return response; // Return the ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Get all offers grouped by status (active, upcoming, expired)
  /// Returns: AllOffersResponse with offers grouped by status
  /// Parameters:
  /// - filter: Optional filter (daily, weekly, monthly)
  /// - date: Optional specific date (yyyy-MM-dd)
  /// API Response: { status, message, data: { active: [], upcoming: [], expired: [] } }
  Future<AllOffersResponse> getAllOffersGrouped({
    String? filter,
    String? date,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (filter != null) params['filter'] = filter;
      if (date != null) params['date'] = date;

      dev.log('🌐 Making API call to: ${AppUrl.getAllOffers} params: $params',
          name: 'IncentiveRepository');

      final response = await _apiService.get(
        AppUrl.getAllOffers,
        params: params.isNotEmpty ? params : null,
      );

      dev.log('📡 API Response status: ${response.status}',
          name: 'IncentiveRepository');

      if (response.status == ApiStatus.success) {
        if (response.data != null) {
          dev.log('📡 API Response data: ${jsonEncode(response.data)}',
              name: 'IncentiveRepository');
          return AllOffersResponse.fromJson(response.data);
        } else {
          throw Exception('No data received from API');
        }
      } else {
        throw Exception(response.message ?? 'Failed to fetch offers');
      }
    } catch (e, stackTrace) {
      dev.log('💥 API Error: $e', name: 'IncentiveRepository');
      dev.log('Stack trace: $stackTrace', name: 'IncentiveRepository');
      rethrow;
    }
  }
}
