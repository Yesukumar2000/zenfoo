import 'package:zenfoo_partner/models/store_location_model.dart';

class PersonalDetailsResponse {
  final int? responseCode;
  final bool? result;
  final String? message;
  final PersonalDetailsData? data;

  PersonalDetailsResponse({
    this.responseCode,
    this.result,
    this.message,
    this.data,
  });

  factory PersonalDetailsResponse.fromJson(Map<String, dynamic> json) {
    return PersonalDetailsResponse(
      responseCode: json['ResponseCode'],
      result: json['Result'],
      message: json['message'],
      data: json['data'] != null
          ? PersonalDetailsData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ResponseCode': responseCode,
      'Result': result,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class PersonalDetailsData {
  final int id;
  final String name;
  final String mobile;
  final String? email;
  final String? dob;
  final String address;
  final String? latitude;
  final String? longitude;
  final List<StoreLocation>? storeLocations;
  final int? storeLocationsCount;
  final String? profileImageUrl;
  final Documents documents;
  final BankDetails bankDetails;
  final String overallStatus;
  final String createdAt;
  final String updatedAt;

  PersonalDetailsData({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.dob,
    required this.address,
    this.latitude,
    this.longitude,
    this.storeLocations,
    this.storeLocationsCount,
    this.profileImageUrl,
    required this.documents,
    required this.bankDetails,
    required this.overallStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PersonalDetailsData.fromJson(Map<String, dynamic> json) {
    return PersonalDetailsData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'],
      dob: json['dob'],
      address: json['address'] ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      storeLocations: json['store_locations'] != null
          ? (json['store_locations'] as List)
              .map((store) => StoreLocation.fromJson(store))
              .toList()
          : null,
      storeLocationsCount: json['store_locations_count'],
      profileImageUrl: json['profile_image_url'],
      documents: json['documents'] != null
          ? Documents.fromJson(json['documents'])
          : Documents.empty(),
      bankDetails: json['bank_details'] != null
          ? BankDetails.fromJson(json['bank_details'])
          : BankDetails.empty(),
      overallStatus: json['overall_status'] ?? 'pending_verification',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'dob': dob,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'store_locations':
          storeLocations?.map((store) => store.toJson()).toList(),
      'store_locations_count': storeLocationsCount,
      'profile_image_url': profileImageUrl,
      'documents': documents.toJson(),
      'bank_details': bankDetails.toJson(),
      'overall_status': overallStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Check if all details are verified
  bool get isFullyVerified {
    return overallStatus == 'verified' &&
        documents.isVerified &&
        bankDetails.isVerified;
  }

  /// Check if verification is pending
  bool get isVerificationPending {
    return overallStatus == 'pending_verification' ||
        documents.status == 'pending_verification' ||
        bankDetails.status == 'pending_verification';
  }

  /// Check if any verification is rejected
  bool get isVerificationRejected {
    return overallStatus == 'rejected' ||
        documents.status == 'rejected' ||
        bankDetails.status == 'rejected';
  }
}

class Documents {
  final String? aadharNumber;
  final String? aadharFrontImageUrl;
  final String? aadharBackImageUrl;
  final String? aadharStatus;
  final String? panNumber;
  final String? panImageUrl;
  final String? panStatus;
  final String? drivingLicenseNumber;
  final String? drivingLicenseFrontImageUrl;
  final String? drivingLicenseBackImageUrl;
  final String? drivingLicenseStatus;
  final String? rcNumber;
  final String? rcFrontImageUrl;
  final String? rcBackImageUrl;
  final String? rcStatus;
  final String? bankName;
  final String? accountHolderName;
  final String? accountNumber;
  final String? ifscCode;
  final String? bankPassbookImageUrl;
  final String? bankDetailsStatus;
  final String status;

  Documents({
    this.aadharNumber,
    this.aadharFrontImageUrl,
    this.aadharBackImageUrl,
    this.aadharStatus,
    this.panNumber,
    this.panImageUrl,
    this.panStatus,
    this.drivingLicenseNumber,
    this.drivingLicenseFrontImageUrl,
    this.drivingLicenseBackImageUrl,
    this.drivingLicenseStatus,
    this.rcNumber,
    this.rcFrontImageUrl,
    this.rcBackImageUrl,
    this.rcStatus,
    this.bankName,
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
    this.bankPassbookImageUrl,
    this.bankDetailsStatus,
    this.status = 'pending_verification',
  });

  factory Documents.fromJson(Map<String, dynamic> json) {
    return Documents(
      // Aadhar
      aadharNumber: json['aadhar']?['number'] ?? json['aadhar']?['aadhar_number'],
      aadharFrontImageUrl: json['aadhar']?['front_image_url'],
      aadharBackImageUrl: json['aadhar']?['back_image_url'],
      aadharStatus: json['aadhar']?['status'],
      // PAN
      panNumber: json['pan']?['number'] ?? json['pan']?['pan_number'],
      panImageUrl: json['pan']?['image_url'] ?? json['pan']?['front_image_url'],
      panStatus: json['pan']?['status'],
      // Driving License
      drivingLicenseNumber: json['driving_license']?['number'] ?? json['driving_license']?['license_number'],
      drivingLicenseFrontImageUrl: json['driving_license']?['front_image_url'],
      drivingLicenseBackImageUrl: json['driving_license']?['back_image_url'],
      drivingLicenseStatus: json['driving_license']?['status'],
      // RC
      rcNumber: json['rc']?['number'],
      rcFrontImageUrl: json['rc']?['front_image_url'],
      rcBackImageUrl: json['rc']?['back_image_url'],
      rcStatus: json['rc']?['status'],
      // Bank Details
      bankName: json['bank_details']?['bank_name'],
      accountHolderName: json['bank_details']?['account_holder_name'],
      accountNumber: json['bank_details']?['account_number'],
      ifscCode: json['bank_details']?['ifsc_code'],
      bankPassbookImageUrl: json['bank_details']?['passbook_image_url'],
      bankDetailsStatus: json['bank_details']?['status'],
      // Overall status
      status: json['overall_status'] ?? json['status'] ?? 'pending_verification',
    );
  }

  factory Documents.empty() {
    return Documents(
      status: 'pending_verification',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aadhar': {
        'number': aadharNumber,
        'front_image_url': aadharFrontImageUrl,
        'back_image_url': aadharBackImageUrl,
        'status': aadharStatus,
      },
      'pan': {
        'number': panNumber,
        'front_image_url': panImageUrl,
        'status': panStatus,
      },
      'driving_license': {
        'number': drivingLicenseNumber,
        'front_image_url': drivingLicenseFrontImageUrl,
        'back_image_url': drivingLicenseBackImageUrl,
        'status': drivingLicenseStatus,
      },
      'rc': {
        'number': rcNumber,
        'front_image_url': rcFrontImageUrl,
        'back_image_url': rcBackImageUrl,
        'status': rcStatus,
      },
      'bank_details': {
        'bank_name': bankName,
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
        'passbook_image_url': bankPassbookImageUrl,
        'status': bankDetailsStatus,
      },
      'overall_status': status,
    };
  }

  bool get isVerified => status == 'verified';

  bool get isPendingVerification => status == 'pending_verification';

  bool get isRejected => status == 'rejected';

  bool get hasAadhar => aadharNumber != null && aadharNumber!.isNotEmpty;

  bool get hasPan => panNumber != null && panNumber!.isNotEmpty;

  bool get hasDrivingLicense =>
      drivingLicenseNumber != null && drivingLicenseNumber!.isNotEmpty;
}

class BankDetails {
  final String? bankName;
  final String? accountHolderName;
  final String? accountNumber;
  final String? ifscCode;
  final String? passbookImageUrl;
  final String status;

  BankDetails({
    this.bankName,
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
    this.passbookImageUrl,
    this.status = 'pending_verification',
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bank_name'],
      accountHolderName: json['account_holder_name'],
      accountNumber: json['account_number'],
      ifscCode: json['ifsc_code'],
      passbookImageUrl: json['passbook_image_url'],
      status: json['status'] ?? 'pending_verification',
    );
  }

  factory BankDetails.empty() {
    return BankDetails(
      status: 'pending_verification',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bank_name': bankName,
      'account_holder_name': accountHolderName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'passbook_image_url': passbookImageUrl,
      'status': status,
    };
  }

  bool get isVerified => status == 'verified';

  bool get isPendingVerification => status == 'pending_verification';

  bool get isRejected => status == 'rejected';

  bool get isComplete =>
      bankName != null &&
      bankName!.isNotEmpty &&
      accountHolderName != null &&
      accountHolderName!.isNotEmpty &&
      accountNumber != null &&
      accountNumber!.isNotEmpty &&
      ifscCode != null &&
      ifscCode!.isNotEmpty;
}
