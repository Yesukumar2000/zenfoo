import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/payment_status_model.dart';
import 'package:zenfoo_partner/repository/payment_status_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class PaymentStatusProvider with ChangeNotifier {
  final PaymentStatusRepository _repository = PaymentStatusRepository();

  // Payment status state
  ApiResponse<PaymentStatusResponse> _paymentStatusState =
      ApiResponse.nothing();
  ApiResponse<PaymentStatusResponse> get paymentStatusState =>
      _paymentStatusState;

  PaymentStatusResponse? _paymentStatus;
  PaymentStatusResponse? get paymentStatus => _paymentStatus;

  // Auto-refresh timer
  Timer? _refreshTimer;

  /// Fetch payment status from API
  Future<void> fetchPaymentStatus() async {
    _paymentStatusState = ApiResponse.loading();
    notifyListeners();

    final response = await _repository.getPaymentStatus();

    _paymentStatusState = response;
    if (response.status == ApiStatus.success) {
      _paymentStatus = response.data;
    }

    notifyListeners();
  }

  /// Start auto-refresh of payment status (every 2 minutes)
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      fetchPaymentStatus();
    });
  }

  /// Stop auto-refresh
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Check if delivery boy is blocked
  bool get isBlocked => _paymentStatus?.data?.isBlocked ?? false;

  /// Check if delivery boy can accept orders
  bool get canAcceptOrders => _paymentStatus?.data?.canAcceptOrders ?? true;

  /// Get blocking reasons
  List<BlockingReason> get blockingReasons =>
      _paymentStatus?.data?.blockingReasons ?? [];

  /// Get required action
  RequiredAction? get requiredAction => _paymentStatus?.data?.requiredAction;

  /// Get payment summary
  PaymentSummary? get paymentSummary => _paymentStatus?.data?.paymentSummary;

  /// Check if there's data to display
  bool get hasPaymentData => _paymentStatus?.hasData ?? false;

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
