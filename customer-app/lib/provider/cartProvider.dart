import 'dart:developer' as developer;

import 'package:project/helper/utils/generalImports.dart';
import 'package:project/screens/cartListScreen/edit_cart_receiver_details.dart';

enum CartState {
  initial,
  loading,
  silentLoading,
  loaded,
  error,
}

class CartProvider extends ChangeNotifier {
  CartState cartState = CartState.initial;
  String message = '';
  Cart? cartData;
  bool isDataLoaded = false;
  late double subTotal = 0.0;
  late double userBalance = 0.0;
  late double savedAmount = 0.0;
  late int totalItemsCount = 0;
  String selfPickupMode = "0";
  bool useWallet = false;

  /// How much wallet balance to apply. Null means "as much as the bill needs",
  /// which is the default when the wallet is switched on.
  double? walletAmountToUse;

  // Delivery Instructions
  List<String> selectedInstructions = [];
  String customInstruction = '';
  String directionsToReach = ''; // Specific field for directions to reach

  // Delivery Tip
  String selectedTip = '';
  double tipAmount = 0.0;

  // Note
  String orderNote = '';

  // Personal Details
  String userName = Constant.session
      .getData(SessionManager.keyUserName, defaultValue: "Guest User");
  String userPhone =
      Constant.session.getData(SessionManager.keyPhone, defaultValue: "+91");
  String deliveryAddress = Constant.session
      .getData(SessionManager.keyAddress, defaultValue: "Add delivery address");

