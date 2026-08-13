import 'package:project/helper/utils/generalImports.dart';


class WalletRechargeProvider extends ChangeNotifier {
  String message = "";

  bool isPaymentUnderProcessing = false;

  //Place order variables
  String placedOrderId = "";
  String razorpayOrderId = "";
  String transactionId = "";
  String payStackReference = "";

  String paytmTxnToken = "";
  String paytmOrderId = "";
  String paytmAmount = "";
  PaytmConfigData? paytmConfig;

  Future setWalletPaymentProcessState(bool value) async {
    isPaymentUnderProcessing = value;
    notifyListeners();
  }

  /// Step 1: Fetch Paytm config + generate txn token for wallet top-up
  Future<bool> initiateWalletPaytmTransactionNew({
    required BuildContext context,
    required String rechargeAmount,
  }) async {
    try {
      debugPrint('💳 [Wallet-Paytm] Initiating wallet Paytm transaction...');

      // Step 1a: Fetch Paytm config
      Map<String, dynamic> configResponse =
          await getPaytmConfigApi(context: context);

      if (configResponse['status'] != true &&
          configResponse['status'].toString() != "1") {
        showMessage(
          context,
          configResponse['message']?.toString() ??
              'Failed to fetch Paytm config',
          MessageType.warning,
        );
        setWalletPaymentProcessState(false);
        return false;
      }

      paytmConfig = PaytmConfigData.fromJson(configResponse['data']);
      debugPrint(
          '💳 [Wallet-Paytm] Config loaded - merchantId: ${paytmConfig?.merchantId}');

      // Step 1b: Get transaction token
      Map<String, String> params = {};
      params[ApiAndParams.type] = ApiAndParams.walletType;
      params[ApiAndParams.walletAmount] = rechargeAmount;

      Map<String, dynamic> txnTokenResponse =
          await getPaytmTransactionTokenApi(
              context: context, params: params);

      debugPrint('💳 [Wallet-Paytm] txn_token response: $txnTokenResponse');

      if (txnTokenResponse['error'] == false ||
          txnTokenResponse['error'] == null) {
        final data = txnTokenResponse['data'];
        paytmTxnToken = data['txn_token']?.toString() ?? "";
        paytmOrderId = data['order_id']?.toString() ?? "";
        paytmAmount = data['amount']?.toString() ?? rechargeAmount;

        debugPrint('💳 [Wallet-Paytm] txnToken: $paytmTxnToken');
        debugPrint('💳 [Wallet-Paytm] orderId: $paytmOrderId');
        debugPrint('💳 [Wallet-Paytm] amount: $paytmAmount');

        notifyListeners();
        return true;
      } else {
        showMessage(
          context,
          txnTokenResponse['message']?.toString() ??
              'Could not generate transaction token. Try again!',
          MessageType.warning,
        );
        setWalletPaymentProcessState(false);
        return false;
      }
    } catch (e) {
      debugPrint('❌ [Wallet-Paytm] initiateTransaction exception: $e');
      message = e.toString();
      showMessage(context, message, MessageType.warning);
      setWalletPaymentProcessState(false);
      return false;
    }
  }

  /// Step 3: Verify Paytm payment with backend
  Future<bool> verifyWalletPaytmPayment({
    required BuildContext context,
    required String paymentTransactionId,
  }) async {
    try {
      debugPrint('💳 [Wallet-Paytm] Verifying payment...');

      Map<String, dynamic> params = {
        'transaction_id': paymentTransactionId,
        'order_id': paytmOrderId,
        'type_of_payment': 'wallet_topup',
      };

      Map<String, dynamic> verifyResponse =
          await verifyPaytmPaymentApi(context: context, params: params);

      debugPrint('💳 [Wallet-Paytm] verify response: $verifyResponse');

      if (verifyResponse['status'] == true ||
          verifyResponse['status'].toString() == "true") {
        debugPrint('💳 [Wallet-Paytm] Payment VERIFIED');
        return true;
      } else {
        String errorMsg = verifyResponse['message']?.toString() ??
            'Payment verification failed';
        showMessage(context, errorMsg, MessageType.warning);
        return false;
      }
    } catch (e) {
      debugPrint('❌ [Wallet-Paytm] verifyPayment exception: $e');
      showMessage(
        context,
        'Failed to verify payment. Please contact support.',
        MessageType.warning,
      );
      return false;
    }
  }

