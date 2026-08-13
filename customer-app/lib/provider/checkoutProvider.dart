import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/additionalCharges.dart';
import 'package:project/helper/phonepe_sdk_helper.dart';

enum CheckoutTimeSlotsState {
  timeSlotsLoading,
  timeSlotsLoaded,
  timeSlotsError,
}

enum CheckoutAddressState {
  addressLoading,
  addressLoaded,
  addressBlank,
  addressError,
}

enum CheckoutDeliveryChargeState {
  deliveryChargeLoading,
  deliveryChargeLoaded,
  deliveryChargeError,
}

enum CheckoutPlaceOrderState {
  placeOrderLoading,
  placeOrderLoaded,
  placeOrderError,
}

class CheckoutProvider extends ChangeNotifier {
  CheckoutAddressState checkoutAddressState =
      CheckoutAddressState.addressLoading;

  CheckoutDeliveryChargeState checkoutDeliveryChargeState =
      CheckoutDeliveryChargeState.deliveryChargeLoading;

  CheckoutTimeSlotsState checkoutTimeSlotsState =
      CheckoutTimeSlotsState.timeSlotsLoading;

  CheckoutPlaceOrderState checkoutPlaceOrderState =
      CheckoutPlaceOrderState.placeOrderLoading;

  String message = '';
  bool isPaymentUnderProcessing = false;

  /// True from the moment the Paytm SDK is launched until its result (success,
  /// failure or cancel) comes back. The SDK often never answers when the user
  /// presses back inside the gateway, which used to leave checkout locked
  /// behind the "processing payment" overlay with no way back or forward.
  bool awaitingPaytmResult = false;

  /// Last resort so the processing overlay can never trap the screen forever.
  Timer? _paymentWatchdog;
  static const Duration _paymentWatchdogTimeout = Duration(minutes: 5);

  /// Transaction currently being (or already) turned into an order. Stops a
  /// late SDK callback and the resume-recovery from placing the order twice.
  String _paytmOrderPlacementFor = "";

  //UserAddress variables
  UserAddressData? selectedAddress = UserAddressData();

  // Order Delivery charge variables
  bool? usedWallet;
  double walletUsedAmount = 0.0;
  double availableWalletAmount = 0.0;
  double subTotalAmount = 0.0;
  double totalAmount = 0.0;
  double savedAmount = 0.0;
  double deliveryCharge = 0.0;
  List<SellersInfo>? sellerWiseDeliveryCharges;
  DeliveryChargeData? deliveryChargeData;
  List<AdditionalCharges>? additionalCharges;

  //Timeslots variables
  TimeSlotsData? timeSlotsData;
  bool isTimeSlotsEnabled = true;
  int selectedDateId = 0;
  String? selectedDate = null;
  int selectedTime = 0;
  int initiallySelectedIndex = -1;
  int totalVisibleTimeSlots = 0;

  //Place order variables
  String placedOrderId = "";
  bool isPreOrderPlaced = false;
  String razorpayOrderId = "";
  String transactionId = "";
  String payStackReference = "";

  String paytmTxnToken = "";
  String paytmOrderId = "";
  String paytmAmount = "";
  PaytmConfigData? paytmConfig;
  //store pickup
  SellerSelfPickup? sellerSelfPickup;
  String? selfPickupMode;
  String? selectedOrderType = "0";

  TextEditingController edtOrderNote = TextEditingController();

  Future addOrResetTimeSlots(bool isReset) async {
    if (isReset) {
      totalVisibleTimeSlots = 0;
    } else {
      totalVisibleTimeSlots = totalVisibleTimeSlots + 1;
    }
  }

  int getTotalVisibleTimeSlots() {
    return totalVisibleTimeSlots;
  }

  Future setPaymentProcessState(bool value) async {
    isPaymentUnderProcessing = value;
    _paymentWatchdog?.cancel();
    if (value) {
      _paymentWatchdog = Timer(_paymentWatchdogTimeout, () {
        // Nothing reported back in time — release the UI instead of leaving
        // the user stuck on a screen they can neither leave nor act on.
        isPaymentUnderProcessing = false;
        awaitingPaytmResult = false;
        notifyListeners();
      });
    } else {
      _paymentWatchdog = null;
      awaitingPaytmResult = false;
    }
    notifyListeners();
  }

  /// Marks that the Paytm gateway is open and we are waiting on its callback.
  void setAwaitingPaytmResult(bool value) {
    awaitingPaytmResult = value;
  }

  /// Recovers from a Paytm SDK call that never reported back — typically the
  /// user pressed back inside the gateway. Asks the backend whether the
  /// transaction actually went through: if it did the order is placed as
  /// usual, otherwise checkout is unlocked so the user can retry.
  Future<void> resolveStuckPaytmPayment(BuildContext context) async {
    if (!isPaymentUnderProcessing || !awaitingPaytmResult) return;
    awaitingPaytmResult = false;

    if (paytmOrderId.isEmpty) {
      await setPaymentProcessState(false);
      return;
    }

    final bool paid = await verifyPaytmPayment(
      context: context,
      paymentTransactionId: paytmOrderId,
      silent: true,
    );

    if (!context.mounted) {
      await setPaymentProcessState(false);
      return;
    }

    if (paid) {
      await placeOrderWithPaytm(
        context: context,
        paymentTransactionId: paytmOrderId,
      );
    } else {
      await setPaymentProcessState(false);
    }
  }

  /// User-initiated abort of an in-flight payment (back button / cancel).
  /// Verifies with the backend first so a payment that actually succeeded is
  /// still turned into an order. Returns true when checkout is free again.
  Future<bool> cancelOngoingPayment(BuildContext context) async {
    if (awaitingPaytmResult) {
      await resolveStuckPaytmPayment(context);
    } else {
      await setPaymentProcessState(false);
    }
    return !isPaymentUnderProcessing;
  }

  @override
  void dispose() {
    _paymentWatchdog?.cancel();
    super.dispose();
  }

  Future userWalletAmount(bool used) async {
    usedWallet = used;
    if (used) {
      if (availableWalletAmount >= totalAmount) {
        walletUsedAmount = totalAmount;
        availableWalletAmount = availableWalletAmount - totalAmount;
        totalAmount = 0.0;
      } else {
        walletUsedAmount = availableWalletAmount;
        totalAmount = totalAmount - walletUsedAmount;
        availableWalletAmount = 0.0;
      }
    } else {
      availableWalletAmount = walletUsedAmount + availableWalletAmount;
      totalAmount = totalAmount + walletUsedAmount;
      walletUsedAmount = 0.0;
    }
    notifyListeners();
  }

  Future<UserAddressData?> getSingleAddressProvider(
      {required BuildContext context}) async {
    try {
      Map<String, dynamic> getAddress = (await getAddressApi(
          context: context, params: {ApiAndParams.isDefault: "1"}));
      if (getAddress[ApiAndParams.status].toString() == "1") {
        UserAddress addressData = UserAddress.fromJson(getAddress);
        selectedAddress = addressData.data?[0];

        if (selectedAddress?.cityId?.toString() == "0") {
          isPaymentUnderProcessing = false;
        }
        checkoutAddressState = CheckoutAddressState.addressLoaded;
        notifyListeners();
        return selectedAddress;
      } else {
        checkoutAddressState = CheckoutAddressState.addressBlank;
        isPaymentUnderProcessing = false;
        notifyListeners();
        return selectedAddress;
      }
    } catch (e) {
      message = e.toString();
      checkoutAddressState = CheckoutAddressState.addressError;
      isPaymentUnderProcessing = false;
      notifyListeners();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      return selectedAddress;
    }
  }

