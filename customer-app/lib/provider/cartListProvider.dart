import 'package:project/helper/utils/generalImports.dart';

enum CartListState { initial, loaded, loading, error }

class CartListProvider extends ChangeNotifier {
  CartListState cartListState = CartListState.initial;
  List<CartList> cartList = [];
  String currentSelectedProduct = "";
  String currentSelectedVariant = "";

  Future<void> addRemoveCartItemFromLocalList({
    required String productId,
    required String productVariantId,
    required String qty,
    required String sellerId,
  }) async {
    if (int.parse(qty) == 0) {
      cartList.removeWhere((element) =>
          element.productId == productId &&
          element.productVariantId == productVariantId);
      cartListState = CartListState.loaded;
      notifyListeners();
    } else {
      cartList.removeWhere((element) =>
          element.productId == productId &&
          element.productVariantId == productVariantId);

      cartList.add(
        CartList(
          productId: productId,
          productVariantId: productVariantId,
          qty: qty,
          sellerId: sellerId,
        ),
      );

      Constant.session.setData(SessionManager.keyGuestCartItems,
          CartList.CartItemsToJson(cartList), false);
      cartListState = CartListState.loaded;
      notifyListeners();
    }
  }

  Future<void> getAllCartItems({required BuildContext context}) async {
    if (Constant.session.isUserLoggedIn()) {
      cartList.clear();
      try {
        Map<String, String> params = await Constant.getProductsDefaultParams();
        Map<String, dynamic> getData =
            await getCartListApi(context: context, params: params);

        if (getData[ApiAndParams.status].toString() == "1") {
          final data = getData[ApiAndParams.data] ?? {};

          // 1) All normal cart items (admin + sellers)
          List<CartItem> allCarts = [];

          // Admin managed store items
          if (data['admin_managed_store'] != null &&
              data['admin_managed_store']['items'] != null) {
            List<CartItem> adminItems =
                (data['admin_managed_store']['items'] as List)
                    .map((e) => CartItem.fromJson(Map.from(e)))
                    .toList();
            allCarts.addAll(adminItems);
          }

          // Seller grouped items
          if (data['grouped_by_seller'] != null) {
            List<dynamic> sellerGroups = data['grouped_by_seller'] as List;
            for (var sellerGroup in sellerGroups) {
              if (sellerGroup['items'] != null) {
                List<CartItem> sellerItems = (sellerGroup['items'] as List)
                    .map((e) => CartItem.fromJson(Map.from(e)))
                    .toList();
                allCarts.addAll(sellerItems);
              }
            }
          }

          // 2) Map normal cart items into local cartList
          for (int i = 0; i < allCarts.length; i++) {
            cartList.add(
              CartList(
                productId: allCarts[i].productId.toString(),
                productVariantId: allCarts[i].productVariantId.toString(),
                qty: allCarts[i].qty.toString(),
                sellerId: allCarts[i].sellerId.toString(),
              ),
            );
          }

          // 3) Add combo products into cartList as normal items
          if (data['custom_combos'] != null &&
              data['custom_combos'] is List &&
              (data['custom_combos'] as List).isNotEmpty) {
            List<dynamic> combos = data['custom_combos'] as List;

            for (var combo in combos) {
              final comboProducts = combo['products'] as List? ?? [];
              for (var p in comboProducts) {
                final productId = p['product_id']?.toString() ?? '';
                final variantId = p['variant_id']?.toString() ?? '';
                final quantity = p['quantity']?.toString() ?? '1';

                if (productId.isEmpty || variantId.isEmpty) continue;

                // For combos seller_id may not be needed in local checks,
                // use "0" or any consistent value if API does not give it.
                final sellerId = (p['seller_id'] ?? 0).toString();

                // Remove any existing entry with same product+variant
                cartList.removeWhere((element) =>
                    element.productId == productId &&
                    element.productVariantId == variantId);

                cartList.add(
                  CartList(
                    productId: productId,
                    productVariantId: variantId,
                    qty: quantity,
                    sellerId: sellerId,
                  ),
                );
              }
            }
          }

          // 4) Persist guest cache for safety (optional)
          Constant.session.setData(
            SessionManager.keyGuestCartItems,
            CartList.CartItemsToJson(cartList),
            false,
          );

          // 5) Update CartProvider summary (subtotal, item count) from API
          try {
            final subTotal =
                double.parse(data['sub_total']?.toString() ?? '0.0');
            context.read<CartProvider>().setSubTotal(subTotal);

            // Total items = normal items + combo products count
            int totalItems = 0;
            if (data['admin_managed_store'] != null &&
                data['admin_managed_store']['items'] != null) {
              totalItems +=
                  (data['admin_managed_store']['items'] as List).length;
            }
            if (data['grouped_by_seller'] != null) {
              List<dynamic> sellers = data['grouped_by_seller'] as List;
              for (var seller in sellers) {
                if (seller['items'] != null) {
                  totalItems += (seller['items'] as List).length;
                }
              }
            }
            if (data['custom_combos'] != null &&
                data['custom_combos'] is List) {
              final combos = data['custom_combos'] as List;
              for (var combo in combos) {
                final comboProducts = combo['products'] as List? ?? [];
                totalItems += comboProducts.length;
              }
            }

            context.read<CartProvider>().setItemCount(totalItems);
          } catch (_) {
            // ignore parsing issues, keep provider unchanged
          }

          cartListState = CartListState.loaded;
          notifyListeners();
        }
      } catch (e) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: ColorsRes.appColorRed,
            ),
          );
        cartListState = CartListState.error;
        notifyListeners();
      }
    }
  }

  // getAllCartItems({required BuildContext context}) async {
  //   if (Constant.session.isUserLoggedIn()) {
  //     cartList.clear();
  //     try {
  //       Map<String, String> params = await Constant.getProductsDefaultParams();
  //       Map<String, dynamic> getData =
  //           await getCartListApi(context: context, params: params);

  //       if (getData[ApiAndParams.status].toString() == "1") {
  //         // Get all cart items from both admin managed store and seller groups
  //         List<CartItem> allCarts = [];

  //         // Get admin managed store items
  //         if (getData[ApiAndParams.data]['admin_managed_store'] != null &&
  //             getData[ApiAndParams.data]['admin_managed_store']['items'] !=
  //                 null) {
  //           List<CartItem> adminItems = (getData[ApiAndParams.data]
  //                   ['admin_managed_store']['items'] as List)
  //               .map((e) => CartItem.fromJson(Map.from(e)))
  //               .toList();
  //           allCarts.addAll(adminItems);
  //         }

  //         // Get seller grouped items
  //         if (getData[ApiAndParams.data]['grouped_by_seller'] != null) {
  //           List<dynamic> sellerGroups =
  //               getData[ApiAndParams.data]['grouped_by_seller'] as List;
  //           for (var sellerGroup in sellerGroups) {
  //             if (sellerGroup['items'] != null) {
  //               List<CartItem> sellerItems = (sellerGroup['items'] as List)
  //                   .map((e) => CartItem.fromJson(Map.from(e)))
  //                   .toList();
  //               allCarts.addAll(sellerItems);
  //             }
  //           }
  //         }

  //         // Add all items to cart list
  //         for (int i = 0; i < allCarts.length; i++) {
  //           cartList.add(
  //             CartList(
  //               productId: allCarts[i].productId.toString(),
  //               productVariantId: allCarts[i].productVariantId.toString(),
  //               qty: (allCarts[i].qty).toString(),
  //               sellerId: allCarts[i].sellerId.toString(),
  //             ),
  //           );
  //         }
  //         notifyListeners();
  //       }
  //     } catch (e) {
  //       String message = e.toString();
  //       showMessage(
  //         context,
  //         message,
  //         MessageType.warning,
  //       );
  //     }
  //   }
  // }

  String getItemCartItemQuantity(String productId, String productVariantId) {
    String quantity = "0";
    for (int i = 0; i < cartList.length; i++) {
      if (cartList[i].productId == productId &&
          cartList[i].productVariantId == productVariantId) {
        quantity = cartList[i].qty;
      }
    }
    return quantity;
  }

  Future addRemoveCartItem({
    required BuildContext context,
    required Map<String, String> params,
    required bool isUnlimitedStock,
    required double maximumAllowedQuantity,
    required double availableStock,
    required String sellerId,
    required String from,
    required String actionFor,
  }) async {
    cartListState = CartListState.loading;
    notifyListeners();


    try {
      Map<String, dynamic> response = {};
      if (int.parse(params[ApiAndParams.qty].toString()) > 0) {
        if (isUnlimitedStock) {
          // if (double.parse(params[ApiAndParams.qty].toString()) >
          //         maximumAllowedQuantity &&
          //     actionFor == "add") {
          //   FocusScope.of(context).unfocus();
          //   ScaffoldMessenger.of(context)
          //     ..hideCurrentSnackBar()
          //     ..showSnackBar(
          //       SnackBar(
          //         content: Text(
          //           getTranslatedValue(
          //             context,
          //             maximumProductsQuantityLimitReachedMessageLabel,
          //           ),
          //         ),
          //         backgroundColor: ColorsRes.appColorRed,
          //       ),
          //     );
          //   cartListState = CartListState.error;
          //   notifyListeners();
          // } else 
          {
            response = await addItemToCartApi(context: context, params: params);

            try {
              if (response[ApiAndParams.status].toString() == "1") {
                // Update subtotal from response.
                // NOTE: the cart/add response returns sub_total /
                // cart_items_count at the TOP level (there is no `data`
                // object). Reading response[data]['sub_total'] threw
                // NoSuchMethodError on null, which was swallowed by the
                // catch below and silently aborted the quantity update.
                double newSubTotal =
                    double.tryParse(response['sub_total']?.toString() ?? '') ??
                        0.0;
                context.read<CartProvider>().setSubTotal(newSubTotal);

                int totalItems = int.tryParse(
                        response['cart_items_count']?.toString() ?? '') ??
                    0;
                context.read<CartProvider>().setItemCount(totalItems);

                addRemoveCartItemFromLocalList(
                    productId: params[ApiAndParams.productId].toString(),
                    productVariantId:
                        params[ApiAndParams.productVariantId].toString(),
                    qty: params[ApiAndParams.qty].toString(),
                    sellerId: sellerId);

                // Refresh cart to get updated prices and billing breakdown
                await context.read<CartProvider>().refreshCart(
                      context: context,
                      silent: true,
                    );
              } else {
                if (response.containsKey(ApiAndParams.data)) {
                  // Check if this is a supermart restriction error
                  final responseData = response[ApiAndParams.data];
                  if (responseData is Map &&
                      responseData.containsKey('super_mart_conflict')) {
                    // Show supermart conflict bottom sheet
                    await _showSupermartConflictDialog(
                      context: context,
                      message: responseData['message']?.toString() ??
                          'You cannot add items from different stores when shopping from a supermart.',
                      existingStoreName:
                          responseData['existing_store_name']?.toString(),
                      newStoreName: responseData['new_store_name']?.toString(),
                      params: params,
                      isUnlimitedStock: isUnlimitedStock,
                      maximumAllowedQuantity: maximumAllowedQuantity,
                      availableStock: availableStock,
                      sellerId: sellerId,
                      from: from,
                      actionFor: actionFor,
                    );
                  } else if (responseData is Map &&
                      (responseData.containsKey('pre_order_conflict') ||
                          responseData.containsKey('combo_conflict'))) {
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        icon: Icon(Icons.warning_amber_rounded,
                            color: ColorsRes.appColorOrange, size: 40),
                        title: Text(
                          'Cannot Add Item',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: Text(
                          responseData['message']?.toString() ??
                              'Cannot add pre-order items with regular products. Please clear your cart to add pre-order items.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        actionsAlignment: MainAxisAlignment.center,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(
                              'OK',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  cartListState = CartListState.error;
                  notifyListeners();
                  return "one_seller_error_code";
                } else {
                  FocusScope.of(context).unfocus();
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          getTranslatedValue(context,
                              response[ApiAndParams.message].toString()),
                        ),
                        backgroundColor: ColorsRes.appColorRed,
                      ),
                    );
                  cartListState = CartListState.error;
                  notifyListeners();
                }
              }
            } catch (e) {
              cartListState = CartListState.error;
              notifyListeners();
              // FocusScope.of(context).unfocus();
              // ScaffoldMessenger.of(context)
              //   ..hideCurrentSnackBar()
              //   ..showSnackBar(
              //     SnackBar(
              //       content: Text(
              //         getTranslatedValue(
              //           context,
              //           maximumProductsQuantityLimitReachedMessageLabel,
              //         ),
              //       ),
              //       backgroundColor: ColorsRes.appColorRed,
              //     ),
              //   );
            }
          }
        } 
        else {
          // if (double.parse(params[ApiAndParams.qty].toString()) >
          //         availableStock &&
          //     actionFor == "add") {
          //   FocusScope.of(context).unfocus();
          //   ScaffoldMessenger.of(context)
          //     ..hideCurrentSnackBar()
          //     ..showSnackBar(
          //       SnackBar(
          //         content: Text(
          //           getTranslatedValue(
          //             context,
          //             outOfStockMessageLabel,
          //           ),
          //         ),
          //         backgroundColor: ColorsRes.appColorRed,
          //       ),
          //     );
          //   cartListState = CartListState.error;
          //   notifyListeners();
          // }
          //  else 
          //  if (double.parse(params[ApiAndParams.qty].toString()) >
          //         maximumAllowedQuantity &&
          //     actionFor == "add") {
          //   log("maximumAllowedQuantity ${maximumAllowedQuantity}");
          //   FocusScope.of(context).unfocus();
          //   ScaffoldMessenger.of(context)
          //     ..hideCurrentSnackBar()
          //     ..showSnackBar(
          //       SnackBar(
          //         content: Text(
          //           getTranslatedValue(
          //             context,
          //             maximumProductsQuantityLimitReachedMessageLabel,
          //           ),
          //         ),
          //         backgroundColor: ColorsRes.appColorRed,
          //       ),
          //     );
          //   cartListState = CartListState.error;
          //   notifyListeners();
          // } else 
          {
            try {
              response =
                  await addItemToCartApi(context: context, params: params);
              if (response[ApiAndParams.status].toString() == "1") {
                log("addRemoveCartItem response $response");
                // Update subtotal from response
                double newSubTotal =
                    double.parse(response['sub_total'].toString());
                context.read<CartProvider>().setSubTotal(newSubTotal);

                // Calculate total items count from grouped structure
                int totalItems = 0;

                context.read<CartProvider>().setItemCount(totalItems);

                addRemoveCartItemFromLocalList(
                  productId: params[ApiAndParams.productId].toString(),
                  productVariantId:
                      params[ApiAndParams.productVariantId].toString(),
                  qty: params[ApiAndParams.qty].toString(),
                  sellerId: sellerId,
                );

                // Refresh cart to get updated prices and billing breakdown
                await context.read<CartProvider>().refreshCart(
                      context: context,
                      silent: true,
                    );
              } else {
                if (response.containsKey(ApiAndParams.data)) {
                  // Check if this is a supermart restriction error
                  final responseData = response[ApiAndParams.data];
                  if (responseData is Map &&
                      responseData.containsKey('super_mart_conflict')) {
                    // Show supermart conflict bottom sheet
                    await _showSupermartConflictDialog(
                      context: context,
                      message: responseData['message']?.toString() ??
                          'You cannot add items from different stores when shopping from a supermart.',
                      existingStoreName:
                          responseData['existing_store_name']?.toString(),
                      newStoreName: responseData['new_store_name']?.toString(),
                      params: params,
                      isUnlimitedStock: isUnlimitedStock,
                      maximumAllowedQuantity: maximumAllowedQuantity,
                      availableStock: availableStock,
                      sellerId: sellerId,
                      from: from,
                      actionFor: actionFor,
                    );
                  } else if (responseData is Map &&
                      (responseData.containsKey('pre_order_conflict') ||
                          responseData.containsKey('combo_conflict'))) {
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        icon: Icon(Icons.warning_amber_rounded,
                            color: ColorsRes.appColorOrange, size: 40),
                        title: Text(
                          'Cannot Add Item',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: Text(
                          responseData['message']?.toString() ??
                              'Cannot add pre-order items with regular products. Please clear your cart to add pre-order items.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        actionsAlignment: MainAxisAlignment.center,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(
                              'OK',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  cartListState = CartListState.error;
                  notifyListeners();
                  return "one_seller_error_code";
                } else {
                  FocusScope.of(context).unfocus();
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          getTranslatedValue(context,
                              response[ApiAndParams.message].toString()),
                        ),
                        backgroundColor: ColorsRes.appColorRed,
                      ),
                    );
                  cartListState = CartListState.error;
                  notifyListeners();
                }
              }
            } catch (e) {
              cartListState = CartListState.error;
              log("addRemoveCartItem error $e");
              notifyListeners();
              // showMessage(
              //   context,
              //   getTranslatedValue(
              //     context,
              //     maximumProductsQuantityLimitReachedMessageLabel,
              //   ),
              //   MessageType.warning,
              // );
            }
          }
        }
      } else {
        response =
            await removeItemFromCartApi(context: context, params: params);

        params[ApiAndParams.qty] = "0";

        if (response[ApiAndParams.status].toString() == "1") {
          // Update subtotal from response
          double newSubTotal = double.parse(response['sub_total'].toString());
          context.read<CartProvider>().setSubTotal(newSubTotal);

          // Calculate total items count from grouped structure
          int totalItems = 0;
          // if (response[ApiAndParams.data]['admin_managed_store'] != null &&
          //     response[ApiAndParams.data]['admin_managed_store']['items'] !=
          //         null) {
          //   totalItems += (response[ApiAndParams.data]['admin_managed_store']
          //           ['items'] as List)
          //       .length;
          // }
          // if (response[ApiAndParams.data]['grouped_by_seller'] != null) {
          //   List<dynamic> sellers =
          //       response[ApiAndParams.data]['grouped_by_seller'] as List;
          //   for (var seller in sellers) {
          //     if (seller['items'] != null) {
          //       totalItems += (seller['items'] as List).length;
          //     }
          //   }
          // }
          context.read<CartProvider>().setItemCount(totalItems);

          addRemoveCartItemFromLocalList(
            productId: params[ApiAndParams.productId].toString(),
            productVariantId: params[ApiAndParams.productVariantId].toString(),
            qty: params[ApiAndParams.qty].toString(),
            sellerId: sellerId,
          );
          if (from == "cartList") {
            context.read<CartProvider>().removeItemFromCartList(
                productId: int.parse(params[ApiAndParams.productId].toString()),
                variantId: int.parse(
                    params[ApiAndParams.productVariantId].toString()));
          }

          // Refresh cart to get updated prices and billing breakdown
          await context.read<CartProvider>().refreshCart(
                context: context,
                silent: true,
              );
        } else {
          if (response.containsKey(ApiAndParams.data)) {
            cartListState = CartListState.error;
            notifyListeners();
            return "one_seller_error_code";
          } else {
            FocusScope.of(context).unfocus();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    getTranslatedValue(
                        context, response[ApiAndParams.message].toString()),
                  ),
                  backgroundColor: ColorsRes.appColorRed,
                ),
              );
            cartListState = CartListState.error;
            notifyListeners();
          }
        }
      }

      if ((await Vibration.hasVibrator())) {
        Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: ColorsRes.appColorRed,
          ),
        );
      cartListState = CartListState.error;
      notifyListeners();
    }
  }

  Future addRemoveGuestCartItem({
    required BuildContext context,
    required Map<String, String> params,
    required bool isUnlimitedStock,
    required double maximumAllowedQuantity,
    required double availableStock,
    required String sellerId,
    String? from = "",
    String? actionFor = "",
  }) async {
    cartListState = CartListState.loading;
    notifyListeners();

    try {
      if (int.parse(params[ApiAndParams.qty].toString()) > 0) {
        if (isUnlimitedStock) {
          // if (double.parse(params[ApiAndParams.qty].toString()) >
          //         maximumAllowedQuantity &&
          //     actionFor == "add") {
          //   FocusScope.of(context).unfocus();
          //   ScaffoldMessenger.of(context)
          //     ..hideCurrentSnackBar()
          //     ..showSnackBar(
          //       SnackBar(
          //         content: Text(
          //           getTranslatedValue(
          //             context,
          //             maximumProductsQuantityLimitReachedMessageLabel,
          //           ),
          //         ),
          //         backgroundColor: ColorsRes.appColorRed,
          //       ),
          //     );
          //   cartListState = CartListState.error;
          //   notifyListeners();
          // } else 
          {
            try {
              if (Constant.oneSellerCart == "1" &&
                  await allCartItemsHasSameSeller()) {
                addRemoveCartItemFromLocalList(
                  productId: params[ApiAndParams.productId].toString(),
                  productVariantId:
                      params[ApiAndParams.productVariantId].toString(),
                  qty: params[ApiAndParams.qty].toString(),
                  sellerId: sellerId,
                ).then(
                  (value) => context
                      .read<CartProvider>()
                      .getGuestCartListProvider(context: context),
                );
              } else if (Constant.oneSellerCart == "0") {
                addRemoveCartItemFromLocalList(
                  productId: params[ApiAndParams.productId].toString(),
                  productVariantId:
                      params[ApiAndParams.productVariantId].toString(),
                  qty: params[ApiAndParams.qty].toString(),
                  sellerId: sellerId,
                ).then(
                  (value) => context
                      .read<CartProvider>()
                      .getGuestCartListProvider(context: context),
                );
              } else {
                cartListState = CartListState.error;
                notifyListeners();
                return "one_seller_error_code";
              }
            } catch (e) {
              cartListState = CartListState.error;
              notifyListeners();
              FocusScope.of(context).unfocus();
              // ScaffoldMessenger.of(context)
              //   ..hideCurrentSnackBar()
              //   ..showSnackBar(
              //     SnackBar(
              //       content: Text(
              //         getTranslatedValue(
              //           context,
              //           maximumProductsQuantityLimitReachedMessageLabel,
              //         ),
              //       ),
              //       backgroundColor: ColorsRes.appColorRed,
              //     ),
              //   );
            }
          }
        } else {
          // if (double.parse(params[ApiAndParams.qty].toString()) >
          //         availableStock &&
          //     actionFor == "add") {
          //   FocusScope.of(context).unfocus();
          //   ScaffoldMessenger.of(context)
          //     ..hideCurrentSnackBar()
          //     ..showSnackBar(
          //       SnackBar(
          //         content: Text(
          //           getTranslatedValue(
          //             context,
          //             outOfStockMessageLabel,
          //           ),
          //         ),
          //         backgroundColor: ColorsRes.appColorRed,
          //       ),
          //     );
          //   cartListState = CartListState.error;
          //   notifyListeners();
          // } else 
          // if (double.parse(params[ApiAndParams.qty].toString()) >
          //         maximumAllowedQuantity &&
          //     actionFor == "add") {
          //   FocusScope.of(context).unfocus();
          //   ScaffoldMessenger.of(context)
          //     ..hideCurrentSnackBar()
          //     ..showSnackBar(
          //       SnackBar(
          //         content: Text(
          //           getTranslatedValue(
          //             context,
          //             maximumProductsQuantityLimitReachedMessageLabel,
          //           ),
          //         ),
          //         backgroundColor: ColorsRes.appColorRed,
          //       ),
          //     );
          //   cartListState = CartListState.error;
          //   notifyListeners();
          // } else 
          {
            try {
              if (Constant.oneSellerCart == "1" &&
                  await allCartItemsHasSameSeller()) {
                addRemoveCartItemFromLocalList(
                  productId: params[ApiAndParams.productId].toString(),
                  productVariantId:
                      params[ApiAndParams.productVariantId].toString(),
                  qty: params[ApiAndParams.qty].toString(),
                  sellerId: sellerId,
                ).then(
                  (value) => context
                      .read<CartProvider>()
                      .getGuestCartListProvider(context: context),
                );
              } else if (Constant.oneSellerCart == "0") {
                addRemoveCartItemFromLocalList(
                  productId: params[ApiAndParams.productId].toString(),
                  productVariantId:
                      params[ApiAndParams.productVariantId].toString(),
                  qty: params[ApiAndParams.qty].toString(),
                  sellerId: sellerId,
                ).then(
                  (value) => context
                      .read<CartProvider>()
                      .getGuestCartListProvider(context: context),
                );
              } else {
                cartListState = CartListState.error;
                notifyListeners();
                return "one_seller_error_code";
              }
            } catch (e) {
              cartListState = CartListState.error;
              notifyListeners();
              FocusScope.of(context).unfocus();
              // ScaffoldMessenger.of(context)
              //   ..hideCurrentSnackBar()
              //   ..showSnackBar(
              //     SnackBar(
              //       content: Text(
              //         getTranslatedValue(
              //           context,
              //           maximumProductsQuantityLimitReachedMessageLabel,
              //         ),
              //       ),
              //       backgroundColor: ColorsRes.appColorRed,
              //     ),
              //   );
            }
          }
        }
      } else {
        params[ApiAndParams.qty] = "0";

        addRemoveCartItemFromLocalList(
          productId: params[ApiAndParams.productId].toString(),
          productVariantId: params[ApiAndParams.productVariantId].toString(),
          qty: params[ApiAndParams.qty].toString(),
          sellerId: sellerId,
        ).then(
          (value) => context
              .read<CartProvider>()
              .getGuestCartListProvider(context: context),
        );
        if (from == "cartList") {
          context.read<CartProvider>().removeItemFromCartList(
              productId: int.parse(params[ApiAndParams.productId].toString()),
              variantId:
                  int.parse(params[ApiAndParams.productVariantId].toString()));
        }
      }

      Constant.session.setData(SessionManager.keyGuestCartItems,
          CartList.CartItemsToJson(cartList), false);

      if ((await Vibration.hasVibrator())) {
        Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: ColorsRes.appColorRed,
          ),
        );
      cartListState = CartListState.error;
      notifyListeners();
    }
  }

  Future clearCart({required BuildContext context}) async {
    cartList.clear();
    context.read<CartProvider>().setSubTotal(0.0);
    context.read<CartProvider>().setItemCount(0);
    context.read<CartProvider>().cartData = null;
    Constant.session.setData(SessionManager.keyGuestCartItems, "", false);
    notifyListeners();
    await removeItemFromCartApi(
        context: context, params: {ApiAndParams.removeAllCartItems: "1"});
  }

  Future allCartItemsHasSameSeller() async {
    bool isSameSeller = true;
    for (int i = 0; i < cartList.length; i++) {
      if (cartList[i].sellerId != cartList[0].sellerId) {
        isSameSeller = false;
        break;
      }
    }
    return isSameSeller;
  }

  Future setGuestCartItems() async {
    cartList = Constant.session.getGuestCartItems();
    notifyListeners();
  }

  /// Show bottom sheet when trying to add items from incompatible stores
  Future<void> _showSupermartConflictDialog({
    required BuildContext context,
    required String message,
    String? existingStoreName,
    String? newStoreName,
    required Map<String, String> params,
    required bool isUnlimitedStock,
    required double maximumAllowedQuantity,
    required double availableStock,
    required String sellerId,
    required String from,
    required String actionFor,
  }) async {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Icon with animated gradient background
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFFF4E5),
                          Color(0xFFFFE5CC),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFF9800).withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      color: Color(0xFFFF9800),
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 24),

                  // Title
                  Text(
                    'Cannot Add This Item',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),

                  // Message
                  Text(
                    'Your cart contains items from a different type of store. To add this item, you need to clear your current cart first.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF666666),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),

                  // Info card
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFE8E8E8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(0xFF9AC444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: Color(0xFF9AC444),
                            size: 22,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You can only shop from one type of store at a time',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Text(
                            'Keep Current Cart',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF666666),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFF5252),
                                Color(0xFFFF1744),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF5252).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();

                              // Clear cart first
                              await clearCart(context: ctx);
                              await context
                                  .read<CartProvider>()
                                  .getCartListProvider(
                                    context: context,
                                  );

                              // Now retry adding the item
                              await addRemoveCartItem(
                                context: context,
                                params: params,
                                isUnlimitedStock: isUnlimitedStock,
                                maximumAllowedQuantity: maximumAllowedQuantity,
                                availableStock: availableStock,
                                sellerId: sellerId,
                                from: from,
                                actionFor: actionFor,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Clear & Add',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}