  /// Step 4: Credit wallet balance via backend
  Future<bool> creditWalletBalance({
    required BuildContext context,
    required String amount,
    required String paymentTransactionId,
  }) async {
    try {
      debugPrint('💳 [Wallet-Paytm] Crediting wallet balance...');

      Map<String, dynamic> params = {
        'type': 'credit',
        'amount': amount,
        'payment_method': 'paytm',
        'transaction_id': paymentTransactionId,
      };

      Map<String, dynamic> response =
          await addWalletBalanceApi(context: context, params: params);

      debugPrint('💳 [Wallet-Paytm] credit response: $response');

      if (response[ApiAndParams.status].toString() == "1") {
        // Update wallet balance from API response
        if (response[ApiAndParams.data] != null &&
            response[ApiAndParams.data][ApiAndParams.userBalance] != null) {
          Constant.session.setData(
            SessionManager.keyWalletBalance,
            response[ApiAndParams.data][ApiAndParams.userBalance].toString(),
            true,
          );
        }

        debugPrint('💳 [Wallet-Paytm] Wallet credited successfully!');
        isPaymentUnderProcessing = false;
        notifyListeners();
        return true;
      } else {
        showMessage(
          context,
          response[ApiAndParams.message]?.toString() ??
              'Failed to credit wallet',
          MessageType.warning,
        );
        isPaymentUnderProcessing = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ [Wallet-Paytm] creditWalletBalance exception: $e');
      message = e.toString();
      showMessage(context, message, MessageType.warning);
      isPaymentUnderProcessing = false;
      notifyListeners();
      return false;
    }
  }

  Future initiateWalletRazorpayTransaction(
      {required BuildContext context, required String rechargeAmount}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      params[ApiAndParams.walletAmount] = rechargeAmount;
      params[ApiAndParams.type] = ApiAndParams.walletType;

      Map<String, dynamic> getInitiatedTransactionResponse =
          (await getInitiatedTransactionApi(context: context, params: params));

      if (getInitiatedTransactionResponse[ApiAndParams.status].toString() ==
          "1") {
        InitiateTransaction initiateTransaction =
            InitiateTransaction.fromJson(getInitiatedTransactionResponse);
        razorpayOrderId = initiateTransaction.data.transactionId;
        notifyListeners();
      } else {
        showMessage(
          context,
          getInitiatedTransactionResponse["message"],
          MessageType.warning,
        );
        notifyListeners();
      }
      return getInitiatedTransactionResponse;
    } catch (e) {
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      notifyListeners();
    }
  }

