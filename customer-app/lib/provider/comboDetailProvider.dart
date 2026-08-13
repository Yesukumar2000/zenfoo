import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/combo.dart';

enum ComboDetailState { initial, loading, loaded, error }

class ComboDetailProvider extends ChangeNotifier {
  ComboDetailState state = ComboDetailState.initial;
  Combo? combo;

  Map<int, ComboVariant> selectedVariants = {};
  Map<int, int> productQuantities = {};

  bool isComboInCart = false;
  int cartComboQuantity = 0;

  bool isBookmarkLoading = false;

  bool isAddingToCart = false;
  bool isUpdatingProduct = false;
  bool isDeletingProduct = false;
  bool isDeletingCombo = false;

  // Track if combo is being edited
  bool isEditingCombo = false;

  Future<void> fetchDetails(BuildContext context, int comboId) async {
    state = ComboDetailState.loading;
    notifyListeners();
    try {
      final res = await fetchComboDetails(context: context, comboId: comboId);
      if (res != null) {
        combo = res;
        _initializeSelectedVariants();
        _checkIfComboInCartFromData(); // ✅ Use the data from API response
        state = ComboDetailState.loaded;
      } else {
        log("Response Error ${res}");
        state = ComboDetailState.error;
      }
    } catch (e, s) {
      log("Exception Error ${e}");
      log("Exception Error ${s}");
      state = ComboDetailState.error;
    }
    notifyListeners();
  }

  void initFromCartCombos(List<CustomCombo> combos) {
    selectedVariants.clear();
    productQuantities.clear();

    for (final combo in combos) {
      for (final p in combo.products) {
        // pick current variant as the one used in cart (variantId)
        ComboVariant? currentVariant;
        try {
          currentVariant = p.variants?.firstWhere((v) => v.id == p.variantId);
        } catch (_) {
          if (p.variants?.isNotEmpty ?? false)
            currentVariant = p.variants?.first;
        }
        if (currentVariant != null) {
          selectedVariants[p.productId ?? 0] = currentVariant;
        }

        // set quantity from cart
        productQuantities[p.productId ?? 0] = p.quantity ?? 1;
      }
    }
    notifyListeners();
  }

  void _initializeSelectedVariants() {
    selectedVariants.clear();
    productQuantities.clear();

    if (combo?.stores != null) {
      for (var store in combo!.stores!) {
        if (store.products != null) {
          for (var product in store.products!) {
            if (product.variants != null && product.variants!.isNotEmpty) {
              ComboVariant? defaultVariant;
              try {
                defaultVariant = product.variants!
                    .firstWhere((v) => v.id == product.variantId);
              } catch (e) {
                defaultVariant = product.variants!.first;
              }
              selectedVariants[product.productId!] = defaultVariant;
            }
            productQuantities[product.productId!] = product.quantity ?? 1;
          }
        }
      }
    }
  }

  /// Check if combo is in cart using is_already_added field from API
  void _checkIfComboInCartFromData() {
    if (combo != null) {
      // Check the is_already_added field (1 = in cart, 0 = not in cart)
      isComboInCart = (combo!.isAlreadyAdded == 1);

      // You can also get quantity if your API provides it
      // If not provided, default to 1 when in cart
      cartComboQuantity = isComboInCart ? (combo!.cartQuantity ?? 1) : 0;
    } else {
      isComboInCart = false;
      cartComboQuantity = 0;
    }
  }

  /// Refresh cart status after operations
  Future<void> refreshCartStatus(BuildContext context) async {
    if (combo == null) return;

    try {
      final res =
          await fetchComboDetails(context: context, comboId: combo!.id!);
      if (res != null) {
        combo = res;
        _softRefreshHomeCombos(context);
        _checkIfComboInCartFromData();
        notifyListeners();
      }

      // Refresh cart to update billing details
      await context.read<CartProvider>().refreshCart(
            context: context,
            silent: true,
          );
    } catch (e) {
      // Handle silently or log
    }
  }

  updateSelectedVariant(int productId, ComboVariant variant) {
    selectedVariants[productId] = variant;
    notifyListeners();
  }

  void updateProductQuantity(int productId, int quantity) {
    if (quantity >= 1) {
      productQuantities[productId] = quantity;
      notifyListeners();
    }
  }

