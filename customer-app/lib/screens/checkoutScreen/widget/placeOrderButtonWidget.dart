import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/storeHoursService.dart';
import 'package:project/screens/cartListScreen/widgets/admin_store_closed_dialog.dart';

class PlaceOrderButtonWidget extends StatefulWidget {
  final BuildContext context;
  final String? selectedMethod;

  const PlaceOrderButtonWidget(
      {Key? key, required this.context, this.selectedMethod})
      : super(key: key);

  @override
  State<PlaceOrderButtonWidget> createState() => PlaceOrderButtonWidgetState();
}

class PlaceOrderButtonWidgetState extends State<PlaceOrderButtonWidget> {
  // final Razorpay _razorpay = Razorpay();
  late String razorpayKey = "";
  late String paystackKey = "";
  late double amount = 0.00;
  late PaystackPlugin paystackPlugin;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((value) async {
      paystackPlugin = PaystackPlugin();

      // _razorpay.on(
      //     Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorPayPaymentSuccess);
      // _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorPayPaymentError);
      // _razorpay.on(
      //     Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorPayExternalWallet);
    });
  }

  // void _handleRazorPayPaymentSuccess(Map<dynamic, dynamic> response) {
  //   debugPrint('✅ Payment Success!');
  //   debugPrint('Payment ID: ${response['paymentId']}');
  //   debugPrint('Order ID: ${response['orderId']}');
  //   debugPrint('Signature: ${response['signature']}');

  //   // Save transaction ID
  //   context.read<CheckoutProvider>().transactionId =
  //       response['paymentId'].toString();

  //   // Add transaction to backend
  //   context.read<CheckoutProvider>().addTransaction(context: context).then((_) {
  //     debugPrint('✅ Transaction added successfully');
  //   }).catchError((error) {
  //     debugPrint('❌ Error adding transaction: $error');
  //     // Still proceed to order placed screen as payment was successful
  //     context.read<CheckoutProvider>().showOrderPlacedScreen(context);
  //   });
  // }

  // void _handleRazorPayPaymentError(Map<dynamic, dynamic> response) {
  //   debugPrint('❌ Payment Failed!');
  //   debugPrint('Code: ${response}');

  //   debugPrint('Message: ${response['message']}');

  //   // Delete awaiting order
  //   context.read<CheckoutProvider>().deleteAwaitingOrder(context);

  //   // Stop payment processing
  //   context.read<CheckoutProvider>().setPaymentProcessState(false);

  //   // Determine error message
  //   String errorMessage = 'Payment failed. Please try again.';

  //   switch (response['code']) {
  //     case 0: // BAD_REQUEST_ERROR
  //       errorMessage = response['message'] ?? 'Invalid payment request';
  //       break;
  //     case 1: // SERVER_ERROR
  //       errorMessage = 'Payment server error. Please try again';
  //       break;
  //     case 2: // NETWORK_ERROR
  //       errorMessage = 'Network error. Please check your connection';
  //       break;
  //     default:
  //       errorMessage = response['message'] ?? 'Payment failed';
  //   }

  //   showMessage(context, errorMessage, MessageType.warning);
  // }

  // void openRazorPayGateway() async {
  //   final selectedUpiApp =
  //       context.read<PaymentMethodsProvider>().selectedUpiApp;

  //   var options = {
  //     'key': razorpayKey,
  //     'email': '${Constant.session.getData(SessionManager.keyPhone)}@gmail.com',
  //     'order_id': context.read<CheckoutProvider>().razorpayOrderId,
  //     'amount': (amount * 100).toInt(),
  //     'currency': 'INR',
  //     'contact': Constant.session
  //         .getData(SessionManager.keyPhone, defaultValue: '+919999999999'),
  //   };

  //   // ✅ If specific UPI app is selected, use direct intent flow
  //   if (selectedUpiApp.isNotEmpty) {
  //     options['method'] = 'upi';
  //     options['_[flow]'] = 'intent'; // Opens UPI app directly

  //     // Map package name to Razorpay identifier
  //     String? upiAppIdentifier = _getUpiAppIdentifier(selectedUpiApp);
  //     if (upiAppIdentifier != null) {
  //       options['upi_app_package_name'] = selectedUpiApp;
  //     }

  //     debugPrint('🚀 Opening Razorpay with UPI app: $selectedUpiApp');
  //   } else {
  //     // Show all payment methods if no UPI app selected
  //     debugPrint('🚀 Opening Razorpay with all payment methods');
  //   }

  //   try {
  //     log('Set options: ${options.toString()}');

  //     _razorpay.submit(options); // Changed from submit() to open()
  //   } catch (e) {
  //     debugPrint('❌ Error opening Razorpay: $e');
  //     context.read<CheckoutProvider>().deleteAwaitingOrder(context);
  //     context.read<CheckoutProvider>().setPaymentProcessState(false);
  //     showMessage(context, 'Failed to open payment: $e', MessageType.error);
  //   }
  // }