  Future initiateWalletPaypalTransaction(
      {required BuildContext context, required String rechargeAmount}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      params[ApiAndParams.walletAmount] = rechargeAmount;
      params[ApiAndParams.type] = ApiAndParams.walletType;

      Map<String, dynamic> getInitiatedTransactionResponse =
          await getInitiatedTransactionApi(context: context, params: params);

      if (getInitiatedTransactionResponse[ApiAndParams.status].toString() ==
          "1") {
        Map<String, dynamic> data =
            getInitiatedTransactionResponse[ApiAndParams.data];
        Navigator.pushNamed(context, paypalPaymentScreen,
                arguments: data["paypal_redirect_url"])
            .then((value) async {
          if (value == "success" || value == "pending") {
            await getUserDetail(context: context).then(
              (value) {
                if (value[ApiAndParams.status].toString() == "1") {
                  context
                      .read<UserProfileProvider>()
                      .updateUserDataInSession(value, context);
                }
              },
            );
            if (value == "pending") {
              showMessage(
                  context,
                  getTranslatedValue(
                      context, walletPaypalPendingLabel),
                  MessageType.warning);
            }
            Navigator.pop(context);
            return true;
          } else if (value == "fail") {
            showMessage(
              context,
              getTranslatedValue(context, paymentCancelledByUserLabel),
              MessageType.warning,
            );
            return false;
          }
        });
        notifyListeners();
      } else {
        showMessage(
          context,
          message,
          MessageType.warning,
        );
        notifyListeners();
        return false;
      }
    } catch (e) {
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      notifyListeners();
      return false;
    }
  }

  Future initiateWalletMidtransTransaction(
      {required BuildContext context, required String rechargeAmount}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      params[ApiAndParams.walletAmount] = rechargeAmount;
      params[ApiAndParams.type] = ApiAndParams.walletType;

      Map<String, dynamic> getInitiatedTransactionResponse =
          await getInitiatedTransactionApi(context: context, params: params);

      if (getInitiatedTransactionResponse[ApiAndParams.status].toString() ==
          "1") {
        Map<String, dynamic> data =
            getInitiatedTransactionResponse[ApiAndParams.data];

        if (data.containsKey("snapUrl") && data["snapUrl"].toString() != "") {
          Navigator.pushNamed(context, midtransPaymentScreen,
                  arguments: data["snapUrl"])
              .then((status_code) async {
            if (status_code is String) {
              if (status_code == "200" || status_code == "201") {
                await getUserDetail(context: context).then(
                  (value) {
                    if (value[ApiAndParams.status].toString() == "1") {
                      context
                          .read<UserProfileProvider>()
                          .updateUserDataInSession(value, context);
                    }
                  },
                );
                if (status_code == "201") {
                  showMessage(
                      context,
                      getTranslatedValue(
                          context, walletMidtransPendingLabel),
                      MessageType.warning);
                }
                notifyListeners();
                Navigator.pop(context, true);
              } else if (status_code == "202") {
                showMessage(
                  context,
                  getTranslatedValue(context, paymentCancelledByUserLabel),
                  MessageType.warning,
                );
                notifyListeners();
                Navigator.pop(context, false);
              }
            }
          });
        }
      } else {
        showMessage(
          context,
          message,
          MessageType.warning,
        );
        notifyListeners();
        Navigator.pop(context, false);
      }
    } catch (e) {
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      notifyListeners();
      Navigator.pop(context, false);
    }
  }

  Future orderStatusPhonePe({required BuildContext context, required String transactionId, required String token}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.transactionId] = transactionId.toString();
      params[ApiAndParams.token] = token;

      Map<String, dynamic> getOrderStatusPhonePeResponse = await getOrderStatusPhonepeApi(context: context, params: params);

      if (getOrderStatusPhonePeResponse[ApiAndParams.status].toString() == "1") {
        if (getOrderStatusPhonePeResponse[ApiAndParams.data][ApiAndParams.status] == "SUCCESS" ||
            getOrderStatusPhonePeResponse[ApiAndParams.data][ApiAndParams.status] == "COMPLETED") {
              Navigator.pop(context, true);
          notifyListeners();
        } else if (getOrderStatusPhonePeResponse[ApiAndParams.data][ApiAndParams.status] == "FAILED") {
          Navigator.pop(context, true);
          notifyListeners();
          showMessage(
            context,
            getTranslatedValue(context, orderPhonePeErrorLabel),
            MessageType.warning,
          );
        } else if (getOrderStatusPhonePeResponse[ApiAndParams.data][ApiAndParams.status] == "PAYMENT_ERROR") {
          Navigator.pop(context, true);
          notifyListeners();
          showMessage(
            context,
            getTranslatedValue(context, orderPhonePeErrorLabel),
            MessageType.warning,
          );
        } else if (getOrderStatusPhonePeResponse[ApiAndParams.data][ApiAndParams.status] == "PAYMENT_DECLINED") {
          Navigator.pop(context, true);
          notifyListeners();
          showMessage(
            context,
            getTranslatedValue(context, orderPhonePeDeclinedLabel),
            MessageType.warning,
          );
        } else if (getOrderStatusPhonePeResponse[ApiAndParams.data][ApiAndParams.status] == "PAYMENT_CANCELLED") {
          Navigator.pop(context, true);
          notifyListeners();
          showMessage(
            context,
            getTranslatedValue(context, orderPhonePeCancelledLabel),
            MessageType.warning,
          );
        }
      } else {
        Navigator.pop(context, true);
        showMessage(
          context,
          getOrderStatusPhonePeResponse[ApiAndParams.message].toString(),
          MessageType.warning,
        );
        notifyListeners();
      }
    } catch (e) {
      Navigator.pop(context, true);
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      notifyListeners();
    }
  }

  Future initiateWalletPhonePeTransaction(
      {required BuildContext context, required String rechargeAmount}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      params[ApiAndParams.walletAmount] = rechargeAmount;
      params[ApiAndParams.type] = ApiAndParams.walletType;

      Map<String, dynamic> getInitiatedTransactionResponse =
          await getInitiatedTransactionApi(context: context, params: params);

      if (getInitiatedTransactionResponse[ApiAndParams.status].toString() ==
          "1") {
        Map<String, dynamic> data =
            getInitiatedTransactionResponse[ApiAndParams.data];

        if (data.containsKey("redirectUrl") &&
            data["redirectUrl"].toString() != "") {
          Navigator.pushNamed(context, phonePePaymentScreen,
                  arguments: data["redirectUrl"])
              .then((status_code) async {
            if (status_code is String) {
              if (status_code == "SUCCESS" ||
                  status_code == "PENDING") {
                await getUserDetail(context: context).then(
                  (value) {
                    if (value[ApiAndParams.status].toString() == "1") {
                      context
                          .read<UserProfileProvider>()
                          .updateUserDataInSession(value, context);
                    }
                  },
                );
                if (status_code == "PENDING") {
                  showMessage(
                      context,
                      getTranslatedValue(
                          context, orderPhonePePendingLabel),
                      MessageType.warning);
                  Navigator.pop(context, true);
                } else if (status_code == "SUCCESS") {
                  orderStatusPhonePe(context: context, transactionId: data['merchantOrderId'], token: data['token']);
                  // Navigator.pop(context, true);
                }
              } else if (status_code == "FAILED") {
                Navigator.pop(context, false);
                showMessage(
                  context,
                  getTranslatedValue(context, orderPhonePeErrorLabel),
                  MessageType.warning,
                );
                return false;
              } else if (status_code == "ERROR") {
                Navigator.pop(context, false);
                showMessage(
                  context,
                  getTranslatedValue(context, orderPhonePeErrorLabel),
                  MessageType.warning,
                );
                return false;
              } else if (status_code == "DECLINED") {
                Navigator.pop(context, false);
                showMessage(
                  context,
                  getTranslatedValue(context, orderPhonePeDeclinedLabel),
                  MessageType.warning,
                );
                return false;
              } else if (status_code == "CANCELLED") {
                Navigator.pop(context, false);
                showMessage(
                  context,
                  getTranslatedValue(
                      context, orderPhonePeCancelledLabel),
                  MessageType.warning,
                );
                return false;
              }
            }
          });
        }
      } else {
        showMessage(
          context,
          message,
          MessageType.warning,
        );
        notifyListeners();
        Navigator.pop(context, false);
      }
    } catch (e) {
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      notifyListeners();
      Navigator.pop(context, false);
    }
  }

  Future initiateWalletCashfreeTransaction(
      {required BuildContext context, required String rechargeAmount}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      params[ApiAndParams.walletAmount] = rechargeAmount;
      params[ApiAndParams.type] = ApiAndParams.walletType;

      Map<String, dynamic> getInitiatedTransactionResponse =
          await getInitiatedTransactionApi(context: context, params: params);

      if (getInitiatedTransactionResponse[ApiAndParams.status].toString() ==
          "1") {
        Map<String, dynamic> data =
            getInitiatedTransactionResponse[ApiAndParams.data];

        if (data.containsKey("redirectUrl") &&
            data["redirectUrl"].toString() != "") {
          Navigator.pushNamed(context, cashfreePaymentScreen,
                  arguments: data["redirectUrl"])
              .then((status_code) async {
            if (status_code is String) {
              if (status_code == "success" || status_code == "pending") {
                await getUserDetail(context: context).then(
                  (value) {
                    if (value[ApiAndParams.status].toString() == "1") {
                      context
                          .read<UserProfileProvider>()
                          .updateUserDataInSession(value, context);
                    }
                  },
                );
                if (status_code == "pending") {
                  showMessage(
                      context,
                      getTranslatedValue(
                          context, walletCashfreeConfirmedLabel),
                      MessageType.warning);
                  Navigator.pop(context, true);
                } else if (status_code == "success") {
                  Navigator.pop(context, true);
                }
              } else if (status_code == "failed") {
                Navigator.pop(context, false);
                showMessage(
                  context,
                  getTranslatedValue(context, walletCashfreeErrorLabel),
                  MessageType.warning,
                );
                return false;
              } else if (status_code == "user_dropped") {
                Navigator.pop(context, false);
                showMessage(
                  context,
                  getTranslatedValue(
                      context, walletCashfreeCancelledLabel),
                  MessageType.warning,
                );
                return false;
              }
            }
          });
        }
      } else {
        showMessage(
          context,
          message,
          MessageType.warning,
        );
        notifyListeners();
        Navigator.pop(context, false);
      }
    } catch (e) {
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      notifyListeners();
      Navigator.pop(context, false);
    }
  }

  Future initiateWalletPaytabsTransaction(
      {required BuildContext context, required String rechargeAmount}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      params[ApiAndParams.walletAmount] = rechargeAmount;
      params[ApiAndParams.type] = ApiAndParams.walletType;

      Map<String, dynamic> getInitiatedTransactionResponse =
          await getInitiatedTransactionApi(context: context, params: params);

      if (getInitiatedTransactionResponse[ApiAndParams.status].toString() ==
          "1") {
        Map<String, dynamic> data =
            getInitiatedTransactionResponse[ApiAndParams.data];

        if (data.containsKey("redirectUrl") &&
            data["redirectUrl"].toString() != "") {
          Navigator.pushNamed(context, cashfreePaymentScreen,
                  arguments: data["redirectUrl"])
              .then((status_code) async {
            if (status_code is String) {
              if (status_code == "success" || status_code == "pending") {
                await getUserDetail(context: context).then(
                  (value) {
                    if (value[ApiAndParams.status].toString() == "1") {
                      context
                          .read<UserProfileProvider>()
                          .updateUserDataInSession(value, context);
                    }
                  },
                );
                if (status_code == "pending") {
                  showMessage(
                      context,
                      getTranslatedValue(
                          context, walletCashfreeConfirmedLabel),
                      MessageType.warning);
                  Navigator.pop(context, true);
                } else if (status_code == "success") {
                  Navigator.pop(context, true);
                }
              } else if (status_code == "failed") {
                Navigator.pop(context, false);
                showMessage(
                  context,
                  getTranslatedValue(context, walletCashfreeErrorLabel),
                  MessageType.warning,
                );
                return false;
              } else if (status_code == "user_dropped") {
                Navigator.pop(context, false);
                showMessage(
                  context,
                  getTranslatedValue(
                      context, walletCashfreeCancelledLabel),
                  MessageType.warning,
                );
                return false;
              }
            }
          });
        }
      } else {
        showMessage(
          context,
          message,
          MessageType.warning,
        );
        notifyListeners();
        Navigator.pop(context, false);
      }
    } catch (e) {
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      notifyListeners();
      Navigator.pop(context, false);
    }
  }

  Future addWalletTransaction(
      {required BuildContext context,
      required String walletRechargeAmount}) async {
    try {
      PackageInfo packageInfo;
      packageInfo = await PackageInfo.fromPlatform();

      Map<String, String> params = {};

      params[ApiAndParams.walletAmount] = walletRechargeAmount;
      params[ApiAndParams.deviceType] =
          setFirstLetterUppercase(Platform.operatingSystem);
      params[ApiAndParams.appVersion] = packageInfo.version;
      params[ApiAndParams.transactionId] = transactionId;
      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      params[ApiAndParams.type] = ApiAndParams.walletType;

      Map<String, dynamic> addedTransaction =
          (await getAddTransactionApi(context: context, params: params));
      if (addedTransaction[ApiAndParams.status].toString() == "1") {
        Map<String, dynamic> transactionData =
            addedTransaction[ApiAndParams.data];

        Constant.session.setData(SessionManager.keyWalletBalance,
            transactionData[ApiAndParams.userBalance].toString(), true);

        isPaymentUnderProcessing = false;
        notifyListeners();
        Navigator.pop(context, true);
      } else {
        showMessage(
          context,
          addedTransaction[ApiAndParams.message],
          MessageType.warning,
        );
        isPaymentUnderProcessing = false;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      isPaymentUnderProcessing = false;
      notifyListeners();
    }
  }
}
