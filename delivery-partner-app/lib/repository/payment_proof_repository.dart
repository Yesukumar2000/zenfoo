import 'dart:io';
import 'package:zenfoo_partner/models/payment_proof_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class PaymentProofRepository {
  final ApiService _api = ApiService();

  Future<PaymentProofResponse?> submitPaymentProof({
    required String transactionId,
    required double amount,
    required File proofImage,
  }) async {
    final response = await _api.post(
      AppUrl.submitPaymentProof,
      data: {
        'transaction_id': transactionId,
        'amount': amount.toStringAsFixed(2),
      },
      files: {'proof_image': proofImage},
    );

    if (response.data != null) {
      try {
        return PaymentProofResponse.fromJson(response.data);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
