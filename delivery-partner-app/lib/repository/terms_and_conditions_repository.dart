import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

import '../services/status.dart';

class TermsAndConditionsRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse> getTermsAndConditions() async {
    return await _apiService.get(AppUrl.termsAndConditions);
  }
}
