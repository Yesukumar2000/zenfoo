import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/banner_model.dart';
import 'package:zenfoo_partner/repository/banner_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class BannerProvider extends ChangeNotifier {
  final BannerRepository _repository = BannerRepository();

  // Home banners
  ApiResponse<List<BannerSliderModel>> _bannersResponse = ApiResponse.nothing();

  ApiResponse<List<BannerSliderModel>> get bannersResponse => _bannersResponse;
  List<BannerSliderModel> get banners => _bannersResponse.data ?? [];
  bool get isLoading => _bannersResponse.status == ApiStatus.loading;
  bool get hasError => _bannersResponse.status == ApiStatus.error;
  bool get hasData =>
      _bannersResponse.status == ApiStatus.success && banners.isNotEmpty;

  // Login banners
  ApiResponse<List<BannerSliderModel>> _loginBannersResponse =
      ApiResponse.nothing();

  ApiResponse<List<BannerSliderModel>> get loginBannersResponse =>
      _loginBannersResponse;
  List<BannerSliderModel> get loginBanners =>
      _loginBannersResponse.data ?? [];
  bool get isLoginLoading =>
      _loginBannersResponse.status == ApiStatus.loading;
  bool get hasLoginError =>
      _loginBannersResponse.status == ApiStatus.error;
  bool get hasLoginData =>
      _loginBannersResponse.status == ApiStatus.success &&
      loginBanners.isNotEmpty;

  // Support contacts
  String supportPhone = '';
  String supportEmail = '';

  BannerProvider() {
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    _bannersResponse = ApiResponse.loading();
    notifyListeners();

    try {
      final data = await _repository.getBanners();
      _bannersResponse = ApiResponse.success(data);
    } catch (e) {
      _bannersResponse = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }

  Future<void> fetchLoginBanners() async {
    _loginBannersResponse = ApiResponse.loading();
    notifyListeners();

    try {
      final data = await _repository.getLoginBanners();
      _loginBannersResponse = ApiResponse.success(data);
    } catch (e) {
      _loginBannersResponse = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }

  Future<void> fetchSupportContacts() async {
    try {
      final data = await _repository.getSupportContacts();
      supportPhone = data['phone'] ?? '';
      supportEmail = data['email'] ?? '';
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching support contacts: $e');
    }
  }
}
