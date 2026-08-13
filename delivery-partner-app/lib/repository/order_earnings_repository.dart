import 'dart:developer' as dev;

import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class OrderEarningsRepository {
  final ApiService _apiService = ApiService();

  /// Get order earnings data
  /// Parameters:
  /// - period: 'daily', 'weekly', or 'monthly'
  /// - offset: offset for navigation (0 = current, -1 = previous, 1 = next, etc.)
  Future<ApiResponse> getOrderEarnings({
    String period = 'weekly',
    int offset = 0,
    int isCancelled = 0,
  }) async {
    try {
      dev.log('🌐 Making API call to: ${AppUrl.orderEarnings}',
          name: 'OrderEarningsRepository');

      final params = {
        'period': period,
        'offset': offset.toString(),
        'is_cancelled': isCancelled.toString(),
      };

      final response = await _apiService.get(
        AppUrl.orderEarnings,
        params: params,
      );

      dev.log('📡 API Response status: ${response.status}',
          name: 'OrderEarningsRepository');
      dev.log('📡 API Response data type: ${response.data?.runtimeType}',
          name: 'OrderEarningsRepository');

      return response;
    } catch (e) {
      dev.log('💥 API Error: $e', name: 'OrderEarningsRepository');
      return ApiResponse.error(e.toString());
    }
  }

  /// Get FAQ questions for the chatbot
  Future<ApiResponse> getChatFAQ({required String orderId}) async {
    try {
      dev.log('🌐 Fetching Chatbot FAQ for Order ID: $orderId',
          name: 'OrderEarningsRepository');

      final response = await _apiService.get(
        AppUrl.getChatbotQuestions,
        params: {'order_id': orderId},
      );

      return response;
    } catch (e) {
      dev.log('💥 Error fetching chatbot FAQ: $e',
          name: 'OrderEarningsRepository');
      return ApiResponse.error(e.toString());
    }
  }

  /// Submit a chatbot question to get an answer
  Future<ApiResponse> submitChatAnswer({
    required String orderId,
    required String questionKey,
  }) async {
    try {
      dev.log(
          '🌐 Submitting chatbot question: Order $orderId, Key $questionKey',
          name: 'OrderEarningsRepository');

      final response = await _apiService.post(
        AppUrl.submitChatbotAnswer,
        data: {
          'order_id': orderId,
          'question': questionKey,
        },
      );

      return response;
    } catch (e) {
      dev.log('💥 Error submitting chatbot question: $e',
          name: 'OrderEarningsRepository');
      return ApiResponse.error(e.toString());
    }
  }
}
