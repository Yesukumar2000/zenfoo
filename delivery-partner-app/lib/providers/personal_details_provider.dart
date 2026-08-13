import 'package:flutter/foundation.dart';
import 'package:zenfoo_partner/models/delivery_boy_model.dart';
import 'package:zenfoo_partner/models/personal_details_model.dart';
import 'package:zenfoo_partner/repository/personal_details_repository.dart';
import 'package:zenfoo_partner/services/local_storage.dart';
import 'package:zenfoo_partner/services/status.dart';

enum PersonalDetailsState { idle, loading, loaded, error }

class PersonalDetailsProvider extends ChangeNotifier {
  PersonalDetailsState _state = PersonalDetailsState.idle;
  PersonalDetailsData? _personalDetails;
  DeliveryBoy? _deliveryBoy;
  String? _errorMessage;

  final PersonalDetailsRepository _repo = PersonalDetailsRepository();

  // Getters
  PersonalDetailsState get state => _state;
  PersonalDetailsData? get personalDetails => _personalDetails;
  DeliveryBoy? get deliveryBoy => _deliveryBoy;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == PersonalDetailsState.loading;
  bool get isLoaded => _state == PersonalDetailsState.loaded;
  bool get hasError => _state == PersonalDetailsState.error;

  // Document details getters
  Documents? get documents => _personalDetails?.documents;
  BankDetails? get bankDetails => _personalDetails?.bankDetails;
  String? get overallStatus => _personalDetails?.overallStatus;

