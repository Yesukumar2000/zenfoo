import 'dart:developer' as dev;
import 'package:zenfoo_partner/models/admin_payment_details_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class AdminPaymentDetailsRepository {
  final ApiService _apiService = ApiService();

  Future<AdminPaymentDetailsModel?> getAdminPaymentDetails() async {
    try {
      final response = await _apiService.get(AppUrl.adminPaymentDetails);
      if (response.data != null &&
          (response.data['status'] == 1 ||
              response.data['status'] == '1' ||
              response.data['status'] == true)) {
        return AdminPaymentDetailsModel.fromJson(
            Map<String, dynamic>.from(response.data['data']));
      }
      return null;
    } catch (e) {
      dev.log('AdminPaymentDetailsRepository error: $e');
      rethrow;
    }
  }
}
