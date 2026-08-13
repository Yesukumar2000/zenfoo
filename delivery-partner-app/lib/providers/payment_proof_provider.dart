import 'dart:io';
import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/payment_proof_model.dart';
import 'package:zenfoo_partner/repository/payment_proof_repository.dart';

class PaymentProofProvider extends ChangeNotifier {
  final PaymentProofRepository _repository = PaymentProofRepository();

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _error;
  PaymentProofData? _submittedData;

  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;
  String? get error => _error;
  PaymentProofData? get submittedData => _submittedData;

  void reset() {
    _isLoading = false;
    _isSuccess = false;
    _error = null;
    _submittedData = null;
    notifyListeners();
  }

  Future<void> submitPaymentProof({
    required String transactionId,
    required double amount,
    required File proofImage,
  }) async {
    _isLoading = true;
    _isSuccess = false;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.submitPaymentProof(
        transactionId: transactionId,
        amount: amount,
        proofImage: proofImage,
      );

      if (result != null && result.status == 1) {
        _isSuccess = true;
        _submittedData = result.data;
      } else {
        _error = result?.message ?? 'Failed to submit payment proof';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
