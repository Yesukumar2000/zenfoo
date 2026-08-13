import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class DocumentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Driving License
  File? drivingLicenseFront;
  File? drivingLicenseBack;
  String? drivingLicenseNumber;
  String? drivingLicenseFrontUrl; // URL from server
  String? drivingLicenseBackUrl; // URL from server
  String? drivingLicenseStatus; // verification status

  // RC
  File? rcFront;
  File? rcBack;
  String? rcNumber;
  String? rcFrontUrl;
  String? rcBackUrl;
  String? rcStatus;

  // Aadhar
  File? aadharFront;
  File? aadharBack;
  String? aadharNumber;
  String? aadharFrontUrl;
  String? aadharBackUrl;
  String? aadharStatus;

  // PAN
  File? panFront;
  File? panBack;
  String? panNumber;
  String? panFrontUrl;
  String? panBackUrl;
  String? panStatus;

  // Bank Details
  File? bankPassbookImage;
  String? bankName;
  String? accountHolderName;
  String? accountNumber;
  String? ifscCode;
  String? bankPassbookImageUrl;
  String? bankDetailsStatus;

  // Overall verification status
  String? overallStatus;

  // Driving License Methods
  void setDrivingLicenseFront(File? image) {
    drivingLicenseFront = image;
    notifyListeners();
  }

  void setDrivingLicenseBack(File? image) {
    drivingLicenseBack = image;
    notifyListeners();
  }

  void setDrivingLicenseNumber(String? number) {
    drivingLicenseNumber = number;
    notifyListeners();
  }

  bool get hasDrivingLicense =>
      drivingLicenseFront != null &&
      drivingLicenseBack != null &&
      drivingLicenseNumber != null &&
      drivingLicenseNumber!.isNotEmpty;

  /// Check if driving license is complete (either local files OR server URLs)
  /// If rejected, requires new local files to be uploaded
  bool get isDrivingLicenseComplete {
    // If rejected, must have new local files
    if (drivingLicenseStatus == 'rejected') {
      return hasDrivingLicense;
    }
    // Otherwise, either local files or server URLs are fine
    return hasDrivingLicense ||
        (drivingLicenseFrontUrl != null &&
            drivingLicenseBackUrl != null &&
            drivingLicenseNumber != null &&
            drivingLicenseNumber!.isNotEmpty);
  }

  // RC Methods
  void setRcFront(File? image) {
    rcFront = image;
    notifyListeners();
  }

  void setRcBack(File? image) {
    rcBack = image;
    notifyListeners();
  }

  void setRcNumber(String? number) {
    rcNumber = number;
    notifyListeners();
  }

  bool get hasRc =>
      rcFront != null &&
      rcBack != null &&
      rcNumber != null &&
      rcNumber!.isNotEmpty;

  /// Check if RC is complete (either local files OR server URLs)
  /// If rejected, requires new local files to be uploaded
  bool get isRcComplete {
    // If rejected, must have new local files
    if (rcStatus == 'rejected') {
      return hasRc;
    }
    // Otherwise, either local files or server URLs are fine
    return hasRc ||
        (rcFrontUrl != null &&
            rcBackUrl != null &&
            rcNumber != null &&
            rcNumber!.isNotEmpty);
  }

  // Aadhar Methods
  void setAadharFront(File? image) {
    aadharFront = image;
    notifyListeners();
  }

  void setAadharBack(File? image) {
    aadharBack = image;
    notifyListeners();
  }

  void setAadharNumber(String? number) {
    aadharNumber = number;
    notifyListeners();
  }

  bool get hasAadhar =>
      aadharFront != null &&
      aadharBack != null &&
      aadharNumber != null &&
      aadharNumber!.isNotEmpty;

  /// Check if Aadhar is complete (either local files OR server URLs)
  /// If rejected, requires new local files to be uploaded
  bool get isAadharComplete {
    // If rejected, must have new local files
    if (aadharStatus == 'rejected') {
      return hasAadhar;
    }
    // Otherwise, either local files or server URLs are fine
    return hasAadhar ||
        (aadharFrontUrl != null &&
            aadharBackUrl != null &&
            aadharNumber != null &&
            aadharNumber!.isNotEmpty);
  }

  // PAN Methods
  void setPanFront(File? image) {
    panFront = image;
    notifyListeners();
  }

  void setPanBack(File? image) {
    panBack = image;
    notifyListeners();
  }

  void setPanNumber(String? number) {
    panNumber = number;
    notifyListeners();
  }

  bool get hasPan =>
      panFront != null &&
      panBack != null &&
      panNumber != null &&
      panNumber!.isNotEmpty;

  /// Check if PAN is complete (either local files OR server URLs)
  /// If rejected, requires new local files to be uploaded
  bool get isPanComplete {
    // If rejected, must have new local files
    if (panStatus == 'rejected') {
      return hasPan;
    }
    // Otherwise, either local files or server URLs are fine
    return hasPan ||
        (panFrontUrl != null &&
            panBackUrl != null &&
            panNumber != null &&
            panNumber!.isNotEmpty);
  }

  // Bank Details Methods
  void setBankPassbookImage(File? image) {
    bankPassbookImage = image;
    notifyListeners();
  }

  void setBankName(String? name) {
    bankName = name;
    notifyListeners();
  }

  void setAccountHolderName(String? name) {
    accountHolderName = name;
    notifyListeners();
  }

  void setAccountNumber(String? number) {
    accountNumber = number;
    notifyListeners();
  }

  void setIfscCode(String? code) {
    ifscCode = code;
    notifyListeners();
  }

  bool get hasBankDetails =>
      bankPassbookImage != null &&
      bankName != null &&
      bankName!.isNotEmpty &&
      accountHolderName != null &&
      accountHolderName!.isNotEmpty &&
      accountNumber != null &&
      accountNumber!.isNotEmpty &&
      ifscCode != null &&
      ifscCode!.isNotEmpty;

  /// Check if Bank Details are complete (either local files OR server data)
  /// If rejected, requires new local files to be uploaded
  bool get isBankDetailsComplete {
    // If rejected, must have new local files
    if (bankDetailsStatus == 'rejected') {
      return hasBankDetails;
    }
    // Otherwise, either local files or server data are fine
    return hasBankDetails ||
        (bankPassbookImageUrl != null &&
            bankName != null &&
            bankName!.isNotEmpty &&
            accountHolderName != null &&
            accountHolderName!.isNotEmpty &&
            accountNumber != null &&
            accountNumber!.isNotEmpty &&
            ifscCode != null &&
            ifscCode!.isNotEmpty);
  }

  /// Check if ALL documents are complete
  bool get areAllDocumentsComplete =>
      isDrivingLicenseComplete &&
      isRcComplete &&
      isAadharComplete &&
      isPanComplete &&
      isBankDetailsComplete;

  /// Load documents data from GET API response
  void loadDocumentsFromApi(Map<String, dynamic> data) {
    debugPrint('🔄 loadDocumentsFromApi called with data');
    debugPrint('📋 Data keys: ${data.keys.toList()}');

    // Driving License
    if (data['driving_license'] != null) {
      final dl = data['driving_license'];
      drivingLicenseNumber = dl['number'];
      drivingLicenseFrontUrl = dl['front_image_url'];
      drivingLicenseBackUrl = dl['back_image_url'];
      drivingLicenseStatus = dl['status'];
      debugPrint('✅ DL loaded: number=$drivingLicenseNumber, status=$drivingLicenseStatus, url=$drivingLicenseFrontUrl');
    } else {
      debugPrint('⚠️ driving_license is null in data');
    }

    // RC
    if (data['rc'] != null) {
      final rc = data['rc'];
      rcNumber = rc['number'];
      rcFrontUrl = rc['front_image_url'];
      rcBackUrl = rc['back_image_url'];
      rcStatus = rc['status'];
      debugPrint('✅ RC loaded: number=$rcNumber, status=$rcStatus');
    }

    // Aadhar
    if (data['aadhar'] != null) {
      final aadhar = data['aadhar'];
      aadharNumber = aadhar['number'];
      aadharFrontUrl = aadhar['front_image_url'];
      aadharBackUrl = aadhar['back_image_url'];
      aadharStatus = aadhar['status'];
      debugPrint('✅ Aadhar loaded: number=$aadharNumber, status=$aadharStatus');
    }

    // PAN
    if (data['pan'] != null) {
      final pan = data['pan'];
      panNumber = pan['number'];
      panFrontUrl = pan['front_image_url'];
      panBackUrl = pan['back_image_url'];
      panStatus = pan['status'];
      debugPrint('✅ PAN loaded: number=$panNumber, status=$panStatus');
    }

    // Bank Details
    if (data['bank_details'] != null) {
      final bank = data['bank_details'];
      bankName = bank['bank_name'];
      accountHolderName = bank['account_holder_name'];
      accountNumber = bank['account_number'];
      ifscCode = bank['ifsc_code'];
      bankPassbookImageUrl = bank['passbook_image_url'];
      bankDetailsStatus = bank['status'];
      debugPrint('✅ Bank Details loaded: bank=$bankName, status=$bankDetailsStatus');
    }

    // Overall status
    overallStatus = data['overall_status'];
    debugPrint('✅ Overall Status: $overallStatus');

    debugPrint('🔔 Calling notifyListeners() - UI should update');
    notifyListeners();
  }

  // Clear all data
  void clearAll() {
    drivingLicenseFront = null;
    drivingLicenseBack = null;
    drivingLicenseNumber = null;
    drivingLicenseFrontUrl = null;
    drivingLicenseBackUrl = null;
    drivingLicenseStatus = null;

    rcFront = null;
    rcBack = null;
    rcNumber = null;
    rcFrontUrl = null;
    rcBackUrl = null;
    rcStatus = null;

    aadharFront = null;
    aadharBack = null;
    aadharNumber = null;
    aadharFrontUrl = null;
    aadharBackUrl = null;
    aadharStatus = null;

    panFront = null;
    panBack = null;
    panNumber = null;
    panFrontUrl = null;
    panBackUrl = null;
    panStatus = null;

    bankPassbookImage = null;
    bankName = null;
    accountHolderName = null;
    accountNumber = null;
    ifscCode = null;
    bankPassbookImageUrl = null;
    bankDetailsStatus = null;

    overallStatus = null;

    notifyListeners();
  }

  /// Fetch documents from API
  Future<void> fetchDocuments() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.get(AppUrls.getDocuments);

      if (response.data != null && response.data is Map) {
        final data = response.data;

        // Handle both status: true and status: 1
        final status = data['status'];
        final isSuccess = status == true || status == 1 || status == '1';

        if (isSuccess && data['data'] != null) {
          debugPrint('✅ Loading documents from API response');
          loadDocumentsFromApi(data['data']);
        } else {
          debugPrint('⚠️ API response status not successful: $status');
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching documents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