  /// Fetch personal details from API (single API call - saves data for both providers)
  Future<bool> fetchPersonalDetails() async {
    try {
      _state = PersonalDetailsState.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _repo.getPersonalDetails();

      if (response.status == ApiStatus.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final deliveryBoyData = data['data']?['delivery_boy'];

        if (deliveryBoyData != null) {
          // Parse delivery boy as model
          _deliveryBoy = DeliveryBoy.fromJson(deliveryBoyData);

          // Extract documents from delivery_boy.documents
          final documentsData = deliveryBoyData['documents'];
          debugPrint('📦 Documents from API: ${documentsData != null ? documentsData.keys.toList() : 'null'}');

          // Log each document if available
          if (documentsData != null) {
            if (documentsData['driving_license'] != null) {
              debugPrint('  ✅ Driving License: ${documentsData['driving_license']['status']} - ${documentsData['driving_license']['number']}');
            }
            if (documentsData['rc'] != null) {
              debugPrint('  ✅ RC: ${documentsData['rc']['status']} - ${documentsData['rc']['number']}');
            }
            if (documentsData['aadhar'] != null) {
              debugPrint('  ✅ Aadhar: ${documentsData['aadhar']['status']}');
            }
            if (documentsData['pan'] != null) {
              debugPrint('  ✅ PAN: ${documentsData['pan']['status']}');
            }
            if (documentsData['bank_details'] != null) {
              debugPrint('  ✅ Bank Details: ${documentsData['bank_details']['status']}');
            }
            debugPrint('  📊 Overall Status: ${documentsData['overall_status']}');
          }

          // Create PersonalDetailsData with documents from delivery_boy
          final parsedDocuments = documentsData != null
              ? Documents.fromJson(documentsData)
              : Documents.empty();

          _personalDetails = PersonalDetailsData(
            id: _deliveryBoy!.id,
            name: _deliveryBoy!.name,
            mobile: _deliveryBoy!.mobile,
            email: _deliveryBoy!.email,
            dob: _deliveryBoy!.dob,
            address: _deliveryBoy!.address,
            latitude: _deliveryBoy!.latitude,
            longitude: _deliveryBoy!.longitude,
            storeLocations: _deliveryBoy!.storeLocations,
            storeLocationsCount: _deliveryBoy!.storeLocationsCount,
            profileImageUrl: _deliveryBoy!.profileImageUrl,
            documents: parsedDocuments,
            bankDetails: BankDetails.empty(),
            overallStatus: documentsData?['overall_status'] ?? 'pending_verification',
            createdAt: _deliveryBoy!.createdAt,
            updatedAt: _deliveryBoy!.createdAt,
          );

          // Log what was parsed into the Documents model
          debugPrint('🔍 Documents parsed into model:');
          debugPrint('  DL: number=${parsedDocuments.drivingLicenseNumber}, status=${parsedDocuments.drivingLicenseStatus}');
          debugPrint('  RC: number=${parsedDocuments.rcNumber}, status=${parsedDocuments.rcStatus}');
          debugPrint('  Aadhar: number=${parsedDocuments.aadharNumber}, status=${parsedDocuments.aadharStatus}');
          debugPrint('  PAN: number=${parsedDocuments.panNumber}, status=${parsedDocuments.panStatus}');
          debugPrint('  Bank: name=${parsedDocuments.bankName}, status=${parsedDocuments.bankDetailsStatus}');

          // Save delivery boy data PLUS documents to localStorage
          final deliveryBoyJson = _deliveryBoy!.toJson();
          deliveryBoyJson['documents'] = _personalDetails!.documents.toJson();

          await LocalStorage.saveDeliveryBoyData(deliveryBoyJson);
          debugPrint('✅ Delivery boy data (${_deliveryBoy!.name}) with documents saved to localStorage');
        }

        _state = PersonalDetailsState.loaded;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to fetch personal details';
        _state = PersonalDetailsState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error fetching personal details: $e';
      _state = PersonalDetailsState.error;
      notifyListeners();
      return false;
    }
  }

  /// Update personal details
  Future<bool> updatePersonalDetails({
    required String name,
    required String email,
    required String dob,
    required String address,
    required String latitude,
    required String longitude,
  }) async {
    try {
      _state = PersonalDetailsState.loading;
      notifyListeners();

      final response = await _repo.updatePersonalDetails(
        name: name,
        email: email,
        dob: dob,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

      if (response.status == ApiStatus.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _personalDetails = PersonalDetailsData.fromJson(data['data'] ?? data);
        _state = PersonalDetailsState.loaded;
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            response.message ?? 'Failed to update personal details';
        _state = PersonalDetailsState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating personal details: $e';
      _state = PersonalDetailsState.error;
      notifyListeners();
      return false;
    }
  }

  /// Clear personal details
  void clearPersonalDetails() {
    _personalDetails = null;
    _deliveryBoy = null;
    _errorMessage = null;
    _state = PersonalDetailsState.idle;
    notifyListeners();
  }

  /// Get document verification status
  DocumentVerificationStatus getDocumentStatus() {
    if (_personalDetails == null) {
      return DocumentVerificationStatus(
        isVerified: false,
        isPending: true,
        isRejected: false,
        message: 'Documents not uploaded',
      );
    }

    final docs = _personalDetails!.documents;

    if (docs.isVerified) {
      return DocumentVerificationStatus(
        isVerified: true,
        isPending: false,
        isRejected: false,
        message: 'All documents verified',
      );
    } else if (docs.isRejected) {
      return DocumentVerificationStatus(
        isVerified: false,
        isPending: false,
        isRejected: true,
        message: 'Documents rejected. Please reupload.',
      );
    } else {
      return DocumentVerificationStatus(
        isVerified: false,
        isPending: true,
        isRejected: false,
        message: 'Documents pending verification',
      );
    }
  }

  /// Get bank details verification status
  BankVerificationStatus getBankStatus() {
    if (_personalDetails == null) {
      return BankVerificationStatus(
        isVerified: false,
        isPending: true,
        isRejected: false,
        message: 'Bank details not submitted',
      );
    }

    final bank = _personalDetails!.bankDetails;

    if (bank.isVerified) {
      return BankVerificationStatus(
        isVerified: true,
        isPending: false,
        isRejected: false,
        message: 'Bank details verified',
      );
    } else if (bank.isRejected) {
      return BankVerificationStatus(
        isVerified: false,
        isPending: false,
        isRejected: true,
        message: 'Bank details rejected. Please update.',
      );
    } else {
      return BankVerificationStatus(
        isVerified: false,
        isPending: true,
        isRejected: false,
        message: 'Bank details pending verification',
      );
    }
  }

  /// Check if all verification is complete
  bool get isFullyVerified => _personalDetails?.isFullyVerified ?? false;

  /// Check if any verification is pending
  bool get isVerificationPending =>
      _personalDetails?.isVerificationPending ?? true;

  /// Check if any verification is rejected
  bool get isVerificationRejected =>
      _personalDetails?.isVerificationRejected ?? false;
}

class DocumentVerificationStatus {
  final bool isVerified;
  final bool isPending;
  final bool isRejected;
  final String message;

  DocumentVerificationStatus({
    required this.isVerified,
    required this.isPending,
    required this.isRejected,
    required this.message,
  });
}

class BankVerificationStatus {
  final bool isVerified;
  final bool isPending;
  final bool isRejected;
  final String message;

  BankVerificationStatus({
    required this.isVerified,
    required this.isPending,
    required this.isRejected,
    required this.message,
  });
}