  // ============ Personal Details Bottom Sheet ============
  Future<void> showEditPersonalDetailsBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPersonalDetailsBottomSheet(
        currentName: userName,
        currentPhone: userPhone,
      ),
    );

    if (result != null) {
      String newName = result['name'] ?? userName;
      String newPhone = result['phone'] ?? userPhone;

      updateUserName(newName);
      updateUserPhone(newPhone);

      // Save to session
      Constant.session.setData(SessionManager.keyUserName, newName, true);
      Constant.session.setData(SessionManager.keyPhone, newPhone, true);

      // Save to cart metadata API
      await saveCartMetadata(
        context: context,
        contactName: newName,
        contactPhone: newPhone,
      );
    }
  }

  // ============ Cart API Methods ============
  Future<void> getCartListProvider({
    required BuildContext context,
    bool silent = false,
  }) async {
    if (silent && cartState == CartState.loaded) {
      cartState = CartState.silentLoading;
    } else {
      cartState = CartState.loading;
    }
    notifyListeners();

    try {
      Map<String, String> params = await Constant.getProductsDefaultParams();
      params['use_wallet'] = useWallet ? '1' : '0';
      if (useWallet && walletAmountToUse != null) {
        params['wallet_amount_value'] = walletAmountToUse!.toStringAsFixed(2);
      }
      Map<String, dynamic> getData =
          await getCartListApi(context: context, params: params);

      developer.log("GetCartListProvider getData: $getData");

      if (getData[ApiAndParams.status].toString() == "1") {
        cartData = Cart.fromJson(getData);
        isDataLoaded = true;
        developer.log(
            "GetCartListProvider cartData: ${cartData?.data.getAllCartItems().length} items, ${cartData?.data.customCombos.length} combos");

        // Calculate totals
        _updateCartTotals();

        // Load delivery instructions from cart metadata
        _loadDeliveryInstructionsFromMetadata();

        // Load contact details from cart metadata
        _loadContactDetailsFromMetadata();

        cartState = CartState.loaded;
        developer.log("GetCartListProvider cartState: $cartState");
        notifyListeners();
      } else {
        message = getData[ApiAndParams.message] ?? "Failed to load cart";
        cartState = CartState.error;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      developer.log("GetCartListProvider error: $message");
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      cartState = CartState.error;
      notifyListeners();
    }
  }

  Future<void> getGuestCartListProvider({
    required BuildContext context,
    bool silent = false,
  }) async {
    if (silent && cartState == CartState.loaded) {
      cartState = CartState.silentLoading;
    } else {
      cartState = CartState.loading;
    }

    notifyListeners();

    try {
      Map<String, String> params = await Constant.getProductsDefaultParams();
      params.addAll(Constant.setGuestCartParams(
          cartList: context.read<CartListProvider>().cartList,
          cartParams: params));

      if (params[ApiAndParams.quantities].toString().isNotEmpty &&
          params[ApiAndParams.variant_ids].toString().isNotEmpty) {
        Map<String, dynamic> getData =
            await getGuestCartListApi(context: context, params: params);

        if (getData[ApiAndParams.status].toString() == "1") {
          cartData = Cart.fromJson(getData);
          isDataLoaded = true;
          _updateCartTotals();
          _loadDeliveryInstructionsFromMetadata();
          _loadContactDetailsFromMetadata();
          cartState = CartState.loaded;
          notifyListeners();
        } else {
          message = getData[ApiAndParams.message] ?? "Failed to load cart";
          cartState = CartState.error;
          notifyListeners();
        }
      } else {
        _clearCart();
        cartState = CartState.loaded;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      cartState = CartState.error;
      notifyListeners();
    }
  }

  // ============ Helper Methods ============
  void _updateCartTotals() {
    totalItemsCount = cartData?.data.getTotalItemCount() ?? 0;

    // Use billing summary from API instead of old fields
    final billingSummary = cartData?.data.billingSummary;
    // if (billingSummary != null) {
    subTotal = billingSummary?.toBePaid ?? 0.0;
    savedAmount = (billingSummary?.savings ?? 0.0) + (billingSummary?.discount ?? 0.0);
    tipAmount = billingSummary?.deliveryTip ?? 0.0;
    // } else {
    //   // Fallback to old fields if billing summary not available
    //   subTotal = double.parse(cartData?.data.subTotal ?? "0.0");
    //   savedAmount = double.parse(cartData?.data.savedAmount ?? "0.0");
    // }

    userBalance = double.parse(cartData?.data.userBalance ?? "0.0");
    selfPickupMode = cartData?.data.selfPickupMode ?? "0";
    walletAmountToUse = billingSummary?.walletAmountValue;
  }

  /// Wallet amount the server actually applied to this cart.
  double get walletDeduction =>
      cartData?.data.billingSummary.walletDeduction ?? 0.0;

  /// Bill total before the wallet is applied — the most wallet worth spending.
  double get maxUsableWalletAmount {
    final payable =
        (cartData?.data.billingSummary.toBePaid ?? 0.0) + walletDeduction;
    return payable < userBalance ? payable : userBalance;
  }

  void _loadDeliveryInstructionsFromMetadata() {
    final metadata = cartData?.data.cartMetadata;
    if (metadata?.deliveryInstructions != null &&
        metadata!.deliveryInstructions!.isNotEmpty) {
      // Parse the delivery instructions back into selectedInstructions and customInstruction
      // The backend saves the combined string, so we need to parse it intelligently
      String instructions = metadata.deliveryInstructions!;

      // Clear current instructions
      selectedInstructions.clear();
      customInstruction = '';

      // List of predefined instructions from the UI (with \n as shown in UI)
      Map<String, String> predefinedInstructions = {
        'Directions\nto reach': 'Directions to reach',
        'Leave\nat door': 'Leave at door',
        'Avoid\ncalling': 'Avoid calling',
        'Beware of\npets': 'Beware of pets',
        'Leave with\nSecurity': 'Leave with Security',
      };

      // Check which predefined instructions are in the saved string
      predefinedInstructions.forEach((uiLabel, savedLabel) {
        if (instructions.contains(savedLabel)) {
          selectedInstructions.add(uiLabel); // Add with \n format for UI
        }
      });

      // Extract custom instruction by removing all predefined instructions
      String remaining = instructions;
      predefinedInstructions.values.forEach((savedLabel) {
        remaining = remaining.replaceAll(savedLabel, '').replaceAll(', ,', ',');
      });
      remaining = remaining.trim().replaceAll(RegExp(r'^[,.\s]+|[,.\s]+$'), '');

      if (remaining.isNotEmpty) {
        customInstruction = remaining;
      }
    }

    // Load delivery tip from metadata
    _loadDeliveryTipFromMetadata();
  }

  void _loadDeliveryTipFromMetadata() {
    final metadata = cartData?.data.cartMetadata;
    if (metadata?.deliveryTip != null && metadata!.deliveryTip > 0) {
      tipAmount = metadata.deliveryTip;

      // Determine which tip button should be selected
      switch (tipAmount.toInt()) {
        case 10:
          selectedTip = '₹10';
          break;
        case 20:
          selectedTip = '₹20';
          break;
        case 30:
          selectedTip = '₹30';
          break;
        case 50:
          selectedTip = '₹50';
          break;
        default:
          selectedTip = 'Other';
          break;
      }
    } else {
      selectedTip = '';
      tipAmount = 0.0;
    }
  }

  void _loadContactDetailsFromMetadata() {
    final metadata = cartData?.data.cartMetadata;

    // Load contact name if available
    if (metadata?.contactName != null && metadata!.contactName!.isNotEmpty) {
      userName = metadata.contactName!;
      Constant.session.setData(SessionManager.keyUserName, userName, true);
    }

    // Load contact phone if available
    if (metadata?.contactPhone != null && metadata!.contactPhone!.isNotEmpty) {
      userPhone = metadata.contactPhone!;
      Constant.session.setData(SessionManager.keyPhone, userPhone, true);
    }
  }

  void _clearCart() {
    subTotal = 0.0;
    userBalance = 0.0;
    savedAmount = 0.0;
    if (isDataLoaded && cartData?.data != null) {
      cartData?.data.adminManagedStore.items.clear();
      cartData?.data.groupedBySeller.clear();
    }
    totalItemsCount = 0;
    selfPickupMode = "0";
  }

  // ============ Cart Item Management ============
  Future removeItemFromCartList({
    required int productId,
    required int variantId,
  }) async {
    // Remove from admin managed store
    cartData?.data.adminManagedStore.items.removeWhere((item) =>
        item.productId.toString() == productId.toString() &&
        item.productVariantId.toString() == variantId.toString());

    // Remove from seller groups
    for (var sellerGroup in cartData?.data.groupedBySeller ?? []) {
      sellerGroup.items.removeWhere((item) =>
          item.productId.toString() == productId.toString() &&
          item.productVariantId.toString() == variantId.toString());
    }

    // Remove empty seller groups
    cartData?.data.groupedBySeller.removeWhere((group) => group.items.isEmpty);

    // Update totals
    totalItemsCount = cartData?.data.getTotalItemCount() ?? 0;
    notifyListeners();
  }

  Future<bool> checkCartItemsStockStatus() async {
    for (var item in cartData?.data.getAllCartItems() ?? []) {
      if (item.status == "0") {
        return true;
      }
    }
    return false;
  }

  // ============ Cart Data Getters ============
  List<SellerGroup> getSellerGroups() {
    return cartData?.data.groupedBySeller ?? [];
  }

  List<CartItem> getAdminManagedItems() {
    return cartData?.data.adminManagedStore.items ?? [];
  }

  List<CartItem> getSaveForLaterItems() {
    return cartData?.data.saveForLater ?? [];
  }

  /// Check if cart has any non-admin items (grouped_by_seller or custom combos)
  bool hasNonAdminCartItems() {
    for (var group in (cartData?.data.groupedBySeller ?? [])) {
      if (group.items.isNotEmpty) return true;
    }
    if ((cartData?.data.customCombos ?? []).isNotEmpty) return true;
    return false;
  }

  /// Check if cart has any admin_managed_store items
  bool hasAdminManagedItems() {
    return (cartData?.data.adminManagedStore.items ?? []).isNotEmpty;
  }

  /// Check if cart has any pre-order items
  bool hasPreOrderItems() {
    final adminItems = cartData?.data.adminManagedStore.items ?? [];
    if (adminItems.any((item) => item.isPreOrderItem == 1)) return true;
    for (final group in (cartData?.data.groupedBySeller ?? [])) {
      if (group.items.any((item) => item.isPreOrderItem == 1)) return true;
    }
    return false;
  }

  /// Remove all admin_managed_store items from cart via API.
  /// Returns true if cart still has items remaining after removal.
  Future<bool> removeAdminManagedItems({
    required BuildContext context,
  }) async {
    final items = cartData?.data.adminManagedStore.items ?? [];
    if (items.isEmpty) return true;

    for (final item in List<CartItem>.from(items)) {
      final params = <String, dynamic>{
        ApiAndParams.productId: item.productId,
        ApiAndParams.productVariantId: item.productVariantId,
        ApiAndParams.qty: "0",
      };
      try {
        await removeItemFromCartApi(context: context, params: params);
      } catch (e) {
        debugPrint("Error removing admin item ${item.productId}: $e");
      }
    }

    await refreshCart(context: context, silent: false);

    final remainingItems = cartData?.data.getTotalItemCount() ?? 0;
    return remainingItems > 0;
  }

  /// Remove offline seller products from cart via API.
  /// Returns true if cart still has items remaining after removal.
  Future<bool> removeOfflineProducts({
    required BuildContext context,
  }) async {
    final offlineProducts =
        cartData?.data.shopStatusCheck.offlineProducts ?? [];
    if (offlineProducts.isEmpty) return true;

    for (final product in offlineProducts) {
      final params = <String, dynamic>{
        ApiAndParams.productId: product.productId,
        ApiAndParams.productVariantId: product.productVariantId,
        ApiAndParams.qty: "0",
      };
      try {
        await removeItemFromCartApi(context: context, params: params);
      } catch (e) {
        debugPrint(
            "Error removing offline product ${product.productId}: $e");
      }
    }

    await refreshCart(context: context, silent: false);

    final remainingItems = cartData?.data.getTotalItemCount() ?? 0;
    return remainingItems > 0;
  }

  // ============ Cart State Management ============
  void setItemCount(int count) {
    totalItemsCount = count;
    notifyListeners();
  }

  Future setSubTotal(double newSubtotal) async {
    Constant.isPromoCodeApplied = false;
    Constant.selectedCoupon = "";
    Constant.discountedAmount = 0.0;
    Constant.discount = 0.0;
    Constant.selectedPromoCodeId = "0";
    subTotal = newSubtotal;
    notifyListeners();
  }

  void resetCartList() {
    _clearCart();
    notifyListeners();
  }

  // ============ Delivery Instructions Methods ============
  Future<void> toggleInstruction(String instruction, BuildContext context) async {
    if (selectedInstructions.contains(instruction)) {
      selectedInstructions.remove(instruction);
    } else {
      selectedInstructions.add(instruction);
    }
    notifyListeners();

    // Auto-save delivery instructions to API
    await saveCartMetadata(
      context: context,
      deliveryInstructions: getDeliveryInstructions(),
    );
  }

  bool isInstructionSelected(String instruction) {
    return selectedInstructions.contains(instruction);
  }

  Future<void> setCustomInstruction(String instruction, BuildContext context) async {
    customInstruction = instruction;
    notifyListeners();

    // Auto-save delivery instructions to API
    await saveCartMetadata(
      context: context,
      deliveryInstructions: getDeliveryInstructions(),
    );
  }

  Future<void> setDirectionsToReach(String directions, BuildContext context) async {
    directionsToReach = directions;
    notifyListeners();

    // Auto-save delivery instructions to API
    await saveCartMetadata(
      context: context,
      deliveryInstructions: getDeliveryInstructions(),
      directionsToReach: directions,
    );
  }

  void clearInstructions() {
    selectedInstructions.clear();
    customInstruction = '';
    directionsToReach = '';
    notifyListeners();
  }

  String getDeliveryInstructions() {
    // Convert UI labels (with \n) to saved format (without \n)
    List<String> formattedInstructions = selectedInstructions.map((instruction) {
      return instruction.replaceAll('\n', ' ');
    }).toList();

    String instructions = formattedInstructions.join(', ');
    if (customInstruction.isNotEmpty) {
      if (instructions.isNotEmpty) {
        instructions += '. ';
      }
      instructions += customInstruction;
    }
    return instructions;
  }

  // ============ Delivery Tip Methods ============
  Future<void> selectTip(String tip, BuildContext context) async {
    // If clicking the same tip, deselect it (toggle)
    if (selectedTip == tip) {
      selectedTip = '';
      tipAmount = 0.0;
      notifyListeners();

      // Clear tip from API and refresh cart
      await saveCartMetadata(
        context: context,
        deliveryTip: 0.0,
      );

      // Refresh cart to get updated billing calculations
      await refreshCart(context: context, silent: true);
      return;
    }

    // Select new tip
    selectedTip = tip;

    switch (tip) {
      case '₹10':
        tipAmount = 10.0;
        break;
      case '₹20':
        tipAmount = 20.0;
        break;
      case '₹30':
        tipAmount = 30.0;
        break;
      case '₹50':
        tipAmount = 50.0;
        break;
      case 'Other':
        tipAmount = 0.0;
        break;
      default:
        tipAmount = 0.0;
    }

    notifyListeners();

    // Save tip to API (only if not "Other" which requires manual input)
    if (tip != 'Other' && tipAmount > 0) {
      await saveCartMetadata(
        context: context,
        deliveryTip: tipAmount,
      );

      // Refresh cart to get updated billing calculations
      await refreshCart(context: context, silent: true);
    }
  }

  Future<void> setCustomTipAmount(double amount, BuildContext context) async {
    if (amount >= 0) {
      tipAmount = amount;
      selectedTip = 'Other';
      notifyListeners();

      // Save custom tip to API
      await saveCartMetadata(
        context: context,
        deliveryTip: tipAmount,
      );

      // Refresh cart to get updated billing calculations
      await refreshCart(context: context, silent: true);
    }
  }

  bool isTipSelected(String tip) {
    return selectedTip == tip;
  }

  Future<void> clearTip(BuildContext context) async {
    selectedTip = '';
    tipAmount = 0.0;
    notifyListeners();

    // Clear tip from API
    await saveCartMetadata(
      context: context,
      deliveryTip: 0.0,
    );

    // Refresh cart to get updated billing calculations
    await refreshCart(context: context, silent: true);
  }

  // ============ Order Note Methods ============
  void setOrderNote(String note) {
    orderNote = note.trim();
    notifyListeners();
  }

  void clearOrderNote() {
    orderNote = '';
    notifyListeners();
  }

  // ============ Personal Details Methods ============
  void updateUserName(String name) {
    userName = name.trim();
    notifyListeners();
  }

  void updateUserPhone(String phone) {
    userPhone = phone.trim();
    notifyListeners();
  }

  void updateDeliveryAddress(String address) {
    deliveryAddress = address.trim();
    Constant.session.setData(SessionManager.keyAddress, address.trim(), true);
    notifyListeners();
  }

  bool isPersonalDetailsComplete() {
    return userName.isNotEmpty &&
        userName != "Guest User" &&
        userPhone.isNotEmpty &&
        userPhone.length >= 10 &&
        deliveryAddress.isNotEmpty &&
        deliveryAddress != "Add delivery address";
  }

  // ============ Wallet Methods ============
  Future<void> toggleWalletUsage(BuildContext context) async {
    useWallet = !useWallet;
    // Switching the wallet off drops any partial amount, so switching it back
    // on starts from "cover the whole bill" again.
    if (!useWallet) {
      walletAmountToUse = null;
    }
    notifyListeners();

    // Persist the wallet selection for BOTH enable and disable so the saved
    // cart metadata stays in sync. The checkout screen reads this flag when it
    // re-fetches charges; if we only ever saved `true`, the flag stayed
    // "sticky-on" and the wallet got auto-applied on later checkouts.
    await saveCartMetadata(
      context: context,
      walletAmount: useWallet && userBalance > 0,
    );

    // Refresh cart to get updated pricing with wallet applied
    await refreshCart(context: context, silent: true);
  }

  /// Applies a partial wallet amount. Pass null to go back to letting the
  /// wallet cover as much of the bill as the balance allows.
  Future<void> setWalletAmount(BuildContext context, double? amount) async {
    final capped = (amount == null || amount <= 0)
        ? null
        : (amount > maxUsableWalletAmount ? maxUsableWalletAmount : amount);

    walletAmountToUse = capped;
    if (!useWallet) useWallet = true;
    notifyListeners();

    await saveCartMetadata(
      context: context,
      walletAmount: userBalance > 0,
      // '' clears the stored amount and restores whole-balance behaviour
      walletAmountValue: capped?.toStringAsFixed(2) ?? '',
    );

    await refreshCart(context: context, silent: true);
  }

  // ============ Calculate Methods ============
  double getTotalWithTip() {
    return subTotal + tipAmount;
  }

  double getFinalBillAmount({
    double deliveryCharge = 40.0,
    double platformFee = 5.0,
    double gst = 8.0,
  }) {
    // Use billing summary from API if available
    final billingSummary = cartData?.data.billingSummary;
    if (billingSummary != null) {
      return billingSummary.toBePaid;
    }

    // Fallback to manual calculation
    double total = subTotal + deliveryCharge + platformFee + gst + tipAmount;
    if (Constant.isPromoCodeApplied) {
      total -= Constant.discount;
    }
    return total > 0 ? total : 0.0;
  }

  double getTotalSavings() {
    double totalSavings = 0.0;

    // Sum all discount items from billing breakdown
    final billingBreakdown = cartData?.data.billingBreakdown ?? [];
    for (final item in billingBreakdown) {
      // isCredit means it's a discount/credit (reduces the total)
      if (item.isCredit) {
        totalSavings += item.amount;
      }
    }

    // If no billing breakdown, fallback to billing summary
    if (totalSavings == 0.0) {
      final billingSummary = cartData?.data.billingSummary;
      if (billingSummary != null) {
        totalSavings = billingSummary.savings + billingSummary.discount;
      } else {
        // Last resort: use savedAmount
        totalSavings = savedAmount;
        if (Constant.isPromoCodeApplied) {
          totalSavings += Constant.discount;
        }
      }
    }

    return totalSavings;
  }

  // ============ Billing Summary Getters ============
  double getDeliveryCharge() {
    return cartData?.data.billingSummary.deliveryCharge ?? 0.0;
  }

  double getGSTCharges() {
    return cartData?.data.billingSummary.gstCharges ?? 0.0;
  }

  double getAdditionalCharges() {
    return cartData?.data.billingSummary.additionalCharges ?? 0.0;
  }

  double getDiscount() {
    return cartData?.data.billingSummary.discount ?? 0.0;
  }

  String getCurrency() {
    return cartData?.data.billingSummary.currency ?? '₹';
  }

  // ============ Validation Methods ============
  bool canProceedToCheckout() {
    return totalItemsCount > 0 &&
        isPersonalDetailsComplete() &&
        cartState == CartState.loaded;
  }

  String? getCheckoutValidationError() {
    if (totalItemsCount == 0) {
      return "Your cart is empty";
    }
    if (!isPersonalDetailsComplete()) {
      return "Please complete your personal details";
    }
    if (cartState == CartState.loading) {
      return "Please wait while we load your cart";
    }
    return null;
  }

  // ============ Refresh Cart ============
  Future<void> refreshCart({
    required BuildContext context,
    bool silent = true,
  }) async {
    if (Constant.session.isUserLoggedIn()) {
      await getCartListProvider(context: context, silent: silent);
    } else {
      await getGuestCartListProvider(context: context, silent: silent);
    }
    // Force UI update to ensure billing details refresh
    notifyListeners();
  }

  // ============ Cart Metadata API Methods ============
  Future<bool> saveCartMetadata({
    required BuildContext context,
    int? sellerId,
    String? sellerNote,
    int? comboId,
    String? comboNote,
    double? deliveryTip,
    String? deliveryInstructions,
    String? directionsToReach,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? promoCode,
    String? promoCodeId,
    bool? walletAmount,
    String? walletAmountValue,
  }) async {
    try {
      Map<String, dynamic> params = {};

      // Add seller notes - send ALL existing notes plus the new one
      if (sellerId != null && sellerNote != null) {
        Map<String, String> sellerNotes = {};
        // Preserve existing notes from cart metadata
        if (cartData?.data.cartMetadata.sellerNotes.isNotEmpty == true) {
          sellerNotes.addAll(cartData!.data.cartMetadata.sellerNotes);
        }
        // Add or update the new note
        sellerNotes[sellerId.toString()] = sellerNote;
        params['seller_notes'] = sellerNotes;
      }

      // Add combo notes - send ALL existing notes plus the new one
      if (comboId != null && comboNote != null) {
        Map<String, String> comboNotes = {};
        // Preserve existing notes from cart metadata
        if (cartData?.data.cartMetadata.comboNotes.isNotEmpty == true) {
          comboNotes.addAll(cartData!.data.cartMetadata.comboNotes);
        }
        // Add or update the new note
        comboNotes[comboId.toString()] = comboNote;
        params['combo_notes'] = comboNotes;
      }

      // Add delivery tip
      if (deliveryTip != null) {
        params['delivery_tip'] = deliveryTip;
      }

      // Add delivery instructions
      if (deliveryInstructions != null && deliveryInstructions.isNotEmpty) {
        params['delivery_instructions'] = deliveryInstructions;
      }

      // Add directions to reach separately
      if (directionsToReach != null && directionsToReach.isNotEmpty) {
        params['directions_to_reach'] = directionsToReach;
      }

      // Add contact details
      if (contactName != null && contactName.isNotEmpty) {
        params['contact_name'] = contactName;
      }

      if (contactPhone != null && contactPhone.isNotEmpty) {
        params['contact_phone'] = contactPhone;
      }

      if (contactEmail != null && contactEmail.isNotEmpty) {
        params['contact_email'] = contactEmail;
      }

      // Add promo code details
      if (promoCode != null) {
        params['promo_code'] = promoCode;
      }

      if (promoCodeId != null) {
        params['promocode_id'] = promoCodeId;
      }

      // Add wallet amount. Send as '1'/'0' string: params are serialized via
      // toString(), and PHP's (bool) cast treats the string "false" as TRUE,
      // so a boolean false would never disable the wallet on the backend.
      if (walletAmount != null) {
        params['wallet_amount'] = walletAmount ? '1' : '0';
      }

      // Partial wallet amount. An empty string clears it on the backend, which
      // restores the "cover the whole bill" default.
      if (walletAmountValue != null) {
        params['wallet_amount_value'] = walletAmountValue;
      }

      if (params.isEmpty) {
        developer.log('No metadata to save');
        return false;
      }

      developer.log("Saving cart metadata: $params");

      Map<String, dynamic> response =
          await saveCartMetadataApi(context: context, params: params);

      if (response['error'] == false || response['status'] == 1) {
        developer.log("Cart metadata saved successfully");

        // Update local cart billing info without full refresh to preserve scroll position
        if (response['data'] != null) {
          if (cartData != null) {
            // Note: We don't update cartMetadata here because it's late final
            // The metadata is already loaded from the cart and will be refreshed if needed

            // Update billing summary if available from API response
            if (response['data']['billing_summary'] != null) {
              cartData!.data.billingSummary = BillingSummary.fromJson(response['data']['billing_summary']);
              _updateCartTotals();
            } else if (deliveryTip != null) {
              // Fallback: manually update tip if billing_summary not in response
              cartData!.data.billingSummary.deliveryTip = deliveryTip;
              _updateCartTotals();
            }

            // Update billing breakdown if available
            if (response['data']['billing_breakdown'] != null) {
              final breakdownList = response['data']['billing_breakdown'] as List;
              cartData!.data.billingBreakdown = breakdownList
                  .map((item) => BillingBreakdownItem.fromJson(item))
                  .toList();
            }

            notifyListeners();
          }
        }

        return true;
      } else {
        developer.log("Failed to save cart metadata: ${response['message']}");
        return false;
      }
    } catch (e) {
      developer.log("Error saving cart metadata: $e");
      return false;
    }
  }

  Future<bool> clearCartMetadata({
    required BuildContext context,
    List<String>? fields,
  }) async {
    try {
      Map<String, dynamic> params = {};
      if (fields != null && fields.isNotEmpty) {
        params['fields'] = fields;
      }

      Map<String, dynamic> response =
          await clearCartMetadataApi(context: context, params: params);

      if (response['error'] == false) {
        developer.log("Cart metadata cleared successfully");
        // Refresh cart to get updated metadata
        await getCartListProvider(context: context, silent: true);
        return true;
      } else {
        developer.log("Failed to clear cart metadata: ${response['message']}");
        return false;
      }
    } catch (e) {
      developer.log("Error clearing cart metadata: $e");
      return false;
    }
  }

  String? getSellerNote(int sellerId) {
    return cartData?.data.cartMetadata.sellerNotes[sellerId.toString()];
  }

  String? getComboNote(int comboId) {
    return cartData?.data.cartMetadata.comboNotes[comboId.toString()];
  }

  // ============ Super Mart Validation ============

  /// Check if cart has any super mart items
  bool hasSupermartItems() {
    if (cartData?.data == null) return false;

    // Check admin managed store items
    for (var item in cartData!.data.adminManagedStore.items) {
      if (item.sellerStore?.isSuperMart == true) {
        return true;
      }
    }

    // Check seller grouped items
    for (var sellerGroup in cartData!.data.groupedBySeller) {
      for (var item in sellerGroup.items) {
        if (item.sellerStore?.isSuperMart == true) {
          return true;
        }
      }
    }

    return false;
  }

  /// Check if cart has any non-super mart items
  bool hasNonSupermartItems() {
    if (cartData?.data == null) return false;

    // Check admin managed store items
    for (var item in cartData!.data.adminManagedStore.items) {
      if (item.sellerStore?.isSuperMart == false) {
        return true;
      }
    }

    // Check seller grouped items
    for (var sellerGroup in cartData!.data.groupedBySeller) {
      for (var item in sellerGroup.items) {
        if (item.sellerStore?.isSuperMart == false) {
          return true;
        }
      }
    }

    return false;
  }

  /// Validate if a new item can be added based on super mart rules
  /// Returns validation result with error message if invalid
  Map<String, dynamic> validateSupermartAddition({
    required bool isSupermartItem,
    String? storeName,
  }) {
    if (cartData?.data == null || totalItemsCount == 0) {
      return {'valid': true};
    }

    // If trying to add supermart item but cart has non-supermart items
    if (isSupermartItem && hasNonSupermartItems()) {
      return {
        'valid': false,
        'message': 'You cannot add items from ${storeName ?? 'this store'} to your cart. Your cart contains items from other stores. Please clear your cart or checkout first.',
      };
    }

    // If trying to add non-supermart item but cart has supermart items
    if (!isSupermartItem && hasSupermartItems()) {
      final supermartStoreName = _getFirstSupermartStoreName();
      return {
        'valid': false,
        'message': 'You cannot add items from other stores. Your cart contains items from ${supermartStoreName ?? 'a supermart'}. Please clear your cart or checkout first.',
      };
    }

    return {'valid': true};
  }

  /// Get the name of the first supermart store in cart
  String? _getFirstSupermartStoreName() {
    if (cartData?.data == null) return null;

    // Check admin managed store items
    for (var item in cartData!.data.adminManagedStore.items) {
      if (item.sellerStore?.isSuperMart == true) {
        return item.sellerStore?.name;
      }
    }

    // Check seller grouped items
    for (var sellerGroup in cartData!.data.groupedBySeller) {
      for (var item in sellerGroup.items) {
        if (item.sellerStore?.isSuperMart == true) {
          return item.sellerStore?.name;
        }
      }
    }

    return null;
  }

  // ============ Reset Cart State ============
  void resetCartState() {
    selectedInstructions.clear();
    customInstruction = '';
    directionsToReach = '';
    selectedTip = '';
    tipAmount = 0.0;
    orderNote = '';
    notifyListeners();
  }

  void resetAll() {
    resetCartList();
    resetCartState();
    notifyListeners();
  }

  // ============ Debug Methods ============
  void logCartState() {
    developer.log('=== Cart State ===');
    developer.log('State: $cartState');
    developer.log('Items Count: $totalItemsCount');
    developer.log('SubTotal: ₹$subTotal');
    developer.log('Tip Amount: ₹$tipAmount');
    developer.log('Final Amount: ₹${getFinalBillAmount()}');
    developer.log('Selected Instructions: $selectedInstructions');
    developer.log('Custom Instruction: $customInstruction');
    developer.log('Order Note: $orderNote');
    developer.log('==================');
  }
}
