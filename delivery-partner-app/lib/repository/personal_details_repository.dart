import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class PersonalDetailsRepository {
  final ApiService _api = ApiService();

  /// Fetch personal details from API
  Future<ApiResponse> getPersonalDetails() async {
    return await _api.get(
      AppUrl.getPersonalDetails,
      isToast: false,
    );
  }

  /// Update personal details
  Future<ApiResponse> updatePersonalDetails({
    required String name,
    required String email,
    required String dob,
    required String address,
    required String latitude,
    required String longitude,
  }) async {
    return await _api.post(
      AppUrl.updatePersonalDetails,
      data: {
        'name': name,
        'email': email,
        'dob': dob,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  /// Update bank details
  Future<ApiResponse> updateBankDetails({
    required String bankName,
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
  }) async {
    return await _api.post(
      AppUrl.addBank,
      data: {
        'bank_name': bankName,
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
      },
    );
  }

  /// Upload document
  Future<ApiResponse> uploadDocument({
    required String documentType,
    required String imagePath,
    String? documentSide,
  }) async {
    return await _api.post(
      _getUploadUrl(documentType),
      data: {
        'document_type': documentType,
        if (documentSide != null) 'document_side': documentSide,
      },
    );
  }

  /// Upload bank passbook image
  Future<ApiResponse> uploadBankPassbook({
    required String imagePath,
  }) async {
    return await _api.post(
      AppUrl.uploadBank,
      data: {},
    );
  }

  /// Get upload URL based on document type
  String _getUploadUrl(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'aadhar':
        return AppUrl.uploadAadhar;
      case 'pan':
        return AppUrl.uploadInsurance;
      case 'driving_license':
        return AppUrl.uploadLicense;
      case 'rc':
        return AppUrl.uploadRc;
      case 'bank':
        return AppUrl.uploadBank;
      default:
        return AppUrl.uploadAadhar;
    }
  }
}