// // Helper method to map package names to Razorpay UPI identifiers
  // String? _getUpiAppIdentifier(String packageName) {
  //   const Map<String, String> appIdentifiers = {
  //     'com.phonepe.app': 'phonepe',
  //     'com.google.android.apps.nbu.paisa.user': 'googlepay',
  //     'net.one97.paytm': 'paytm',
  //     'in.org.npci.upiapp': 'bhim',
  //     'com.dreamplug.androidapp': 'cred',
  //     'in.amazon.mShop.android.shopping': 'amazonpay',
  //     'com.whatsapp': 'whatsapp',
  //     'com.freecharge.android': 'freecharge',
  //     'com.mobikwik_new': 'mobikwik',
  //   };

  //   return appIdentifiers[packageName];
  // }

  // Using package flutter_paystack
  Future openPaystackPaymentGateway() async {
    await paystackPlugin.initialize(
        publicKey: context
                .read<PaymentMethodsProvider>()
                .paymentMethodsData
                ?.paystackPublicKey ??
            "0");

    Charge charge = Charge()
      ..amount = (context.read<CheckoutProvider>().totalAmount * 100).toInt()
      ..currency = context
              .read<PaymentMethodsProvider>()
              .paymentMethodsData
              ?.paystackCurrencyCode ??
          ""
      ..reference = context.read<CheckoutProvider>().payStackReference
      ..email = Constant.session.getData(SessionManager.keyEmail);

    CheckoutResponse response = await paystackPlugin.checkout(
      context,
      fullscreen: false,
      logo: defaultImg(
        height: 50,
        width: 50,
        image: AppAssets.logoIcon,
        requiredRTL: false,
      ),
      method: CheckoutMethod.card,
      charge: charge,
    );

    if (response.status) {
      context.read<CheckoutProvider>().addTransaction(context: context);
    } else {
      context.read<CheckoutProvider>().deleteAwaitingOrder(context);
      context.read<CheckoutProvider>().setPaymentProcessState(false);
    }
  }

  openPaytmPaymentGateway({bool restrictAppInvoke = true}) async {
    final checkoutProvider = context.read<CheckoutProvider>();
    final paytmConfig = checkoutProvider.paytmConfig;

    // Use the exact amount from backend (same as used to generate txnToken)
    final String sdkAmount = checkoutProvider.paytmAmount.isNotEmpty
        ? checkoutProvider.paytmAmount
        : checkoutProvider.totalAmount.toString();

    debugPrint('💳 [Paytm] openPaytmPaymentGateway() called');
    debugPrint('💳 [Paytm] ====== SDK PARAMS ======');
    debugPrint('💳 [Paytm] merchantId: ${paytmConfig?.merchantId}');
    debugPrint('💳 [Paytm] orderId: ${checkoutProvider.paytmOrderId}');
    debugPrint('💳 [Paytm] amount (from backend): $sdkAmount');
    debugPrint('💳 [Paytm] amount (local): ${checkoutProvider.totalAmount}');
    debugPrint('💳 [Paytm] txnToken: ${checkoutProvider.paytmTxnToken}');
    debugPrint('💳 [Paytm] callbackUrl: ${paytmConfig?.callbackUrl}');
    debugPrint('💳 [Paytm] isStaging: ${paytmConfig?.isStaging}');
    debugPrint('💳 [Paytm] environment: ${paytmConfig?.environment}');
    debugPrint('💳 [Paytm] =======================');

    if (paytmConfig == null || paytmConfig.merchantId == null) {
      debugPrint('❌ [Paytm] Config not loaded! Cannot open gateway.');
      showMessage(
          context, 'Paytm configuration not loaded', MessageType.warning);
      checkoutProvider.setPaymentProcessState(false);
      return;
    }

    try {
      // Build callback URL: for staging use Paytm's official URL, for production use backend's URL
      final String callbackUrl = paytmConfig.isStaging
          ? "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=${checkoutProvider.paytmOrderId}"
          : (paytmConfig.callbackUrl ?? "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=${checkoutProvider.paytmOrderId}");

      debugPrint('💳 [Paytm] Launching Paytm SDK...');
      debugPrint('💳 [Paytm] SDK callbackUrl: $callbackUrl');
      debugPrint('💳 [Paytm] SDK amount: $sdkAmount');
      debugPrint('💳 [Paytm] restrictAppInvoke: $restrictAppInvoke');
      // Gateway takes over from here; the checkout screen recovers on resume
      // if the SDK never calls back (e.g. user pressed back inside it).
      checkoutProvider.setAwaitingPaytmResult(true);

      var response = PaytmPaymentsAllinonesdk().startTransaction(
        paytmConfig.merchantId!,
        checkoutProvider.paytmOrderId,
        sdkAmount,
        checkoutProvider.paytmTxnToken,
        callbackUrl,
        paytmConfig.isStaging,
        restrictAppInvoke,
      );

      response.then((value) async {
        debugPrint('💳 [Paytm] ====== SDK RESPONSE ======');
        debugPrint('💳 [Paytm] Full response: $value');
        checkoutProvider.setAwaitingPaytmResult(false);
        if (value != null) {
          // Log all fields from SDK response
          value.forEach((key, val) {
            debugPrint('💳 [Paytm] $key: $val');
          });

          String status = value['STATUS']?.toString() ?? '';
          String txnId = value['TXNID']?.toString() ?? '';

          debugPrint('💳 [Paytm] STATUS: $status, TXNID: $txnId');

          if (status == 'TXN_SUCCESS' && txnId.isNotEmpty) {
            debugPrint('💳 [Paytm] Payment SUCCESS - Step 1: Verifying payment...');
            debugPrint('💳 [Paytm] TXNID: $txnId');
            debugPrint('💳 [Paytm] ORDER_ID (sending as transaction_id): ${checkoutProvider.paytmOrderId}');
            // Step 1: Verify with backend — transaction_id = merchant ORDER_ID (backend uses it to check Paytm status)
            bool verified = await checkoutProvider.verifyPaytmPayment(
              context: context,
              paymentTransactionId: checkoutProvider.paytmOrderId,
            );

            if (verified) {
              debugPrint('💳 [Paytm] Payment VERIFIED - Step 2: Placing order...');
              // Step 2: Place order ONLY after payment is paid AND verified
              await checkoutProvider.placeOrderWithPaytm(
                context: context,
                paymentTransactionId: checkoutProvider.paytmOrderId,
              );
            } else {
              debugPrint('❌ [Paytm] Payment verification FAILED - NOT placing order');
              checkoutProvider.setPaymentProcessState(false);
            }
          } else {
            debugPrint('❌ [Paytm] Payment NOT successful - STATUS: $status, RESPMSG: ${value['RESPMSG']}');
            debugPrint('❌ [Paytm] NOT calling place_order_with_paytm');
            checkoutProvider.setPaymentProcessState(false);
            showMessage(
              context,
              value['RESPMSG']?.toString() ??
                  'Payment failed. Please try again.',
              MessageType.warning,
            );
          }
        } else {
          debugPrint('❌ [Paytm] SDK returned null - Payment cancelled');
          debugPrint('❌ [Paytm] NOT calling place_order_with_paytm');
          checkoutProvider.setPaymentProcessState(false);
          showMessage(
              context, 'Payment cancelled or failed', MessageType.warning);
        }
      }).catchError((onError) {
        debugPrint('❌ [Paytm] SDK catchError: $onError');
        debugPrint('❌ [Paytm] NOT calling place_order_with_paytm');
        checkoutProvider.setAwaitingPaytmResult(false);
        checkoutProvider.setPaymentProcessState(false);
        String errorMessage = 'Payment failed. Please try again.';
        if (onError is PlatformException) {
          errorMessage = onError.message ?? errorMessage;
        }
        showMessage(context, errorMessage, MessageType.warning);
      });
    } catch (err) {
      debugPrint('❌ [Paytm] openPaytmPaymentGateway exception: $err');
      debugPrint('❌ [Paytm] NOT calling place_order_with_paytm');
      checkoutProvider.setAwaitingPaytmResult(false);
      checkoutProvider.setPaymentProcessState(false);
      showMessage(
          context, 'Failed to open payment gateway', MessageType.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    return Consumer<CheckoutProvider>(
      builder: (context, checkoutProvider, child) {
        bool isAddressDeliverable =
            checkoutProvider.selectedAddress?.cityId.toString() == "0";
        bool isAddressEmpty = checkoutProvider.selectedAddress == null ||
            checkoutProvider.selectedAddress == "";
        bool isDisabled = widget.selectedMethod == "0" &&
            (isAddressDeliverable || isAddressEmpty);

        final isStoreClosed = StoreHoursService().isLoaded &&
            !StoreHoursService().isStoreOpen;
        final cartProv = context.read<CartProvider>();
        final hasAdminItems = cartProv.hasAdminManagedItems();
        final hasNonAdminItems = cartProv.hasNonAdminCartItems();
        final isBlockedByStoreClosed =
            isStoreClosed && hasAdminItems && !hasNonAdminItems;

        return GestureDetector(
          onTap: isDisabled || isBlockedByStoreClosed || checkoutProvider.isPaymentUnderProcessing
              ? isBlockedByStoreClosed
                  ? () {
                      showMessage(
                          context,
                          "${getTranslatedValue(context, 'store_closed')}. ${getTranslatedValue(context, 'will_open_at')} ${StoreHoursService().formattedOpeningTime}",
                          MessageType.warning);
                    }
                  : null
              : () async {
                  // If store closed with admin items but also has non-admin items
                  if (isStoreClosed && hasAdminItems) {
                    final confirmed = await showAdminStoreClosedDialog(
                      context: context,
                      adminManagedItems: cartProv.getAdminManagedItems(),
                    );
                    if (!confirmed) return;

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          Center(child: CircularProgressIndicator()),
                    );
                    final hasRemaining = await cartProv
                        .removeAdminManagedItems(context: context);
                    Navigator.of(context).pop(); // dismiss loading

                    if (!hasRemaining) {
                      showMessage(context, "Your cart is now empty",
                          MessageType.warning);
                      Navigator.of(context).pop(); // go back to cart
                      return;
                    }
                  }
                  print("widget.selectedMethod:${widget.selectedMethod}");
                  context
                      .read<CheckoutProvider>()
                      .setOrderType(widget.selectedMethod ?? "0");
                  context.read<CheckoutProvider>().selectedOrderType =
                      widget.selectedMethod;
                  if (context
                          .read<PaymentMethodsProvider>()
                          .selectedPaymentMethod ==
                      "") {
                    showMessage(
                        context,
                        getTranslatedValue(
                            context, paymentMethodUnavailableLabel),
                        MessageType.warning);
                  } else if (widget.selectedMethod == "0" &&
                      isAddressDeliverable) {
                    showMessage(
                        context,
                        getTranslatedValue(
                            context, addressNotDeliverableSelectedLabel),
                        MessageType.warning);
                  } else if (widget.selectedMethod == "0" && isAddressEmpty) {
                    showMessage(
                        context,
                        getTranslatedValue(context, addAddressFirstLabel),
                        MessageType.warning);
                    // } else if (widget.selectedMethod == "0" && checkoutProvider.checkoutTimeSlotsState ==
                    //     CheckoutTimeSlotsState.timeSlotsError) {
                    //   showMessage(
                    //       context,
                    //       getTranslatedValue(
                    //           context, pleaseAddTimeslotInAdminPanelLabel),
                    //       MessageType.warning);
                  } else if (widget.selectedMethod == "0" &&
                      checkoutProvider.getTotalVisibleTimeSlots().toString() ==
                          "0" &&
                      checkoutProvider.timeSlotsData?.timeSlotsIsEnabled
                              .toString() ==
                          "true") {
                    showMessage(
                        context,
                        getTranslatedValue(context, timeSlotsExpiredIssueLabel),
                        MessageType.warning);
                  } else if (!checkoutProvider.isPaymentUnderProcessing) {
                    checkoutProvider.setPaymentProcessState(true).then((value) {
                      if (context
                                  .read<PaymentMethodsProvider>()
                                  .selectedPaymentMethod ==
                              "COD" ||
                          context
                                  .read<PaymentMethodsProvider>()
                                  .selectedPaymentMethod ==
                              "Wallet") {
                        checkoutProvider.placeOrder(context: context);
                        // RAZORPAY COMMENTED OUT
                        // } else if (context
                        //         .read<PaymentMethodsProvider>()
                        //         .selectedPaymentMethod ==
                        //     "Razorpay") {
                        //   razorpayKey = context
                        //           .read<PaymentMethodsProvider>()
                        //           .paymentMethodsData
                        //           ?.razorpayKey ??
                        //       "0";
                        //   amount = context.read<CheckoutProvider>().totalAmount;
                        //   context
                        //       .read<CheckoutProvider>()
                        //       .placeOrder(context: context)
                        //       .then((value) {
                        //     if (value) {
                        //       context
                        //           .read<CheckoutProvider>()
                        //           .initiateRazorpayTransaction(context: context)
                        //           .then((value) /* =>  */ {
                        //         if (value["status"].toString() == "1") {
                        //           print("value:${value}");
                        //           openRazorPayGateway();
                        //         } else {
                        //           context
                        //               .read<CheckoutProvider>()
                        //               .setPaymentProcessState(false);
                        //           showMessage(
                        //               context, value["message"], MessageType.warning);
                        //         }
                        //       });
                        //     }
                        //   });
                      } else if (context
                              .read<PaymentMethodsProvider>()
                              .selectedPaymentMethod ==
                          "Midtrans") {
                        amount = context.read<CheckoutProvider>().totalAmount;
                        context
                            .read<CheckoutProvider>()
                            .placeOrder(context: context);
                      } else if (context
                              .read<PaymentMethodsProvider>()
                              .selectedPaymentMethod ==
                          "Phonepe") {
                        amount = context.read<CheckoutProvider>().totalAmount;

                        debugPrint('💳 [UPI/Paytm] Place Order tapped with UPI app');
                        debugPrint('💳 [UPI/Paytm] amount: $amount');

                        // UPI apps use Paytm gateway — restrictAppInvoke=false to open UPI app directly
                        context
                            .read<CheckoutProvider>()
                            .initiatePaytmTransaction(context: context)
                            .then((success) {
                          debugPrint('💳 [UPI/Paytm] initiatePaytmTransaction result: $success');
                          if (success == true) {
                            debugPrint('💳 [UPI/Paytm] Opening Paytm payment gateway...');
                            openPaytmPaymentGateway(restrictAppInvoke: false);
                          } else {
                            debugPrint('❌ [UPI/Paytm] initiatePaytmTransaction failed');
                            checkoutProvider.setPaymentProcessState(false);
                          }
                        }).catchError((error) {
                          debugPrint('❌ [UPI/Paytm] initiatePaytmTransaction error: $error');
                          checkoutProvider.setPaymentProcessState(false);
                        });
                      } else if (context
                              .read<PaymentMethodsProvider>()
                              .selectedPaymentMethod ==
                          "Paystack") {
                        amount = context.read<CheckoutProvider>().totalAmount;
                        context
                            .read<CheckoutProvider>()
                            .placeOrder(context: context)
                            .then((value) {
                          if (value) {
                            return openPaystackPaymentGateway();
                          }
                        });
                      } else if (context
                              .read<PaymentMethodsProvider>()
                              .selectedPaymentMethod ==
                          "Stripe") {
                        amount = context.read<CheckoutProvider>().totalAmount;

                        context
                            .read<CheckoutProvider>()
                            .placeOrder(context: context)
                            .then((value) {
                          if (value) {
                            StripeService.payWithPaymentSheet(
                              amount:
                                  int.parse((amount * 100).toStringAsFixed(0)),
                              isTestEnvironment: true,
                              awaitedOrderId: checkoutProvider.placedOrderId,
                              context: context,
                              currency: context
                                      .read<PaymentMethodsProvider>()
                                      .paymentMethods
                                      ?.data
                                      .stripeCurrencyCode ??
                                  "inr",
                              from: "order",
                            ).then((value) {
                              if (!value.success!) {
                                context
                                    .read<CheckoutProvider>()
                                    .deleteAwaitingOrder(context);

                                context
                                    .read<CheckoutProvider>()
                                    .setPaymentProcessState(false);
                                showMessage(
                                    context,
                                    getTranslatedValue(
                                        context, paymentCancelledByUserLabel),
                                    MessageType.warning);
                              }
                            });
                          }
                        });
                      } else if (context
                              .read<PaymentMethodsProvider>()
                              .selectedPaymentMethod ==
                          "Paytm") {
                        amount = context.read<CheckoutProvider>().totalAmount;
                        debugPrint('💳 [Paytm] Place Order tapped, amount: $amount');

                        // Paytm: Get config + token first, then pay, then place order
                        // NO order is placed until payment is done and verified
                        context
                            .read<CheckoutProvider>()
                            .initiatePaytmTransaction(context: context)
                            .then((success) {
                          debugPrint('💳 [Paytm] initiatePaytmTransaction result: $success');
                          if (success == true) {
                            debugPrint('💳 [Paytm] Opening Paytm payment gateway...');
                            openPaytmPaymentGateway();
                          } else {
                            debugPrint('❌ [Paytm] initiatePaytmTransaction failed - NOT opening gateway');
                            checkoutProvider.setPaymentProcessState(false);
                          }
                        }).catchError((error) {
                          debugPrint('❌ [Paytm] initiatePaytmTransaction error: $error');
                          checkoutProvider.setPaymentProcessState(false);
                        });
                      } else if (context
                              .read<PaymentMethodsProvider>()
                              .selectedPaymentMethod ==
                          "Paypal") {
                        amount = context.read<CheckoutProvider>().totalAmount;
                        context
                            .read<CheckoutProvider>()
                            .placeOrder(context: context)
                            .then((value) {
                          if (value is bool) {
                            context
                                .read<CheckoutProvider>()
                                .setPaymentProcessState(false);
                          }
                        });
                      } else if (context
                              .read<PaymentMethodsProvider>()
                              .selectedPaymentMethod ==
                          "Cashfree") {
                        /* if (context
                          .read<PaymentMethodsProvider>()
                          .paymentMethodsData
                          ?.cashfreeMode ==
                      "sandbox") {
                    showMessage(
                        context,
                        getTranslatedValue(context, cashfreeSandboxWarningLabel),
                        MessageType.warning);
                  } */
                        amount = context.read<CheckoutProvider>().totalAmount;
                        context
                            .read<CheckoutProvider>()
                            .placeOrder(context: context)
                            .then((value) {
                          if (value is bool) {
                            context
                                .read<CheckoutProvider>()
                                .setPaymentProcessState(false);
                          }
                        });
                      } else if (context
                              .read<PaymentMethodsProvider>()
                              .selectedPaymentMethod ==
                          "Paytabs") {
                        amount = context.read<CheckoutProvider>().totalAmount;
                        context
                            .read<CheckoutProvider>()
                            .placeOrder(context: context)
                            .then((value) {
                          if (value is bool) {
                            context
                                .read<CheckoutProvider>()
                                .setPaymentProcessState(false);
                          }
                        });
                      }
                    });
                  }
                },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              color: isBlockedByStoreClosed
                  ? const Color(0xFFE53E3E)
                  : isDisabled
                      ? colorScheme.buttonDisabledBackground
                      : colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: (isDisabled || isBlockedByStoreClosed)
                  ? []
                  : [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: (checkoutProvider.checkoutDeliveryChargeState ==
                      CheckoutDeliveryChargeState.deliveryChargeLoading)
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.buttonPrimaryText,
                        ),
                      ),
                    )
                  : checkoutProvider.isPaymentUnderProcessing
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.buttonPrimaryText,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isBlockedByStoreClosed
                                  ? Icons.storefront_outlined
                                  : isDisabled
                                      ? Icons.warning_amber_rounded
                                      : Icons.shopping_bag_outlined,
                              color: isBlockedByStoreClosed
                                  ? Colors.white
                                  : isDisabled
                                      ? colorScheme.buttonDisabledText
                                      : colorScheme.buttonPrimaryText,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isBlockedByStoreClosed
                                    ? "${getTranslatedValue(context, 'store_closed')} · ${getTranslatedValue(context, 'will_open_at')} ${StoreHoursService().formattedOpeningTime}"
                                    : widget.selectedMethod == "0"
                                        ? (isAddressDeliverable
                                            ? getTranslatedValue(context,
                                                addressNotDeliverableLabel)
                                            : isAddressEmpty
                                                ? getTranslatedValue(context,
                                                    addAddressFirstLabel)
                                                : getTranslatedValue(context,
                                                    placeOrderLabel))
                                        : getTranslatedValue(
                                            context, placeOrderLabel),
                                style: GoogleFonts.inter(
                                  fontSize: isBlockedByStoreClosed ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                  color: isBlockedByStoreClosed
                                      ? Colors.white
                                      : isDisabled
                                          ? colorScheme.buttonDisabledText
                                          : colorScheme.buttonPrimaryText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // _razorpay.clear();
    paystackPlugin.dispose();
    super.dispose();
  }
}
