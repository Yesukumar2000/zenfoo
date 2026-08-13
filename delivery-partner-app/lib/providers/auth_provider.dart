import 'dart:io';
import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/auth_response_model.dart';
import 'package:zenfoo_partner/models/city_model.dart';
import 'package:zenfoo_partner/models/delivery_boy_model.dart';
import 'package:zenfoo_partner/models/store_location_model.dart';
import 'package:zenfoo_partner/models/user_model.dart';
import 'package:zenfoo_partner/models/vehicle_model.dart';
import 'package:zenfoo_partner/repository/auth_repository.dart';
import 'package:zenfoo_partner/services/fcm_token_service.dart';
import 'package:zenfoo_partner/services/local_storage.dart';
import 'package:zenfoo_partner/services/status.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  // Current authenticated user data
  User? _currentUser;
  DeliveryBoy? _currentDeliveryBoy;
  String? _accessToken;
  List<Vehicle> _vehicles = [];

  User? get currentUser => _currentUser;
  DeliveryBoy? get currentDeliveryBoy => _currentDeliveryBoy;
  String? get accessToken => _accessToken;
  List<Vehicle> get vehicles => _vehicles;

  // ================= OTP =================

  ApiResponse sendOtpState = ApiResponse.nothing();
  ApiResponse requestOtpState = ApiResponse.nothing();
  ApiResponse verifyOtpState = ApiResponse.nothing();

  Future<void> sendOtp({
    required String phone,
    String? referralCode,
  }) async {
    sendOtpState = ApiResponse.loading();
    notifyListeners();

    sendOtpState = await _repo.sendOtp(
      phone: phone,
      referralCode: referralCode,
    );

    notifyListeners();
  }

  Future<void> requestOtp({
    required String phone,
  }) async {
    requestOtpState = ApiResponse.loading();
    notifyListeners();

    requestOtpState = await _repo.requestOtp(phone: phone);

    notifyListeners();
  }

  Future<void> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    verifyOtpState = ApiResponse.loading();
    notifyListeners();

    verifyOtpState = await _repo.verifyOtp(phone: phone, otp: otp);

    if (isStatusSuccess(verifyOtpState.status)) {
      debugPrint('🟢 verifyOtp state success. Data: ${verifyOtpState.data}');
      try {
        final authResponse = AuthResponseModel.fromJson(verifyOtpState.data);

        _currentUser = authResponse.data.user;
        _currentDeliveryBoy = authResponse.data.deliveryBoy;
        _accessToken = authResponse.data.accessToken;

        debugPrint(
            '👤 User ID: ${_currentUser?.id}, Name: ${_currentUser?.name}');
        debugPrint(
            '📦 Delivery Boy ID: ${_currentDeliveryBoy?.id}, Status: ${_currentDeliveryBoy?.status}');

        await LocalStorage.saveToken(authResponse.data.accessToken);
        await LocalStorage.saveUserData(authResponse.data.user.toJson());
        await LocalStorage.saveUserId(
          authResponse.data.user.id.toString(),
        );
        await LocalStorage.saveDeliveryBoyData(
          authResponse.data.deliveryBoy.toJson(),
        );

        await LocalStorage.saveRequireSignup(
          authResponse.data.deliveryBoy.needsRegistration,
        );
        await LocalStorage.saveDocumentApprove(
          authResponse.data.deliveryBoy.isApproved,
        );

        // ✅ DO NOT update FCM here
        debugPrint('✅ Auth success, skipping FCM update here');
      } catch (e) {
        debugPrint('❌ Error parsing auth response: $e');
        _saveLegacyAuthData(verifyOtpState.data, phone);
      }
    } else {
      debugPrint(
          '🔴 verifyOtp state failed: ${verifyOtpState.status} - ${verifyOtpState.message}');
    }

    notifyListeners();
  }

  Future<void> updateFcmTokenSafe() async {
    try {
      await _updateFcmTokenAfterAuth();
    } catch (e) {
      debugPrint('⚠️ FCM update failed (ignored): $e');
    }
  }

  /// Fallback method for legacy data storage
  Future<void> _saveLegacyAuthData(dynamic data, String phone) async {
    final accessToken = data['data']?['access_token'] ?? '';
    await LocalStorage.saveToken(accessToken);

    final userData = data['data']?['user'];
    if (userData != null) {
      await LocalStorage.saveUserData(userData);
      await LocalStorage.saveUserId(userData['id']?.toString() ?? '');
    }

    final deliveryBoyData = data['data']?['delivery_boy'];
    if (deliveryBoyData != null) {
      await LocalStorage.saveDeliveryBoyData(deliveryBoyData);

      final needsRegistration =
          deliveryBoyData['name'] == phone || deliveryBoyData['email'] == null;
      await LocalStorage.saveRequireSignup(needsRegistration);

      final status = deliveryBoyData['status'] ?? 0;
      final isApproved = status != 0;
      await LocalStorage.saveDocumentApprove(isApproved);
    }
  }

  /// Load user data from local storage
  Future<void> loadUserData() async {
    try {
      final userData = await LocalStorage.getUserData();
      final deliveryBoy = await LocalStorage.getDeliveryBoyModel();
      final token = await LocalStorage.getToken();

      if (userData != null) {
        _currentUser = User.fromJson(userData);
      }
      if (deliveryBoy != null) {
        _currentDeliveryBoy = deliveryBoy;
      }
      _accessToken = token;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  /// Clear all user data (logout)
  Future<void> clearUserData() async {
    _currentUser = null;
    _currentDeliveryBoy = null;
    _accessToken = null;

    // Clear all local storage including token, user data, delivery boy data, flags, etc.
    await LocalStorage.clearLocalStorate();

    notifyListeners();
  }

  // ================= VEHICLES =================

  ApiResponse getVehiclesState = ApiResponse.nothing();
  ApiResponse selectVehicleState = ApiResponse.nothing();

  Future<void> getVehicles() async {
    getVehiclesState = ApiResponse.loading();
    notifyListeners();

    getVehiclesState = await _repo.getVehicles();

    if (isStatusSuccess(getVehiclesState.status)) {
      try {
        final vehiclesData = getVehiclesState.data['data'] as List?;
        if (vehiclesData != null) {
          _vehicles = vehiclesData.map((v) => Vehicle.fromJson(v)).toList();
        }
      } catch (e) {
        debugPrint('Error fetching vehicles: $e');
      }
    }

    notifyListeners();
  }

  Future<void> selectVehicle({
    required int vehicleId,
  }) async {
    selectVehicleState = ApiResponse.loading();
    notifyListeners();

    selectVehicleState = await _repo.selectVehicle(vehicleId: vehicleId);

    if (isStatusSuccess(selectVehicleState.status)) {
      try {
        // Update delivery boy data with selected vehicle
        await getPersonalDetails();
      } catch (e) {
        debugPrint('Error selecting vehicle: $e');
      }
    }

    notifyListeners();
  }

  // ================= CITIES =================

  List<City> _cities = [];
  List<City> get cities => _cities;

  ApiResponse getNearbyCitiesState = ApiResponse.nothing();
  ApiResponse updateCityState = ApiResponse.nothing();

  // ================= STORE LOCATIONS =================

  List<StoreLocation> _storeLocations = [];
  List<StoreLocation> get storeLocations => _storeLocations;

  ApiResponse getStoreLocationsState = ApiResponse.nothing();
  ApiResponse selectStoreLocationsState = ApiResponse.nothing();

  // ================= PROFILE IMAGE =================

  ApiResponse updateProfileImageState = ApiResponse.nothing();

  Future<void> getStoreLocations() async {
    getStoreLocationsState = ApiResponse.loading();
    notifyListeners();

    getStoreLocationsState = await _repo.getStoreLocations();

    if (isStatusSuccess(getStoreLocationsState.status)) {
      try {
        final storesData =
            getStoreLocationsState.data['data']?['store_locations'] as List?;
        if (storesData != null) {
          _storeLocations =
              storesData.map((s) => StoreLocation.fromJson(s)).toList();
        }
      } catch (e) {
        debugPrint('Error fetching store locations: $e');
      }
    }

    notifyListeners();
  }

  Future<void> selectStoreLocations({
    required List<int> storeLocationIds,
  }) async {
    selectStoreLocationsState = ApiResponse.loading();
    notifyListeners();

    selectStoreLocationsState = await _repo.selectStoreLocations(
      storeLocationIds: storeLocationIds,
    );

    if (isStatusSuccess(selectStoreLocationsState.status)) {
      try {
        // Update delivery boy data with selected stores
        await getPersonalDetails();
      } catch (e) {
        debugPrint('Error selecting store locations: $e');
      }
    }

    notifyListeners();
  }

  Future<void> getNearbyCities({String search = ''}) async {
    getNearbyCitiesState = ApiResponse.loading();
    notifyListeners();

    getNearbyCitiesState = await _repo.getNearbyCities(search: search);

    if (isStatusSuccess(getNearbyCitiesState.status)) {
      try {
        final citiesData =
            getNearbyCitiesState.data['data']?['cities'] as List?;
        if (citiesData != null) {
          _cities = citiesData.map((c) => City.fromJson(c)).toList();
        }
      } catch (e) {
        debugPrint('Error fetching cities: $e');
      }
    }

    notifyListeners();
  }

  Future<void> updateCity({
    required int cityId,
  }) async {
    updateCityState = ApiResponse.loading();
    notifyListeners();

    updateCityState = await _repo.updateCity(cityId: cityId);

    if (isStatusSuccess(updateCityState.status)) {
      try {
        // Update delivery boy data with selected city
        await getPersonalDetails();
      } catch (e) {
        debugPrint('Error updating city: $e');
      }
    }

    notifyListeners();
  }

  Future<void> updateProfileImage({
    required String imagePath,
  }) async {
    updateProfileImageState = ApiResponse.loading();
    notifyListeners();

    updateProfileImageState =
        await _repo.updateProfileImage(imagePath: imagePath);

    if (isStatusSuccess(updateProfileImageState.status)) {
      try {
        // Update delivery boy data with new profile image
        await getPersonalDetails();
      } catch (e) {
        debugPrint('Error updating profile image: $e');
      }
    }

    notifyListeners();
  }

  // ================= PERSONAL DETAILS =================

  ApiResponse getPersonalDetailsState = ApiResponse.nothing();
  ApiResponse updatePersonalDetailsState = ApiResponse.nothing();

  Future<void> getPersonalDetails({bool skipLogout = false}) async {
    getPersonalDetailsState = ApiResponse.loading();
    notifyListeners();

    getPersonalDetailsState =
        await _repo.getPersonalDetails(skipLogout: skipLogout);

    if (isStatusSuccess(getPersonalDetailsState.status)) {
      try {
        final deliveryBoyData =
            getPersonalDetailsState.data['data']?['delivery_boy'];
        if (deliveryBoyData != null) {
          _currentDeliveryBoy = DeliveryBoy.fromJson(deliveryBoyData);
          await LocalStorage.saveDeliveryBoyData(deliveryBoyData);

          // Load documents into DocumentProvider if available
          if (deliveryBoyData['documents'] != null) {
            // DocumentProvider will be updated via context in the calling widget
            debugPrint(
                'Documents available in response: ${deliveryBoyData['documents']}');
          }
        }
      } catch (e) {
        debugPrint('Error fetching delivery boy data: $e');
      }
    }

    notifyListeners();
  }

  Future<void> updatePersonalDetails({
    required String name,
    String? email,
    String? dob,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    updatePersonalDetailsState = ApiResponse.loading();
    notifyListeners();

    updatePersonalDetailsState = await _repo.updatePersonalDetails(
      name: name,
      email: email,
      dob: dob,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );

    // If successful, update delivery boy data in storage
    if (isStatusSuccess(updatePersonalDetailsState.status)) {
      try {
        final deliveryBoyData =
            updatePersonalDetailsState.data['data']?['delivery_boy'];
        if (deliveryBoyData != null) {
          _currentDeliveryBoy = DeliveryBoy.fromJson(deliveryBoyData);
          await LocalStorage.saveDeliveryBoyData(deliveryBoyData);
        }
      } catch (e) {
        debugPrint('Error updating delivery boy data: $e');
      }
    }

    notifyListeners();
  }

  // ================= SIGNUP =================

  ApiResponse signupState = ApiResponse.nothing();

  Future<void> signup({
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
    signupState = ApiResponse.loading();
    notifyListeners();

    signupState = await _repo.signup(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      primaryCcode: primaryCcode,
      primaryPhone: primaryPhone,
      secondaryCcode: secondaryCcode,
      secondaryPhone: secondaryPhone,
      password: password,
      nationality: nationality,
      dob: dob,
      address: address,
      zone: zone,
      language: language,
      houseNo: houseNo,
      city: city,
      state: state,
    );

    notifyListeners();
  }

  // ================= PROFILE =================

  ApiResponse profileImageState = ApiResponse.nothing();

  Future<void> uploadProfileImage({
    required String driverId,
    required File image,
  }) async {
    profileImageState = ApiResponse.loading();
    notifyListeners();

    profileImageState =
        await _repo.uploadProfileImage(driverId: driverId, image: image);

    notifyListeners();
  }

  // ================= VEHICLE =================

  ApiResponse addVehicleState = ApiResponse.nothing();

  Future<void> addVehicle({
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
    addVehicleState = ApiResponse.loading();
    notifyListeners();

    addVehicleState = await _repo.addVehicle(
      driverId: driverId,
      serviceCategory: serviceCategory,
      vehicle: vehicle,
      maxWeight: maxWeight,
      brand: brand,
      model: model,
      vehicleNumber: vehicleNumber,
      color: color,
      capacity: capacity,
      preference: preference,
      vehicleImage: vehicleImage,
    );

    notifyListeners();
  }

  // ================= AADHAR =================

  ApiResponse uploadAadharState = ApiResponse.nothing();
  ApiResponse addAadharState = ApiResponse.nothing();

  Future<void> uploadAadhar({
    required File image,
  }) async {
    uploadAadharState = ApiResponse.loading();
    notifyListeners();

    uploadAadharState = await _repo.uploadAadhar(image: image);

    notifyListeners();
  }

  Future<void> addAadhar({
    required String aadharNumber,
    required String frontImagePath,
    required String backImagePath,
  }) async {
    addAadharState = ApiResponse.loading();
    notifyListeners();

    addAadharState = await _repo.addAadhar(
      driverId: await LocalStorage.getUserId() ?? '',
      aadharNumber: aadharNumber,
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
    );

    notifyListeners();
  }

  // ================= BANK =================

  ApiResponse uploadBankState = ApiResponse.nothing();
  ApiResponse addBankState = ApiResponse.nothing();

  Future<void> uploadBankPassbook({
    required File image,
  }) async {
    uploadBankState = ApiResponse.loading();
    notifyListeners();

    uploadBankState = await _repo.uploadPassbook(image: image);

    notifyListeners();
  }

  Future<void> addBankAccount({
    required String driverId,
    required String iban,
    required String bankName,
    required String holderName,
    required String ifsc,
    required String passbookImagePath,
  }) async {
    addBankState = ApiResponse.loading();
    notifyListeners();

    addBankState = await _repo.addBank(
      driverId: driverId,
      iban: iban,
      bankName: bankName,
      holderName: holderName,
      ifsc: ifsc,
      passbookImagePath: passbookImagePath,
    );

    notifyListeners();
  }

  // ================= RC =================

  ApiResponse uploadRcState = ApiResponse.nothing();
  ApiResponse addRcState = ApiResponse.nothing();

  Future<void> uploadRc({
    required File image,
  }) async {
    uploadRcState = ApiResponse.loading();
    notifyListeners();

    uploadRcState = await _repo.uploadRc(image: image);

    notifyListeners();
  }

  Future<void> addRc({
    required String driverId,
    required String rcNumber,
    required String frontImagePath,
    required String backImagePath,
  }) async {
    addRcState = ApiResponse.loading();
    notifyListeners();

    addRcState = await _repo.addRc(
      driverId: driverId,
      rcNumber: rcNumber,
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
    );

    notifyListeners();
  }

  // ================= LICENSE =================

  ApiResponse uploadLicenseState = ApiResponse.nothing();
  ApiResponse addLicenseState = ApiResponse.nothing();

  Future<void> uploadLicense({
    required File image,
  }) async {
    uploadLicenseState = ApiResponse.loading();
    notifyListeners();

    uploadLicenseState = await _repo.uploadLicense(image: image);

    notifyListeners();
  }

  Future<void> addLicense({
    required String driverId,
    required String licenseNumber,
    required String frontImagePath,
    required String backImagePath,
  }) async {
    addLicenseState = ApiResponse.loading();
    notifyListeners();

    addLicenseState = await _repo.addLicense(
      driverId: driverId,
      licenseNumber: licenseNumber,
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
    );

    notifyListeners();
  }

  // ================= INSURANCE =================

  ApiResponse uploadInsuranceState = ApiResponse.nothing();
  ApiResponse addInsuranceState = ApiResponse.nothing();

  Future<void> uploadInsurance({
    required File image,
  }) async {
    uploadInsuranceState = ApiResponse.loading();
    notifyListeners();

    uploadInsuranceState = await _repo.uploadInsurance(image: image);

    notifyListeners();
  }

  Future<void> addInsurance({
    required String driverId,
    required String imagePath,
  }) async {
    addInsuranceState = ApiResponse.loading();
    notifyListeners();

    addInsuranceState = await _repo.addInsurance(
      driverId: driverId,
      imagePath: imagePath,
    );

    notifyListeners();
  }

  // ================= POLLUTION =================

  ApiResponse uploadPollutionState = ApiResponse.nothing();
  ApiResponse addPollutionState = ApiResponse.nothing();

  Future<void> uploadPollution({
    required File image,
  }) async {
    uploadPollutionState = ApiResponse.loading();
    notifyListeners();

    uploadPollutionState = await _repo.uploadPollution(image: image);

    notifyListeners();
  }

  Future<void> addPollution({
    required String driverId,
    required String imagePath,
  }) async {
    addPollutionState = ApiResponse.loading();
    notifyListeners();

    addPollutionState = await _repo.addPollution(
      driverId: driverId,
      imagePath: imagePath,
    );

    notifyListeners();
  }

  // ================= APPROVAL =================

  ApiResponse approveDriverState = ApiResponse.nothing();

  Future<void> approveDriver({
    required String cartId,
  }) async {
    approveDriverState = ApiResponse.loading();
    notifyListeners();

    approveDriverState = await _repo.approveDriver(cartId: cartId);

    notifyListeners();
  }

  /// Update FCM token after successful authentication
  Future<void> _updateFcmTokenAfterAuth() async {
    try {
      final fcmService = FcmTokenService();

      // Update FCM token on backend
      final success = await fcmService.updateFcmToken();

      if (success) {
        debugPrint('✅ FCM token updated after auth');
      } else {
        debugPrint(
            '⚠️ Failed to update FCM token after auth, will retry on token refresh');
      }

      // Setup listener for token refresh to update automatically
      fcmService.setupTokenRefreshListener((newToken) async {
        debugPrint('🔄 FCM token refresh detected, updating backend');
        await fcmService.updateFcmToken();
      });
    } catch (e) {
      debugPrint('❌ Error updating FCM token after auth: $e');
    }
  }
}