  setSelectedAddress(BuildContext context, var address) async {
    selectedAddress = address;

    checkoutAddressState = CheckoutAddressState.addressLoaded;
    notifyListeners();

    Map<String, String> params = {
      ApiAndParams.cityId: selectedAddress!.cityId.toString(),
      ApiAndParams.latitude: selectedAddress!.latitude.toString(),
      ApiAndParams.longitude: selectedAddress!.longitude.toString(),
      ApiAndParams.isCheckout: "1"
    };
    if (Constant.isPromoCodeApplied) {
      params[ApiAndParams.promoCodeId] = Constant.selectedPromoCodeId;
    }

    if (selectedAddress!.cityId.toString() != "0") {
      await getOrderChargesProvider(
        context: context,
        params: params,
      );
    } else {
      isPaymentUnderProcessing = false;
      message = e.toString();
      checkoutDeliveryChargeState =
          CheckoutDeliveryChargeState.deliveryChargeError;
      checkoutAddressState = CheckoutAddressState.addressLoaded;
      notifyListeners();

      showMessage(
          context,
          getTranslatedValue(context, addressNotDeliverableSelectedLabel),
          MessageType.warning);
    }
  }

  /// Re-fetch order charges using the currently-selected address but with
  /// a specific payment method. Payment gateway fees only apply to online
  /// payments — backend strips them when payment_method=COD.
  Future<void> refreshChargesForPaymentMethod(
      BuildContext context, String paymentMethod) async {
    if (selectedAddress == null ||
        selectedAddress!.cityId.toString() == "0") {
      return;
    }

    Map<String, String> params = {
      ApiAndParams.cityId: selectedAddress!.cityId.toString(),
      ApiAndParams.latitude: selectedAddress!.latitude.toString(),
      ApiAndParams.longitude: selectedAddress!.longitude.toString(),
      ApiAndParams.isCheckout: "1",
      ApiAndParams.paymentMethod: paymentMethod,
    };
    if (Constant.isPromoCodeApplied) {
      params[ApiAndParams.promoCodeId] = Constant.selectedPromoCodeId;
    }

    await getOrderChargesProvider(context: context, params: params);
  }

  Future getOrderChargesProvider(
      {required BuildContext context,
      required Map<String, String> params}) async {
    try {
      checkoutDeliveryChargeState =
          CheckoutDeliveryChargeState.deliveryChargeLoading;
      notifyListeners();

      // Wallet is opt-in from the cart screen. Send the current selection
      // explicitly so the checkout total reflects the user's actual choice
      // and does NOT fall back to a stale saved cart-metadata flag (which
      // previously caused the wallet to be auto-applied at checkout).
      if (!params.containsKey('use_wallet')) {
        params['use_wallet'] =
            context.read<CartProvider>().useWallet ? '1' : '0';
      }

      Map<String, dynamic> getCheckoutData =
          (await getCartListApi(context: context, params: params));

      if (getCheckoutData[ApiAndParams.status].toString() == "1") {
        Checkout checkoutData = Checkout.fromJson(getCheckoutData);
        deliveryChargeData = checkoutData.data!;
        context.read<PaymentMethodsProvider>().isCodAllowed =
            deliveryChargeData?.codAllowed.toString() ?? "===";
        subTotalAmount = deliveryChargeData?.billingSummary?.itemsMrp;
        totalAmount = deliveryChargeData?.billingSummary?.toBePaid;
        deliveryCharge = deliveryChargeData?.billingSummary?.deliveryCharge;
        sellerWiseDeliveryCharges =
            deliveryChargeData?.deliveryCharge!.sellersInfo ?? [];
        additionalCharges = deliveryChargeData?.additionalCharges ?? [];
        selfPickupMode = deliveryChargeData!.selfPickupMode ?? "0";
        sellerSelfPickup = deliveryChargeData!.sellerSelfPickup;

        usedWallet = false;
        walletUsedAmount = 0.0;
        availableWalletAmount =
            double.parse(deliveryChargeData!.userBalance.toString());

        checkoutDeliveryChargeState =
            CheckoutDeliveryChargeState.deliveryChargeLoaded;
        checkoutAddressState = CheckoutAddressState.addressLoaded;
        notifyListeners();
      } else {
        checkoutDeliveryChargeState =
            CheckoutDeliveryChargeState.deliveryChargeError;
        checkoutAddressState = CheckoutAddressState.addressLoaded;
        isPaymentUnderProcessing = false;
        notifyListeners();
        showMessage(
          context,
          getTranslatedValue(context, getCheckoutData["message"]),
          MessageType.warning,
        );
      }
    } catch (e) {
      isPaymentUnderProcessing = false;
      message = e.toString();
      checkoutDeliveryChargeState =
          CheckoutDeliveryChargeState.deliveryChargeError;
      checkoutAddressState = CheckoutAddressState.addressLoaded;
      notifyListeners();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
    }
  }

  Future getTimeSlotsSettings({required BuildContext context}) async {
    try {
      Map<String, dynamic> getTimeSlotsSettings =
          (await getTimeSlotSettingsApi(context: context, params: {}));
      if (getTimeSlotsSettings[ApiAndParams.status].toString() == "1") {
        TimeSlotsSettings timeSlots =
            TimeSlotsSettings.fromJson(getTimeSlotsSettings);
        timeSlotsData = timeSlots.data;
        isTimeSlotsEnabled = timeSlots.data.timeSlotsIsEnabled == "true";

        selectedDateId = 0;
        selectedTime = 0;

        checkoutTimeSlotsState = CheckoutTimeSlotsState.timeSlotsLoaded;
        notifyListeners();
      } else {
        showMessage(
          context,
          getTimeSlotsSettings[ApiAndParams.message].toString(),
          MessageType.warning,
        );
        checkoutTimeSlotsState = CheckoutTimeSlotsState.timeSlotsError;
        notifyListeners();
      }
    } catch (e) {
      showMessage(
        context,
        getTranslatedValue(context, pleaseAddTimeslotInAdminPanelLabel),
        MessageType.warning,
      );
      checkoutTimeSlotsState = CheckoutTimeSlotsState.timeSlotsError;
      notifyListeners();
    }
  }

  setSelectedDate(int index) {
    selectedTime = 0;
    selectedDateId = index;
    if (int.parse(timeSlotsData?.estimateDeliveryDays.toString() ?? "0") > 1) {
      selectedTime = 0;
    }
    notifyListeners();
  }

  setOrderType(String orderType) {
    selectedOrderType = orderType;
    notifyListeners();
  }

  setSelectedTime(int index) {
    initiallySelectedIndex = index;
    selectedTime = index;
    notifyListeners();
  }

  setSelectedTimeWithoutNotify(int index) {
    initiallySelectedIndex = index;
    selectedTime = index;
  }

  void handlePaymentSuccess(
      BuildContext context, Map<dynamic, dynamic> response) {
    // Payment successful
    transactionId = response['paymentId'] ?? '';

    // Add transaction to backend
    addTransaction(context: context).then((_) {
      // Order placed successfully
      showOrderPlacedScreen(context);
    });
  }

  void handlePaymentError(
      BuildContext context, Map<dynamic, dynamic>? response) {
    // Payment failed or cancelled
    setPaymentProcessState(false);
    deleteAwaitingOrder(context); // Delete the awaiting order

    showMessage(
      context,
      response?["message"] ?? 'Payment failed. Please try again.',
      MessageType.error,
    );
  }

