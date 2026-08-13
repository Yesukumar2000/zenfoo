import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/emergency_support_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class EmergencySupportProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<EmergencySupportContact> _emergencyContacts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EmergencySupportContact> get emergencyContacts => _emergencyContacts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchEmergencyContacts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get(AppUrl.emergencyContacts2);

      if (response.data != null) {
        final emergencySupportResponse = EmergencySupportResponse.fromJson(response.data);

        if (emergencySupportResponse.status == 1) {
          _emergencyContacts = emergencySupportResponse.emergencyContacts;
          _errorMessage = null;
        } else {
          _errorMessage = emergencySupportResponse.message;
          _emergencyContacts = [];
        }
      } else {
        _errorMessage = 'Failed to fetch emergency contacts';
        _emergencyContacts = [];
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      _emergencyContacts = [];
      debugPrint('Error fetching emergency contacts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
