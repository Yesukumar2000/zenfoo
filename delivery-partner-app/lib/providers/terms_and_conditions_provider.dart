import 'package:flutter/material.dart';
import 'package:zenfoo_partner/repository/terms_and_conditions_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class TermsAndConditionsProvider extends ChangeNotifier {
  final TermsAndConditionsRepository _repo = TermsAndConditionsRepository();

  ApiResponse getTermsAndConditionsState = ApiResponse.nothing();
  String? htmlContent;

  Future<void> getTermsAndConditions() async {
    getTermsAndConditionsState = ApiResponse.loading();
    notifyListeners();

    getTermsAndConditionsState = await _repo.getTermsAndConditions();

    if (isStatusSuccess(getTermsAndConditionsState.status)) {
      // Extract HTML content from the response
      final data = getTermsAndConditionsState.data;
      if (data != null) {
        // Handle both direct HTML string and nested data structure
        if (data is String) {
          htmlContent = data;
        } else if (data is Map) {
          htmlContent = data['html'] ?? data['data'] ?? data.toString();
        }
      }
    }

    notifyListeners();
  }

  void reset() {
    getTermsAndConditionsState = ApiResponse.nothing();
    htmlContent = null;
    notifyListeners();
  }
}