  Future placeOrder({required BuildContext context}) async {
    // if (timeSlotsData!.timeSlots.isNotEmpty) {
    try {
      isPaymentUnderProcessing = true;

      if (totalAmount == 0.0) {
        context.read<PaymentMethodsProvider>().selectedPaymentMethod = "Wallet";
      }

      final orderStatus = (context
                      .read<PaymentMethodsProvider>()
                      .selectedPaymentMethod ==
                  "COD" ||
              context.read<PaymentMethodsProvider>().selectedPaymentMethod ==
                  "Wallet")
          ? "2"
          : "1";

      Constant.session.setData(SessionManager.keyWalletBalance,
          availableWalletAmount.toString(), true);

      Map<String, String> params = {};
      params[ApiAndParams.productVariantId] =
          deliveryChargeData?.productVariantId.toString() ?? "0";
      params[ApiAndParams.quantity] =
          deliveryChargeData?.quantity.toString() ?? "0";
      params[ApiAndParams.total] =
          (deliveryChargeData?.subTotal.toString() ?? "0")
              .toDouble
              .toPrecision(2)
              .toString();
      if (selectedOrderType == "0") {
        params[ApiAndParams.deliveryCharge] =
            (deliveryChargeData?.deliveryCharge?.totalDeliveryCharge ?? "0")
                .toDouble
                .toPrecision(2)
                .toString();
      }
      params[ApiAndParams.finalTotal] =
          totalAmount.toString().toDouble.toPrecision(2).toString();
      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      if (usedWallet == true) {
        params[ApiAndParams.walletUsed] = "1";
        params[ApiAndParams.walletBalance] =
            walletUsedAmount.toString().toDouble.toPrecision(2).toString();
      }
      if (selectedOrderType == "0") {
        params[ApiAndParams.addressId] = selectedAddress!.id.toString();
      }
      if (edtOrderNote.text.isNotEmpty) {
        params[ApiAndParams.orderNote] = edtOrderNote.text;
      }
      if (selectedOrderType == "0") {
        if (isTimeSlotsEnabled) {
          params[ApiAndParams.deliveryTime] =
              "$selectedDate ${timeSlotsData?.timeSlots[selectedTime].title}";
        } else {
          params[ApiAndParams.deliveryTime] = "N/A";
        }
      }
      params[ApiAndParams.status] = orderStatus;
      if (Constant.isPromoCodeApplied) {
        params[ApiAndParams.promoCodeId] = Constant.selectedPromoCodeId;
      }
      params[ApiAndParams.orderDeliveryType] =
          selectedOrderType == "0" ? "doorstep" : "selfpickup";

      // Add custom combos data
      final cartProvider = context.read<CartProvider>();
      final customCombos = cartProvider.cartData?.data.customCombos ?? [];
      if (customCombos.isNotEmpty) {
        List<Map<String, dynamic>> combosData = [];
        for (var combo in customCombos) {
          combosData.add({
            'combo_custom_cart_id': combo.comboCustomCartId,
            'combo_id': combo.comboId,
          });
        }
        params['custom_combos'] = json.encode(combosData);
      }

      Map<String, dynamic> getPlaceOrderResponse =
          await getPlaceOrderApi(context: context, params: params);

      if (getPlaceOrderResponse[ApiAndParams.status].toString() == "1") {
        // Detect pre-order from API response
        isPreOrderPlaced =
            getPlaceOrderResponse['is_pre_order']?.toString() == '1';

        // Parse and set placedOrderId for all payment methods
        try {
          PlacedPrePaidOrder placedPrePaidOrder =
              PlacedPrePaidOrder.fromJson(getPlaceOrderResponse);
          placedOrderId = placedPrePaidOrder.data.orderId.toString();
        } catch (e) {
          // Fallback: try to extract order_id directly from response
          if (getPlaceOrderResponse.containsKey('order_id')) {
            placedOrderId = getPlaceOrderResponse['order_id'].toString();
          } else if (getPlaceOrderResponse['data'] != null &&
              getPlaceOrderResponse['data']['order_id'] != null) {
            placedOrderId =
                getPlaceOrderResponse['data']['order_id'].toString();
          }
          log('Error parsing PlacedPrePaidOrder: $e, placedOrderId: $placedOrderId');
        }

        // Update your placeOrder() method:

        if (context.read<PaymentMethodsProvider>().selectedPaymentMethod ==
            "Razorpay") {
          // Initialize Razorpay
          // initializeRazorpay();

          // Initiate transaction (this gets the order_id from your backend)
          // await initiateRazorpayTransaction(context: context).then((response) {
          //   if (response != null &&
          //       response[ApiAndParams.status].toString() == "1") {
          //     // Now open Razorpay payment UI
          //     openRazorpayCheckout(context: context);
          //   } else {
          //     // Failed to initiate transaction
          //     deleteAwaitingOrder(context);
          //     setPaymentProcessState(false);
          //     showMessage(
          //       context,
          //       'Failed to initiate payment',
          //       MessageType.error,
          //     );
          //   }
          // });
        } else if (context
                .read<PaymentMethodsProvider>()
                .selectedPaymentMethod ==
            "Stripe") {
          // Handle Stripe similarly
        } else if (context
                .read<PaymentMethodsProvider>()
                .selectedPaymentMethod ==
            "Paystack") {
          payStackReference =
              "Charged_From_${setFirstLetterUppercase(Platform.operatingSystem)}_${DateTime.now().millisecondsSinceEpoch}";
          transactionId = payStackReference;
        } else if (context
                    .read<PaymentMethodsProvider>()
                    .selectedPaymentMethod ==
                "COD" ||
            context.read<PaymentMethodsProvider>().selectedPaymentMethod ==
                "Wallet") {
          showOrderPlacedScreen(context);
        } else if (context
                .read<PaymentMethodsProvider>()
                .selectedPaymentMethod ==
            "Paypal") {
          initiatePaypalTransaction(context: context).then((value) {
            return value;
          });
        } else if (context
                .read<PaymentMethodsProvider>()
                .selectedPaymentMethod ==
            "Midtrans") {
          initiateMidtransTransaction(context: context).then((value) {
            return value;
          });
        } else if (context
                .read<PaymentMethodsProvider>()
                .selectedPaymentMethod ==
            "Phonepe") {
          // PhonePe/UPI now uses Paytm gateway from widget directly
          // This branch should NOT be reached - widget handles it via initiatePaytmTransaction
          debugPrint('⚠️ [PhonePe] placeOrder() called for Phonepe - this should not happen!');
          setPaymentProcessState(false);
        } else if (context
                .read<PaymentMethodsProvider>()
                .selectedPaymentMethod ==
            "Cashfree") {
          initiateCashfreeTransaction(context: context).then((value) {
            return value;
          });
        } else if (context
                .read<PaymentMethodsProvider>()
                .selectedPaymentMethod ==
            "Paytabs") {
          initiatePaytabsTransaction(context: context).then((value) {
            return value;
          });
        }

        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoaded;
        notifyListeners();
        return true;
      } else {
        showMessage(
          context,
          getPlaceOrderResponse[ApiAndParams.message],
          MessageType.warning,
        );
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
        isPaymentUnderProcessing = false;
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
      checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
      isPaymentUnderProcessing = false;
      notifyListeners();
      return false;
    }
    // } else {
    //   showMessage(
    //     context,
    //     getTranslatedValue(context, pleaseAddTimeslotInAdminPanelLabel),
    //     MessageType.warning,
    //   );
    //   checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
    //   isPaymentUnderProcessing = false;
    // }
    notifyListeners();

    return false;
  }

  /// Fetches Paytm config and transaction token (no order placed yet).
  /// Called BEFORE payment, not after placeOrder.
  Future<bool> initiatePaytmTransaction({required BuildContext context}) async {
    try {
      debugPrint('💳 [Paytm] initiatePaytmTransaction() called');
      debugPrint('💳 [Paytm] totalAmount: $totalAmount');

      // Step 1: Fetch Paytm config
      debugPrint('💳 [Paytm] Step 1: Fetching Paytm config...');
      Map<String, dynamic> configResponse =
          await getPaytmConfigApi(context: context);

      debugPrint('💳 [Paytm] Config response: $configResponse');

      if (configResponse['status'] != true &&
          configResponse['status'].toString() != "1") {
        debugPrint('❌ [Paytm] Config fetch failed: ${configResponse['message']}');
        showMessage(
          context,
          configResponse['message']?.toString() ??
              'Failed to fetch Paytm config',
          MessageType.warning,
        );
        setPaymentProcessState(false);
        notifyListeners();
        return false;
      }

      paytmConfig = PaytmConfigData.fromJson(configResponse['data']);
      debugPrint('💳 [Paytm] Config loaded - merchantId: ${paytmConfig?.merchantId}, isStaging: ${paytmConfig?.isStaging}');

      // Step 2: Get transaction token
      debugPrint('💳 [Paytm] Step 2: Getting transaction token...');
      Map<String, String> params = {};
      params[ApiAndParams.type] = "order";
      // Paytm requires the amount in canonical 2-decimal form ("191.00").
      // Backend signs the checksum from this string, and the gateway later
      // compares it to what the SDK submits — any drift triggers "session expired".
      params[ApiAndParams.amount] = totalAmount.toStringAsFixed(2);

      debugPrint('💳 [Paytm] txn_token params: $params');

      Map<String, dynamic> txnTokenResponse =
          await getPaytmTransactionTokenApi(
              context: context, params: params);

      debugPrint('💳 [Paytm] txn_token response: $txnTokenResponse');

      if (txnTokenResponse['error'] == false ||
          txnTokenResponse['error'] == null) {
        final data = txnTokenResponse['data'];
        paytmTxnToken = data['txn_token']?.toString() ?? "";
        paytmOrderId = data['order_id']?.toString() ?? "";
        final num? rawAmount = data['amount'] is num
            ? data['amount'] as num
            : num.tryParse(data['amount']?.toString() ?? '');
        paytmAmount = (rawAmount ?? totalAmount).toStringAsFixed(2);
        debugPrint('💳 [Paytm] txnToken: $paytmTxnToken');
        debugPrint('💳 [Paytm] orderId: $paytmOrderId');
        debugPrint('💳 [Paytm] amount from backend: $paytmAmount');
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ [Paytm] txn_token fetch failed: ${txnTokenResponse['message']}');
        showMessage(
          context,
          txnTokenResponse['message']?.toString() ??
              'Could not generate transaction token. Try again!',
          MessageType.warning,
        );
        setPaymentProcessState(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ [Paytm] initiatePaytmTransaction exception: $e');
      message = e.toString();
      showMessage(context, message, MessageType.warning);
      setPaymentProcessState(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPaytmPayment({
    required BuildContext context,
    required String paymentTransactionId,
    bool silent = false,
  }) async {
    try {
      debugPrint('💳 [Paytm] verifyPaytmPayment() called');
      debugPrint('💳 [Paytm] paymentTransactionId: $paymentTransactionId');

      Map<String, dynamic> params = {
        'transaction_id': paymentTransactionId,
        'order_id': paytmOrderId,
        'type_of_payment': 'order_placing',
      };

      debugPrint('💳 [Paytm] verify params: $params');

      Map<String, dynamic> verifyResponse =
          await verifyPaytmPaymentApi(context: context, params: params);

      debugPrint('💳 [Paytm] verify response: $verifyResponse');

      if (verifyResponse['status'] == true ||
          verifyResponse['status'].toString() == "true") {
        debugPrint('💳 [Paytm] Payment VERIFIED successfully');
        return true;
      } else {
        debugPrint('❌ [Paytm] Payment verification FAILED: ${verifyResponse['message']}');
        String errorMsg = verifyResponse['message']?.toString() ??
            'Payment verification failed';
        // Silent when we are only probing whether a cancelled/unanswered
        // attempt went through — a warning there would confuse the user.
        if (!silent) showMessage(context, errorMsg, MessageType.warning);
        return false;
      }
    } catch (e) {
      debugPrint('❌ [Paytm] verifyPaytmPayment exception: $e');
      if (!silent) {
        showMessage(
          context,
          'Failed to verify payment. Please contact support.',
          MessageType.warning,
        );
      }
      return false;
    }
  }

  /// Places order after Paytm payment is verified.
  /// IMPORTANT: This must ONLY be called after payment is paid AND verified.
  Future<bool> placeOrderWithPaytm({
    required BuildContext context,
    required String paymentTransactionId,
  }) async {
    try {
      debugPrint('💳 [Paytm] placeOrderWithPaytm() called');
      debugPrint('💳 [Paytm] paymentTransactionId: $paymentTransactionId');

      if (paymentTransactionId.isEmpty) {
        debugPrint('❌ [Paytm] BLOCKED: paymentTransactionId is empty! Payment not completed.');
        showMessage(context, 'Payment transaction ID missing. Cannot place order without payment.', MessageType.warning);
        setPaymentProcessState(false);
        return false;
      }
      if (_paytmOrderPlacementFor == paymentTransactionId) {
        debugPrint('💳 [Paytm] Order already in flight for $paymentTransactionId — ignoring duplicate call');
        return false;
      }
      _paytmOrderPlacementFor = paymentTransactionId;
      Constant.session.setData(SessionManager.keyWalletBalance,
          availableWalletAmount.toString(), true);

      Map<String, String> params = {};
      params[ApiAndParams.productVariantId] =
          deliveryChargeData?.productVariantId.toString() ?? "0";
      params[ApiAndParams.quantity] =
          deliveryChargeData?.quantity.toString() ?? "0";
      params[ApiAndParams.total] =
          (deliveryChargeData?.subTotal.toString() ?? "0")
              .toDouble
              .toPrecision(2)
              .toString();
      if (selectedOrderType == "0") {
        params[ApiAndParams.deliveryCharge] =
            (deliveryChargeData?.deliveryCharge?.totalDeliveryCharge ?? "0")
                .toDouble
                .toPrecision(2)
                .toString();
      }
      params[ApiAndParams.finalTotal] =
          totalAmount.toString().toDouble.toPrecision(2).toString();
      params[ApiAndParams.paymentMethod] = "paytm";
      params['transaction_id'] = paymentTransactionId;
      if (usedWallet == true) {
        params[ApiAndParams.walletUsed] = "1";
        params[ApiAndParams.walletBalance] =
            walletUsedAmount.toString().toDouble.toPrecision(2).toString();
      }
      if (selectedOrderType == "0") {
        params[ApiAndParams.addressId] = selectedAddress!.id.toString();
      }
      if (edtOrderNote.text.isNotEmpty) {
        params[ApiAndParams.orderNote] = edtOrderNote.text;
      }
      if (selectedOrderType == "0") {
        if (isTimeSlotsEnabled) {
          params[ApiAndParams.deliveryTime] =
              "$selectedDate ${timeSlotsData?.timeSlots[selectedTime].title}";
        } else {
          params[ApiAndParams.deliveryTime] = "N/A";
        }
      }
      params[ApiAndParams.status] = "1";
      if (Constant.isPromoCodeApplied) {
        params[ApiAndParams.promoCodeId] = Constant.selectedPromoCodeId;
      }
      params[ApiAndParams.orderDeliveryType] =
          selectedOrderType == "0" ? "doorstep" : "selfpickup";

      // Add custom combos data
      final cartProvider = context.read<CartProvider>();
      final customCombos = cartProvider.cartData?.data.customCombos ?? [];
      if (customCombos.isNotEmpty) {
        List<Map<String, dynamic>> combosData = [];
        for (var combo in customCombos) {
          combosData.add({
            'combo_custom_cart_id': combo.comboCustomCartId,
            'combo_id': combo.comboId,
          });
        }
        params['custom_combos'] = json.encode(combosData);
      }

      debugPrint('💳 [Paytm] placeOrderWithPaytm API params: $params');

      Map<String, dynamic> response =
          await placeOrderWithPaytmApi(context: context, params: params);

      debugPrint('💳 [Paytm] placeOrderWithPaytm response: $response');

      if (response[ApiAndParams.status].toString() == "1" ||
          response['error'] == false) {
        if (response['data'] != null && response['data']['order_id'] != null) {
          placedOrderId = response['data']['order_id'].toString();
        }
        isPreOrderPlaced =
            response['is_pre_order']?.toString() == '1';
        debugPrint('💳 [Paytm] Order placed successfully! orderId: $placedOrderId');
        showMessage(
          context,
          response['message']?.toString() ?? 'Order placed successfully',
          MessageType.success,
        );
        showOrderPlacedScreen(context);
        return true;
      } else {
        debugPrint('❌ [Paytm] Order placement failed: ${response['message']}');
        _paytmOrderPlacementFor = "";
        showMessage(
          context,
          response['message']?.toString() ?? 'Order placement failed',
          MessageType.warning,
        );
        setPaymentProcessState(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ [Paytm] placeOrderWithPaytm exception: $e');
      _paytmOrderPlacementFor = "";
      showMessage(context, e.toString(), MessageType.warning);
      setPaymentProcessState(false);
      notifyListeners();
      return false;
    }
  }

// Add these methods to your CheckoutProvider class:

  // late Razorpay _razorpay;

  // void initializeRazorpay() {
  //   _razorpay = Razorpay();
  //   _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
  //   _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  // }

  // void disposeRazorpay() {
  //   _razorpay.clear();
  // }

// // Open Razorpay checkout after getting order_id
  // Future<void> openRazorpayCheckout({
  //   required BuildContext context,
  // }) async {
  //   try {
  //     final paymentProvider = context.read<PaymentMethodsProvider>();

  //     var options = {
  //       'key': paymentProvider.paymentMethodsData?.razorpayKey ?? '',
  //       'amount':
  //           (totalAmount * 100).toInt(), // Amount in paise (multiply by 100)
  //       'order_id': razorpayOrderId, // This is "order_RmfNXc1HkT1Rd0"
  //       'name': Constant.appName ?? 'Your Store',
  //       'description': 'Order Payment #$placedOrderId',
  //       'timeout': 300, // 5 minutes in seconds
  //       'prefill': {
  //         'contact': selectedAddress?.mobile ??
  //             Constant.session.getData(SessionManager.keyPhone) ??
  //             '',
  //         'email': Constant.session.getData(SessionManager.keyEmail) ?? '',
  //         'name': selectedAddress?.name ??
  //             Constant.session.getData(SessionManager.keyUserName) ??
  //             '',
  //       },
  //       'theme': {
  //         'color': '#9AC444', // Your app color
  //       },
  //       // 'modal': {
  //       //   'ondismiss': () {
  //       //     debugPrint('Razorpay checkout dismissed');
  //       //   }
  //       // },
  //     };

  //     // If specific UPI app is selected, use UPI intent flow
  //     if (paymentProvider.selectedUpiApp.isNotEmpty) {
  //       options['method'] = 'upi';
  //       options['_[flow]'] = 'intent'; // Opens selected UPI app directly

  //       // Add specific UPI app
  //       String? upiAppIdentifier =
  //           _getUpiAppIdentifier(paymentProvider.selectedUpiApp);
  //       if (upiAppIdentifier != null) {
  //         options['_[app]'] = upiAppIdentifier;
  //       }

  //       debugPrint(
  //           'Opening Razorpay with UPI app: ${paymentProvider.selectedUpiApp}');
  //     } else {
  //       // Show all payment methods
  //       debugPrint('Opening Razorpay with all payment methods');
  //     }

  //     _razorpay.submit(options);
  //   } catch (e, stackTrace) {
  //     debugPrint('Error opening Razorpay: $e');
  //     log("Error in Razorpay ${e.toString()}");
  //     log("Error in Razorpay ${stackTrace.toString()}");
  //     setPaymentProcessState(false);
  //   }
  // }

  // // Map package names to Razorpay UPI app identifiers
  // String? _getUpiAppIdentifier(String packageName) {
  //   const Map<String, String> appIdentifiers = {
  //     'com.phonepe.app': 'phonepe',
  //     'com.google.android.apps.nbu.paisa.user': 'googlepay',
  //     'net.one97.paytm': 'paytm',
  //     'in.org.npci.upiapp': 'bhim',
  //     'com.dreamplug.androidapp': 'cred',
  //     'in.amazon.mShop.android.shopping': 'amazonpay',
  //   };

  //   return appIdentifiers[packageName];
  // }

  // // void _handlePaymentSuccess(Map<dynamic, dynamic> response) {
  //   debugPrint('✅ Payment Success!');
  //   debugPrint('Payment ID: ${response["paymentId"]}');
  //   debugPrint('Order ID: ${response["orderId"]}');
  //   debugPrint('Signature: ${response["signature"]}');

  //   // Save transaction ID
  //   transactionId = response["paymentId"] ?? '';

  //   // Add transaction to backend
  //   addTransaction(context: navigatorKey.currentContext!).then((_) {
  //     // Payment successful, order placed
  //     debugPrint('Transaction added successfully');
  //   }).catchError((error) {
  //     debugPrint('Error adding transaction: $error');
  //     // Still show success as payment was done
  //     showOrderPlacedScreen(navigatorKey.currentContext!);
  //   });
  // }

  // void _handlePaymentError(Map<dynamic, dynamic> response) {
  //   debugPrint('❌ Payment Failed!');
  //   debugPrint('Code: ${response}');
  //   debugPrint('Message: ${response["message"]}');

  //   isPaymentUnderProcessing = false;
  //   notifyListeners();

  //   // Delete awaiting order
  //   deleteAwaitingOrder(navigatorKey.currentContext!);

  //   // Stop payment processing state
  //   setPaymentProcessState(false);

  //   // Show error message
  //   String errorMessage = 'Payment failed. Please try again.';

  //   // Handle specific error codes
  //   switch (response['code']) {
  //     case 0: // User cancelled
  //       errorMessage = 'Payment cancelled by user';
  //       break;
  //     case 1: // Credential error
  //       errorMessage = 'Invalid payment credentials';
  //       break;
  //     case 2: // Network error
  //       errorMessage = 'Network error. Please check your connection';
  //       break;
  //     default:
  //       errorMessage = response['message'] ?? 'Payment failed';
  //   }

  //   showMessage(
  //     navigatorKey.currentContext!,
  //     errorMessage,
  //     MessageType.error,
  //   );
  // }

  // Future<Map<String, dynamic>> initiateRazorpayTransaction({
  //   required BuildContext context,
  // }) async {
  //   try {
  //     Map<String, String> params = {};

  //     params[ApiAndParams.paymentMethod] = context
  //         .read<PaymentMethodsProvider>()
  //         .selectedPaymentMethod
  //         .toString();
  //     params[ApiAndParams.orderId] = placedOrderId;
  //     params[ApiAndParams.type] = ApiAndParams.orderType;

  //     Map<String, dynamic> getInitiatedTransactionResponse =
  //         (await getInitiatedTransactionApi(context: context, params: params));

  //     if (getInitiatedTransactionResponse[ApiAndParams.status].toString() ==
  //         "1") {
  //       InitiateTransaction initiateTransaction =
  //           InitiateTransaction.fromJson(getInitiatedTransactionResponse);
  //       razorpayOrderId = initiateTransaction.data.transactionId;

  //       debugPrint('✅ Razorpay Order ID: $razorpayOrderId');

  //       checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoaded;
  //       notifyListeners();

  //       return getInitiatedTransactionResponse; // ✅ Return response
  //     } else {
  //       deleteAwaitingOrder(context);
  //       showMessage(
  //         context,
  //         getInitiatedTransactionResponse["message"] ??
  //             "Failed to initiate payment",
  //         MessageType.warning,
  //       );
  //       checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
  //       notifyListeners();

  //       return getInitiatedTransactionResponse; // ✅ Return response even on error
  //     }
  //   } catch (e, stackTrace) {
  //     deleteAwaitingOrder(context);
  //     message = e.toString();
  //     log("Error in Razorpay ${stackTrace}");
  //     showMessage(
  //       context,
  //       message,
  //       MessageType.warning,
  //     );
  //     checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
  //     isPaymentUnderProcessing = false;
  //     notifyListeners();

  //     return {
  //       "status": "0",
  //       "message": e.toString()
  //     }; // ✅ Return error response
  //   }
  // }

  showOrderPlacedScreen(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
    Navigator.pushNamed(context, orderPlaceScreen, arguments: {
      'orderId': placedOrderId,
      'isPreOrder': isPreOrderPlaced,
    });
  }

  Future initiatePhonePeTransaction({required BuildContext context}) async {
    try {
      debugPrint("📱 [PhonePe] initiatePhonePeTransaction() called");
      debugPrint("📱 [PhonePe] placedOrderId: $placedOrderId");
      Map<String, String> params = {};

      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      params[ApiAndParams.orderId] = placedOrderId;
      params[ApiAndParams.type] = ApiAndParams.orderType;

      debugPrint("📱 [PhonePe] API params: $params");

      Map<String, dynamic> getInitiatedTransactionResponse =
          await getInitiatedTransactionApi(context: context, params: params);

      debugPrint("📱 [PhonePe] API response: $getInitiatedTransactionResponse");

      if (getInitiatedTransactionResponse[ApiAndParams.status].toString() ==
          "1") {
        Map<String, dynamic> data =
            getInitiatedTransactionResponse[ApiAndParams.data];

        // Use WebView as fallback if redirectUrl is provided
        // if (data.containsKey("redirectUrl") &&
        //     data["redirectUrl"].toString() != "") {
        //   Navigator.pushNamed(context, phonePePaymentScreen,
        //           arguments: data["redirectUrl"])
        //       .then((status_code) {
        //     if (status_code is String) {
        //       print("status_code:--${status_code}");
        //       if (status_code == "SUCCESS" || status_code == "PENDING") {
        //         if (status_code == "PENDING") {
        //           showMessage(
        //               context,
        //               getTranslatedValue(context, orderPhonePePendingLabel),
        //               MessageType.warning);
        //           showOrderPlacedScreen(context);
        //         } else if (status_code == "SUCCESS") {
        //           orderStatusPhonePe(
        //               context: context,
        //               transactionId: data['merchantOrderId'],
        //               token: data['token']);
        //         }
        //       } else if (status_code == "PAYMENT_ERROR") {
        //         deleteAwaitingOrder(context);
        //         showMessage(
        //           context,
        //           getTranslatedValue(context, orderPhonePeErrorLabel),
        //           MessageType.warning,
        //         );
        //         return false;
        //       } else if (status_code == "FAILED") {
        //         orderStatusPhonePe(
        //             context: context,
        //             transactionId: data['merchantOrderId'],
        //             token: data['token']);
        //         return false;
        //       } else if (status_code == "PAYMENT_DECLINED") {
        //         deleteAwaitingOrder(context);
        //         showMessage(
        //           context,
        //           getTranslatedValue(context, orderPhonePeDeclinedLabel),
        //           MessageType.warning,
        //         );
        //         return false;
        //       } else if (status_code == "PAYMENT_CANCELLED") {
        //         deleteAwaitingOrder(context);
        //         showMessage(
        //           context,
        //           getTranslatedValue(context, orderPhonePeCancelledLabel),
        //           MessageType.warning,
        //         );
        //         return false;
        //       }
        //     }
        //   });
        // } else {
        // Use token + orderId if available (SDK v3.0.2)
        if (data.containsKey("token") && data.containsKey("merchantOrderId")) {
          debugPrint('📱 [PhonePe] Token received: ${data['token']}');
          debugPrint('📱 [PhonePe] merchantOrderId: ${data['merchantOrderId']}');
          debugPrint('📱 [PhonePe] Attempting PhonePe SDK payment...');

          await _initiatePhonePeSDKPayment(
            context: context,
            orderId: data['merchantOrderId'],
            token: data['token'],
          );
        } else if (data.containsKey("redirectUrl")) {
          // Fallback to redirect if SDK fails or no token
          debugPrint('📱 [PhonePe] No token in response, using redirect URL: ${data['redirectUrl']}');
          Navigator.pushNamed(context, phonePePaymentScreen,
                  arguments: data["redirectUrl"])
              .then((status_code) {
            if (status_code is String) {
              if (status_code == "SUCCESS" || status_code == "PENDING") {
                if (status_code == "PENDING") {
                  showMessage(
                      context,
                      getTranslatedValue(context, orderPhonePePendingLabel),
                      MessageType.warning);
                  showOrderPlacedScreen(context);
                } else if (status_code == "SUCCESS") {
                  orderStatusPhonePe(
                      context: context,
                      transactionId: data['merchantOrderId'],
                      token: data['token'] ?? '');
                }
              } else if (status_code == "PAYMENT_ERROR" ||
                  status_code == "FAILED") {
                deleteAwaitingOrder(context);
                showMessage(
                    context,
                    getTranslatedValue(context, orderPhonePeErrorLabel),
                    MessageType.warning);
              }
            }
          });
        }
        // }
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoaded;
        notifyListeners();
      } else {
        debugPrint('❌ [PhonePe] initiateTransaction API status != 1: ${getInitiatedTransactionResponse[ApiAndParams.message]}');
        deleteAwaitingOrder(context);
        setPaymentProcessState(false);
        showMessage(
          context,
          getInitiatedTransactionResponse[ApiAndParams.message] ??
              "Failed to initiate payment",
          MessageType.warning,
        );
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ [PhonePe] initiatePhonePeTransaction exception: $e');
      deleteAwaitingOrder(context);
      setPaymentProcessState(false);
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
      notifyListeners();
    }
  }

  Future<void> _initiatePhonePeSDKPayment({
    required BuildContext context,
    required String orderId,
    required String token,
  }) async {
    try {
      debugPrint("📱 [PhonePe] _initiatePhonePeSDKPayment() called");
      debugPrint("📱 [PhonePe] orderId: $orderId, token: $token");

      // Get merchant info from payment methods provider
      final paymentProvider = context.read<PaymentMethodsProvider>();

      // Get merchant ID from backend payment settings (CRITICAL: Backend must provide this)
      String merchantId =
          paymentProvider.paymentMethodsData?.phonePeMerchantId ?? '';

      if (merchantId.isEmpty) {
        debugPrint('❌ [PhonePe] ERROR: PhonePe Merchant ID not configured!');
        debugPrint('❌ [PhonePe] Backend must return "phonePeMerchantId" in payment settings API response');
        showMessage(
          context,
          'Payment configuration error: PhonePe merchant ID not found. Please contact support.',
          MessageType.error,
        );
        deleteAwaitingOrder(context);
        setPaymentProcessState(false);
        return;
      }

      debugPrint('📱 [PhonePe] Using Merchant ID: $merchantId');

      // Get client ID from backend payment settings (for SDK initialization)
      String? clientId = paymentProvider.paymentMethodsData?.phonePeClientId;
      debugPrint('📱 [PhonePe] Client ID: $clientId');

      // Get selected UPI app if any
      final selectedUpiAppPackage =
          paymentProvider.selectedPhonePeUpiApp.isNotEmpty
              ? paymentProvider.selectedPhonePeUpiApp
              : null;

      debugPrint('📱 [PhonePe] Selected UPI app: $selectedUpiAppPackage');

      // Initialize SDK with merchant ID and client ID
      debugPrint('📱 [PhonePe] Initializing SDK...');
      bool sdkInitResult = await PhonePeSdkHelper.initPhonePeSDK(merchantId: merchantId, flowId: '');
      debugPrint('📱 [PhonePe] SDK init result: $sdkInitResult');

      if (!sdkInitResult) {
        debugPrint('❌ [PhonePe] SDK initialization failed!');
        showMessage(
          context,
          'PhonePe SDK initialization failed. Please try again.',
          MessageType.error,
        );
        deleteAwaitingOrder(context);
        setPaymentProcessState(false);
        return;
      }

      // Create SDK request JSON
      final sdkRequest = PhonePeSdkHelper.createSDKRequest(
        orderId: orderId,
        merchantId: merchantId,
        token: token,
      );

      debugPrint('📱 [PhonePe] SDK Request: $sdkRequest');

      // Start transaction with callback
      debugPrint('📱 [PhonePe] Starting SDK transaction...');
      await PhonePeSdkHelper.startTransaction(
        body: sdkRequest,
        checksum: "",
        merchantId: merchantId,
        appSchema: "zenfoo",
        packageName: selectedUpiAppPackage,
        callback: (Map<String, dynamic> response) {
          debugPrint('📱 [PhonePe] SDK transaction response: $response');
          _handlePhonePeSDKResponse(context, response, orderId, token);
        },
      );
    } catch (e) {
      debugPrint('❌ [PhonePe] SDK Payment Error: $e');
      showMessage(
        context,
        'Payment failed: ${e.toString()}',
        MessageType.error,
      );
      deleteAwaitingOrder(context);
      setPaymentProcessState(false);
    }
  }

  void _handlePhonePeSDKResponse(
    BuildContext context,
    Map<String, dynamic> response,
    String transactionId,
    String token,
  ) {
    debugPrint('📱 [PhonePe] _handlePhonePeSDKResponse() called');
    debugPrint('📱 [PhonePe] Response: $response');
    debugPrint('📱 [PhonePe] TransactionId: $transactionId, Token: $token');

    if (response['status'] == 'SUCCESS') {
      debugPrint('📱 [PhonePe] Payment SUCCESS - checking order status...');
      orderStatusPhonePe(
        context: context,
        transactionId: transactionId,
        token: token,
      );
    } else if (response['status'] == 'FAILED') {
      debugPrint('❌ [PhonePe] Payment FAILED: ${response['error'] ?? 'No error details'}');
      deleteAwaitingOrder(context);
      setPaymentProcessState(false);
      showMessage(
        context,
        response['error']?.toString() ?? getTranslatedValue(context, orderPhonePeErrorLabel),
        MessageType.warning,
      );
    } else {
      debugPrint('❌ [PhonePe] Payment cancelled or unknown status: ${response['status']}');
      deleteAwaitingOrder(context);
      setPaymentProcessState(false);
      showMessage(
        context,
        'Payment cancelled',
        MessageType.warning,
      );
    }
  }

  Future orderStatusPhonePe(
      {required BuildContext context,
      required String transactionId,
      required String token}) async {
    try {
      debugPrint('📱 [PhonePe] orderStatusPhonePe() called');
      debugPrint('📱 [PhonePe] transactionId: $transactionId, token: $token');
      Map<String, String> params = {};

      params[ApiAndParams.transactionId] = transactionId.toString();
      params[ApiAndParams.token] = token;

      Map<String, dynamic> getOrderStatusPhonePeResponse =
          await getOrderStatusPhonepeApi(context: context, params: params);

      debugPrint('📱 [PhonePe] orderStatus response: $getOrderStatusPhonePeResponse');

      if (getOrderStatusPhonePeResponse[ApiAndParams.status].toString() ==
          "1") {
        final dataStatus = getOrderStatusPhonePeResponse[ApiAndParams.data]
                [ApiAndParams.status];
        debugPrint('📱 [PhonePe] orderStatus data.status: $dataStatus');

        if (dataStatus == "SUCCESS" || dataStatus == "COMPLETED") {
          debugPrint('📱 [PhonePe] Order status SUCCESS/COMPLETED - showing order placed screen');
          showOrderPlacedScreen(context);
          checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoaded;
          notifyListeners();
        } else if (dataStatus == "FAILED") {
          debugPrint('❌ [PhonePe] Order status FAILED');
          deleteAwaitingOrder(context);
          setPaymentProcessState(false);
          showMessage(
            context,
            getTranslatedValue(context, orderPhonePeErrorLabel),
            MessageType.warning,
          );
        } else if (dataStatus == "PAYMENT_ERROR") {
          debugPrint('❌ [PhonePe] Order status PAYMENT_ERROR');
          deleteAwaitingOrder(context);
          setPaymentProcessState(false);
          showMessage(
            context,
            getTranslatedValue(context, orderPhonePeErrorLabel),
            MessageType.warning,
          );
        } else if (dataStatus == "PAYMENT_DECLINED") {
          debugPrint('❌ [PhonePe] Order status PAYMENT_DECLINED');
          deleteAwaitingOrder(context);
          setPaymentProcessState(false);
          showMessage(
            context,
            getTranslatedValue(context, orderPhonePeDeclinedLabel),
            MessageType.warning,
          );
        } else if (dataStatus == "PAYMENT_CANCELLED") {
          debugPrint('❌ [PhonePe] Order status PAYMENT_CANCELLED');
          deleteAwaitingOrder(context);
          setPaymentProcessState(false);
          showMessage(
            context,
            getTranslatedValue(context, orderPhonePeCancelledLabel),
            MessageType.warning,
          );
        } else {
          debugPrint('❌ [PhonePe] Order status UNKNOWN: $dataStatus');
          deleteAwaitingOrder(context);
          setPaymentProcessState(false);
        }
      } else {
        debugPrint('❌ [PhonePe] orderStatus API returned status != 1: ${getOrderStatusPhonePeResponse[ApiAndParams.message]}');
        deleteAwaitingOrder(context);
        setPaymentProcessState(false);
        showMessage(
          context,
          getOrderStatusPhonePeResponse[ApiAndParams.message].toString(),
          MessageType.warning,
        );
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ [PhonePe] orderStatusPhonePe exception: $e');
      deleteAwaitingOrder(context);
      setPaymentProcessState(false);
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
      notifyListeners();
    }
  }

  Future initiatePaypalTransaction({required BuildContext context}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      params[ApiAndParams.orderId] = placedOrderId;
      params[ApiAndParams.type] = ApiAndParams.orderType;

      Map<String, dynamic> getInitiatedTransactionResponse =
          await getInitiatedTransactionApi(context: context, params: params);

      if (getInitiatedTransactionResponse[ApiAndParams.status].toString() ==
          "1") {
        Map<String, dynamic> data =
            getInitiatedTransactionResponse[ApiAndParams.data];
        Navigator.pushNamed(context, paypalPaymentScreen,
                arguments: data["paypal_redirect_url"])
            .then((value) {
          if (value == "success" || value == "pending") {
            if (value == "pending") {
              showMessage(
                  context,
                  getTranslatedValue(context, orderPaypalPendingLabel),
                  MessageType.warning);
            }
            showOrderPlacedScreen(context);
          } else if (value == "fail") {
            deleteAwaitingOrder(context);
            showMessage(
              context,
              getTranslatedValue(context, paymentCancelledByUserLabel),
              MessageType.warning,
            );
            return false;
          }
        });
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoaded;
        notifyListeners();
      } else {
        deleteAwaitingOrder(context);
        showMessage(
          context,
          message,
          MessageType.warning,
        );
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
        notifyListeners();
      }
    } catch (e) {
      deleteAwaitingOrder(context);
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
      notifyListeners();
    }
  }

  Future initiateMidtransTransaction({required BuildContext context}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      params[ApiAndParams.orderId] = placedOrderId;
      params[ApiAndParams.type] = ApiAndParams.orderType;

      Map<String, dynamic> getInitiatedTransactionResponse =
          await getInitiatedTransactionApi(context: context, params: params);

      if (getInitiatedTransactionResponse[ApiAndParams.status].toString() ==
          "1") {
        Map<String, dynamic> data =
            getInitiatedTransactionResponse[ApiAndParams.data];

        if (data.containsKey("snapUrl") && data["snapUrl"].toString() != "") {
          Navigator.pushNamed(context, midtransPaymentScreen,
                  arguments: data["snapUrl"])
              .then((status_code) {
            if (status_code is String) {
              if (status_code == "200" || status_code == "201") {
                if (status_code == "201") {
                  showMessage(
                      context,
                      getTranslatedValue(context, orderMidtransPendingLabel),
                      MessageType.warning);
                  showOrderPlacedScreen(context);
                } else if (status_code == "200") {
                  showOrderPlacedScreen(context);
                }
              } else if (status_code == "202") {
                deleteAwaitingOrder(context);
                showMessage(
                  context,
                  getTranslatedValue(context, paymentCancelledByUserLabel),
                  MessageType.warning,
                );
                return false;
              }
            }
          });
        }
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoaded;
        notifyListeners();
      }
    } catch (e) {
      deleteAwaitingOrder(context);
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
      notifyListeners();
    }
  }

  Future initiateCashfreeTransaction({required BuildContext context}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      params[ApiAndParams.orderId] = placedOrderId;
      params[ApiAndParams.type] = ApiAndParams.orderType;

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
              .then((status_code) {
            if (status_code is String) {
              if (status_code == "success" || status_code == "pending") {
                if (status_code == "pending") {
                  showMessage(
                      context,
                      getTranslatedValue(context, orderCashfreePendingLabel),
                      MessageType.warning);
                  showOrderPlacedScreen(context);
                } else if (status_code == "success") {
                  showOrderPlacedScreen(context);
                }
              } else if (status_code == "failed") {
                deleteAwaitingOrder(context);
                showMessage(
                  context,
                  getTranslatedValue(context, orderCashfreeErrorLabel),
                  MessageType.warning,
                );
                return false;
              } else if (status_code == "user_dropped") {
                deleteAwaitingOrder(context);
                showMessage(
                  context,
                  getTranslatedValue(context, orderCashfreeCancelledLabel),
                  MessageType.warning,
                );
                return false;
              }
            }
          });
        }
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoaded;
        notifyListeners();
      }
    } catch (e) {
      deleteAwaitingOrder(context);
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
      notifyListeners();
    }
  }

  Future initiatePaytabsTransaction({required BuildContext context}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      params[ApiAndParams.orderId] = placedOrderId;
      params[ApiAndParams.type] = ApiAndParams.orderType;

      Map<String, dynamic> getInitiatedTransactionResponse =
          await getInitiatedTransactionApi(context: context, params: params);

      if (getInitiatedTransactionResponse[ApiAndParams.status].toString() ==
          "1") {
        Map<String, dynamic> data =
            getInitiatedTransactionResponse[ApiAndParams.data];

        if (data.containsKey("redirectUrl") &&
            data["redirectUrl"].toString() != "") {
          Navigator.pushNamed(context, paytabsPaymentScreen,
                  arguments: data["redirectUrl"])
              .then((status) {
            if (status is String) {
              if (status == "success" || status == "pending") {
                if (status == "pending") {
                  showMessage(
                      context,
                      getTranslatedValue(context, orderMidtransPendingLabel),
                      MessageType.warning);
                  showOrderPlacedScreen(context);
                } else if (status == "success") {
                  showOrderPlacedScreen(context);
                }
              } else if (status == "cancelled") {
                deleteAwaitingOrder(context);
                showMessage(
                  context,
                  getTranslatedValue(context, paymentCancelledByUserLabel),
                  MessageType.warning,
                );
                return false;
              }
            }
          });
        }
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoaded;
        notifyListeners();
      }
    } catch (e) {
      deleteAwaitingOrder(context);
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
      notifyListeners();
    }
  }

  Future addTransaction({required BuildContext context}) async {
    try {
      PackageInfo packageInfo;
      packageInfo = await PackageInfo.fromPlatform();

      Map<String, String> params = {};

      params[ApiAndParams.orderId] = placedOrderId;
      params[ApiAndParams.deviceType] =
          setFirstLetterUppercase(Platform.operatingSystem);
      params[ApiAndParams.appVersion] = packageInfo.version;
      params[ApiAndParams.transactionId] = transactionId;
      params[ApiAndParams.paymentMethod] = context
          .read<PaymentMethodsProvider>()
          .selectedPaymentMethod
          .toString();
      params[ApiAndParams.type] = ApiAndParams.orderType;

      Map<String, dynamic> addedTransaction =
          (await getAddTransactionApi(context: context, params: params));
      if (addedTransaction[ApiAndParams.status].toString() == "1") {
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoaded;
        notifyListeners();
        showOrderPlacedScreen(context);
      } else {
        showMessage(
          context,
          addedTransaction[ApiAndParams.message],
          MessageType.warning,
        );
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
      notifyListeners();
    }
  }

  Future deleteAwaitingOrder(BuildContext context) async {
    try {
      await deleteAwaitingOrderApi(
          params: {ApiAndParams.orderId: placedOrderId}, context: context);
      setPaymentProcessState(false);
    } catch (e) {
      showMessage(context, e.toString(), MessageType.error);
    }
  }
}
