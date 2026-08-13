import 'dart:developer' as dev;

import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class PaymentHistoryRepository {
  final ApiService _api = ApiService();

  Future<ApiResponse> getPaymentHistory({
    String period = 'daily',
    int offset = 0,
  }) async {
    try {
      dev.log('🌐 Making API call to: ${AppUrl.manualPaymentHistory}',
          name: 'PaymentHistoryRepository');

      final params = {
        'period': period,
        'offset': offset.toString(),
      };

      final response = await _api.get(
        AppUrl.manualPaymentHistory,
        params: params,
      );

      dev.log('📡 API Response status: ${response.status}',
          name: 'PaymentHistoryRepository');

      return response;
    } catch (e) {
      dev.log('💥 API Error: $e', name: 'PaymentHistoryRepository');
      return ApiResponse.error(e.toString());
    }
  }
}
