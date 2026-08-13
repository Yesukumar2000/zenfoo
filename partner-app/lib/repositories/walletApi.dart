import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/wallet_transaction.dart';

/// Get wallet overview with current balance and recent transactions
/// API: GET /api/seller/wallet/overview
Future<WalletTransactionResponse?> getWalletOverview({
  required BuildContext context,
}) async {
  try {
    final response = await sendApiRequest(
      apiName: 'wallet/overview',
      params: {},
      isPost: false,
    );

    final Map<String, dynamic> data = json.decode(response);
    return WalletTransactionResponse.fromJson(data);
  } catch (e) {
    debugPrint('Error fetching wallet overview: $e');
    showMessage(
      context,
      'Error loading wallet overview',
      MessageType.error,
    );
    return null;
  }
}

/// Get transaction history with pagination and filters
/// API: GET /api/seller/wallet/transactions
Future<Map<String, dynamic>?> getWalletTransactions({
  required BuildContext context,
  int page = 1,
  int perPage = 20,
  String? type,
  String? fromDate,
  String? toDate,
}) async {
  try {
    Map<String, String> params = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (type != null && type.isNotEmpty) {
      params['type'] = type;
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      params['from_date'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      params['to_date'] = toDate;
    }

    final response = await sendApiRequest(
      apiName: 'wallet/transactions',
      params: params,
      isPost: false,
    );

    final Map<String, dynamic> data = json.decode(response);

    if (data['status'] == 1 && data['data'] != null) {
      // API returns nested structure: data.transactions and data.pagination
      final responseData = data['data'];
      return {
        'data': responseData['transactions'] ?? [],
        'last_page': responseData['pagination']?['last_page'] ?? 1,
        'current_page': responseData['pagination']?['current_page'] ?? 1,
        'total': responseData['pagination']?['total'] ?? 0,
        'per_page': responseData['pagination']?['per_page'] ?? 20,
      };
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching wallet transactions: $e');
    showMessage(
      context,
      'Error loading transactions',
      MessageType.error,
    );
    return null;
  }
}

/// Create a new withdrawal request
/// API: POST /api/seller/wallet/withdrawal-request
Future<Map<String, dynamic>?> createWithdrawalRequest({
  required BuildContext context,
  required double amount,
  required String accountNumber,
  required String bankIfscCode,
  required String accountName,
  required String bankName,
  String? branchName,
  String? sellerNote,
}) async {
  try {
    final response = await sendApiRequest(
      apiName: 'wallet/withdrawal-request',
      params: {
        'amount': amount.toString(),
        'account_number': accountNumber,
        'bank_ifsc_code': bankIfscCode,
        'account_name': accountName,
        'bank_name': bankName,
        if (branchName != null && branchName.isNotEmpty)
          'branch_name': branchName,
        if (sellerNote != null && sellerNote.isNotEmpty)
          'seller_note': sellerNote,
      },
      isPost: true,
    );

    final Map<String, dynamic> data = json.decode(response);

    if (data['status'] == 1) {
      showMessage(
        context,
        data['message'] ?? 'Withdrawal request created successfully',
        MessageType.success,
      );
      return data['data'];
    } else {
      showMessage(
        context,
        data['message'] ?? 'Failed to create withdrawal request',
        MessageType.warning,
      );
      return null;
    }
  } catch (e) {
    debugPrint('Error creating withdrawal request: $e');
    showMessage(
      context,
      'Error creating withdrawal request: ${e.toString()}',
      MessageType.error,
    );
    return null;
  }
}

/// Get withdrawal requests with pagination and filters
/// API: GET /api/seller/wallet/withdrawal-requests
Future<Map<String, dynamic>?> getWithdrawalRequests({
  required BuildContext context,
  int page = 1,
  int perPage = 20,
  String? status,
}) async {
  try {
    Map<String, String> params = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }

    final response = await sendApiRequest(
      apiName: 'wallet/withdrawal-requests',
      params: params,
      isPost: false,
    );

    final Map<String, dynamic> data = json.decode(response);

    if (data['status'] == 1 && data['data'] != null) {
      // API returns nested structure: data.withdrawal_requests and data.pagination
      final responseData = data['data'];
      return {
        'data': responseData['withdrawal_requests'] ?? [],
        'last_page': responseData['pagination']?['last_page'] ?? 1,
        'current_page': responseData['pagination']?['current_page'] ?? 1,
        'total': responseData['pagination']?['total'] ?? 0,
        'per_page': responseData['pagination']?['per_page'] ?? 20,
      };
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching withdrawal requests: $e');
    showMessage(
      context,
      'Error loading withdrawal requests',
      MessageType.error,
    );
    return null;
  }
}

/// Get earnings summary by time period
/// API: GET /api/seller/wallet/earnings-summary
Future<EarningsSummary?> getEarningsSummary({
  required BuildContext context,
}) async {
  try {
    final response = await sendApiRequest(
      apiName: 'wallet/earnings-summary',
      params: {},
      isPost: false,
    );

    final Map<String, dynamic> data = json.decode(response);

    if (data['status'] == 1 && data['data'] != null) {
      return EarningsSummary.fromJson(data['data']);
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching earnings summary: $e');
    showMessage(
      context,
      'Error loading earnings summary',
      MessageType.error,
    );
    return null;
  }
}
