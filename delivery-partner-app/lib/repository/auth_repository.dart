import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:zenfoo_partner/models/profile_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class AuthRepository {
  final ApiService _api = ApiService();

  /// 🔹 1. SEND OTP (New API)
  Future<ApiResponse> sendOtp({
    required String phone,
    String? referralCode,
  }) async {
    final Map<String, dynamic> data = {
      'phone': phone,
    };
    if (referralCode != null && referralCode.isNotEmpty) {
      data['referral_code'] = referralCode;
    }
    return await _api.post(
      AppUrl.sendOtp,
      data: data,
    );
  }

  /// 🔹 1. REQUEST OTP (Old API - kept for backward compatibility)
  Future<ApiResponse> requestOtp({
    required String phone,
  }) async {
    return await _api.post(
      AppUrl.requestOtp,
      data: {
        "phoneno": phone,
        // "ccode": ccode,
      },
    );
  }

  /// 🔹 2. VERIFY OTP (New API)
  Future<ApiResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    return await _api.post(
      '${AppUrl.verifyOtp}?phone=$phone&otp=$otp',
      data: {},
    );
  }

  /// 🔹 3. GET PERSONAL DETAILS
  Future<ApiResponse> getPersonalDetails({bool skipLogout = false}) async {
    return await _api.get(
      AppUrl.getPersonalDetails,
      isToast: false,
      skipLogout: skipLogout,
    );
  }

  /// 🔹 4. GET VEHICLES
  Future<ApiResponse> getVehicles() async {
    return await _api.get(
      AppUrl.getVehicles,
      isToast: false,
    );
  }

  /// 🔹 5. SELECT VEHICLE
  Future<ApiResponse> selectVehicle({
    required int vehicleId,
  }) async {
    return await _api.post(
      AppUrl.selectVehicle,
      data: {
        'vehicle_id': vehicleId,
      },
    );
  }

  /// 🔹 6. GET NEARBY CITIES
  Future<ApiResponse> getNearbyCities({
    String search = '',
  }) async {
    return await _api.get(
      '${AppUrl.getNearbyCities}?search=$search',
      isToast: false,
    );
  }

  /// 🔹 7. UPDATE CITY
  Future<ApiResponse> updateCity({
    required int cityId,
  }) async {
    return await _api.post(
      '${AppUrl.updateCity}?city_id=$cityId',
      data: {},
    );
  }

  /// 🔹 8. GET STORE LOCATIONS
  Future<ApiResponse> getStoreLocations() async {
    return await _api.get(
      AppUrl.getStoreLocations,
      isToast: false,
    );
  }

  /// 🔹 9. SELECT STORE LOCATIONS
  Future<ApiResponse> selectStoreLocations({
    required List<int> storeLocationIds,
  }) async {
    return await _api.post(
      AppUrl.selectStoreLocations,
      data: {
        'store_location_ids': storeLocationIds,
      },
    );
  }

  /// 🔹 10. UPDATE PROFILE IMAGE
  Future<ApiResponse> updateProfileImage({
    required String imagePath,
  }) async {
    return await _api.post(
      AppUrl.updateProfileImage,
      data: {},
      files: {
        'profile_image': File(imagePath),
      },
    );
  }

  /// 🔹 2. VERIFY OTP (Old API - kept for backward compatibility)
  Future<ApiResponse> verifyOtpOld({
    required String phone,
    required String otp,
  }) async {
    return await _api.post(
      AppUrl.verifyOtpOld,
      data: {
        "phoneno": phone,
        "otp": otp,
      },
    );
  }

  /// 🔹 3. UPDATE PERSONAL DETAILS
  Future<ApiResponse> updatePersonalDetails({
    required String name,
    String? email,
    String? dob,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    final Map<String, dynamic> body = {
      'name': name,
      'address': address,
    };

    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }
    if (dob != null && dob.isNotEmpty) {
      body['dob'] = dob;
    }
    if (latitude != null) {
      body['latitude'] = latitude.toString();
      debugPrint('📍 Adding latitude to request: $latitude');
    } else {
      debugPrint('⚠️ Latitude is null');
    }
    if (longitude != null) {
      body['longitude'] = longitude.toString();
      debugPrint('📍 Adding longitude to request: $longitude');
    } else {
      debugPrint('⚠️ Longitude is null');
    }

    debugPrint('🔍 Update personal details request body: $body');

    return await _api.post(
      AppUrl.updatePersonalDetails,
      data: body,
    );
  }

  /// SIGNUP
  Future<ApiResponse> signup({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String primaryCcode,
    required String primaryPhone,
    required String secondaryCcode,
    required String secondaryPhone,
    required String password,
    required String nationality,
    required String dob,
    required String address,
    required String zone,
    required String language,
    required String houseNo,
    required String city,
    required String state,
  }) async {
    return await _api.post(
      AppUrl.driverSignup,
      data: {
        "id": id,
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "primary_ccode": primaryCcode,
        "primary_phoneNo": primaryPhone,
        // "secound_ccode": secondaryCcode,
        // "secound_phoneNo": secondaryPhone,
        "password": password,
        "nationality": nationality,
        "date_of_birth": dob,
        "com_address": address,
        "zone": zone,
        "language": language,
        "house_no": houseNo,
        "city": city,
        "state": state,
      },
    );
  }

  // ================= PROFILE =================

  /// UPLOAD PROFILE IMAGE
  Future<ApiResponse> uploadProfileImage({
    required String driverId,
    required File image,
  }) async {
    return await _api.post(
      AppUrl.driverProfileImage(driverId),
      data: {},
      files: {
        "file": image,
      },
    );
  }

  Future<ApiResponse> addVehicle({
    required String driverId,
    required String serviceCategory,
    required String vehicle,
    required String maxWeight,
    required String brand,
    required String model,
    required String vehicleNumber,
    required String color,
    required String capacity,
    required String preference,
    required File vehicleImage,
  }) async {
    return await _api.post(
      AppUrl.addVehicle,
      data: {
        "id": driverId,
        "service_category": serviceCategory,
        "vehicle": vehicle,
        "max_weight_kg": maxWeight,
        "vehicle_brand": brand,
        "vehicle_model": model,
        "vehicle_number": vehicleNumber,
        "car_color": color,
        "passenger_capacity": capacity,
        "vehicle_prefrence": preference,
      },
      files: {
        "vehicle_image": vehicleImage,
      },
    );
  }

  // ================= AADHAR =================

  /// UPLOAD AADHAR IMAGES
  Future<ApiResponse> uploadAadhar({
    required File image,
  }) async {
    return await _api.post(
      AppUrl.uploadAadhar,
      isToast: false,
      data: {},
      files: {
        "image": image,
      },
    );
  }

  /// ADD AADHAR DETAILS
  Future<ApiResponse> addAadhar({
    required String driverId,
    required String aadharNumber,
    required String frontImagePath,
    required String backImagePath,
  }) async {
    return await _api.post(
      AppUrl.addAadhar,
      data: {
        "id": driverId,
        "aadhar_number": aadharNumber,
        "aadhar_front_img": frontImagePath,
        "aadhar_back_img": backImagePath,
      },
    );
  }

  // ================= BANK =================

  /// UPLOAD PASSBOOK
  Future<ApiResponse> uploadPassbook({
    required File image,
  }) async {
    return await _api.post(AppUrl.uploadBank,
        data: {},
        files: {
          "image": image,
        },
        isToast: false);
  }

  /// ADD BANK DETAILS
  Future<ApiResponse> addBank({
    required String driverId,
    required String iban,
    required String bankName,
    required String holderName,
    required String ifsc,
    required String passbookImagePath,
  }) async {
    return await _api.post(
      AppUrl.addBank,
      data: {
        "id": driverId,
        "iban_number": iban,
        "bank_name": bankName,
        "account_hol_name": holderName,
        "ifsc_number": ifsc,
        "passbook_image": passbookImagePath,
      },
    );
  }

  // ================= RC =================

  /// UPLOAD RC
  Future<ApiResponse> uploadRc({
    required File image,
  }) async {
    return await _api.post(
      AppUrl.uploadRc,
      data: {},
      isToast: false,
      files: {
        "image": image,
      },
    );
  }

  /// ADD RC DETAILS
  Future<ApiResponse> addRc({
    required String driverId,
    required String rcNumber,
    required String frontImagePath,
    required String backImagePath,
  }) async {
    return await _api.post(
      AppUrl.addRc,
      data: {
        "id": driverId,
        "rc_number": rcNumber,
        "rc_front": frontImagePath,
        "rc_back": backImagePath,
      },
    );
  }

  // ================= LICENSE =================

  /// UPLOAD LICENSE
  Future<ApiResponse> uploadLicense({
    required File image,
  }) async {
    return await _api.post(AppUrl.uploadLicense,
        data: {},
        files: {
          "image": image,
        },
        isToast: false);
  }

  /// ADD LICENSE DETAILS
  Future<ApiResponse> addLicense({
    required String driverId,
    required String licenseNumber,
    required String frontImagePath,
    required String backImagePath,
  }) async {
    return await _api.post(
      AppUrl.addLicense,
      data: {
        "id": driverId,
        "driving_license_number": licenseNumber,
        "driving_license_img_front": frontImagePath,
        "driving_license_img_back": backImagePath,
      },
    );
  }

  // ================= INSURANCE =================

  /// UPLOAD INSURANCE
  Future<ApiResponse> uploadInsurance({
    required File image,
  }) async {
    return await _api.post(AppUrl.uploadInsurance,
        data: {},
        files: {
          "image": image,
        },
        isToast: false);
  }

  /// ADD INSURANCE
  Future<ApiResponse> addInsurance({
    required String driverId,
    required String imagePath,
  }) async {
    return await _api.post(
      AppUrl.addInsurance,
      data: {
        "id": driverId,
        "insurance_image": imagePath,
      },
    );
  }

  // ================= POLLUTION =================

  /// UPLOAD POLLUTION
  Future<ApiResponse> uploadPollution({
    required File image,
  }) async {
    return await _api.post(
      AppUrl.uploadPollution,
      data: {},
      files: {
        "image": image,
      },
    );
  }

  /// ADD POLLUTION
  Future<ApiResponse> addPollution({
    required String driverId,
    required String imagePath,
  }) async {
    return await _api.post(
      AppUrl.addPollution,
      data: {
        "id": driverId,
        "pollution_image": imagePath,
      },
    );
  }

  // ================= APPROVAL =================

  /// APPROVE DRIVER
  Future<ApiResponse> approveDriver({
    required String cartId,
  }) async {
    return await _api.post(
      AppUrl.approveDriver,
      data: {
        "cart_id": cartId,
      },
    );
  }
}
