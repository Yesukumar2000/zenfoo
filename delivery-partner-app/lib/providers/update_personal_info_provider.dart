import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/get_phone_number_model.dart';
import 'package:zenfoo_partner/repository/help_center/update_personal_info/update_details_repository.dart';

import '../models/get_license_model.dart';
import '../models/get_pan_response_model.dart' show PanModel;
import '../services/status.dart';

class UpdatePersonalInfoProvider extends ChangeNotifier {
  final UpdateDetailsRepository _repo = UpdateDetailsRepository();

  // ================= OTP =================

  ApiResponse sendOtpState = ApiResponse.nothing();

  Future<void> sendOtp({
    required String phoneNumber,
  }) async {
    sendOtpState = ApiResponse.loading();
    notifyListeners();

    sendOtpState = await _repo.sendotp(phoneNumber: phoneNumber);

    notifyListeners();
  }

  // ================= Phone Number =================

  ApiResponse<PhoneNumberModel> getPhoneNumberState = ApiResponse.nothing();

  Future<void> getPhoneNumber() async {
    getPhoneNumberState = ApiResponse.loading();
    notifyListeners();

    final response = await _repo.getPhoneNumber();

    if (response.status == ApiStatus.success) {
      try {
        final model = PhoneNumberModel.fromJson(response.data);
        getPhoneNumberState = ApiResponse.success(model);
      } catch (e) {
        getPhoneNumberState =
            ApiResponse.error('Failed to parse phone number data');
      }
    } else {
      getPhoneNumberState =
          ApiResponse.error(response.message ?? 'Failed to fetch phone number');
    }

    notifyListeners();
  }

  ApiResponse verifyOtpState = ApiResponse.nothing();

  Future<void> verifyotp({
    required String phone,
    required String otp,
  }) async {
    verifyOtpState = ApiResponse.loading();
    notifyListeners();

    verifyOtpState = await _repo.verifyOtp(phoneNumber: phone, otp: otp);

    notifyListeners();
  }

  // ================= PAN =================

  ApiResponse getPanState = ApiResponse.nothing();

  Future<void> getPan() async {
    getPanState = ApiResponse.loading();
    notifyListeners();

    final response = await _repo.getPan();

    if (response.status == ApiStatus.success) {
      try {
        final model = PanModel.fromJson(response.data);
        getPanState = ApiResponse.success(model.data);
      } catch (e) {
        getPanState = ApiResponse.error('Failed to parse pan data');
      }
    } else {
      getPanState =
          ApiResponse.error(response.message ?? 'Failed to fetch pan');
    }

    notifyListeners();
  }

  ApiResponse updatePanState = ApiResponse.nothing();

  Future<void> updatePan({
    required String panNumber,
    required File? frontImage,
    required File? backImage,
    String? frontUrl,
    String? backUrl,
  }) async {
    updatePanState = ApiResponse.loading();
    notifyListeners();

    updatePanState = await _repo.updatePan(
      panNumber: panNumber,
      frontImage: frontImage,
      backImage: backImage,
      frontUrl: frontUrl,
      backUrl: backUrl,
    );

    notifyListeners();
  }

  // ================= driving license update =================

  ApiResponse getLicenseState = ApiResponse.nothing();

  Future<void> getLicense() async {
    getLicenseState = ApiResponse.loading();
    notifyListeners();

    final response = await _repo.getLicense();

    if (response.status == ApiStatus.success) {
      try {
        final model = LicenseModel.fromJson(response.data);
        getLicenseState = ApiResponse.success(model.data);
      } catch (e) {
        getLicenseState = ApiResponse.error('Failed to parse license data');
      }
    } else {
      getLicenseState =
          ApiResponse.error(response.message ?? 'Failed to fetch license');
    }

    notifyListeners();
  }

  ApiResponse updateLicenseState = ApiResponse.nothing();

  Future<void> updateLicense({
    required String licenseNumber,
    required File? frontImage,
    required File? backImage,
    String? frontUrl,
    String? backUrl,
  }) async {
    updateLicenseState = ApiResponse.loading();
    notifyListeners();

    updateLicenseState = await _repo.updateLicense(
      licenseNumber: licenseNumber,
      frontImage: frontImage,
      backImage: backImage,
      frontUrl: frontUrl,
      backUrl: backUrl,
    );

    notifyListeners();
  }
}
