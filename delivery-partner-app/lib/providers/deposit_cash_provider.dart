import 'package:flutter/material.dart';
import 'package:paytmpayments_allinonesdk/paytmpayments_allinonesdk.dart';
import 'package:zenfoo_partner/models/deposit_cash_model.dart';
import 'package:zenfoo_partner/repository/deposit_cash_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class DepositCashProvider extends ChangeNotifier {
  final DepositCashRepository _repo = DepositCashRepository();

  ApiResponse<DepositCashData> _handCashResponse = ApiResponse.nothing();
  ApiResponse<DepositCashData> get handCashResponse => _handCashResponse;

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  Summary? _summary;
  Summary? get summary => _summary;

  Pagination? _pagination;
  Pagination? get pagination => _pagination;

  int _selectedFilterIndex = 0; // 0: Total, 1: Not Settled, 2: Settled
  int get selectedFilterIndex => _selectedFilterIndex;

  List<int> _selectedTransactionIds = [];
  List<int> get selectedTransactionIds => _selectedTransactionIds;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Transaction> _depositTransactions = [];
  List<Transaction> get depositTransactions => _depositTransactions;

  bool _isDepositLoading = false;
  bool get isDepositLoading => _isDepositLoading;

  Future<void> fetchHandCash({int? isSettled}) async {
    _isLoading = true;
    _handCashResponse = ApiResponse.loading();
    notifyListeners();

    try {
      final response = await _repo.depositCash(isSettled: isSettled);
      if (response.status == ApiStatus.success) {
        final model = DepositCashModel.fromJson(response.data);
        _transactions = model.data?.transactions ?? [];

        // Only update summary/pagination when fetching "Total" (isSettled == null)
        // OR preserve existing summary if fetching filtered view
        if (isSettled == null) {
          _summary = model.data?.summary;
          _pagination = model.data?.pagination;
        }

        _handCashResponse = ApiResponse.success(model.data);
      } else {
        _handCashResponse = ApiResponse.error(response.message);
      }
    } catch (e) {
      _handCashResponse = ApiResponse.error(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDepositTransactions() async {
    _isDepositLoading = true;
    notifyListeners();

    try {
      // Always fetch not settled for deposit
      final response = await _repo.depositCash(isSettled: 0);
      if (response.status == ApiStatus.success) {
        final model = DepositCashModel.fromJson(response.data);
        _depositTransactions = model.data?.transactions ?? [];
      } else {
        // Handle error? For now just empty list
        _depositTransactions = [];
      }
    } catch (e) {
      _depositTransactions = [];
    } finally {
      _isDepositLoading = false;
      notifyListeners();
    }
  }

  void setFilter(int index) {
    if (_selectedFilterIndex == index) return;

    _selectedFilterIndex = index;
    _transactions = []; // Clear current list while loading
    notifyListeners();

    int? isSettled;
    if (index == 1) {
      isSettled = 0; // Not Settled
    } else if (index == 2) {
      isSettled = 1; // Settled
    }
    // index 0 -> isSettled = null (Total)

    fetchHandCash(isSettled: isSettled);
  }

  void toggleTransactionSelection(int id) {
    if (_selectedTransactionIds.contains(id)) {
      _selectedTransactionIds.remove(id);
    } else {
      _selectedTransactionIds.add(id);
    }
    notifyListeners();
  }

  void toggleAllNotSettled(bool select) {
    if (select) {
      // Select from depositTransactions
      _selectedTransactionIds = _depositTransactions.map((t) => t.id!).toList();
    } else {
      _selectedTransactionIds.clear();
    }
    notifyListeners();
  }

  bool isAllNotSettledSelected() {
    if (_depositTransactions.isEmpty) return false;
    return _selectedTransactionIds.length == _depositTransactions.length;
  }

  double get selectedAmount {
    // Calculate based on depositTransactions
    return _depositTransactions
        .where((t) => _selectedTransactionIds.contains(t.id))
        .fold(0.0, (sum, t) => sum + t.adminCash);
  }

  // Helper to load not settled transactions for the bottom sheet
  Future<void> prepareForDeposit() async {
    _selectedTransactionIds.clear();
    // Fetch specifically for deposit, independent of main view
    await fetchDepositTransactions();
  }

  // ─── PAYTM PAYMENT FLOW ────────────────────────────────────────────

  bool _isPaymentProcessing = false;
  bool get isPaymentProcessing => _isPaymentProcessing;

  String? _paymentError;
  String? get paymentError => _paymentError;

  bool _paymentSuccess = false;
  bool get paymentSuccess => _paymentSuccess;

  /// Orchestrates the full Paytm payment flow:
  /// 1. Fetch Paytm config
  /// 2. Generate transaction token
  /// 3. Launch Paytm SDK
  /// 4. Settle hand cash on success
  /// 5. Reload transactions
  Future<void> processPayment() async {
    if (_selectedTransactionIds.isEmpty || selectedAmount <= 0) {
      _paymentError = 'Please select transactions to pay';
      notifyListeners();
      return;
    }

    _isPaymentProcessing = true;
    _paymentError = null;
    _paymentSuccess = false;
    notifyListeners();

    try {
      // Step 1: Get Paytm config
      final configResponse = await _repo.getPaytmConfig();
      if (configResponse.status != ApiStatus.success ||
          configResponse.data == null) {
        _paymentError = 'Failed to load payment configuration';
        return;
      }

      final configData = configResponse.data['data'];
      if (configData == null) {
        _paymentError = 'Invalid payment configuration';
        return;
      }

      final String merchantId = configData['merchant_id']?.toString() ?? '';
      final String environment = configData['environment']?.toString() ?? 'test';
      final String configCallbackUrl =
          configData['callback_url']?.toString() ?? '';

      // Step 2: Generate transaction token
      final tokenResponse =
          await _repo.generatePaytmToken(selectedAmount);
      if (tokenResponse.status != ApiStatus.success ||
          tokenResponse.data == null) {
        _paymentError = 'Failed to generate payment token';
        return;
      }

      final tokenData = tokenResponse.data['data'];
      if (tokenData == null) {
        _paymentError = 'Invalid payment token response';
        return;
      }

      final String txnToken = tokenData['txn_token']?.toString() ?? '';
      final String orderId = tokenData['order_id']?.toString() ?? '';
      final String amount = tokenData['amount']?.toString() ?? '';

      if (txnToken.isEmpty || orderId.isEmpty) {
        _paymentError = 'Invalid transaction token or order ID';
        return;
      }

      // Step 3: Launch Paytm SDK
      final bool isStaging = environment.toLowerCase() == 'test';
      final String callbackUrl = isStaging
          ? 'https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId'
          : (configCallbackUrl.isNotEmpty  ? configCallbackUrl : 'https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId');

      final sdkResponse = await PaytmPaymentsAllinonesdk().startTransaction(
        merchantId,
        orderId,
        amount,
        txnToken,
        callbackUrl,
        isStaging,
        true, // restrictAppInvoke — forces in-app WebView
      );
      
      if (sdkResponse == null) {
        _paymentError = 'Payment is Cancelled';
        return;
      }

      final String txnStatus = sdkResponse['STATUS']?.toString() ?? '';
      final String respCode = sdkResponse['RESPCODE']?.toString() ?? '';
      final String respMsg = sdkResponse['RESPMSG']?.toString() ?? '';

      if (txnStatus != 'TXN_SUCCESS') {
        final bool isCancelled = respCode == '141' ||
            respMsg.toLowerCase().contains('cancel') ||
            txnStatus.isEmpty;
        _paymentError = isCancelled ? 'Payment is Cancelled' : (respMsg.isNotEmpty ? respMsg : 'Payment failed');
        return;
      }

      // Step 4: Settle hand cash
      final settleResponse = await _repo.settleHandCash(
        transactionIds: _selectedTransactionIds,
        paymentTransactionId: orderId,
      );

      if (settleResponse.status != ApiStatus.success) {
        _paymentError =
            settleResponse.message ?? 'Settlement failed';
        return;
      }

      final settleData = settleResponse.data;
      if (settleData != null &&
          (settleData['success'] == 0 || settleData['success'] == '0')) {
        _paymentError =
            settleData['message']?.toString() ?? 'Settlement verification failed';
        return;
      }

      // Step 5: Success — clear selections & reload
      _paymentSuccess = true;
      _selectedTransactionIds.clear();
      await fetchHandCash();
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      final bool isCancelled = errStr.contains('cancel') ||
          errStr.contains('not completed') ||
          errStr.contains('respcode: 141') ||
          errStr.contains('user has not');
      _paymentError = isCancelled ? 'Payment is Cancelled' : e.toString();
    } finally {
      _isPaymentProcessing = false;
      notifyListeners();
    }
  }

  void clearPaymentState() {
    _paymentError = null;
    _paymentSuccess = false;
    notifyListeners();
  }
}
