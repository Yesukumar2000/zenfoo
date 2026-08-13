import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/referral_tracking_model.dart';
import 'package:zenfoo_partner/repository/referral_repository.dart';

class ReferralProvider with ChangeNotifier {
  final ReferralRepository _repository = ReferralRepository();

  ReferralTrackingModel? _referralData;
  bool _isLoading = false;
  String? _error;

  ReferralTrackingModel? get referralData => _referralData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchReferralTracking() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _referralData = await _repository.getReferralTracking();
      if (_referralData == null) {
        _error = "No referral data found";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
