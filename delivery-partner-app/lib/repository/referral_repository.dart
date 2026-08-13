import 'package:zenfoo_partner/models/referral_tracking_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class ReferralRepository {
  final ApiService _apiService = ApiService();

  Future<ReferralTrackingModel?> getReferralTracking() async {
    try {
      final response = await _apiService.get(AppUrl.referralTracking);

      if (response.data != null &&
          (response.data['status'] == 1 || response.data['status'] == '1')) {
        return ReferralTrackingModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
