import 'dart:io';

import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class DocumentRepository {
  final ApiService _api = ApiService();

  /// 🔹 1. UPLOAD ALL DOCUMENTS (Initial submission - all documents required)
  /// This API is called when submitting all documents together for the first time
  Future<ApiResponse> uploadAllDocuments({
    // Driving License
    required File drivingLicenseFront,
    required File drivingLicenseBack,
    required String drivingLicenseNumber,
    // RC
    required File rcFront,
    required File rcBack,
    required String rcNumber,
    // Aadhar
    required File aadharFront,
    required File aadharBack,
    required String aadharNumber,
    // PAN
    required File panFront,
    required File panBack,
    required String panNumber,
    // Bank Details
    required File bankPassbookImage,
    required String bankName,
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
  }) async {
    return await _api.post(
      AppUrl.uploadAllDocuments,
      data: {
        'driving_license_number': drivingLicenseNumber,
        'rc_number': rcNumber,
        'aadhar_number': aadharNumber,
        'pan_number': panNumber,
        'bank_name': bankName,
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
      },
      files: {
        'driving_license_front': drivingLicenseFront,
        'driving_license_back': drivingLicenseBack,
        'rc_front': rcFront,
        'rc_back': rcBack,
        'aadhar_front': aadharFront,
        'aadhar_back': aadharBack,
        'pan_front': panFront,
        'pan_back': panBack,
        'bank_passbook_image': bankPassbookImage,
      },
    );
  }

  /// 🔹 2. UPDATE DOCUMENTS (Partial update - only send fields that changed)
  /// This API allows updating one or more documents without needing to resend everything
  Future<ApiResponse> updateDocuments({
    // Driving License (optional)
    File? drivingLicenseFront,
    File? drivingLicenseBack,
    String? drivingLicenseNumber,
    // RC (optional)
    File? rcFront,
    File? rcBack,
    String? rcNumber,
    // Aadhar (optional)
    File? aadharFront,
    File? aadharBack,
    String? aadharNumber,
    // PAN (optional)
    File? panFront,
    File? panBack,
    String? panNumber,
    // Bank Details (optional)
    File? bankPassbookImage,
    String? bankName,
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
  }) async {
    // Build the body with only non-null text fields
    final Map<String, dynamic> body = {};

    if (drivingLicenseNumber != null) {
      body['driving_license_number'] = drivingLicenseNumber;
    }
    if (rcNumber != null) {
      body['rc_number'] = rcNumber;
    }
    if (aadharNumber != null) {
      body['aadhar_number'] = aadharNumber;
    }
    if (panNumber != null) {
      body['pan_number'] = panNumber;
    }
    if (bankName != null) {
      body['bank_name'] = bankName;
    }
    if (accountHolderName != null) {
      body['account_holder_name'] = accountHolderName;
    }
    if (accountNumber != null) {
      body['account_number'] = accountNumber;
    }
    if (ifscCode != null) {
      body['ifsc_code'] = ifscCode;
    }

    // Build the files map with only non-null files
    final Map<String, File> files = {};

    if (drivingLicenseFront != null) {
      files['driving_license_front'] = drivingLicenseFront;
    }
    if (drivingLicenseBack != null) {
      files['driving_license_back'] = drivingLicenseBack;
    }
    if (rcFront != null) {
      files['rc_front'] = rcFront;
    }
    if (rcBack != null) {
      files['rc_back'] = rcBack;
    }
    if (aadharFront != null) {
      files['aadhar_front'] = aadharFront;
    }
    if (aadharBack != null) {
      files['aadhar_back'] = aadharBack;
    }
    if (panFront != null) {
      files['pan_front'] = panFront;
    }
    if (panBack != null) {
      files['pan_back'] = panBack;
    }
    if (bankPassbookImage != null) {
      files['bank_passbook_image'] = bankPassbookImage;
    }

    return await _api.post(
      AppUrl.updateDocuments,
      data: body,
      files: files.isNotEmpty ? files : null,
    );
  }

  /// 🔹 3. GET ALL DOCUMENTS (Retrieve stored documents)
  Future<ApiResponse> getDocuments() async {
    return await _api.get(
      AppUrl.getDocuments,
      isToast: false,
    );
  }
}