  /// Add or edit a custom combo product via API
  Future<Map<String, dynamic>?> addOrEditCustomComboProductProvider({
    required BuildContext context,
    required int comboId,
    required int productId,
    required int variantId,
    required int quantity,
  }) async {
    try {
      // Call your existing API method
      final result = await addOrEditCustomComboProduct(
        context: context,
        comboId: comboId,
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );

      log("✅ addOrEditCustomComboProduct API result: $result");
      return result;
    } catch (e, stackTrace) {
      log("❌ Error in addOrEditCustomComboProduct: $e");
      log("❌ Stack trace: $stackTrace");
      return null;
    }
  }

  /// Update multiple products at once (called from edit modal Done button)
  Future<bool> updateMultipleProducts(
    BuildContext context,
    Map<int, ComboVariant> originalVariants,
    Map<int, int> originalQuantities,
  ) async {
    if (combo == null) return false;

    isUpdatingProduct = true;
    notifyListeners();

    try {
      bool allSuccess = true;

      // Process each product
      for (var entry in selectedVariants.entries) {
        final productId = entry.key;
        final currentVariant = entry.value;
        final currentQuantity = productQuantities[productId] ?? 1;

        final originalVariant = originalVariants[productId];
        final originalQuantity = originalQuantities[productId] ?? 1;

        // Check if variant changed
        final variantChanged = originalVariant?.id != currentVariant.id;

        // Check if quantity changed
        final quantityChanged = currentQuantity != originalQuantity;

        if (variantChanged) {
          // Delete old product
          final deleteResult = await deleteSingleCustomProduct(
            context: context,
            comboId: combo!.id!,
            productId: productId,
          );

          if (deleteResult == null || deleteResult['status'] != 1) {
            allSuccess = false;
            continue;
          }

          // Add new variant with quantity
          final addResult = await addOrEditCustomComboProduct(
            context: context,
            comboId: combo!.id!,
            productId: productId,
            variantId: currentVariant.id!,
            quantity: currentQuantity,
          );

          if (addResult == null || addResult['status'] != 1) {
            allSuccess = false;
          }
        } else if (quantityChanged) {
          // Just update quantity
          final updateResult = await addOrEditCustomComboProduct(
            context: context,
            comboId: combo!.id!,
            productId: productId,
            variantId: currentVariant.id!,
            quantity: currentQuantity,
          );

          if (updateResult == null || updateResult['status'] != 1) {
            allSuccess = false;
          }
        }
      }

      isUpdatingProduct = false;

      // Refresh cart status after update
      await refreshCartStatus(context);

      if (allSuccess) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Combo updated successfully'),
              backgroundColor: ColorsRes.appColorGreen,
            ),
          );
      } else {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Some items failed to update'),
              backgroundColor: ColorsRes.appColorRed,
            ),
          );
      }

      return allSuccess;
    } catch (e) {
      isUpdatingProduct = false;
      notifyListeners();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to update combo'),
            backgroundColor: ColorsRes.appColorRed,
          ),
        );
      return false;
    }
  }

  /// Update multiple products at once (called from edit modal Done button)
  Future<bool> updateMultipleProductsWithComboId(
    BuildContext context,
    Map<int, ComboVariant> originalVariants,
    Map<int, int> originalQuantities,
    int comboId,
  ) async {
    isUpdatingProduct = true;
    notifyListeners();

    try {
      bool allSuccess = true;

      // Process each product
      for (var entry in selectedVariants.entries) {
        final productId = entry.key;
        final currentVariant = entry.value;
        final currentQuantity = productQuantities[productId] ?? 1;

        final originalVariant = originalVariants[productId];
        final originalQuantity = originalQuantities[productId] ?? 1;

        // Check if variant changed
        final variantChanged = originalVariant?.id != currentVariant.id;

        // Check if quantity changed
        final quantityChanged = currentQuantity != originalQuantity;

        if (variantChanged) {
          // Delete old product
          final deleteResult = await deleteSingleCustomProduct(
            context: context,
            comboId: comboId,
            productId: productId,
          );

          if (deleteResult == null || deleteResult['status'] != 1) {
            allSuccess = false;
            continue;
          }

          // Add new variant with quantity
          final addResult = await addOrEditCustomComboProduct(
            context: context,
            comboId: comboId,
            productId: productId,
            variantId: currentVariant.id!,
            quantity: currentQuantity,
          );

          if (addResult == null || addResult['status'] != 1) {
            allSuccess = false;
          }
        } else if (quantityChanged) {
          // Just update quantity
          final updateResult = await addOrEditCustomComboProduct(
            context: context,
            comboId: comboId,
            productId: productId,
            variantId: currentVariant.id!,
            quantity: currentQuantity,
          );

          if (updateResult == null || updateResult['status'] != 1) {
            allSuccess = false;
          }
        }
      }

      isUpdatingProduct = false;

      // Refresh cart status after update
      await refreshCartStatus(context);

      if (allSuccess) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Combo updated successfully'),
              backgroundColor: ColorsRes.appColorGreen,
            ),
          );
      } else {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Some items failed to update'),
              backgroundColor: ColorsRes.appColorRed,
            ),
          );
      }

      return allSuccess;
    } catch (e) {
      isUpdatingProduct = false;
      notifyListeners();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to update combo'),
            backgroundColor: ColorsRes.appColorRed,
          ),
        );
      return false;
    }
  }

  Future<bool> addComboToCart(BuildContext context) async {
    if (combo == null) return false;

    isAddingToCart = true;
    notifyListeners();

    try {
      List<Map<String, dynamic>> products = [];

      selectedVariants.forEach((productId, variant) {
        final quantity = productQuantities[productId] ?? 1;
        products.add({
          "product_id": productId,
          "variant_id": variant.id,
          "quantity": quantity,
        });
      });

      if (products.isEmpty) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Please add at least one product to the combo'),
              backgroundColor: ColorsRes.appColorRed,
            ),
          );
        isAddingToCart = false;
        notifyListeners();
        return false;
      }

      final result = await storeCustomComboCart(
        context: context,
        comboId: combo!.id!,
        products: products,
      );

      if (result != null && result['status'] == 1) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Combo added to cart successfully'),
              backgroundColor: ColorsRes.appColorGreen,
            ),
          );

        // Update cart status
        isComboInCart = true;
        cartComboQuantity = 1;

        // Refresh from API to get latest status
        await refreshCartStatus(context);

        isAddingToCart = false;
        notifyListeners();
        return true;
      } else if (result != null && result['status'] == 0) {
        isAddingToCart = false;
        notifyListeners();

        final responseData = result['data'];
        final hasConflictInData = responseData is Map &&
            (responseData.containsKey('pre_order_conflict') ||
                responseData.containsKey('combo_conflict'));
        final hasConflictTopLevel =
            result.containsKey('pre_order_conflict') ||
                result.containsKey('combo_conflict');
        if (hasConflictInData || hasConflictTopLevel) {
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
                (responseData is Map
                        ? responseData['message']?.toString()
                        : null) ??
                    result['message']?.toString() ??
                    'Cannot add this item. Please clear your cart first.',
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
        } else {
          showMessage(
              context,
              result['message'] ?? 'Failed to add combo to cart',
              MessageType.error);
        }
        return false;
      }
    } catch (e) {
      showMessage(context, 'Failed to add combo to cart', MessageType.error);
    }
    isAddingToCart = false;
    notifyListeners();
    return false;
  }

  Future<bool> addComboToCartWithComboId(
    BuildContext context,
    int comboId,
  ) async {
    isAddingToCart = true;
    notifyListeners();

    try {
      List<Map<String, dynamic>> products = [];

      selectedVariants.forEach((productId, variant) {
        final quantity = productQuantities[productId] ?? 1;
        products.add({
          "product_id": productId,
          "variant_id": variant.id,
          "quantity": quantity,
        });
      });

      if (products.isEmpty) {
        showMessage(context, 'Please add at least one product to the combo',
            MessageType.error);
        isAddingToCart = false;
        notifyListeners();
        return false;
      }

      final result = await storeCustomComboCart(
        context: context,
        comboId: comboId,
        products: products,
      );

      if (result != null && result['status'] == 1) {
        // Update cart status
        isComboInCart = true;
        cartComboQuantity = 1;

        // Refresh from API to get latest status
        await refreshCartStatus(context);

        isAddingToCart = false;
        notifyListeners();
        return true;
      } else if (result != null && result['status'] == 0) {
        isAddingToCart = false;
        notifyListeners();

        final responseData = result['data'];
        final hasConflictInData = responseData is Map &&
            (responseData.containsKey('pre_order_conflict') ||
                responseData.containsKey('combo_conflict'));
        final hasConflictTopLevel =
            result.containsKey('pre_order_conflict') ||
                result.containsKey('combo_conflict');
        if (hasConflictInData || hasConflictTopLevel) {
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
                (responseData is Map
                        ? responseData['message']?.toString()
                        : null) ??
                    result['message']?.toString() ??
                    'Cannot add this item. Please clear your cart first.',
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
        } else {
          showMessage(
            context,
            result['message'] ?? 'Failed to add combo to cart',
            MessageType.error,
          );
        }
        return false;
      }
    } catch (e) {
      showMessage(context, 'Failed to add combo to cart', MessageType.error);
    }

    isAddingToCart = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateProductInCart(
    BuildContext context,
    int productId,
  ) async {
    if (combo == null) return false;

    final variant = selectedVariants[productId];
    final quantity = productQuantities[productId];

    if (variant == null || quantity == null) return false;

    try {
      final result = await addOrEditCustomComboProduct(
        context: context,
        comboId: combo!.id!,
        productId: productId,
        variantId: variant.id!,
        quantity: quantity,
      );

      if (result != null && result['status'] == 1) {
        return true;
      }
    } catch (e) {
      return false;
    }

    return false;
  }

  Future<bool> updateCartComboProduct({
    required BuildContext context,
    required int comboId,
    required int productId,
  }) async {
    final variant = selectedVariants[productId];
    final quantity = productQuantities[productId];
    if (variant == null || quantity == null) return false;

    try {
      final result = await addOrEditCustomComboProduct(
        context: context,
        comboId: comboId,
        productId: productId,
        variantId: variant.id!,
        quantity: quantity,
      );
      return result != null && result['status'] == 1;
    } catch (_) {
      return false;
    }
  }

  /// Add or update a product in the combo (wrapper for external use)
  /// Refreshes the combo details after successful update
  Future<bool> addOrUpdateComboProduct({
    required BuildContext context,
    required int productId,
    required int variantId,
    required int quantity,
  }) async {
    if (combo == null) return false;

    isAddingToCart =
        true; // Use valid state flag or create new one if needed, reusing for loading indicator
    notifyListeners();

    try {
      final result = await addOrEditCustomComboProduct(
        context: context,
        comboId: combo!.id!,
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );

      if (result != null && result['status'] == 1) {
        await refreshCartStatus(context);
        isAddingToCart = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    isAddingToCart = false;
    notifyListeners();
    return false;
  }

  Future<void> _softRefreshHomeCombos(BuildContext context) async {
    try {
      await context.read<HomeScreenProvider>().fetchHomeCombos(
            context,
          );
    } catch (_) {}
  }

  Future<bool> removeProduct(BuildContext context, int productId) async {
    if (combo == null) return false;

    isDeletingProduct = true;
    notifyListeners();

    try {
      final result = await deleteSingleCustomProduct(
        context: context,
        comboId: combo!.id!,
        productId: productId,
      );

      if (result != null && result['status'] == 1) {
        selectedVariants.remove(productId);
        productQuantities.remove(productId);

        if (combo?.stores != null) {
          for (var store in combo!.stores!) {
            store.products?.removeWhere((p) => p.productId == productId);
          }
        }

        // Refresh cart status
        await refreshCartStatus(context);

        if (selectedVariants.isEmpty) {
          isComboInCart = false;
          cartComboQuantity = 0;
        }

        isDeletingProduct = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to remove product'),
            backgroundColor: ColorsRes.appColorRed,
          ),
        );
    }

    isDeletingProduct = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteComboFromCart(BuildContext context) async {
    if (combo == null) return false;

    isDeletingCombo = true;
    notifyListeners();

    try {
      final result = await deleteCustomComboCart(
        context: context,
        comboId: combo!.id!,
      );

      if (result != null && result['status'] == 1) {
        isComboInCart = false;
        cartComboQuantity = 0;

        // Refresh cart status
        await refreshCartStatus(context);

        isDeletingCombo = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to delete combo'),
            backgroundColor: ColorsRes.appColorRed,
          ),
        );
    }

    isDeletingCombo = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteComboFromCartWithComboId(
    BuildContext context,
    int comboId,
  ) async {
    isDeletingCombo = true;
    notifyListeners();

    try {
      final result = await deleteCustomComboCart(
        context: context,
        comboId: comboId,
      );

      if (result != null && result['status'] == 1) {
        isComboInCart = false;
        cartComboQuantity = 0;

        // Refresh cart status
        await refreshCartStatus(context);

        isDeletingCombo = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to delete combo'),
            backgroundColor: ColorsRes.appColorRed,
          ),
        );
    }

    isDeletingCombo = false;
    notifyListeners();
    return false;
  }

  Future<bool> increaseComboQuantity(BuildContext context) async {
    if (!isComboInCart || combo == null) return false;

    List<Map<String, dynamic>> products = [];
    selectedVariants.forEach((productId, variant) {
      final quantity = productQuantities[productId] ?? 1;
      products.add({
        "product_id": productId,
        "variant_id": variant.id,
        "quantity": quantity,
      });
    });

    final result = await storeCustomComboCart(
      context: context,
      comboId: combo!.id!,
      products: products,
    );

    if (result != null && result['status'] == 1) {
      cartComboQuantity++;

      // Refresh cart status
      await refreshCartStatus(context);

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> decreaseComboQuantity(BuildContext context) async {
    if (!isComboInCart || combo == null || cartComboQuantity <= 1) {
      if (cartComboQuantity == 1) {
        return await deleteComboFromCart(context);
      }
      return false;
    }

    List<Map<String, dynamic>> products = [];
    selectedVariants.forEach((productId, variant) {
      final quantity = productQuantities[productId] ?? 1;
      products.add({
        "product_id": productId,
        "variant_id": variant.id,
        "quantity": quantity,
      });
    });

    final result = await storeCustomComboCart(
      context: context,
      comboId: combo!.id!,
      products: products,
    );

    if (result != null && result['status'] == 1) {
      cartComboQuantity--;
      if (cartComboQuantity == 0) {
        isComboInCart = false;
      }

      // Refresh cart status
      await refreshCartStatus(context);

      notifyListeners();
      return true;
    }
    return false;
  }

  double get totalActualPrice {
    double total = 0;
    selectedVariants.forEach((productId, variant) {
      final quantity = productQuantities[productId] ?? 1;
      total += (variant.actualPrice ?? 0) * quantity;
    });
    return total;
  }

  double get totalPrice {
    double total = 0;
    selectedVariants.forEach((productId, variant) {
      final quantity = productQuantities[productId] ?? 1;
      total += (variant.price ?? 0) * quantity;
    });
    return total;
  }

  double get totalSavings => totalActualPrice - totalPrice;

  int get totalProducts => selectedVariants.length;

  int get totalItems {
    int total = 0;
    productQuantities.forEach((productId, quantity) {
      total += quantity;
    });
    return total;
  }

  void toggleEditingMode() {
    isEditingCombo = !isEditingCombo;
    notifyListeners();
  }

  void setEditingMode(bool value) {
    isEditingCombo = value;
    notifyListeners();
  }

  /// Toggle combo bookmark status
  Future<bool> toggleComboBookmark(BuildContext context) async {
    if (combo == null) return false;

    isBookmarkLoading = true;
    notifyListeners();

    try {
      final result = await toggleComboBookmarkApi(
        context: context,
        comboId: combo!.id!,
      );

      if (result != null && result['status'] == 1) {
        // Toggle the bookmark status
        combo!.isBookmarked = !(combo!.isBookmarked ?? false);
        notifyListeners();

        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Bookmark updated'),
              backgroundColor: ColorsRes.appColorGreen,
            ),
          );
        return true;
      } else {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(result?['message'] ?? 'Failed to update bookmark'),
              backgroundColor: ColorsRes.appColorRed,
            ),
          );
      }
    } catch (e) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to update bookmark'),
            backgroundColor: ColorsRes.appColorRed,
          ),
        );
    }

    isBookmarkLoading = false;
    notifyListeners();
    return false;
  }

  void reset() {
    combo = null;
    selectedVariants.clear();
    productQuantities.clear();
    isComboInCart = false;
    cartComboQuantity = 0;
    isAddingToCart = false;
    isUpdatingProduct = false;
    isDeletingProduct = false;
    isDeletingCombo = false;
    isEditingCombo = false;
    state = ComboDetailState.initial;
    notifyListeners();
  }
}
