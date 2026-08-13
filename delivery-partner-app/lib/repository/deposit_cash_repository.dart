import 'package:zenfoo_partner/services/api_services.dart';

import '../services/status.dart';
import '../utils/app_urls.dart';

class DepositCashRepository {
  final ApiService _api = ApiService();

  Future<ApiResponse> depositCash({int? isSettled}) async {
    String url = AppUrls.depositCash;
    if (isSettled != null) {
      url += '?is_settled=$isSettled';
    }
    return await _api.get(url);
  }

  Future<ApiResponse> getPaytmConfig() async {
    return await _api.get(AppUrl.paytmConfig);
  }

  Future<ApiResponse> generatePaytmToken(double amount) async {
    return await _api.post(
      AppUrl.generatePaytmToken,
      data: {'amount': amount},
    );
  }

  Future<ApiResponse> settleHandCash({
    required List<int> transactionIds,
    required String paymentTransactionId,
    String paymentGateway = 'paytm',
  }) async {
    return await _api.post(
      AppUrl.settleHandCash,
      data: {
        'transaction_ids': transactionIds,
        'payment_transaction_id': paymentTransactionId,
        'payment_gateway': paymentGateway,
      },
    );
  }
}
