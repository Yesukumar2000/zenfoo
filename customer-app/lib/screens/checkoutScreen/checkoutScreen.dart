import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:velocity_x/velocity_x.dart';

class CheckoutScreen extends StatefulWidget {
  final String? selfPickupMode, total;
  const CheckoutScreen({Key? key, this.selfPickupMode, this.total})
      : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with WidgetsBindingObserver {
  late UserAddressData? selectedAddress;
  String _selectedMethod = "0";

  /// True while the order is being placed automatically because the wallet
  /// already covers the whole bill.
  bool _isAutoPlacingOrder = false;

  /// Grace period after returning from the payment gateway before we treat a
  /// missing SDK callback as "the user backed out".
  static const Duration _gatewayReturnGrace = Duration(seconds: 3);
  Timer? _gatewayReturnTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration.zero).then(
      (value) async {
        // Only fetch default address if no address is currently selected
        UserAddressData? selectedAddress =
            context.read<CheckoutProvider>().selectedAddress;
        if (selectedAddress == null || selectedAddress.id == null) {
          selectedAddress = await context
              .read<CheckoutProvider>()
              .getSingleAddressProvider(context: context);
        }

        Map<String, String> params = {
          ApiAndParams.latitude: selectedAddress?.latitude?.toString() ??
              Constant.session.getData(SessionManager.keyLatitude),
          ApiAndParams.longitude: selectedAddress?.longitude?.toString() ??
              Constant.session.getData(SessionManager.keyLongitude),
          ApiAndParams.isCheckout: "1"
        };

        if (Constant.selectedPromoCodeId != "0") {
          params[ApiAndParams.promoCodeId] = Constant.selectedPromoCodeId;
        }

        await context.read<CheckoutProvider>().getOrderChargesProvider(
              context: context,
              params: params,
            );

        await context
            .read<PaymentMethodsProvider>()
            .getPaymentMethods(context: context, from: "checkout");

        // After payment methods load (and a default like COD is auto-selected),
        // re-fetch charges so payment gateway fees match the selected method.
        if (context.mounted) {
          final defaultMethod =
              context.read<PaymentMethodsProvider>().selectedPaymentMethod;
          if (defaultMethod.isNotEmpty) {
            await context
                .read<CheckoutProvider>()
                .refreshChargesForPaymentMethod(context, defaultMethod);
          }
        }

        // Initialize Stripe after payment methods are loaded
        StripeService.init(
          stripeId: context
                  .read<PaymentMethodsProvider>()
                  .paymentMethods
                  ?.data
                  .stripePublishableKey ??
              "",
          secretKey: context
                  .read<PaymentMethodsProvider>()
                  .paymentMethods
                  ?.data
                  .stripeSecretKey ??
              "",
        );

        if (context.mounted) {
          await _autoPlaceOrderIfNothingToPay();
        }
      },
    );
  }

  /// When the wallet covers the whole bill there is nothing to pay and no
  /// payment method to pick, so this screen has nothing to show. Place the
  /// order straight away instead of leaving the customer on a blank page.
  Future<void> _autoPlaceOrderIfNothingToPay() async {
    final checkoutProvider = context.read<CheckoutProvider>();

    // Only when the charges actually loaded — a failed fetch also leaves the
    // total at 0, and that must not place an order.
    if (checkoutProvider.checkoutDeliveryChargeState !=
        CheckoutDeliveryChargeState.deliveryChargeLoaded) {
      return;
    }

    if (checkoutProvider.totalAmount != 0.0) return;
    if (checkoutProvider.isPaymentUnderProcessing) return;

    // Delivery orders still need a deliverable address. Fall back to the normal
    // screen so the customer can fix it rather than failing silently.
    final address = checkoutProvider.selectedAddress;
    if (_selectedMethod == "0" &&
        (address?.id == null || address?.cityId.toString() == "0")) {
      return;
    }

    setState(() => _isAutoPlacingOrder = true);

    checkoutProvider.setOrderType(_selectedMethod);
    checkoutProvider.selectedOrderType = _selectedMethod;
    context.read<PaymentMethodsProvider>().selectedPaymentMethod = "Wallet";

    await checkoutProvider.setPaymentProcessState(true);
    await checkoutProvider.placeOrder(context: context);

    // Reached only if placing failed; success navigates away from this screen.
    if (mounted) setState(() => _isAutoPlacingOrder = false);
  }

  @override
  void dispose() {
    _gatewayReturnTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;

    final checkoutProvider = context.read<CheckoutProvider>();
    if (!checkoutProvider.isPaymentUnderProcessing ||
        !checkoutProvider.awaitingPaytmResult) {
      return;
    }

    // We're back from the gateway. Give the SDK a moment to deliver its
    // result; if it stays silent (what happens when the user presses back
    // inside the gateway) ask the backend what really happened so checkout
    // never stays locked.
    _gatewayReturnTimer?.cancel();
    _gatewayReturnTimer = Timer(_gatewayReturnGrace, () {
      if (!mounted) return;
      context.read<CheckoutProvider>().resolveStuckPaytmPayment(context);
    });
  }

  /// Back / cancel while a payment is in flight. Confirms with the user, then
  /// verifies with the backend before unlocking, so a payment that actually
  /// succeeded still becomes an order.
  Future<void> _handleBackDuringPayment() async {
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              getTranslatedValue(dialogContext, 'cancel_payment_title'),
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
              ),
            ),
            content: Text(
              getTranslatedValue(dialogContext, 'cancel_payment_message'),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.textSecondary,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  getTranslatedValue(dialogContext, 'keep_waiting'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  getTranslatedValue(dialogContext, 'cancel_payment'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    _gatewayReturnTimer?.cancel();
    final bool freed =
        await context.read<CheckoutProvider>().cancelOngoingPayment(context);

    // Not freed means the payment did go through and the order screen took
    // over — nothing left to pop here.
    if (freed && mounted) {
      Navigator.pop(context);
    }
  }

  // Premium Delivery Option Widget
  Widget _buildOption(
      {required String value, required String title, required IconData icon}) {
    final bool isSelected = _selectedMethod == value;
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (value == "1" && widget.selfPickupMode == "1") {
            setState(() {
              _selectedMethod = value;
            });
            await _handleDeliveryTypeChange(value);
          } else if (value == "0") {
            setState(() {
              _selectedMethod = value;
            });
            await _handleDeliveryTypeChange(value);
          } else {
            showMessage(
              context,
              getTranslatedValue(context, storePickupNoteLabel),
              MessageType.success,
            );
          }
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              width: 1,
              color: isSelected ? colorScheme.primary : colorScheme.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : colorScheme.cardShadow,
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(height: 12),
              CustomTextLabel(
                jsonKey: title,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : colorScheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              if (isSelected) ...[
                SizedBox(height: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openMap(String lat, String lng) async {
    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _handleDeliveryTypeChange(String deliveryType) async {
    try {
      if (deliveryType == "0") {
        await _loadHomeDeliveryData();
      } else if (deliveryType == "1") {
        await _loadSelfPickupData();
      }
    } catch (e) {
      print("Error handling delivery type change: $e");
    }
  }

  Future<void> _loadHomeDeliveryData() async {
    // Only fetch default address if no address is currently selected
    UserAddressData? selectedAddress =
        context.read<CheckoutProvider>().selectedAddress;
    if (selectedAddress == null || selectedAddress.id == null) {
      selectedAddress = await context
          .read<CheckoutProvider>()
          .getSingleAddressProvider(context: context);
    }

    Map<String, String> params = {
      ApiAndParams.latitude: selectedAddress?.latitude?.toString() ??
          Constant.session.getData(SessionManager.keyLatitude),
      ApiAndParams.longitude: selectedAddress?.longitude?.toString() ??
          Constant.session.getData(SessionManager.keyLongitude),
      ApiAndParams.isCheckout: "1",
      ApiAndParams.isSelfPickup: "0"
    };

    if (Constant.selectedPromoCodeId != "0") {
      params[ApiAndParams.promoCodeId] = Constant.selectedPromoCodeId;
    }

    await context.read<CheckoutProvider>().getOrderChargesProvider(
          context: context,
          params: params,
        );
  }

  Future<void> _loadSelfPickupData() async {
    Map<String, String> params = {
      ApiAndParams.isCheckout: "1",
      ApiAndParams.isSelfPickup: "1"
    };

    if (Constant.selectedPromoCodeId != "0") {
      params[ApiAndParams.promoCodeId] = Constant.selectedPromoCodeId;
    }

    await context.read<CheckoutProvider>().getOrderChargesProvider(
          context: context,
          params: params,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        } else {
          if (!context.read<CheckoutProvider>().isPaymentUnderProcessing) {
            Navigator.pop(context);
          } else {
            _handleBackDuringPayment();
          }
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: PreferredSize(
          preferredSize: Size(double.infinity, double.maxFinite),
          child: Consumer<CheckoutProvider>(
            builder: (context, checkoutProvider, _) {
              final total = checkoutProvider.totalAmount == 0.0
                  ? widget.total.toString().numCurrency
                  : checkoutProvider.totalAmount.numCurrency;
              return AppHeader(
                label: getTranslatedValue(context, checkoutLabel),
                title:
                    "${getTranslatedValue(context, 'total_prefix')} $total",
                showBackButton: true,
                onBackPressed: () {
                  if (checkoutProvider.isPaymentUnderProcessing) {
                    _handleBackDuringPayment();
                  } else {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
        body: Consumer<CheckoutProvider>(
          builder: (context, checkoutProvider, _) {
            if (_isAutoPlacingOrder) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 2.5,
                    ),
                    SizedBox(height: 20),
                    Text(
                      getTranslatedValue(context, placeOrderLabel),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // // Gradient AppBar
                    // SliverAppBar(
                    //   pinned: true,
                    //   floating: true,
                    //   elevation: 0,
                    //   automaticallyImplyLeading: false,
                    //   toolbarHeight: 70,
                    //   backgroundColor: Colors.transparent,
                    //   flexibleSpace: Container(
                    //     decoration: BoxDecoration(
                    //       gradient: colorScheme.surfaceGradient,
                    //     ),
                    //     child: SafeArea(
                    //       bottom: false,
                    //       child: Padding(
                    //         padding: EdgeInsets.symmetric(
                    //             horizontal: 16, vertical: 14),
                    //         child: Row(
                    //           children: [
                    //             GestureDetector(
                    //               onTap: () async {
                    //                 if (context
                    //                     .read<CheckoutProvider>()
                    //                     .isPaymentUnderProcessing) {
                    //                   showMessage(
                    //                       context,
                    //                       getTranslatedValue(
                    //                         context,
                    //                         noBackUntilPaymentDoneLabel,
                    //                       ),
                    //                       MessageType.warning);
                    //                 } else {
                    //                   Navigator.pop(context);
                    //                 }
                    //               },
                    //               child: Container(
                    //                 width: 40,
                    //                 height: 40,
                    //                 decoration: BoxDecoration(
                    //                   color: colorScheme.surface
                    //                       .withValues(alpha: 0.3),
                    //                   borderRadius: BorderRadius.circular(12),
                    //                   border: Border.all(
                    //                     color: colorScheme.border,
                    //                     width: 1,
                    //                   ),
                    //                 ),
                    //                 child: Center(
                    //                   child: Icon(
                    //                     Icons.arrow_back_ios_new_rounded,
                    //                     color: colorScheme.appBarIcon,
                    //                     size: 18,
                    //                   ),
                    //                 ),
                    //               ),
                    //             ),
                    //             SizedBox(width: 12),
                    //             Expanded(
                    //               child: Column(
                    //                 crossAxisAlignment:
                    //                     CrossAxisAlignment.start,
                    //                 mainAxisAlignment: MainAxisAlignment.center,
                    //                 mainAxisSize: MainAxisSize.min,
                    //                 children: [
                    //                   Text(
                    //                     getTranslatedValue(
                    //                         context, checkoutLabel),
                    //                     style: GoogleFonts.inter(
                    //                       color: colorScheme.appBarText,
                    //                       fontSize: 12,
                    //                       fontWeight: FontWeight.w500,
                    //                       height: 1.2,
                    //                       letterSpacing: -0.2,
                    //                     ),
                    //                   ),
                    //                   SizedBox(height: 2),
                    //                   Text(
                    //                     "Total ${context.read<CheckoutProvider>().totalAmount == 0.0 ? widget.total.toString().numCurrency : context.read<CheckoutProvider>().totalAmount.numCurrency}",
                    //                     style: GoogleFonts.inter(
                    //                       color: colorScheme.appBarText,
                    //                       fontSize: 14,
                    //                       fontWeight: FontWeight.w700,
                    //                       height: 1.2,
                    //                       letterSpacing: -0.3,
                    //                     ),
                    //                     maxLines: 1,
                    //                     overflow: TextOverflow.ellipsis,
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Delivery Method Selection
                            // Container(
                            //   padding: EdgeInsets.all(20),
                            //   decoration: BoxDecoration(
                            //     color: Colors.white,
                            //     borderRadius: BorderRadius.circular(16),
                            //     boxShadow: [
                            //       BoxShadow(
                            //         color: Color(0x08000000),
                            //         blurRadius: 12,
                            //         offset: Offset(0, 2),
                            //       ),
                            //     ],
                            //   ),
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: [
                            //       Row(
                            //         children: [
                            //           Container(
                            //             padding: EdgeInsets.all(8),
                            //             decoration: BoxDecoration(
                            //               gradient: LinearGradient(
                            //                 colors: [
                            //                   Color(0xFF9AC444).withOpacity(0.15),
                            //                   Color(0xFF9AC444).withOpacity(0.08),
                            //                 ],
                            //               ),
                            //               borderRadius: BorderRadius.circular(10),
                            //             ),
                            //             child: Icon(
                            //               Icons.local_shipping_rounded,
                            //               color: Color(0xFF9AC444),
                            //               size: 20,
                            //             ),
                            //           ),
                            //           SizedBox(width: 12),
                            //           CustomTextLabel(
                            //             jsonKey: chooseDeliveryMethodLabel,
                            //             style: GoogleFonts.inter(
                            //               color: Color(0xFF0A0A0A),
                            //               fontSize: 17,
                            //               fontWeight: FontWeight.w700,
                            //               letterSpacing: -0.3,
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //       SizedBox(height: 18),
                            //       Row(
                            //         children: [
                            //           _buildOption(
                            //             value: "0",
                            //             title: homeDeliveryLabel,
                            //             icon: Icons.home_rounded,
                            //           ),
                            //           SizedBox(width: 12),
                            //           _buildOption(
                            //             value: "1",
                            //             title: storePickupLabel,
                            //             icon: Icons.store_rounded,
                            //           ),
                            //         ],
                            //       ),
                            //       SizedBox(height: 14),
                            //       Container(
                            //         padding: EdgeInsets.all(12),
                            //         decoration: BoxDecoration(
                            //           color: Color(0xFFFFF9EB),
                            //           borderRadius: BorderRadius.circular(10),
                            //           border: Border.all(
                            //             color: Color(0xFFFFE5B4),
                            //             width: 1,
                            //           ),
                            //         ),
                            //         child: Row(
                            //           children: [
                            //             Icon(
                            //               Icons.info_outline_rounded,
                            //               color: Color(0xFFFF9800),
                            //               size: 18,
                            //             ),
                            //             SizedBox(width: 10),
                            //             Expanded(
                            //               child: CustomTextLabel(
                            //                 jsonKey: storePickupNoteLabel,
                            //                 style: GoogleFonts.inter(
                            //                   color: Color(0xFF7D6E00),
                            //                   fontSize: 12,
                            //                   fontWeight: FontWeight.w500,
                            //                   letterSpacing: -0.1,
                            //                 ),
                            //               ),
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),

                            // SizedBox(height: 16),

                            // // Wallet Balance
                            // if (checkoutProvider.deliveryChargeData?.userBalance
                            //             .toString() !=
                            //         "0" &&
                            //     checkoutProvider.deliveryChargeData?.userBalance
                            //             .toString() !=
                            //         null)
                            //   Container(
                            //     padding: EdgeInsets.all(18),
                            //     decoration: BoxDecoration(
                            //       gradient: LinearGradient(
                            //         begin: Alignment.topLeft,
                            //         end: Alignment.bottomRight,
                            //         colors: [
                            //           Color(0xFFF8FFEB),
                            //           Colors.white,
                            //         ],
                            //       ),
                            //       borderRadius: BorderRadius.circular(16),
                            //       border: Border.all(
                            //         color: Color(0xFF9AC444).withOpacity(0.3),
                            //         width: 1.5,
                            //       ),
                            //       boxShadow: [
                            //         BoxShadow(
                            //           color: Color(0x08000000),
                            //           blurRadius: 12,
                            //           offset: Offset(0, 2),
                            //         ),
                            //       ],
                            //     ),
                            //     child: Row(
                            //       children: [
                            //         Container(
                            //           padding: EdgeInsets.all(12),
                            //           decoration: BoxDecoration(
                            //             gradient: LinearGradient(
                            //               colors: [
                            //                 Color(0xFF9AC444),
                            //                 Color(0xFF87B23D),
                            //               ],
                            //             ),
                            //             borderRadius: BorderRadius.circular(12),
                            //           ),
                            //           child: Icon(
                            //             Icons.account_balance_wallet_rounded,
                            //             color: Colors.white,
                            //             size: 22,
                            //           ),
                            //         ),
                            //         SizedBox(width: 14),
                            //         Expanded(
                            //           child: Column(
                            //             crossAxisAlignment: CrossAxisAlignment.start,
                            //             children: [
                            //               CustomTextLabel(
                            //                 jsonKey: walletBalanceLabel,
                            //                 style: GoogleFonts.inter(
                            //                   fontSize: 13,
                            //                   fontWeight: FontWeight.w500,
                            //                   color: Color(0xFF757575),
                            //                   letterSpacing: -0.1,
                            //                 ),
                            //               ),
                            //               SizedBox(height: 2),
                            //               CustomTextLabel(
                            //                 jsonKey:
                            //                     "${context.read<CheckoutProvider>().availableWalletAmount}"
                            //                         .currency,
                            //                 overflow: TextOverflow.ellipsis,
                            //                 style: GoogleFonts.inter(
                            //                   color: Color(0xFF9AC444),
                            //                   fontWeight: FontWeight.w700,
                            //                   fontSize: 18,
                            //                   letterSpacing: -0.3,
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //         ),
                            //         SizedBox(width: 12),
                            //         Transform.scale(
                            //           scale: 1.1,
                            //           child: Checkbox(
                            //             value: checkoutProvider.usedWallet ?? false,
                            //             onChanged: (value) {
                            //               checkoutProvider.userWalletAmount(value!);
                            //             },
                            //             activeColor: Color(0xFF9AC444),
                            //             shape: RoundedRectangleBorder(
                            //               borderRadius: BorderRadius.circular(6),
                            //             ),
                            //           ),
                            //         ),
                            //       ],
                            //     ),
                            //   ),

                            // // Store Pickup Info & Other Sections
                            // if (_selectedMethod == "1" &&
                            //     context.read<CheckoutProvider>().sellerSelfPickup != null)
                            //   _buildStorePickupInfo(context, checkoutProvider),

                            // Loading State
                            if (checkoutProvider.checkoutAddressState ==
                                    CheckoutAddressState.addressLoading &&
                                checkoutProvider.checkoutTimeSlotsState ==
                                    CheckoutTimeSlotsState.timeSlotsLoading &&
                                context
                                        .read<PaymentMethodsProvider>()
                                        .paymentMethodsState ==
                                    PaymentMethodsState.loading)
                              CheckoutShimmer(),

                            // Address Widget
                            if (_selectedMethod == "0" &&
                                context
                                        .read<PaymentMethodsProvider>()
                                        .paymentMethodsState ==
                                    PaymentMethodsState.loaded &&
                                (checkoutProvider.checkoutTimeSlotsState ==
                                        CheckoutTimeSlotsState
                                            .timeSlotsLoaded ||
                                    checkoutProvider.checkoutTimeSlotsState ==
                                        CheckoutTimeSlotsState
                                            .timeSlotsError) &&
                                (checkoutProvider.checkoutAddressState ==
                                        CheckoutAddressState.addressLoaded ||
                                    checkoutProvider.checkoutAddressState ==
                                        CheckoutAddressState.addressBlank ||
                                    checkoutProvider.checkoutAddressState ==
                                        CheckoutAddressState.addressError))
                              AddressWidget(),

                            // Time Slots & Order Note
                            if (context
                                        .read<PaymentMethodsProvider>()
                                        .paymentMethodsState ==
                                    PaymentMethodsState.loaded &&
                                (checkoutProvider.checkoutTimeSlotsState ==
                                        CheckoutTimeSlotsState
                                            .timeSlotsLoaded ||
                                    checkoutProvider.checkoutTimeSlotsState ==
                                        CheckoutTimeSlotsState
                                            .timeSlotsError) &&
                                (checkoutProvider.checkoutAddressState ==
                                        CheckoutAddressState.addressLoaded ||
                                    checkoutProvider.checkoutAddressState ==
                                        CheckoutAddressState.addressBlank ||
                                    checkoutProvider.checkoutAddressState ==
                                        CheckoutAddressState.addressError))
                              Column(
                                children: [
                                  if (_selectedMethod == "0") GetTimeSlots(),
                                  OrderNoteWidget(
                                    edtOrderNote: context
                                        .read<CheckoutProvider>()
                                        .edtOrderNote,
                                  ),
                                ],
                              ),

                            // Payment Methods
                            if (checkoutProvider.totalAmount != 0.0)
                              PaymentMethodsWidget(
                                isPaymentUnderProcessing:
                                    checkoutProvider.isPaymentUnderProcessing,
                                totalAmount: checkoutProvider.totalAmount,
                              ),

                            // Delivery Charges
                            if (context
                                        .read<PaymentMethodsProvider>()
                                        .paymentMethodsState ==
                                    PaymentMethodsState.loaded &&
                                ((_selectedMethod == "0" &&
                                        checkoutProvider
                                                .checkoutDeliveryChargeState ==
                                            CheckoutDeliveryChargeState
                                                .deliveryChargeLoaded &&
                                        (checkoutProvider
                                                    .checkoutTimeSlotsState ==
                                                CheckoutTimeSlotsState
                                                    .timeSlotsLoaded ||
                                            checkoutProvider
                                                    .checkoutTimeSlotsState ==
                                                CheckoutTimeSlotsState
                                                    .timeSlotsError) &&
                                        (checkoutProvider
                                                    .checkoutAddressState ==
                                                CheckoutAddressState
                                                    .addressLoaded ||
                                            checkoutProvider
                                                    .checkoutAddressState ==
                                                CheckoutAddressState
                                                    .addressBlank ||
                                            checkoutProvider
                                                    .checkoutAddressState ==
                                                CheckoutAddressState
                                                    .addressError) &&
                                        checkoutProvider.selectedAddress?.id !=
                                            null) ||
                                    (_selectedMethod == "1")))
                              DeliveryChargesWidget(orderType: _selectedMethod),

                            if (checkoutProvider.checkoutDeliveryChargeState ==
                                CheckoutDeliveryChargeState
                                    .deliveryChargeLoading)
                              DeliveryChargeShimmer(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Full-screen loading overlay
                if (checkoutProvider.isPaymentUnderProcessing)
                  Positioned.fill(
                    child: Container(
                      color: colorScheme.overlay,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: colorScheme.elevatedShadow,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PaymentProcessingIndicator(),
                              SizedBox(height: 16),
                              Text(
                                getTranslatedValue(
                                    context, 'processing_payment'),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                getTranslatedValue(context, 'please_wait'),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                              SizedBox(height: 4),
                              // Always-available escape hatch: a gateway that
                              // never reports back must not lock the screen.
                              TextButton(
                                onPressed: _handleBackDuringPayment,
                                child: Text(
                                  getTranslatedValue(
                                      context, 'cancel_payment'),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        // Bottom Bar
        bottomNavigationBar: Consumer<CheckoutProvider>(
          builder: (context, checkoutProvider, _) {
            // Nothing to confirm while the order places itself
            if (_isAutoPlacingOrder) return const SizedBox.shrink();

            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: colorScheme.bottomNavBackground,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.cardShadowColor,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomTextLabel(
                            jsonKey: totalLabel,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: colorScheme.textSecondary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                          ),
                          SizedBox(height: 2),
                          CustomTextLabel(
                            text:
                                context.read<CheckoutProvider>().totalAmount ==
                                        0.0
                                    ? widget.total.toString().currency
                                    : context
                                        .read<CheckoutProvider>()
                                        .totalAmount
                                        .toString()
                                        .currency,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: PlaceOrderButtonWidget(
                        context: context,
                        selectedMethod: _selectedMethod,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStorePickupInfo(
      BuildContext context, CheckoutProvider checkoutProvider) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.store_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: CustomTextLabel(
                  jsonKey: pickupFromStoreLabel,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final lat = checkoutProvider.sellerSelfPickup?.pickupLatitude;
                  final lng =
                      checkoutProvider.sellerSelfPickup?.pickupLongitude;
                  if (lat != null && lng != null) {
                    _openMap(lat, lng);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        getTranslatedValue(context, directionLabel),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 32, thickness: 1, color: colorScheme.divider),
          _buildStoreDetailRow(
            icon: Icons.location_on_outlined,
            title: checkoutProvider.sellerSelfPickup?.sellerName
                    ?.toCapitalized() ??
                "",
            subtitle:
                checkoutProvider.sellerSelfPickup?.pickupStoreAddress ?? "",
          ),
          SizedBox(height: 14),
          _buildStoreDetailRow(
            icon: Icons.phone_outlined,
            title: checkoutProvider.sellerSelfPickup?.sellerMobile ?? "",
          ),
          SizedBox(height: 14),
          _buildStoreDetailRow(
            icon: Icons.access_time_outlined,
            title:
                "${getTranslatedValue(context, openHoursLabel)}: ${checkoutProvider.sellerSelfPickup?.openingTime ?? "--"} - ${checkoutProvider.sellerSelfPickup?.closingTime ?? "--"}",
          ),
        ],
      ),
    );
  }

  Widget _buildStoreDetailRow({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 18),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// import 'package:project/helper/utils/generalImports.dart';

// class CheckoutScreen extends StatefulWidget {
//   final String? selfPickupMode, total;
//   const CheckoutScreen({Key? key, this.selfPickupMode, this.total})
//       : super(key: key);

//   @override
//   State<CheckoutScreen> createState() => _CheckoutScreenState();
// }

// class _CheckoutScreenState extends State<CheckoutScreen> {
//   late UserAddressData? selectedAddress;
//   String _selectedMethod = "0";

//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(Duration.zero).then(
//       (value) async {
//         // await context
//         //     .read<CheckoutProvider>()
//         //     .getTimeSlotsSettings(context: context);

//         await context
//             .read<CheckoutProvider>()
//             .getSingleAddressProvider(context: context)
//             .then(
//           (selectedAddress) async {
//             Map<String, String> params = {
//               ApiAndParams.latitude: selectedAddress?.latitude?.toString() ??
//                   Constant.session.getData(SessionManager.keyLatitude),
//               ApiAndParams.longitude: selectedAddress?.longitude?.toString() ??
//                   Constant.session.getData(SessionManager.keyLongitude),
//               ApiAndParams.isCheckout: "1"
//             };

//             if (Constant.selectedPromoCodeId != "0") {
//               params[ApiAndParams.promoCodeId] = Constant.selectedPromoCodeId;
//             }

//             await context
//                 .read<CheckoutProvider>()
//                 .getOrderChargesProvider(
//                   context: context,
//                   params: params,
//                 )
//                 .then(
//               (value) async {
//                 setState(() {});
//                 await context
//                     .read<PaymentMethodsProvider>()
//                     .getPaymentMethods(context: context, from: "checkout")
//                     .then(
//                   (value) {
//                     setState(() {});
//                     StripeService.init(
//                       stripeId: context
//                               .read<PaymentMethodsProvider>()
//                               .paymentMethods
//                               ?.data
//                               .stripePublishableKey ??
//                           "",
//                       secretKey: context
//                               .read<PaymentMethodsProvider>()
//                               .paymentMethods
//                               ?.data
//                               .stripeSecretKey ??
//                           "",
//                     );
//                   },
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildOption({required String value, required String title}) {
//     final bool isSelected = _selectedMethod == value;

//     return GestureDetector(
//       onTap: () async {
//         if (value == "1" && /* context.read<CheckoutProvider>(). */
//             widget.selfPickupMode == "1") {
//           setState(() {
//             _selectedMethod = value;
//           });
//           // For self pickup (value = "1"), only call basic required APIs
//           await _handleDeliveryTypeChange(value);
//         } else if (value == "0") {
//           setState(() {
//             _selectedMethod = value;
//           });
//           // For home delivery (value = "0"), call all required APIs including slots and address
//           await _handleDeliveryTypeChange(value);
//         } else {
//           showMessage(
//             context,
//             getTranslatedValue(context, storePickupNoteLabel),
//             MessageType.success,
//           );
//         }
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//         margin: const EdgeInsetsDirectional.fromSTEB(0, 5, 10, 5),
//         decoration: BoxDecoration(
//             color: isSelected
//                 ? Theme.of(context).cardColor
//                 : Theme.of(context).scaffoldBackgroundColor,
//             borderRadius: Constant.borderRadius7,
//             border: Border.all(
//               width: isSelected ? 1 : 0.3,
//               color: isSelected ? ColorsRes.appColor : ColorsRes.grey,
//             )),
//         child: Row(
//           children: [
//             CustomRadio(
//               visualDensity: VisualDensity.compact,
//               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               inactiveColor: ColorsRes.mainTextColor,
//               value: value,
//               groupValue: _selectedMethod,
//               activeColor: ColorsRes.appColor,
//               onChanged: (value) async {
//                 if (value == "1" && /* context.read<CheckoutProvider>(). */
//                     widget.selfPickupMode == "1") {
//                   setState(() {
//                     _selectedMethod = value!;
//                   });
//                   // For self pickup (value = "1"), only call basic required APIs
//                   await _handleDeliveryTypeChange(value!);
//                 } else if (value == "0") {
//                   setState(() {
//                     _selectedMethod = value!;
//                   });
//                   // For home delivery (value = "0"), call all required APIs including slots and address
//                   await _handleDeliveryTypeChange(value!);
//                 } else {
//                   showMessage(
//                     context,
//                     getTranslatedValue(context, storePickupNoteLabel),
//                     MessageType.success,
//                   );
//                 }
//               },
//             ),
//             Expanded(
//               child: CustomTextLabel(
//                 jsonKey: title,
//                 style: TextStyle(
//                   color: isSelected ? ColorsRes.mainTextColor : ColorsRes.grey,
//                   fontSize: 13,
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   void _openMap(String lat, String lng) async {
//     final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
//     if (await canLaunchUrl(Uri.parse(url))) {
//       await launchUrl(Uri.parse(url));
//     }
//   }

//   Future<void> _handleDeliveryTypeChange(String deliveryType) async {
//     try {
//       if (deliveryType == "0") {
//         // Home delivery - call all required APIs including slots and address
//         await _loadHomeDeliveryData();
//       } else if (deliveryType == "1") {
//         // Self pickup - skip slots and address APIs, only call basic APIs
//         await _loadSelfPickupData();
//       }
//     } catch (e) {
//       // Handle error
//       print("Error handling delivery type change: $e");
//     }
//   }

//   Future<void> _loadHomeDeliveryData() async {
//     // Get time slots for home delivery
//     // await context
//     //     .read<CheckoutProvider>()
//     //     .getTimeSlotsSettings(context: context);

//     // Get address and calculate delivery charges
//     await context
//         .read<CheckoutProvider>()
//         .getSingleAddressProvider(context: context)
//         .then(
//       (selectedAddress) async {
//         Map<String, String> params = {
//           ApiAndParams.latitude: selectedAddress?.latitude?.toString() ??
//               Constant.session.getData(SessionManager.keyLatitude),
//           ApiAndParams.longitude: selectedAddress?.longitude?.toString() ??
//               Constant.session.getData(SessionManager.keyLongitude),
//           ApiAndParams.isCheckout: "1",
//           ApiAndParams.isSelfPickup: "0" // Home delivery type
//         };

//         if (Constant.selectedPromoCodeId != "0") {
//           params[ApiAndParams.promoCodeId] = Constant.selectedPromoCodeId;
//         }

//         await context.read<CheckoutProvider>().getOrderChargesProvider(
//               context: context,
//               params: params,
//             );
//       },
//     );

//     setState(() {});
//   }

//   Future<void> _loadSelfPickupData() async {
//     // For self pickup, only get order charges without address/location dependency
//     Map<String, String> params = {
//       ApiAndParams.isCheckout: "1",
//       ApiAndParams.isSelfPickup: "1" // Self pickup delivery type
//     };

//     if (Constant.selectedPromoCodeId != "0") {
//       params[ApiAndParams.promoCodeId] = Constant.selectedPromoCodeId;
//     }

//     // Get order charges for self pickup (no delivery charges)
//     await context.read<CheckoutProvider>().getOrderChargesProvider(
//           context: context,
//           params: params,
//         );

//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//         canPop: false,
//         onPopInvokedWithResult: (didPop, _) {
//           if (didPop) {
//             return;
//           } else {
//             if (!context.read<CheckoutProvider>().isPaymentUnderProcessing) {
//               Navigator.pop(context);
//             } else {
//               showMessage(
//                   context,
//                   getTranslatedValue(context, noBackUntilPaymentDoneLabel),
//                   MessageType.warning);
//             }
//           }
//         },
//         child: Scaffold(
//           appBar: getAppBar(
//             context: context,
//             title: CustomTextLabel(
//               jsonKey: checkoutLabel,
//               softWrap: true,
//               style: TextStyle(
//                 color: ColorsRes.mainTextColor,
//               ),
//             ),
//             onTap: () async {
//               if (context.read<CheckoutProvider>().isPaymentUnderProcessing) {
//                 showMessage(
//                     context,
//                     getTranslatedValue(context, noBackUntilPaymentDoneLabel),
//                     MessageType.warning);
//               } else {
//                 Navigator.pop(context);
//               }
//             },
//           ),
//           body: Consumer<CheckoutProvider>(
//             builder: (context, checkoutProvider, _) {
//               return Column(
//                 children: [
//                   Expanded(
//                     child: ListView(
//                       children: [
//                         Container(
//                           decoration: DesignConfig.boxDecoration(
//                               Theme.of(context).cardColor, 10),
//                           padding: const EdgeInsets.all(10),
//                           margin: EdgeInsetsDirectional.only(
//                             start: 10,
//                             end: 10,
//                             top: 10,
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               CustomTextLabel(
//                                 jsonKey: chooseDeliveryMethodLabel,
//                                 style: TextStyle(
//                                   color: ColorsRes.mainTextColor,
//                                   fontSize: 17,
//                                 ),
//                               ),
//                               getSizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: _buildOption(
//                                         value: "0", title: homeDeliveryLabel),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: _buildOption(
//                                         value: "1", title: storePickupLabel),
//                                   ),
//                                 ],
//                               ),
//                               getSizedBox(height: 10),
//                               CustomTextLabel(
//                                 jsonKey: storePickupNoteLabel,
//                                 style: TextStyle(
//                                   color: ColorsRes.grey,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         if (checkoutProvider.deliveryChargeData?.userBalance
//                                     .toString() !=
//                                 "0" &&
//                             checkoutProvider.deliveryChargeData?.userBalance
//                                     .toString() !=
//                                 null)
//                           Container(
//                             decoration: DesignConfig.boxDecoration(
//                                 Theme.of(context).cardColor, 10),
//                             padding: const EdgeInsets.all(10),
//                             margin: EdgeInsetsDirectional.only(
//                               start: 10,
//                               end: 10,
//                               top: 10,
//                             ),
//                             child: Row(
//                               children: [
//                                 defaultImg(
//                                   image: AppAssets.walletIcon,
//                                   iconColor: ColorsRes.appColor,
//                                 ),
//                                 getSizedBox(width: 10),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       CustomTextLabel(
//                                         jsonKey: walletBalanceLabel,
//                                       ),
//                                       CustomTextLabel(
//                                         jsonKey:
//                                             "${context.read<CheckoutProvider>().availableWalletAmount}"
//                                                 .currency,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: TextStyle(
//                                           color: ColorsRes.appColor,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 getSizedBox(width: 10),
//                                 CustomCheckbox(
//                                   value: checkoutProvider.usedWallet ?? false,
//                                   onChanged: (value) {
//                                     checkoutProvider.userWalletAmount(value!);
//                                   },
//                                 ),
//                               ],
//                             ),
//                           ),
//                         if (_selectedMethod == "1" &&
//                             context.read<CheckoutProvider>().sellerSelfPickup !=
//                                 null)
//                           Container(
//                             decoration: DesignConfig.boxDecoration(
//                               Theme.of(context).cardColor,
//                               Constant.size10,
//                               isboarder: false,
//                               bordercolor: ColorsRes.subTitleMainTextColor,
//                             ),
//                             margin: EdgeInsetsDirectional.all(Constant.size10),
//                             padding: EdgeInsetsDirectional.all(Constant.size15),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Icon(
//                                       Icons.store_outlined,
//                                       color: ColorsRes.appColor,
//                                       size: 20,
//                                     ),
//                                     getSizedBox(width: Constant.size8),

//                                     Expanded(
//                                       child: CustomTextLabel(
//                                         jsonKey: pickupFromStoreLabel,
//                                         style: TextStyle(
//                                           color: ColorsRes.mainTextColor,
//                                           fontSize: 17,
//                                         ),
//                                       ),
//                                     ),
//                                     // const Spacer(),
//                                     gradientBtnWidget(
//                                       context,
//                                       Constant.size5,
//                                       callback: () {
//                                         final lat = context
//                                             .read<CheckoutProvider>()
//                                             .sellerSelfPickup
//                                             ?.pickupLatitude;
//                                         final lng = context
//                                             .read<CheckoutProvider>()
//                                             .sellerSelfPickup
//                                             ?.pickupLongitude;
//                                         if (lat != null && lng != null) {
//                                           _openMap(lat, lng);
//                                         }
//                                       },
//                                       height: 35,
//                                       width: 90,
//                                       otherWidgets: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           Icon(
//                                             Icons.directions_outlined,
//                                             color: ColorsRes.mainIconColor,
//                                             size: 14,
//                                           ),
//                                           getSizedBox(width: Constant.size3),
//                                           CustomTextLabel(
//                                             text: getTranslatedValue(
//                                                 context, directionLabel),
//                                             style: TextStyle(
//                                               fontSize: 12,
//                                               color: ColorsRes.mainIconColor,
//                                               fontWeight: FontWeight.w500,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 getDivider(
//                                     color: ColorsRes.subTitleMainTextColor
//                                         .withValues(alpha: 0.15)),
//                                 getSizedBox(height: Constant.size5),
//                                 Row(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Icon(
//                                       Icons.location_on_outlined,
//                                       color: ColorsRes.appColor,
//                                       size: 20,
//                                     ),
//                                     getSizedBox(width: Constant.size8),
//                                     Expanded(
//                                       child: Column(
//                                         mainAxisSize: MainAxisSize.min,
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           CustomTextLabel(
//                                             text:
//                                                 "${context.read<CheckoutProvider>().sellerSelfPickup?.sellerName!.toCapitalized() ?? /* getTranslatedValue(context, "store_name_not_available") */ ""}",
//                                             style: TextStyle(
//                                                 fontSize: 14,
//                                                 color: ColorsRes
//                                                     .subTitleMainTextColor,
//                                                 fontWeight: FontWeight.w700),
//                                             maxLines: 3,
//                                             softWrap: true,
//                                           ),
//                                           CustomTextLabel(
//                                             text:
//                                                 "${context.read<CheckoutProvider>().sellerSelfPickup!.pickupStoreAddress ?? /* getTranslatedValue(context, "address_not_available") */ ""}",
//                                             style: TextStyle(
//                                               fontSize: 14,
//                                               color: ColorsRes
//                                                   .subTitleMainTextColor,
//                                             ),
//                                             maxLines: 3,
//                                             softWrap: true,
//                                             overflow: TextOverflow.ellipsis,
//                                           ),
//                                         ],
//                                       ),
//                                     ), /*
//                                     gradientBtnWidget(
//                                       context,
//                                       Constant.size5,
//                                       callback: () {
//                                         final lat = context.read<CheckoutProvider>().sellerSelfPickup?.pickupLatitude;
//                                         final lng = context.read<CheckoutProvider>().sellerSelfPickup?.pickupLongitude;
//                                         if (lat != null && lng != null) {
//                                           _openMap(lat, lng);
//                                         }
//                                       },
//                                       height: 35,
//                                       width: 90,
//                                       otherWidgets: Row(
//                                         mainAxisAlignment: MainAxisAlignment.center,
//                                         children: [
//                                           Icon(
//                                             Icons.directions_outlined,
//                                             color: ColorsRes.mainIconColor,
//                                             size: 14,
//                                           ),
//                                           getSizedBox(width: Constant.size3),
//                                           CustomTextLabel(
//                                             text: getTranslatedValue(context, directionLabel),
//                                             style: TextStyle(
//                                               fontSize: 12,
//                                               color: ColorsRes.mainIconColor,
//                                               fontWeight: FontWeight.w500,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ), */
//                                   ],
//                                 ),
//                                 getSizedBox(height: Constant.size12),
//                                 Row(
//                                   children: [
//                                     Icon(
//                                       Icons.phone_outlined,
//                                       color: ColorsRes.appColor,
//                                       size: 18,
//                                     ),
//                                     getSizedBox(width: Constant.size8),
//                                     CustomTextLabel(
//                                       text: context
//                                               .read<CheckoutProvider>()
//                                               .sellerSelfPickup
//                                               ?.sellerMobile ?? /*
//                                           getTranslatedValue(context, "phone_not_available") */
//                                           "",
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         color: ColorsRes.subTitleMainTextColor,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 getSizedBox(height: Constant.size12),
//                                 Row(
//                                   children: [
//                                     Icon(
//                                       Icons.access_time_outlined,
//                                       color: ColorsRes.appColor,
//                                       size: 18,
//                                     ),
//                                     getSizedBox(width: Constant.size8),
//                                     CustomTextLabel(
//                                       text:
//                                           "${getTranslatedValue(context, openHoursLabel)}: ${context.read<CheckoutProvider>().sellerSelfPickup?.openingTime ?? "--"} - ${context.read<CheckoutProvider>().sellerSelfPickup?.closingTime ?? "--"}",
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         color: ColorsRes.subTitleMainTextColor,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         if (checkoutProvider.checkoutAddressState ==
//                                 CheckoutAddressState.addressLoading &&
//                             checkoutProvider.checkoutTimeSlotsState ==
//                                 CheckoutTimeSlotsState.timeSlotsLoading &&
//                             context
//                                     .read<PaymentMethodsProvider>()
//                                     .paymentMethodsState ==
//                                 PaymentMethodsState.loading)
//                           CheckoutShimmer(),
//                         if (_selectedMethod == "0" &&
//                             context
//                                     .read<PaymentMethodsProvider>()
//                                     .paymentMethodsState ==
//                                 PaymentMethodsState.loaded &&
//                             (checkoutProvider.checkoutTimeSlotsState ==
//                                     CheckoutTimeSlotsState.timeSlotsLoaded ||
//                                 checkoutProvider.checkoutTimeSlotsState ==
//                                     CheckoutTimeSlotsState.timeSlotsError) &&
//                             (checkoutProvider.checkoutAddressState ==
//                                     CheckoutAddressState.addressLoaded ||
//                                 checkoutProvider.checkoutAddressState ==
//                                     CheckoutAddressState.addressBlank ||
//                                 checkoutProvider.checkoutAddressState ==
//                                     CheckoutAddressState.addressError))
//                           AddressWidget(),
//                         if (context
//                                     .read<PaymentMethodsProvider>()
//                                     .paymentMethodsState ==
//                                 PaymentMethodsState.loaded &&
//                             (checkoutProvider.checkoutTimeSlotsState ==
//                                     CheckoutTimeSlotsState.timeSlotsLoaded ||
//                                 checkoutProvider.checkoutTimeSlotsState ==
//                                     CheckoutTimeSlotsState.timeSlotsError) &&
//                             (checkoutProvider.checkoutAddressState ==
//                                     CheckoutAddressState.addressLoaded ||
//                                 checkoutProvider.checkoutAddressState ==
//                                     CheckoutAddressState.addressBlank ||
//                                 checkoutProvider.checkoutAddressState ==
//                                     CheckoutAddressState.addressError))
//                           Padding(
//                             padding:
//                                 EdgeInsetsDirectional.only(start: 10, end: 10),
//                             child: Column(
//                               children: [
//                                 if (_selectedMethod == "0") GetTimeSlots(),
//                                 OrderNoteWidget(
//                                   edtOrderNote: context
//                                       .read<CheckoutProvider>()
//                                       .edtOrderNote,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         if (checkoutProvider.totalAmount != 0.0
//                         // &&
//                         //     (context
//                         //                 .read<PaymentMethodsProvider>()
//                         //                 .paymentMethodsState ==
//                         //             PaymentMethodsState.loaded &&
//                         //         (checkoutProvider.checkoutTimeSlotsState ==
//                         //                 CheckoutTimeSlotsState
//                         //                     .timeSlotsLoaded ||
//                         //             checkoutProvider.checkoutTimeSlotsState ==
//                         //                 CheckoutTimeSlotsState
//                         //                     .timeSlotsError) &&
//                         //         (checkoutProvider.checkoutAddressState ==
//                         //                 CheckoutAddressState.addressLoaded ||
//                         //             checkoutProvider.checkoutAddressState ==
//                         //                 CheckoutAddressState.addressBlank ||
//                         //             checkoutProvider.checkoutAddressState ==
//                         //                 CheckoutAddressState.addressError))
//                                         )
//                           PaymentMethodsWidget(
//                             isPaymentUnderProcessing:
//                                 checkoutProvider.isPaymentUnderProcessing,
//                           ),
//                         if (context
//                                     .read<PaymentMethodsProvider>()
//                                     .paymentMethodsState ==
//                                 PaymentMethodsState.loaded &&
//                             ((_selectedMethod == "0" &&
//                                     checkoutProvider
//                                             .checkoutDeliveryChargeState ==
//                                         CheckoutDeliveryChargeState
//                                             .deliveryChargeLoaded &&
//                                     (checkoutProvider.checkoutTimeSlotsState ==
//                                             CheckoutTimeSlotsState
//                                                 .timeSlotsLoaded ||
//                                         checkoutProvider
//                                                 .checkoutTimeSlotsState ==
//                                             CheckoutTimeSlotsState
//                                                 .timeSlotsError) &&
//                                     (checkoutProvider.checkoutAddressState ==
//                                             CheckoutAddressState
//                                                 .addressLoaded ||
//                                         checkoutProvider.checkoutAddressState ==
//                                             CheckoutAddressState.addressBlank ||
//                                         checkoutProvider.checkoutAddressState ==
//                                             CheckoutAddressState
//                                                 .addressError) &&
//                                     checkoutProvider.selectedAddress?.id !=
//                                         null) ||
//                                 (_selectedMethod == "1")))
//                           DeliveryChargesWidget(orderType: _selectedMethod),
//                         if (checkoutProvider.checkoutDeliveryChargeState ==
//                             CheckoutDeliveryChargeState.deliveryChargeLoading)
//                           DeliveryChargeShimmer(),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsetsDirectional.only(
//                       start: 15,
//                       end: 15,
//                       bottom: 10,
//                       top: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).cardColor,
//                     ),
//                     child: Row(
//                       children: [
//                         Column(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             CustomTextLabel(
//                               jsonKey: totalLabel,
//                               softWrap: true,
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: ColorsRes.mainTextColor,
//                               ),
//                             ),
//                             getSizedBox(width: 10),
//                             CustomTextLabel(
//                               text: context
//                                           .read<CheckoutProvider>()
//                                           .totalAmount ==
//                                       0.0
//                                   ? widget.total.toString().currency
//                                   : context
//                                       .read<CheckoutProvider>()
//                                       .totalAmount
//                                       .toString()
//                                       .currency, //context.read<CheckoutProvider>().totalAmount.toString().currency,
//                               softWrap: true,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: ColorsRes.appColor,
//                               ),
//                             ),
//                           ],
//                         ),
//                         Spacer(),
//                         PlaceOrderButtonWidget(
//                           context: context,
//                           selectedMethod: _selectedMethod,
//                         ),
//                       ],
//                     ),
//                   )
//                 ],
//               );
//             },
//           ),
//         ));
//   }
// }

class _PaymentProcessingIndicator extends StatefulWidget {
  const _PaymentProcessingIndicator({Key? key}) : super(key: key);

  @override
  State<_PaymentProcessingIndicator> createState() =>
      _PaymentProcessingIndicatorState();
}

class _PaymentProcessingIndicatorState
    extends State<_PaymentProcessingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF9AC444)
                          .withValues(alpha: _opacityAnimation.value),
                      Color(0xFF7FA636)
                          .withValues(alpha: _opacityAnimation.value),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF9AC444)
                          .withValues(alpha: 0.3 * _opacityAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.payment_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              getTranslatedValue(context, 'processing_payment_indicator'),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF9AC444),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
