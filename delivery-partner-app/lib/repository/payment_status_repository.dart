import 'package:zenfoo_partner/models/payment_status_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class PaymentStatusRepository {
  final ApiService _apiService = ApiService();

  /// Fetch payment status for current delivery boy
  Future<ApiResponse<PaymentStatusResponse>> getPaymentStatus() async {
    try {
      final response = await _apiService.get(AppUrl.paymentStatus);
      if (response.status == ApiStatus.success && response.data != null) {
        final paymentStatusResponse = PaymentStatusResponse.fromJson(
            response.data as Map<String, dynamic>);
        return ApiResponse.success(paymentStatusResponse);
      }
      return ApiResponse.error('Failed to fetch payment status');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
