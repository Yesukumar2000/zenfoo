import 'package:project/helper/styles/product_card_metrics.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/combo.dart';
import 'package:project/provider/comboDetailProvider.dart';
import 'package:project/provider/similarFromCartProvider.dart';
import 'package:project/helper/utils/storeHoursService.dart';
import 'package:project/screens/categoryProducts/widgets/product_card.dart';
import 'package:project/screens/cartListScreen/widgets/admin_store_closed_dialog.dart';
import 'package:project/screens/cartListScreen/widgets/seller_offline_dialog.dart';
import 'package:project/screens/cartListScreen/widgets/wallet_amount_bottom_sheet.dart';
import 'package:project/screens/combos/comboDetailScreen.dart';
import 'package:project/screens/checkoutScreen/widget/bikeAnimationWidget.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/supermartDetail/supermart_detail_screen.dart';
import 'package:project/screens/mainHomeScreen/categories_page.dart';
import 'package:project/screens/sweetHouseDetail/sweet_house_detail_screen.dart';
import 'package:velocity_x/velocity_x.dart';

class CartListScreen extends StatefulWidget {
  const CartListScreen({Key? key}) : super(key: key);
  @override
  State<CartListScreen> createState() => _CartListScreenState();
}

class _CartListScreenState extends State<CartListScreen> {
  Timer? _noteSaveDebounce;
  Map<String, Timer?> _sellerNoteDebounce =
      {}; // Track debounce timers per seller
  final TextEditingController _tipController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Constant.isPromoCodeApplied = false;
    Constant.selectedCoupon = "";
    Constant.discountedAmount = 0.0;
    Constant.discount = 0.0;
    Constant.selectedPromoCodeId = "0";

