import 'package:zenfoo_partner/models/ratings_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class RatingsRepository {
  final ApiService _apiService = ApiService();

  Future<RatingsModel?> getRatings() async {
    try {
      final response = await _apiService.get(AppUrl.ratings);

      if (response.data != null &&
          (response.data['status'] == 1 || response.status == 200)) {
        return RatingsModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
