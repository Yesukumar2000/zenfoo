import 'dart:io';

import 'package:zenfoo_partner/services/status.dart';

import '../../../services/api_services.dart';
import '../../../utils/app_urls.dart';

class UpdateDetailsRepository {
  final ApiService _api = ApiService();

  // ============ phone number update ============

  Future<ApiResponse> sendotp({
    required String phoneNumber,
  }) async {
    return await _api.post(
      '${AppUrl.sentOtpToMobile}=$phoneNumber',
      data: {},
    );
  }

  Future<ApiResponse> getPhoneNumber() async {
    return await _api.get(
      AppUrl.getPhoneNumber,
      isToast: false,
    );
  }

  Future<ApiResponse> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    return await _api.post(
      AppUrl.verifyPhoneNumber,
      data: {
        'mobile': phoneNumber,
        'otp': otp,
      },
    );
  }

  // ============ pan update ============

  Future<ApiResponse> getPan() async {
    return await _api.get(
      AppUrl.getPan,
      isToast: false,
    );
  }

  Future<ApiResponse> updatePan({
    required String panNumber,
    required File? frontImage,
    required File? backImage,
    String? frontUrl,
    String? backUrl,
  }) async {
    final Map<String, File> files = {};
    if (frontImage != null) files['pan_front'] = frontImage;
    if (backImage != null) files['pan_back'] = backImage;

    final Map<String, dynamic> data = {
      'pan_number': panNumber,
    };

    // If no new file is provided but we have a remote URL, send the URL
    // (This satisfies backend requirements for mandatory fields)
    if (frontImage == null && frontUrl != null) {
      data['pan_front'] = frontUrl;
    }
    if (backImage == null && backUrl != null) {
      data['pan_back'] = backUrl;
    }

    return await _api.post(
      AppUrl.updatePan,
      data: data,
    );
  }

  // ============ driving license update ============

  Future<ApiResponse> getLicense() async {
    return await _api.get(
      AppUrl.getLicense,
      isToast: false,
    );
  }

  Future<ApiResponse> updateLicense({
    required String licenseNumber,
    required File? frontImage,
    required File? backImage,
    String? frontUrl,
    String? backUrl,
  }) async {
    final Map<String, File> files = {};
    if (frontImage != null) files['driving_license_front'] = frontImage;
    if (backImage != null) files['driving_license_back'] = backImage;

    final Map<String, dynamic> data = {
      'driving_license_number': licenseNumber,
    };

    // If no new file is provided but we have a remote URL, send the URL
    if (frontImage == null && frontUrl != null) {
      data['driving_license_front_url'] = frontUrl;
    }
    if (backImage == null && backUrl != null) {
      data['driving_license_back_url'] = backUrl;
    }

    return await _api.post(
      AppUrl.updateLicense,
      data: data,
      files: files,
    );
  }
}