    Future.delayed(Duration.zero).then((value) async {
      callApi();
    });
  }

  callApi() async {
    if (Constant.session.isUserLoggedIn()) {
      await context.read<CartProvider>().getCartListProvider(context: context);

      final combos =
          context.read<CartProvider>().cartData?.data.customCombos ?? [];
      if (combos.isNotEmpty) {
        context.read<ComboDetailProvider>().initFromCartCombos(combos);
      }

      // Fetch similar products from cart
      context.read<SimilarFromCartProvider>().fetchSimilarProducts(
            context: context,
          );
    } else {
      if (context.read<CartListProvider>().cartList.isNotEmpty) {
        await context
            .read<CartProvider>()
            .getGuestCartListProvider(context: context);
      }
    }
  }

  /// True when a usable delivery location is already stored in the session.
  bool _hasDeliveryLocation() {
    final address = Constant.session.getData(SessionManager.keyAddress);
    final latitude =
        double.tryParse(Constant.session.getData(SessionManager.keyLatitude));
    final longitude =
        double.tryParse(Constant.session.getData(SessionManager.keyLongitude));

    if (address.isEmpty || address == "null") return false;
    if (latitude == null || longitude == null) return false;
    if (latitude == 0 && longitude == 0) return false;

    return true;
  }

  /// Opens the map location screen directly (no "please select address"
  /// message), and on confirm refreshes the cart so delivery charges match the
  /// new location. Returns false if the user came back without confirming.
  Future<bool> _askDeliveryLocation() async {
    final result = await Navigator.pushNamed(
      context,
      confirmLocationScreen,
      arguments: [null, "cart"],
    );

    if (result != true || !mounted) return false;

    await context.read<CartProvider>().refreshCart(
          context: context,
          silent: true,
        );
    if (mounted) setState(() {});
    return true;
  }

  /// The checkout API blocks the order when the account has no saved delivery
  /// address. That case gets the address sheet instead of a warning message.
  bool _isMissingAddressError(String message) {
    return message.toLowerCase().contains('address');
  }

  /// Opens the "Select Delivery Address" sheet directly (no "please select a
  /// delivery address" message) and refreshes the cart with the chosen address.
  /// Returns false when the user closed the sheet without picking one.
  Future<bool> _askDeliveryAddress() async {
    final selected = await showAddressesBottomSheet(context);
    if (selected == null || !mounted) return false;

    if (selected is UserAddressData) {
      await _markAddressAsDefault(selected);
      if (!mounted) return false;
    }

    await context.read<CartProvider>().refreshCart(
          context: context,
          silent: true,
        );
    if (mounted) setState(() {});
    return true;
  }

  /// The order is delivered to whichever saved address is flagged default, so
  /// the picked one has to become the default — otherwise the cart shows one
  /// address and the order ships to another. The sheet only writes to session.
  Future<void> _markAddressAsDefault(UserAddressData address) async {
    // "Current Location" is a session-only address with no saved row.
    if (address.id == null || address.id == "0") return;

    try {
      await updateAddressApi(
        context: context,
        params: {
          ApiAndParams.id: address.id,
          ApiAndParams.name: address.name,
          ApiAndParams.mobile: address.mobile,
          ApiAndParams.alternateMobile: address.alternateMobile ?? "",
          ApiAndParams.address: address.address,
          ApiAndParams.landmark: address.landmark ?? "",
          ApiAndParams.area: address.area ?? "",
          ApiAndParams.pinCode: address.pincode,
          ApiAndParams.city: address.city,
          ApiAndParams.state: address.state,
          ApiAndParams.country: address.country,
          ApiAndParams.latitude: address.latitude,
          ApiAndParams.longitude: address.longitude,
          ApiAndParams.type: address.type,
          ApiAndParams.isDefault: "1",
        },
      );
    } catch (e) {
      // Non-fatal: the checkout validation below reports the real problem.
      debugPrint('Failed to set default address: $e');
    }
  }

  /// Save order note locally - it will be sent to API at checkout
  void _saveOrderNote(String note) {
    context.read<CartProvider>().setOrderNote(note);
  }

  void _saveSellerNote(String sellerId, String note) {
    // Cancel previous timer for this seller if exists
    _sellerNoteDebounce[sellerId]?.cancel();

    // If note is empty, don't save to API
    if (note.trim().isEmpty) {
      return;
    }

    // Set a new timer to save after user stops typing (1.5 seconds)
    _sellerNoteDebounce[sellerId] =
        Timer(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;

      try {
        final cartProvider = context.read<CartProvider>();

        // Save using exact same method as cart_notes_bottom_sheet
        final success = await cartProvider.saveCartMetadata(
          context: context,
          sellerId: int.tryParse(sellerId),
          sellerNote: note.trim(),
        );

        if (success) {
          debugPrint('Seller note saved successfully for seller $sellerId');
        } else {
          if (mounted) {
            final colorScheme =
                context.read<app_theme.ThemeProvider>().colorScheme;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to save note. Please try again.'),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error saving seller note: $e');
        if (mounted) {
          final colorScheme =
              context.read<app_theme.ThemeProvider>().colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save note. Please try again.'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    });
  }

  @override
  dispose() {
    _noteSaveDebounce?.cancel();
    _tipController.dispose();
    // Cancel all seller note debounce timers
    for (var timer in _sellerNoteDebounce.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
        backgroundColor: colorScheme.background,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: btnWidget(),
          ),
        ),
        resizeToAvoidBottomInset: true,
        body:
            // (context.read<CartProvider>().cartState == CartState.error)
            //     ?
            cartWidget()
        // : Container(
        //     alignment: Alignment.center,
        //     height: context.height,
        //     width: context.width,
        //     child: DefaultBlankItemMessageScreen(
        //       image: "cart_empty",
        //       title: emptyCartListMessageLabel,
        //       description: emptyCartListDescriptionLabel,
        //       buttonTitle: emptyCartListButtonNameLabel,
        //       callback: () {
        //         context
        //             .read<HomeMainScreenProvider>()
        //             .selectBottomMenu(0)
        //             .then(
        //               (value) => Navigator.of(context).popUntil(
        //                 (Route<dynamic> route) => route.isFirst,
        //               ),
        //             );
        //       },
        //     ),
        //   ),
        );
  }

  btnWidget() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListenableBuilder(
        listenable: StoreHoursService(),
        builder: (context, _) {
          final isStoreClosed =
              StoreHoursService().isLoaded && !StoreHoursService().isStoreOpen;
          final cartProv = context.read<CartProvider>();
          final hasAdminItems = cartProv.hasAdminManagedItems();
          final hasNonAdminItems = cartProv.hasNonAdminCartItems();
          // Only fully block if store closed AND no non-admin items to order
          final isFullyBlocked =
              isStoreClosed && hasAdminItems && !hasNonAdminItems;

          return ElevatedButton(
            onPressed: () async {
              // Check for offline sellers
              final shopStatus = cartProv.cartData?.data.shopStatusCheck;
              if (shopStatus != null &&
                  !shopStatus.allSellersOnline &&
                  shopStatus.offlineProducts.isNotEmpty) {
                // Find matching CartItem objects for product details
                final allCartItems = <CartItem>[
                  ...cartProv.cartData?.data.adminManagedStore.items ?? [],
                  ...cartProv.cartData?.data.groupedBySeller
                          .expand((g) => g.items) ??
                      [],
                ];
                final offlineCartItems = shopStatus.offlineProducts
                    .map((op) => allCartItems.cast<CartItem?>().firstWhere(
                          (ci) => ci?.productId == op.productId,
                          orElse: () => null,
                        ))
                    .whereType<CartItem>()
                    .toList();

                final confirmed = await showSellerOfflineDialog(
                  context: context,
                  offlineProducts: shopStatus.offlineProducts,
                  offlineCartItems: offlineCartItems,
                  message: shopStatus.message,
                );
                if (!confirmed) return;

                // Show loading & remove offline products
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => Center(child: CircularProgressIndicator()),
                );
                final hasRemaining =
                    await cartProv.removeOfflineProducts(context: context);
                Navigator.of(context).pop();

                if (!hasRemaining) {
                  showMessage(
                      context, "Your cart is now empty", MessageType.warning);
                  return;
                }
              }

              if (isStoreClosed && hasAdminItems) {
                if (!hasNonAdminItems) {
                  // Only admin items — fully blocked
                  showMessage(
                      context,
                      "${getTranslatedValue(context, 'store_closed')}. ${getTranslatedValue(context, 'will_open_at')} ${StoreHoursService().formattedOpeningTime}",
                      MessageType.warning);
                  return;
                }

                // Mixed cart: show popup to remove admin items
                final confirmed = await showAdminStoreClosedDialog(
                  context: context,
                  adminManagedItems: cartProv.getAdminManagedItems(),
                );
                if (!confirmed) return;

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => Center(child: CircularProgressIndicator()),
                );
                final hasRemaining =
                    await cartProv.removeAdminManagedItems(context: context);
                Navigator.of(context).pop(); // dismiss loading

                if (!hasRemaining) {
                  showMessage(
                      context, "Your cart is now empty", MessageType.warning);
                  return;
                }
              }

              // Normal checkout flow
              if (await context
                      .read<CartProvider>()
                      .checkCartItemsStockStatus() ==
                  false) {
                if (Constant.session.isUserLoggedIn()) {
                  // No delivery location picked yet — send the user straight to
                  // the location screen, then continue this same flow on return.
                  if (!_hasDeliveryLocation()) {
                    final picked = await _askDeliveryLocation();
                    if (!picked || !mounted) return;
                  }

                  // Validate checkout via API before proceeding. If it fails
                  // only because no delivery address is saved, open the address
                  // sheet and retry once instead of showing a message.
                  bool validated = false;
                  for (int attempt = 0; attempt < 2 && !validated; attempt++) {
                    late final Map<String, dynamic> checkoutResponse;
                    try {
                      checkoutResponse = await getCartListApi(
                        context: context,
                        params: {
                          ApiAndParams.latitude: Constant.session
                              .getData(SessionManager.keyLatitude),
                          ApiAndParams.longitude: Constant.session
                              .getData(SessionManager.keyLongitude),
                          "is_checkout": "1",
                        },
                      );
                    } catch (e) {
                      showMessage(
                          context, 'Something went wrong', MessageType.error);
                      return;
                    }

                    if (checkoutResponse['status'] != 0) {
                      validated = true;
                      break;
                    }

                    final message =
                        checkoutResponse['message']?.toString() ?? '';

                    if (attempt == 0 && _isMissingAddressError(message)) {
                      final picked = await _askDeliveryAddress();
                      if (!picked || !mounted) return;
                      continue;
                    }

                    showMessage(
                        context,
                        message.isEmpty ? 'Cannot proceed' : message,
                        MessageType.warning);
                    return;
                  }

                  if (!validated || !mounted) return;

                  Navigator.pushNamed(context, checkoutScreen, arguments: [
                    context.read<CartProvider>().selfPickupMode,
                    context.read<CartProvider>().subTotal.toString()
                  ]);
                } else {
                  Navigator.pushNamed(context, loginAccountScreen,
                          arguments: "add_to_cart_register")
                      .then(
                    (value) => callApi(),
                  );
                }
              } else {
                showMessage(
                    context,
                    getTranslatedValue(context, removeSoldOutItemsLabel),
                    MessageType.warning);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isFullyBlocked
                  ? const Color(0xFFE53E3E)
                  : colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isFullyBlocked) ...[
                  Icon(
                    Icons.storefront_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "${getTranslatedValue(context, 'store_closed')} · ${getTranslatedValue(context, 'will_open_at')} ${StoreHoursService().formattedOpeningTime}",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        letterSpacing: -0.3,
                        fontWeight: FontWeight.w700,
                        height: 1.02,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  CustomTextLabel(
                    jsonKey: Constant.session.isUserLoggedIn()
                        ? proceedToCheckoutLabel
                        : loginToCheckoutLabel,
                    softWrap: true,
                    style: GoogleFonts.inter(
                      color: colorScheme.buttonPrimaryText,
                      fontSize: 17,
                      letterSpacing: -0.55,
                      fontWeight: FontWeight.w700,
                      height: 1.02,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colorScheme.buttonPrimaryText,
                    size: 22,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget cartWidget() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        // final cartList = cartProvider.cartData.data.getAllCartItems();
        return (cartProvider.cartState == CartState.initial ||
                cartProvider.cartState == CartState.loading)
            ? getCartListShimmer(context: context)
            : RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<CartListProvider>()
                      .getAllCartItems(context: context);
                  await callApi();
                },
                child: NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    final colorScheme =
                        context.watch<app_theme.ThemeProvider>().colorScheme;

                    return [
                      SliverAppBar(
                        pinned: true,
                        floating: true,
                        elevation: 0,
                        automaticallyImplyLeading: false,
                        toolbarHeight: 70,
                        backgroundColor: Colors.transparent,
                        flexibleSpace: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colorScheme.primary,
                                colorScheme.background,
                              ],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colorScheme.textPrimary
                                            .withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: colorScheme.textPrimary
                                              .withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: colorScheme.textPrimary,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        await showAddressesBottomSheet(context);
                                        // Refresh cart to update delivery charges with new address
                                        if (mounted) {
                                          await context
                                              .read<CartProvider>()
                                              .refreshCart(
                                                context: context,
                                                silent: true,
                                              );
                                        }
                                        setState(() {});
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                getTranslatedValue(context,
                                                        'delivery_to_prefix')
                                                    .replaceAll(
                                                        '{address}',
                                                        Constant.session
                                                            .getData(SessionManager
                                                                .keyAddressObject)
                                                            .toString()),
                                                style: GoogleFonts.inter(
                                                  color: colorScheme.textPrimary
                                                      .withValues(alpha: 0.9),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.2,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                color: colorScheme.textPrimary
                                                    .withValues(alpha: 0.9),
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            Constant.session.getData(
                                                    SessionManager
                                                        .keyAddress) ??
                                                getTranslatedValue(
                                                    context, 'select_address'),
                                            style: GoogleFonts.inter(
                                              color: colorScheme.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              height: 1.02,
                                              letterSpacing: -0.55,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: Builder(
                    builder: (context) {
                      final colorScheme =
                          context.watch<app_theme.ThemeProvider>().colorScheme;

                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.all(8),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate(
                                [
                                  Column(
                                    children: [
                                      // Savings Banner
                                      if (cartProvider.getTotalSavings() > 0)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 12),
                                          child: Container(
                                            width: double.infinity,
                                            height: 62,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 14),
                                            clipBehavior: Clip.antiAlias,
                                            decoration: ShapeDecoration(
                                              color: const Color(0xFFE3F6E8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              shadows: [
                                                BoxShadow(
                                                  color:
                                                      const Color(0x21000000),
                                                  blurRadius: 22,
                                                  offset: const Offset(0, 0),
                                                  spreadRadius: 0,
                                                )
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  clipBehavior: Clip.antiAlias,
                                                  decoration: BoxDecoration(),
                                                  child: Icon(
                                                    Icons.verified,
                                                    color:
                                                        const Color(0xFF28A745),
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'You saved ₹${cartProvider.getTotalSavings().toStringAsFixed(0)}',
                                                  style: GoogleFonts.inter(
                                                    color:
                                                        const Color(0xFF28A745),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      // Admin Managed Store Items
                                      if (cartProvider
                                          .getAdminManagedItems()
                                          .isNotEmpty) ...[
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                colorScheme.surface,
                                                colorScheme.surface,
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: colorScheme.border,
                                              width: 1,
                                            ),
                                            boxShadow: colorScheme.cardShadow,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Header with Icon
                                              Container(
                                                padding: EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary
                                                      .withValues(alpha: 0.08),
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(16),
                                                    topRight:
                                                        Radius.circular(16),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // Container(
                                                    //   width: 36,
                                                    //   height: 36,
                                                    //   decoration: BoxDecoration(
                                                    //     gradient: LinearGradient(
                                                    //       begin: Alignment.topLeft,
                                                    //       end: Alignment.bottomRight,
                                                    //       colors: [
                                                    //         Color(0xFF9AC444),
                                                    //         Color(0xFF8AB338),
                                                    //       ],
                                                    //     ),
                                                    //     borderRadius:
                                                    //         BorderRadius.circular(10),
                                                    //     boxShadow: [
                                                    //       BoxShadow(
                                                    //         color: Color(0x269AC444),
                                                    //         blurRadius: 8,
                                                    //         offset: Offset(0, 3),
                                                    //       ),
                                                    //     ],
                                                    //   ),
                                                    //   child: Icon(
                                                    //     Icons.store_outlined,
                                                    //     color: Colors.white,
                                                    //     size: 20,
                                                    //   ),
                                                    // ),
                                                    // SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            getTranslatedValue(
                                                                context,
                                                                'store_items'),
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: colorScheme
                                                                  .textPrimary,
                                                              letterSpacing:
                                                                  -0.55,
                                                              height: 1.02,
                                                            ),
                                                          ),
                                                          SizedBox(height: 2),
                                                          Text(
                                                            '${cartProvider.getAdminManagedItems().length} ${getTranslatedValue(context, 'product_${cartProvider.getAdminManagedItems().length > 1 ? 'plural' : 'singular'}')}',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: colorScheme
                                                                  .textSecondary,
                                                              letterSpacing:
                                                                  -0.55,
                                                              height: 1.02,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Add Items Button
                                                    GestureDetector(
                                                      onTap: () async {
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                CategoriesPage(
                                                              scrollController:
                                                                  ScrollController(),
                                                            ),
                                                          ),
                                                        );
                                                        if (mounted) {
                                                          await context
                                                              .read<
                                                                  CartProvider>()
                                                              .refreshCart(
                                                                context:
                                                                    context,
                                                                silent: true,
                                                              );
                                                        }
                                                      },
                                                      child: Container(
                                                        // width: 86,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 6,
                                                        ),
                                                        clipBehavior:
                                                            Clip.antiAlias,
                                                        decoration:
                                                            ShapeDecoration(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            side:
                                                                const BorderSide(
                                                              width: 1,
                                                              strokeAlign:
                                                                  BorderSide
                                                                      .strokeAlignOutside,
                                                              color: Color(
                                                                  0xFF9E9E9E),
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              getTranslatedValue(
                                                                  context,
                                                                  addItemsLabel),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: GoogleFonts
                                                                  .inter(
                                                                color: const Color(
                                                                    0xFF9E9F9F),
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                height: 0.68,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    // Container(
                                                    //   padding: EdgeInsets.symmetric(
                                                    //       horizontal: 10,
                                                    //       vertical: 5),
                                                    //   decoration: BoxDecoration(
                                                    //     color: Color(0xFF9AC444),
                                                    //     borderRadius:
                                                    //         BorderRadius.circular(8),
                                                    //   ),
                                                    //   child: Text(
                                                    //     'Official',
                                                    //     style: GoogleFonts.inter(
                                                    //       fontSize: 11,
                                                    //       fontWeight: FontWeight.w700,
                                                    //       color: Colors.white,
                                                    //       letterSpacing: -0.55,
                                                    //       height: 1.02,
                                                    //     ),
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
                                              ),
                                              // Items List
                                              Padding(
                                                padding: EdgeInsets.fromLTRB(
                                                    12, 12, 12, 16),
                                                child: ListView.separated(
                                                  padding: EdgeInsets.zero,
                                                  itemCount: cartProvider
                                                      .getAdminManagedItems()
                                                      .length,
                                                  shrinkWrap: true,
                                                  physics:
                                                      NeverScrollableScrollPhysics(),
                                                  separatorBuilder: (_, __) =>
                                                      Column(
                                                    children: [
                                                      SizedBox(height: 12),
                                                      Divider(
                                                        color:
                                                            colorScheme.border,
                                                        height: 1,
                                                        thickness: 1,
                                                      ),
                                                      SizedBox(height: 12),
                                                    ],
                                                  ),
                                                  itemBuilder: (context, idx) {
                                                    CartItem cart = cartProvider
                                                            .getAdminManagedItems()[
                                                        idx];
                                                    return CartListItemContainerProvider(
                                                      key: ValueKey(cart
                                                              .productId +
                                                          cart.productVariantId),
                                                      cart: cart,
                                                      from: 'cartList',
                                                    );
                                                  },
                                                ),
                                              ),
                                              // Notes Input Field for admin store
                                              SizedBox(height: 12),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 12),
                                                child: CustomTextFormField(
                                                  title: getTranslatedValue(
                                                      context,
                                                      'special_instruction'),
                                                  hintText: getTranslatedValue(
                                                      context,
                                                      'add_notes_for_store'),
                                                  initialValue:
                                                      cartProvider.orderNote,
                                                  maxLines: 2,
                                                  prefixIcon: Icon(
                                                    Icons.edit_note_rounded,
                                                    size: 20,
                                                  ),
                                                  onChanged: (value) {
                                                    // Save order note with debounce
                                                    _saveOrderNote(value);
                                                  },
                                                ),
                                              ),
                                              SizedBox(height: 12),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                      ],

                                      // Seller Grouped Items
                                      ...cartProvider
                                          .getSellerGroups()
                                          .map((sellerGroup) {
                                        return Column(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    colorScheme.surface,
                                                    colorScheme.surface,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: colorScheme.border,
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(0x0A000000),
                                                    blurRadius: 24,
                                                    offset: Offset(0, 4),
                                                    spreadRadius: 0,
                                                  ),
                                                  BoxShadow(
                                                    color: Color(0x05000000),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                    spreadRadius: 0,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Seller Header
                                                  Container(
                                                    padding: EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment
                                                            .centerLeft,
                                                        end: Alignment
                                                            .centerRight,
                                                        colors: [
                                                          colorScheme.surface,
                                                          colorScheme.surface,
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(16),
                                                        topRight:
                                                            Radius.circular(16),
                                                      ),
                                                      border: Border(
                                                        bottom: BorderSide(
                                                          color: colorScheme
                                                              .border,
                                                          width: 1,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        // Seller Avatar
                                                        // Container(
                                                        //   width: 40,
                                                        //   height: 40,
                                                        //   decoration: BoxDecoration(
                                                        //     gradient: LinearGradient(
                                                        //       begin:
                                                        //           Alignment.topLeft,
                                                        //       end: Alignment
                                                        //           .bottomRight,
                                                        //       colors: [
                                                        //         Color(0xFF6B7280),
                                                        //         Color(0xFF4B5563),
                                                        //       ],
                                                        //     ),
                                                        //     borderRadius:
                                                        //         BorderRadius.circular(
                                                        //             12),
                                                        //     boxShadow: [
                                                        //       BoxShadow(
                                                        //         color:
                                                        //             Color(0x1A000000),
                                                        //         blurRadius: 8,
                                                        //         offset: Offset(0, 3),
                                                        //       ),
                                                        //     ],
                                                        //   ),
                                                        //   child: Center(
                                                        //     child: Text(
                                                        //       sellerGroup.sellerName
                                                        //               .isNotEmpty
                                                        //           ? sellerGroup
                                                        //               .sellerName[0]
                                                        //               .toUpperCase()
                                                        //           : 'S',
                                                        //       style:
                                                        //           GoogleFonts.inter(
                                                        //         fontSize: 18,
                                                        //         fontWeight:
                                                        //             FontWeight.w700,
                                                        //         color: Colors.white,
                                                        //         letterSpacing: -0.55,
                                                        //       ),
                                                        //     ),
                                                        //   ),
                                                        // ),
                                                        // SizedBox(width: 12),
                                                        // Seller Info
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Flexible(
                                                                    child: Text(
                                                                      sellerGroup
                                                                          .storeName,
                                                                      style: GoogleFonts
                                                                          .inter(
                                                                        fontSize:
                                                                            15,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        color: colorScheme
                                                                            .textPrimary,
                                                                        letterSpacing:
                                                                            -0.3,
                                                                        height:
                                                                            1.3,
                                                                      ),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      width: 6),
                                                                  Container(
                                                                    width: 16,
                                                                    height: 16,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: colorScheme
                                                                          .primary,
                                                                      shape: BoxShape
                                                                          .circle,
                                                                    ),
                                                                    child: Icon(
                                                                      Icons
                                                                          .verified,
                                                                      color: colorScheme
                                                                          .buttonPrimaryText,
                                                                      size: 10,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                  height: 3),
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .inventory_2_outlined,
                                                                    size: 12,
                                                                    color: colorScheme
                                                                        .iconSecondary,
                                                                  ),
                                                                  SizedBox(
                                                                      width: 4),
                                                                  Text(
                                                                    '${sellerGroup.items.length} ${getTranslatedValue(context, sellerGroup.items.length > 1 ? 'product_plural' : 'product_singular')}',
                                                                    style: GoogleFonts
                                                                        .inter(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color: colorScheme
                                                                          .textSecondary,
                                                                      letterSpacing:
                                                                          -0.1,
                                                                      height:
                                                                          1.3,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        // Add Items Button
                                                        InkWell(
                                                          onTap: () {
                                                            Navigator.pop(
                                                                context);
                                                            if (sellerGroup
                                                                .isSuperMart) {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          SupermartDetailScreen(
                                                                    sellerId: int
                                                                        .parse(
                                                                      sellerGroup
                                                                          .sellerId,
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            } else {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          SweetHouseDetailScreen(
                                                                    sellerId:
                                                                        sellerGroup
                                                                            .sellerId,
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          child: Container(
                                                            // width: 86,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 8,
                                                              vertical: 6,
                                                            ),
                                                            clipBehavior:
                                                                Clip.antiAlias,
                                                            decoration:
                                                                ShapeDecoration(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                side:
                                                                    const BorderSide(
                                                                  width: 1,
                                                                  strokeAlign:
                                                                      BorderSide
                                                                          .strokeAlignOutside,
                                                                  color: Color(
                                                                      0xFF9E9E9E),
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Text(
                                                                  getTranslatedValue(
                                                                      context,
                                                                      addItemsLabel),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    color: const Color(
                                                                        0xFF9E9F9F),
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    height:
                                                                        0.68,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Seller Items
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            12, 12, 12, 16),
                                                    child: ListView.separated(
                                                      padding: EdgeInsets.zero,
                                                      itemCount: sellerGroup
                                                          .items.length,
                                                      shrinkWrap: true,
                                                      physics:
                                                          NeverScrollableScrollPhysics(),
                                                      separatorBuilder:
                                                          (_, __) => Column(
                                                        children: [
                                                          SizedBox(height: 12),
                                                          Divider(
                                                            color: colorScheme
                                                                .border,
                                                            height: 1,
                                                            thickness: 1,
                                                          ),
                                                          SizedBox(height: 12),
                                                        ],
                                                      ),
                                                      itemBuilder:
                                                          (context, idx) {
                                                        CartItem cart =
                                                            sellerGroup
                                                                .items[idx];
                                                        return CartListItemContainerProvider(
                                                          key: ValueKey(cart
                                                                  .productId +
                                                              cart.productVariantId),
                                                          cart: cart,
                                                          from: 'cartList',
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  // Notes Section for this seller/store
                                                  SizedBox(height: 12),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 12),
                                                    child: CustomTextFormField(
                                                      title: getTranslatedValue(
                                                          context,
                                                          'special_instruction'),
                                                      hintText: getTranslatedValue(
                                                          context,
                                                          'add_notes_for_store'),
                                                      initialValue: cartProvider
                                                                  .cartData
                                                                  ?.data
                                                                  .cartMetadata
                                                                  .sellerNotes[
                                                              sellerGroup
                                                                  .sellerId] ??
                                                          '',
                                                      maxLines: 2,
                                                      prefixIcon: Icon(
                                                        Icons.edit_note_rounded,
                                                        size: 20,
                                                      ),
                                                      onChanged: (value) {
                                                        // Save seller note with debounce
                                                        _saveSellerNote(
                                                            sellerGroup
                                                                .sellerId,
                                                            value);
                                                      },
                                                    ),
                                                  ),
                                                  SizedBox(height: 12),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                          ],
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                  SizedBox(height: 12),

                                  if (cartProvider.cartData?.data.customCombos
                                          .isNotEmpty ??
                                      false)
                                    CartComboSection(
                                      combos: cartProvider
                                          .cartData!.data.customCombos,
                                      comboProvider:
                                          context.read<ComboDetailProvider>(),
                                    ),

                                  // Similar Products Section
                                  Consumer<SimilarFromCartProvider>(
                                    builder: (context, similarProvider, _) {
                                      if (similarProvider.state !=
                                              SimilarFromCartState.loaded ||
                                          similarProvider.products.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return Container(
                                        width: double.infinity,
                                        margin: EdgeInsets.only(bottom: 12),
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surface,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: colorScheme.border,
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0x0A000000),
                                              blurRadius: 24,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20),
                                              child: Text(
                                                getTranslatedValue(context,
                                                    'add_similar_items'),
                                                style: GoogleFonts.inter(
                                                  color:
                                                      colorScheme.textPrimary,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.02,
                                                  letterSpacing: -0.55,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            SizedBox(
                                              height: productCardExtent,
                                              child: ListView.builder(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16),
                                                itemCount: similarProvider
                                                    .products.length,
                                                itemBuilder: (context, index) {
                                                  return SizedBox(
                                                    width: productRailCardWidth,
                                                    child: MiniProductCardContainer(
                                                      product: similarProvider
                                                          .products[index],
                                                      disableHero: true,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                  // Coupons Section
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          colorScheme.surface,
                                          colorScheme.surface,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: colorScheme.border,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x0A000000),
                                          blurRadius: 24,
                                          offset: Offset(0, 4),
                                          spreadRadius: 0,
                                        ),
                                        BoxShadow(
                                          color: Color(0x05000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getTranslatedValue(
                                              context, 'coupons_label'),
                                          style: GoogleFonts.inter(
                                            color: colorScheme.textPrimary,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            height: 1.02,
                                            letterSpacing: -0.55,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        GestureDetector(
                                          onTap: () async {
                                            final result =
                                                await Navigator.pushNamed(
                                              context,
                                              promoCodeScreen,
                                              arguments: context
                                                  .read<CartProvider>()
                                                  .subTotal,
                                            );

                                            // Refresh cart when coming back from coupon screen
                                            if (result != null && mounted) {
                                              await context
                                                  .read<CartProvider>()
                                                  .refreshCart(
                                                    context: context,
                                                    silent: true,
                                                  );
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 14),
                                            decoration: BoxDecoration(
                                              color:
                                                  colorScheme.inputBackground,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: colorScheme.border,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    Icons.local_offer_outlined,
                                                    color: colorScheme.primary,
                                                    size: 20,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    getTranslatedValue(context,
                                                        'apply_coupons'),
                                                    style: GoogleFonts.inter(
                                                      color: colorScheme
                                                          .textPrimary,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      height: 1.02,
                                                      letterSpacing: -0.55,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  color:
                                                      colorScheme.iconSecondary,
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (Constant.isPromoCodeApplied) ...[
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 16),
                                            height: 1,
                                            color: colorScheme.border,
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: colorScheme.primary
                                                          .withValues(
                                                              alpha: 0.15),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.check_rounded,
                                                  color: colorScheme
                                                      .buttonPrimaryText,
                                                  size: 16,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  '₹${Constant.discount.toStringAsFixed(0)} saved with ${Constant.selectedCoupon.toString() ?? "coupon"}',
                                                  style: GoogleFonts.inter(
                                                    color:
                                                        colorScheme.textPrimary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.02,
                                                    letterSpacing: -0.55,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: colorScheme.primary
                                                          .withValues(
                                                              alpha: 0.15),
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  'Applied',
                                                  style: GoogleFonts.inter(
                                                    color: colorScheme
                                                        .buttonPrimaryText,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.02,
                                                    letterSpacing: -0.55,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),

                                  // Delivery Instructions Section
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          colorScheme.surface,
                                          colorScheme.surface,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: colorScheme.border,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x0A000000),
                                          blurRadius: 24,
                                          offset: Offset(0, 4),
                                          spreadRadius: 0,
                                        ),
                                        BoxShadow(
                                          color: Color(0x05000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                getTranslatedValue(context,
                                                    'delivery_instruction'),
                                                style: GoogleFonts.inter(
                                                  color:
                                                      colorScheme.textPrimary,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.02,
                                                  letterSpacing: -0.55,
                                                ),
                                              ),
                                            ),
                                            if (context
                                                .watch<CartProvider>()
                                                .selectedInstructions
                                                .isNotEmpty)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${context.watch<CartProvider>().selectedInstructions.length} selected',
                                                  style: GoogleFonts.inter(
                                                    color: colorScheme
                                                        .buttonPrimaryText,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: -0.55,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              _buildSelectableInstructionChip(
                                                getTranslatedValue(context,
                                                    'delivery_directions'),
                                                Icons.navigation_outlined,
                                                context,
                                              ),
                                              SizedBox(width: 10),
                                              _buildSelectableInstructionChip(
                                                getTranslatedValue(
                                                    context, 'leave_at_door'),
                                                Icons.door_front_door_outlined,
                                                context,
                                              ),
                                              SizedBox(width: 10),
                                              _buildSelectableInstructionChip(
                                                getTranslatedValue(
                                                    context, 'avoid_calling'),
                                                Icons.phone_disabled_outlined,
                                                context,
                                              ),
                                              SizedBox(width: 10),
                                              _buildSelectableInstructionChip(
                                                getTranslatedValue(
                                                    context, 'beware_of_pets'),
                                                Icons.pets_outlined,
                                                context,
                                              ),
                                              SizedBox(width: 10),
                                              _buildSelectableInstructionChip(
                                                getTranslatedValue(context,
                                                    'leave_with_security'),
                                                Icons.security_outlined,
                                                context,
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Show directions input only if "Directions to reach" is selected
                                        if (context
                                            .watch<CartProvider>()
                                            .isInstructionSelected(
                                                getTranslatedValue(context,
                                                    'delivery_directions'))) ...[
                                          SizedBox(height: 16),
                                          CustomTextFormField(
                                            hintText: getTranslatedValue(
                                                context,
                                                'directions_placeholder'),
                                            title: '',
                                            controller: TextEditingController(
                                              text: context
                                                  .watch<CartProvider>()
                                                  .directionsToReach,
                                            ),
                                            maxLines: 3,
                                            onChanged: (value) {
                                              context
                                                  .read<CartProvider>()
                                                  .setDirectionsToReach(
                                                      value, context);
                                            },
                                            prefixIcon: Container(
                                              padding: EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.navigation_outlined,
                                                color: colorScheme.primary,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],

                                        // SizedBox(height: 16),
                                        // CustomTextFormField(
                                        //   hintText: 'Add custom instructions...',
                                        //   title: '',
                                        //   controller: TextEditingController(
                                        //     text: context
                                        //         .watch<CartProvider>()
                                        //         .customInstruction,
                                        //   ),
                                        //   maxLines: 3,
                                        //   onChanged: (value) {
                                        //     context
                                        //         .read<CartProvider>()
                                        //         .setCustomInstruction(value, context);
                                        //   },
                                        //   prefixIcon: Container(
                                        //     padding: EdgeInsets.all(2),
                                        //     decoration: BoxDecoration(
                                        //       color:
                                        //           Color(0xFF9AC444).withOpacity(0.1),
                                        //       borderRadius: BorderRadius.circular(8),
                                        //     ),
                                        //     child: Icon(
                                        //       Icons.edit_note_rounded,
                                        //       color: Color(0xFF9AC444),
                                        //       size: 20,
                                        //     ),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),

                                  // Personal Details Section
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: colorScheme.border,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.04),
                                          blurRadius: 24,
                                          offset: Offset(0, 4),
                                          spreadRadius: 0,
                                        ),
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.02),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getTranslatedValue(
                                              context, 'personal_details'),
                                          style: GoogleFonts.inter(
                                            color: colorScheme.textPrimary,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            height: 1.02,
                                            letterSpacing: -0.55,
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.person_outline_rounded,
                                                size: 22,
                                                color: colorScheme
                                                    .buttonPrimaryText,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    context
                                                        .watch<CartProvider>()
                                                        .userName,
                                                    style: GoogleFonts.inter(
                                                      color: colorScheme
                                                          .textPrimary,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      height: 1.02,
                                                      letterSpacing: -0.55,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    context
                                                        .watch<CartProvider>()
                                                        .userPhone,
                                                    style: GoogleFonts.inter(
                                                      color: colorScheme
                                                          .textSecondary,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 1.02,
                                                      letterSpacing: -0.55,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () async {
                                                await context
                                                    .read<CartProvider>()
                                                    .showEditPersonalDetailsBottomSheet(
                                                        context);
                                                // Trigger rebuild to update UI
                                                if (mounted) {
                                                  setState(() {});
                                                }
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: colorScheme.primary
                                                        .withValues(alpha: 0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.edit_outlined,
                                                      size: 16,
                                                      color:
                                                          colorScheme.primary,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      getTranslatedValue(
                                                          context,
                                                          'edit_button'),
                                                      style: GoogleFonts.inter(
                                                        color:
                                                            colorScheme.primary,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        height: 1.02,
                                                        letterSpacing: -0.55,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 20),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0xFF4B5563),
                                                    Color(0xFF374151),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.location_on_outlined,
                                                size: 22,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    getTranslatedValue(context,
                                                        'delivery_address'),
                                                    style: GoogleFonts.inter(
                                                      color: colorScheme
                                                          .textPrimary,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      height: 1.02,
                                                      letterSpacing: -0.55,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    Constant.session.getData(
                                                        SessionManager
                                                            .keyAddress,
                                                        defaultValue:
                                                            "Select Address"),
                                                    style: GoogleFonts.inter(
                                                      color: colorScheme
                                                          .iconSecondary,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 1.02,
                                                      letterSpacing: -0.55,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () async {
                                                await showAddressesBottomSheet(
                                                    context);
                                                // Refresh cart to update delivery charges with new address
                                                if (mounted) {
                                                  await context
                                                      .read<CartProvider>()
                                                      .refreshCart(
                                                        context: context,
                                                        silent: true,
                                                      );
                                                }
                                                setState(() {});
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: colorScheme.border,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.edit_outlined,
                                                      size: 16,
                                                      color: colorScheme
                                                          .iconSecondary,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      getTranslatedValue(
                                                          context,
                                                          'edit_button'),
                                                      style: GoogleFonts.inter(
                                                        color: colorScheme
                                                            .iconSecondary,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        height: 1.02,
                                                        letterSpacing: -0.55,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  // Delivery Tip Section
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: colorScheme.border,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.04),
                                          blurRadius: 24,
                                          offset: Offset(0, 4),
                                          spreadRadius: 0,
                                        ),
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.02),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Text(
                                                  //   getTranslatedValue(context,
                                                  //       'delivery_tip'),
                                                  //   style: GoogleFonts.inter(
                                                  //     color: colorScheme
                                                  //         .textPrimary,
                                                  //     fontSize: 17,
                                                  //     fontWeight:
                                                  //         FontWeight.w700,
                                                  //     height: 1.02,
                                                  //     letterSpacing: -0.55,
                                                  //   ),
                                                  // ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    getTranslatedValue(context,
                                                        'tip_support_text'),
                                                    style: GoogleFonts.inter(
                                                      color: colorScheme
                                                          .textSecondary,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 1.02,
                                                      letterSpacing: -0.55,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            BikeAnimationWidget(
                                              width: 70,
                                              height: 70,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 20),
                                        SizedBox(
                                          height: 42,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _buildTipButton(
                                                    '₹10', context),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    _buildTipButton(
                                                        '₹20', context),
                                                    Positioned(
                                                      top: -10,
                                                      left: 0,
                                                      right: 0,
                                                      child: Center(
                                                        child: Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal: 2,
                                                                  vertical: 2),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: colorScheme
                                                                .primary,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                            border: Border.all(
                                                              color: colorScheme
                                                                  .surface,
                                                              width: 2,
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: colorScheme
                                                                    .primary
                                                                    .withValues(
                                                                        alpha:
                                                                            0.15),
                                                                blurRadius: 4,
                                                                offset: Offset(
                                                                    0, 2),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Text(
                                                            getTranslatedValue(
                                                                context,
                                                                'most_tipped'),
                                                            style: GoogleFonts
                                                                .inter(
                                                              color: colorScheme
                                                                  .buttonPrimaryText,
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              height: 1.02,
                                                              letterSpacing:
                                                                  -0.55,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: _buildTipButton(
                                                    '₹30', context),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: _buildTipButton(
                                                  getTranslatedValue(
                                                      context, 'other_label'),
                                                  context,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Custom Tip Amount Input
                                        if (context
                                                .watch<CartProvider>()
                                                .selectedTip ==
                                            'Other') ...[
                                          SizedBox(height: 16),
                                          AnimatedContainer(
                                            duration:
                                                Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                            child: CustomTextFormField(
                                              title: '',
                                              hintText: getTranslatedValue(
                                                  context,
                                                  'tip_amount_placeholder'),
                                              controller: _tipController,
                                              keyboardType:
                                                  TextInputType.number,
                                              prefixIcon: Container(
                                                padding: EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.currency_rupee_rounded,
                                                  color: colorScheme.primary,
                                                  size: 20,
                                                ),
                                              ),
                                              textInputAction:
                                                  TextInputAction.done,
                                              onEditingComplete: () {
                                                final amount = double.tryParse(
                                                        _tipController.text) ??
                                                    0.0;
                                                if (amount >= 0) {
                                                  context
                                                      .read<CartProvider>()
                                                      .setCustomTipAmount(
                                                          amount, context);
                                                }
                                                FocusScope.of(context)
                                                    .unfocus();
                                              },
                                              suffixIcon: GestureDetector(
                                                onTap: () {
                                                  final amount =
                                                      double.tryParse(
                                                              _tipController
                                                                  .text) ??
                                                          0.0;
                                                  if (amount >= 0) {
                                                    context
                                                        .read<CartProvider>()
                                                        .setCustomTipAmount(
                                                            amount, context);
                                                  }
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    Icons.check_rounded,
                                                    color: colorScheme.primary,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return getTranslatedValue(
                                                      context,
                                                      'enter_tip_amount_error');
                                                }
                                                final amount =
                                                    double.tryParse(value);
                                                if (amount == null ||
                                                    amount < 0) {
                                                  return 'Please enter a valid amount';
                                                }
                                                if (amount > 1000) {
                                                  return getTranslatedValue(
                                                      context,
                                                      'maximum_tip_amount_error');
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                        // Show selected tip amount
                                        if (context
                                                .watch<CartProvider>()
                                                .tipAmount >
                                            0) ...[
                                          SizedBox(height: 12),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons
                                                        .volunteer_activism_rounded,
                                                    color: colorScheme
                                                        .buttonPrimaryText,
                                                    size: 16,
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    getTranslatedValue(context,
                                                            'tipping_amount')
                                                        .replaceAll(
                                                            '{amount}',
                                                            context
                                                                .watch<
                                                                    CartProvider>()
                                                                .tipAmount
                                                                .toStringAsFixed(
                                                                    0)),
                                                    style: GoogleFonts.inter(
                                                      color: colorScheme
                                                          .textPrimary,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      height: 1.02,
                                                      letterSpacing: -0.55,
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    context
                                                        .read<CartProvider>()
                                                        .clearTip(context);
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          colorScheme.surface,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Icon(
                                                      Icons.close_rounded,
                                                      color: colorScheme
                                                          .iconSecondary,
                                                      size: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 12),

                                  // Wallet Section
                                  if (cartProvider.userBalance > 0)
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            colorScheme.surface,
                                            colorScheme.surface,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: cartProvider.useWallet
                                              ? colorScheme.primary
                                                  .withValues(alpha: 0.3)
                                              : colorScheme.border,
                                          width: 1,
                                        ),
                                        boxShadow: cartProvider.useWallet
                                            ? [
                                                BoxShadow(
                                                  color: colorScheme.primary
                                                      .withValues(alpha: 0.1),
                                                  blurRadius: 12,
                                                  offset: Offset(0, 4),
                                                ),
                                              ]
                                            : [
                                                BoxShadow(
                                                  color: Color(0x08000000),
                                                  blurRadius: 12,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                      ),
                                      child: GestureDetector(
                                        onTap: () async {
                                          HapticFeedback.lightImpact();
                                          await cartProvider
                                              .toggleWalletUsage(context);
                                          // Refresh cart data when wallet is toggled
                                          await callApi();
                                        },
                                        child: Row(
                                          children: [
                                            // Wallet Icon
                                            Container(
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: cartProvider.useWallet
                                                    ? colorScheme.primary
                                                        .withValues(alpha: 0.15)
                                                    : colorScheme
                                                        .surfaceVariant,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons
                                                    .account_balance_wallet_outlined,
                                                color: cartProvider.useWallet
                                                    ? colorScheme.primary
                                                    : colorScheme.iconSecondary,
                                                size: 24,
                                              ),
                                            ),
                                            SizedBox(width: 16),

                                            // Wallet Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Use Wallet Balance',
                                                    style: GoogleFonts.inter(
                                                      color: colorScheme
                                                          .textPrimary,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: -0.55,
                                                      height: 1.02,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'Available: ₹${cartProvider.userBalance.toStringAsFixed(2)}',
                                                    style: GoogleFonts.inter(
                                                      color: colorScheme
                                                          .textSecondary,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      letterSpacing: -0.55,
                                                      height: 1.02,
                                                    ),
                                                  ),
                                                  if (cartProvider
                                                      .useWallet) ...[
                                                    SizedBox(height: 8),
                                                    GestureDetector(
                                                      onTap: () async {
                                                        await showWalletAmountBottomSheet(
                                                            context);
                                                        if (mounted)
                                                          setState(() {});
                                                      },
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Applying ₹${cartProvider.walletDeduction.toStringAsFixed(2)}',
                                                            style: GoogleFonts
                                                                .inter(
                                                              color: colorScheme
                                                                  .primary,
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              letterSpacing:
                                                                  -0.2,
                                                              height: 1.2,
                                                            ),
                                                          ),
                                                          SizedBox(width: 4),
                                                          Icon(
                                                            Icons.edit_outlined,
                                                            size: 14,
                                                            color: colorScheme
                                                                .primary,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),

                                            // Toggle Checkbox
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: cartProvider.useWallet
                                                    ? colorScheme.primary
                                                    : colorScheme
                                                        .surfaceVariant,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: cartProvider.useWallet
                                                      ? colorScheme.primary
                                                      : colorScheme.border,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: cartProvider.useWallet
                                                  ? Icon(
                                                      Icons.check,
                                                      color: colorScheme
                                                          .buttonPrimaryText,
                                                      size: 16,
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  if (cartProvider.userBalance > 0)
                                    SizedBox(height: 12),

                                  // Bill Details Section
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x08000000),
                                          blurRadius: 12,
                                          offset: Offset(0, 2),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getTranslatedValue(
                                              context, 'bill_details'),
                                          style: GoogleFonts.inter(
                                            color: colorScheme.textPrimary,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            height: 1.02,
                                            letterSpacing: -0.55,
                                          ),
                                        ),
                                        SizedBox(height: 20),

                                        // Dynamically render billing breakdown from API
                                        ...cartProvider
                                                .cartData?.data.billingBreakdown
                                                .where((item) {
                                              if (item.isTotal) return false;

                                              // Skip 'Multi Order Charge' if it's a single order Source
                                              if (item.label
                                                  .toLowerCase()
                                                  .contains(
                                                      'multi order charge')) {
                                                final sellerCount = (cartProvider
                                                            .cartData
                                                            ?.data
                                                            .groupedBySeller
                                                            .length ??
                                                        0) +
                                                    (cartProvider
                                                                .cartData
                                                                ?.data
                                                                .adminManagedStore
                                                                .items
                                                                .isNotEmpty ==
                                                            true
                                                        ? 1
                                                        : 0) +
                                                    (cartProvider
                                                                .cartData
                                                                ?.data
                                                                .customCombos
                                                                .isNotEmpty ==
                                                            true
                                                        ? 1
                                                        : 0);
                                                if (sellerCount <= 1)
                                                  return false;
                                              }

                                              return true;
                                            }).map((item) {
                                              return Column(
                                                children: [
                                                  _buildBillRow(
                                                    item.label,
                                                    '${item.isCredit ? '-' : ''}${item.currency}${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 2)}',
                                                    isDiscount: item.isCredit,
                                                    showInfo: item
                                                        .description.isNotEmpty,
                                                    description:
                                                        item.description,
                                                  ),
                                                  SizedBox(height: 12),
                                                ],
                                              );
                                            }).toList() ??
                                            [],

                                        Container(
                                          margin: EdgeInsets.only(
                                              top: 4, bottom: 16),
                                          height: 1,
                                          color: colorScheme.border,
                                        ),

                                        // Display total (to_be_paid)
                                        ...cartProvider
                                                .cartData?.data.billingBreakdown
                                                .where((item) => item.isTotal)
                                                .map((item) {
                                              return Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    item.label,
                                                    style: GoogleFonts.inter(
                                                      color: colorScheme
                                                          .textPrimary,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      height: 1.02,
                                                      letterSpacing: -0.55,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${item.currency}${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 2)}',
                                                    style: GoogleFonts.inter(
                                                      color: colorScheme
                                                          .textPrimary,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      height: 1.02,
                                                      letterSpacing: -0.55,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList() ??
                                            [],
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  // Pre-Order Info Card (replaces normal cancellation policy)
                                  if (cartProvider.hasPreOrderItems())
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF4E8),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFE8922D)
                                              .withValues(alpha: 0.35),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8922D)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(16),
                                                topRight: Radius.circular(16),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.schedule_rounded,
                                                  color: Color(0xFFE8922D),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Pre-Order Items in Your Cart',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xFFE8922D),
                                                    letterSpacing: -0.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Body
                                          Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // What is a Pre-Order
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                      Icons.info_outline_rounded,
                                                      size: 16,
                                                      color: Color(0xFFE8922D),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'What is a Pre-Order?',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: const Color(
                                                                  0xFF1A1A1A),
                                                              letterSpacing:
                                                                  -0.2,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 3),
                                                          Text(
                                                            'Pre-order items are reserved in advance and dispatched every Friday morning. Place your order before Friday and it will be shipped out.',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: const Color(
                                                                  0xFF555555),
                                                              height: 1.5,
                                                              letterSpacing:
                                                                  -0.1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Divider(
                                                  color: const Color(0xFFE8922D)
                                                      .withValues(alpha: 0.2),
                                                  height: 1,
                                                  thickness: 1,
                                                ),
                                                const SizedBox(height: 12),
                                                // Cancellation Policy
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                      Icons.cancel_outlined,
                                                      size: 16,
                                                      color: Color(0xFFE8922D),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Cancellation Policy',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: const Color(
                                                                  0xFF1A1A1A),
                                                              letterSpacing:
                                                                  -0.2,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 3),
                                                          Text(
                                                            'You can cancel your pre-order at any time before it is dispatched. Once dispatched, cancellation is no longer possible. To cancel, go to your order details and tap "Cancel Order".',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: const Color(
                                                                  0xFF555555),
                                                              height: 1.5,
                                                              letterSpacing:
                                                                  -0.1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Normal Cancellation Policy (hidden for pre-order carts)
                                  if (!cartProvider.hasPreOrderItems())
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: colorScheme.border,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.03),
                                          blurRadius: 12,
                                          offset: Offset(0, 2),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline_rounded,
                                              size: 20,
                                              color: colorScheme.iconSecondary,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              getTranslatedValue(context,
                                                  'cancellation_policy'),
                                              style: GoogleFonts.inter(
                                                color: colorScheme.textPrimary,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                height: 1.02,
                                                letterSpacing: -0.55,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          getTranslatedValue(context,
                                              'cancellation_policy_text'),
                                          style: GoogleFonts.inter(
                                            color: colorScheme.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            height: 1.02,
                                            letterSpacing: -0.55,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        GestureDetector(
                                          onTap: () {
                                            launchUrl(
                                              Uri.parse(
                                                  'https://wheat-rook-708688.hostingersite.com/customer/cancellation-policy'),
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          },
                                          child: Text(
                                            'Read cancellation policy',
                                            style: GoogleFonts.inter(
                                              color: colorScheme.primary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              height: 1.02,
                                              letterSpacing: -0.55,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
      },
    );
  }

// Helper Widget for Tip Buttons
  Widget _buildTipButton(String label, BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final cartProvider = context.watch<CartProvider>();
    final isSelected = cartProvider.isTipSelected(label);
    final isOther = label == 'Other';

    return GestureDetector(
      onTap: () {
        context.read<CartProvider>().selectTip(label, context);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isOther && isSelected)
              Container(
                width: 18,
                height: 18,
                margin: EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: colorScheme.buttonPrimaryText,
                  size: 12,
                ),
              ),
            Flexible(
                child: Text(
              label,
              style: GoogleFonts.inter(
                color:
                    isSelected ? colorScheme.primary : colorScheme.textPrimary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                height: 1.02,
                letterSpacing: -0.55,
              ),
              overflow: TextOverflow.ellipsis,
            )),
            // if (!isOther && isSelected)
            //   Container(
            //     width: 18,
            //     height: 18,
            //     margin: EdgeInsets.only(left: 4),
            //     decoration: BoxDecoration(
            //       gradient: LinearGradient(
            //         colors: [
            //           Color(0xFF9AC444),
            //           Color(0xFF87B23D),
            //         ],
            //       ),
            //       shape: BoxShape.circle,
            //     ),
            //     child: Icon(
            //       Icons.check_rounded,
            //       color: Colors.white,
            //       size: 12,
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

// Helper Widget for Selectable Instruction Chips
  Widget _buildSelectableInstructionChip(
    String label,
    IconData icon,
    BuildContext context,
  ) {
    final cartProvider = context.watch<CartProvider>();
    final isSelected = cartProvider.isInstructionSelected(label);

    return GestureDetector(
      onTap: () {
        context.read<CartProvider>().toggleInstruction(label, context);
      },
      child: Container(
        width: 90,
        height: 80,
        padding: const EdgeInsets.all(8),
        decoration: ShapeDecoration(
          color: isSelected ? const Color(0xFFF1FEDB) : Colors.transparent,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: isSelected
                  ? const Color(0xFF9AC444)
                  : const Color(0xFFDCDCDC),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF9AC444)
                  : const Color(0xFF7C7B7B),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.black : const Color(0xFF7C7B7B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 0.95,
              ),
              textAlign: TextAlign.center,
            ),
            // if (isSelected)
            //   Container(
            //     width: 16,
            //     height: 16,
            //     decoration: BoxDecoration(
            //       color: const Color(0xFF9AC444),
            //       borderRadius: BorderRadius.circular(4),
            //     ),
            //     child: Icon(
            //       Icons.check,
            //       size: 12,
            //       color: Colors.white,
            //     ),
            //   ),
          ],
        ),
      ).p2(),
    );
  }

  Widget _buildBillRow(String label, String value,
      {bool showInfo = false, bool isDiscount = false, String? description}) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.02,
                    letterSpacing: -0.55,
                  ),
                ),
              ),
              if (showInfo &&
                  description != null &&
                  description.isNotEmpty) ...[
                SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    _showBillDetailDialog(label, description);
                  },
                  child: Container(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: isDiscount ? colorScheme.primary : colorScheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.02,
            letterSpacing: -0.55,
          ),
        ),
      ],
    );
  }

  void _showBillDetailDialog(String title, String description) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final colorScheme =
            dialogContext.watch<app_theme.ThemeProvider>().colorScheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          height: 1.02,
                          letterSpacing: -0.55,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colorScheme.iconSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textSecondary,
                      height: 1.02,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Got it',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.buttonPrimaryText,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  getCartListShimmer({required BuildContext context}) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _ShimmerCartCard(),
    );
  }
}

class _ShimmerCartCard extends StatefulWidget {
  const _ShimmerCartCard({Key? key}) : super(key: key);

  @override
  State<_ShimmerCartCard> createState() => _ShimmerCartCardState();
}

class _ShimmerCartCardState extends State<_ShimmerCartCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    // Theme-aware shimmer colors
    final shimmerBaseColor =
        colorScheme.isDark ? const Color(0xFF2D3339) : const Color(0xFFE0E0E0);
    final shimmerHighlightColor =
        colorScheme.isDark ? const Color(0xFF3C4248) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.border, width: 1),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  shimmerBaseColor,
                                  shimmerHighlightColor,
                                  shimmerBaseColor,
                                ],
                                stops: [
                                  _animation.value - 0.3,
                                  _animation.value,
                                  _animation.value + 0.3,
                                ].map((e) => e.clamp(0.0, 1.0)).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  shimmerBaseColor,
                                  shimmerHighlightColor,
                                  shimmerBaseColor,
                                ],
                                stops: [
                                  _animation.value - 0.3,
                                  _animation.value,
                                  _animation.value + 0.3,
                                ].map((e) => e.clamp(0.0, 1.0)).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            shimmerBaseColor,
                            shimmerHighlightColor,
                            shimmerBaseColor,
                          ],
                          stops: [
                            _animation.value - 0.3,
                            _animation.value,
                            _animation.value + 0.3,
                          ].map((e) => e.clamp(0.0, 1.0)).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Cart items
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildShimmerCartItem(
                        shimmerBaseColor, shimmerHighlightColor),
                    const SizedBox(height: 12),
                    Divider(color: colorScheme.border, height: 1, thickness: 1),
                    const SizedBox(height: 12),
                    _buildShimmerCartItem(
                        shimmerBaseColor, shimmerHighlightColor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerCartItem(Color baseColor, Color highlightColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image placeholder
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Product details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      baseColor,
                      highlightColor,
                      baseColor,
                    ],
                    stops: [
                      _animation.value - 0.3,
                      _animation.value,
                      _animation.value + 0.3,
                    ].map((e) => e.clamp(0.0, 1.0)).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      baseColor,
                      highlightColor,
                      baseColor,
                    ],
                    stops: [
                      _animation.value - 0.3,
                      _animation.value,
                      _animation.value + 0.3,
                    ].map((e) => e.clamp(0.0, 1.0)).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 16,
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          baseColor,
                          highlightColor,
                          baseColor,
                        ],
                        stops: [
                          _animation.value - 0.3,
                          _animation.value,
                          _animation.value + 0.3,
                        ].map((e) => e.clamp(0.0, 1.0)).toList(),
                      ),
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          baseColor,
                          highlightColor,
                          baseColor,
                        ],
                        stops: [
                          _animation.value - 0.3,
                          _animation.value,
                          _animation.value + 0.3,
                        ].map((e) => e.clamp(0.0, 1.0)).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CartComboSection extends StatelessWidget {
  final List<CustomCombo> combos;
  final ComboDetailProvider comboProvider; // or a dedicated ComboCartProvider

  const CartComboSection({
    Key? key,
    required this.combos,
    required this.comboProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (combos.isEmpty) return const SizedBox.shrink();

    return Column(
      children: combos.map((combo) {
        return _CartComboCard(
          combo: combo,
          comboProvider: comboProvider,
        );
      }).toList(),
    );
  }
}

class _CartComboCard extends StatelessWidget {
  final CustomCombo combo;
  final ComboDetailProvider comboProvider;

  const _CartComboCard({
    Key? key,
    required this.combo,
    required this.comboProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final cartProvider = context.watch<CartProvider>();
    final savedNote = cartProvider.getComboNote(combo.comboCustomCartId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 24,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, cartProvider),

          // Combo Items
          Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: combo.products.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => Column(
                children: [
                  SizedBox(height: 12),
                  Divider(
                    color: colorScheme.border,
                    height: 1,
                    thickness: 1,
                  ),
                  SizedBox(height: 12),
                ],
              ),
              itemBuilder: (context, index) {
                final p = combo.products[index];
                return ComboProductRow(
                  product: p,
                  quantity: comboProvider.getQuantityForCartProduct(p),
                  selectedVariant:
                      comboProvider.getSelectedVariantForCartProduct(p),
                  onVariantTap: () async {
                    await _showVariantSelectionSheet(
                      context,
                      p,
                      comboProvider,
                    );
                    context.read<CartProvider>().refreshCart(context: context);
                    if (Constant.session.isUserLoggedIn()) {
                      await context
                          .read<CartProvider>()
                          .getCartListProvider(context: context);

                      final combos = context
                              .read<CartProvider>()
                              .cartData
                              ?.data
                              .customCombos ??
                          [];
                      if (combos.isNotEmpty) {
                        context
                            .read<ComboDetailProvider>()
                            .initFromCartCombos(combos);
                      }
                    }
                  },
                  onIncrement: () => comboProvider.changeCartProductQuantity(
                    context,
                    combo.comboId,
                    p,
                    comboProvider.getQuantityForCartProduct(p) + 1,
                  ),
                  onDecrement: () => comboProvider.changeCartProductQuantity(
                    context,
                    combo.comboId,
                    p,
                    comboProvider.getQuantityForCartProduct(p) - 1,
                  ),
                );
              },
            ),
          ),

          // Notes Input Field for this combo
          Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: CustomTextFormField(
              title: getTranslatedValue(context, 'special_instruction'),
              hintText: getTranslatedValue(context, 'add_notes_for_combo'),
              initialValue: savedNote ?? '',
              maxLines: 2,
              prefixIcon: Icon(
                Icons.edit_note_rounded,
                size: 20,
              ),
              onChanged: (value) async {
                if (value.isNotEmpty) {
                  await cartProvider.saveCartMetadata(
                    context: context,
                    comboId: int.tryParse(combo.comboCustomCartId.toString()),
                    comboNote: value,
                  );
                }
              },
            ),
          ),

          // Display saved note if exists
          if (savedNote != null && savedNote.isNotEmpty)
            Container(
              margin: EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFFFFE5A3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E0B),
                            height: 1.2,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          savedNote,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF78350F),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showVariantSelectionSheet(BuildContext context,
      ComboProduct product, ComboDetailProvider provider) async {
    // Track original state to detect changes
    final Map<int, ComboVariant> originalVariants =
        Map.from(provider.selectedVariants);
    final Map<int, int> originalQuantities =
        Map.from(provider.productQuantities);

    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 16, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colorScheme.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getTranslatedValue(context, 'select_size'),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.textPrimary,
                              height: 1.02,
                              letterSpacing: -0.55,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            product.productName ?? "",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.textSecondary,
                              height: 1.02,
                              letterSpacing: -0.55,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: colorScheme.iconSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Variants List
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: product.variants?.length ?? 0,
                  itemBuilder: (context, index) {
                    final variant = product.variants![index];
                    final isSelected =
                        provider.selectedVariants[product.productId]?.id ==
                            variant.id;

                    final variantText =
                        "${variant.measurement} ${variant.unit}";

                    return GestureDetector(
                      onTap: () async {
                        await provider.updateSelectedVariant(
                            product.productId!, variant);
                        final success =
                            await provider.updateMultipleProductsWithComboId(
                          context,
                          originalVariants,
                          originalQuantities,
                          combo.comboId,
                        );
                        if (success) {
                          Navigator.pop(context);
                        }
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.1)
                              : colorScheme.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    blurRadius: 16,
                                    offset: Offset(0, 4),
                                    spreadRadius: 0,
                                  ),
                                ]
                              : colorScheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            // Product Image
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: colorScheme.cardShadow,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: product.productImage ?? '',
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: const Color(0xFFE0E0E0),
                                    highlightColor: const Color(0xFFF5F5F5),
                                    child: Container(color: Colors.white),
                                  ),
                                  errorWidget: (context, url, error) => imgErrorWidget(iconSize: 28),
                                ),
                              ),
                            ),
                            SizedBox(width: 14),
                            // Variant Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Size
                                  Text(
                                    variantText,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.textPrimary,
                                      height: 1.02,
                                      letterSpacing: -0.55,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  // Price Row
                                  Row(
                                    children: [
                                      Text(
                                        "${variant.currency}${variant.price?.toStringAsFixed(0) ?? '0'}",
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme.textPrimary,
                                          height: 1.02,
                                          letterSpacing: -0.55,
                                        ),
                                      ),
                                      if ((variant.actualPrice ?? 0) >
                                          (variant.price ?? 0)) ...[
                                        SizedBox(width: 6),
                                        Text(
                                          "${variant.currency}${variant.actualPrice?.toStringAsFixed(0) ?? '0'}",
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.textSecondary,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationColor:
                                                colorScheme.textSecondary,
                                            height: 1.02,
                                            letterSpacing: -0.55,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Selection Indicator
                            if (isSelected)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.15),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, CartProvider cartProvider) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  combo.comboName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.55,
                    height: 1.02,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  '${combo.productCount} Product${combo.productCount > 1 ? 's' : ''} • ${combo.comboType}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                    letterSpacing: -0.55,
                    height: 1.02,
                  ),
                ),
              ],
            ),
          ),
          // Add Items Button + Total Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider<ComboDetailProvider>(
                        create: (_) => ComboDetailProvider(),
                      ),
                    ],
                    child: ComboDetailScreen(
                      comboId: combo.comboId,
                    ),
                  ),
                ),
              );
            },
            child: Container(
              // width: 86,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignOutside,
                    color: Color(0xFF9E9E9E),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    getTranslatedValue(context, addItemsLabel),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9E9F9F),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 0.68,
                    ),
                  ),
                ],
              ),
            ),
          ),
              SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${combo.totalActualPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (combo.discountPercentage > 0) ...[
                    SizedBox(width: 5),
                    Text(
                      '₹${combo.totalProductsPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension ComboCartActions on ComboDetailProvider {
  Future<void> updateComboProductQty(
    BuildContext context,
    int comboId,
    ComboProduct product,
    int newQty,
  ) async {
    if (newQty < 1) {
      // Optionally prevent 0 from cart screen
      return;
    }

    try {
      final res = await addOrEditCustomComboProduct(
        context: context,
        comboId: comboId,
        productId: product.productId ?? 0,
        variantId: product.variantId ?? 0,
        quantity: newQty,
      );

      if (res != null && res['status'] == 1) {
        product.quantity = newQty;
        notifyListeners();
        // refresh main cart
        await context
            .read<CartProvider>()
            .refreshCart(context: context, silent: true);
      } else {
        showMessage(
          context,
          res?['message']?.toString() ?? 'Failed to update combo item',
          MessageType.warning,
        );
      }
    } catch (e) {
      showMessage(
        context,
        'Failed to update combo item',
        MessageType.error,
      );
    }
  }
}

extension ComboCartBindings on ComboDetailProvider {
  ComboVariant? getSelectedVariantForCartProduct(ComboProduct p) {
    return selectedVariants[p.productId] ??
        p.variants?.firstWhere(
          (v) => v.id == p.variantId,
          // orElse: () => p.variants?.first,
        );
  }

  int getQuantityForCartProduct(ComboProduct p) {
    return productQuantities[p.productId] ?? p.quantity ?? 1;
  }

  Future<void> changeCartProductVariant(
    BuildContext context,
    int comboId,
    ComboProduct product,
    ComboVariant newVariant,
  ) async {
    selectedVariants[product.productId ?? 1] = newVariant;
    notifyListeners();

    final ok = await updateCartComboProduct(
      context: context,
      comboId: comboId,
      productId: product.productId ?? 0,
    );

    if (!ok) {
      // revert if needed
      selectedVariants.remove(product.productId);
      notifyListeners();
      showMessage(
        context,
        'Failed to update combo item',
        MessageType.warning,
      );
      return;
    }

    await context
        .read<CartProvider>()
        .refreshCart(context: context, silent: true);
  }

  Future<void> changeCartProductQuantity(
    BuildContext context,
    int comboId,
    ComboProduct product,
    int newQty,
  ) async {
    if (newQty < 1) {
      await deleteSingleCustomProduct(
        context: context,
        comboId: comboId,
        productId: product.productId ?? 0,
      );
      productQuantities.remove(product.productId);
      await context
          .read<CartProvider>()
          .refreshCart(context: context, silent: true);
      return;
    }

    productQuantities[product.productId ?? 1] = newQty;
    notifyListeners();

    final ok = await updateCartComboProduct(
      context: context,
      comboId: comboId,
      productId: product.productId ?? 0,
    );

    if (!ok) {
      productQuantities[product.productId ?? 0] = product.quantity ?? 1;
      notifyListeners();
      showMessage(
        context,
        'Failed to update combo quantity',
        MessageType.warning,
      );
      return;
    }

    await context
        .read<CartProvider>()
        .refreshCart(context: context, silent: true);
  }
}

class ComboProductRow extends StatelessWidget {
  final ComboProduct product;
  final VoidCallback? onVariantTap;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final int quantity;
  final ComboVariant? selectedVariant;

  const ComboProductRow({
    Key? key,
    required this.product,
    required this.quantity,
    this.selectedVariant,
    this.onVariantTap,
    this.onIncrement,
    this.onDecrement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final variantLabel =
        '${selectedVariant?.measurement?.toStringAsFixed((selectedVariant?.measurement ?? 1) % 1 == 0 ? 0 : 1)} ${selectedVariant?.unit}';

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceVariant,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: product.productImage ?? '',
                fit: BoxFit.contain,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: const Color(0xFFE0E0E0),
                  highlightColor: const Color(0xFFF5F5F5),
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => imgErrorWidget(iconSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  product.productName ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textPrimary,
                    height: 1.02,
                    letterSpacing: -0.55,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Variant Selector
                GestureDetector(
                  onTap: onVariantTap,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.straighten_outlined,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          variantLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                            height: 1.02,
                            letterSpacing: -0.55,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Price
                Row(
                  children: [
                    Text(
                      '${product.currency}${(selectedVariant?.price ?? product.price ?? 0).toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.textPrimary,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                    if ((selectedVariant?.actualPrice ??
                            product.actualPrice ??
                            0) >
                        (selectedVariant?.price ?? product.price ?? 0)) ...[
                      const SizedBox(width: 5),
                      Text(
                        '${product.currency}${(selectedVariant?.actualPrice ?? product.actualPrice ?? 0).toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textSecondary,
                          height: 1.02,
                          letterSpacing: -0.55,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: colorScheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Quantity Control
          Container(
            width: 92,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.primary,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Decrement
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDecrement,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    child: SizedBox(
                      width: 30,
                      child: Center(
                        child: Icon(
                          Icons.remove_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),

                // Quantity
                Text(
                  quantity.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                  ),
                ),

                // Increment
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onIncrement,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: SizedBox(
                      width: 30,
                      child: Center(
                        child: Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
