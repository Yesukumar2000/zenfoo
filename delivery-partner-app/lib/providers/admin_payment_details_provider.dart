import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/admin_payment_details_model.dart';
import 'package:zenfoo_partner/repository/admin_payment_details_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class AdminPaymentDetailsProvider extends ChangeNotifier {
  final AdminPaymentDetailsRepository _repository =
      AdminPaymentDetailsRepository();

  ApiResponse<AdminPaymentDetailsModel> _response = ApiResponse.nothing();

  ApiResponse<AdminPaymentDetailsModel> get response => _response;
  AdminPaymentDetailsModel? get data => _response.data;
  bool get isLoading => _response.status == ApiStatus.loading;

  AdminPaymentDetailsProvider() {
    fetchAdminPaymentDetails();
  }

  Future<void> fetchAdminPaymentDetails() async {
    _response = ApiResponse.loading();
    notifyListeners();

    try {
      final result = await _repository.getAdminPaymentDetails();
      _response = result != null
          ? ApiResponse.success(result)
          : ApiResponse.error('No data');
    } catch (e) {
      _response = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }
}
