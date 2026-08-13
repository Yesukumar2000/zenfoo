import 'dart:developer' as dev;
import 'package:zenfoo_partner/models/banner_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class BannerRepository {
  final ApiService _apiService = ApiService();

  Future<List<BannerSliderModel>> getBanners() async {
    try {
      final response = await _apiService.get(AppUrl.driverBanners);

      if (response.data != null &&
          (response.data['status'] == 1 ||
              response.data['status'] == '1')) {
        final List<dynamic> dataList = response.data['data'] ?? [];
        return dataList
            .map((item) =>
                BannerSliderModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      return [];
    } catch (e) {
      dev.log('BannerRepository.getBanners error: $e');
      rethrow;
    }
  }

  Future<List<BannerSliderModel>> getLoginBanners() async {
    try {
      final response = await _apiService.get(AppUrl.driverLoginBanners);

      if (response.data != null &&
          (response.data['status'] == 1 ||
              response.data['status'] == '1')) {
        final List<dynamic> dataList = response.data['data'] ?? [];
        return dataList
            .map((item) =>
                BannerSliderModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      return [];
    } catch (e) {
      dev.log('BannerRepository.getLoginBanners error: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> getSupportContacts() async {
    try {
      final response = await _apiService.get(AppUrl.supportContacts);

      if (response.data != null &&
          (response.data['status'] == 1 ||
              response.data['status'] == '1')) {
        final data = response.data['data'] ?? {};
        return {
          'phone': data['phone']?.toString() ?? '',
          'email': data['email']?.toString() ?? '',
        };
      }

      return {'phone': '', 'email': ''};
    } catch (e) {
      dev.log('BannerRepository.getSupportContacts error: $e');
      rethrow;
    }
  }
}
