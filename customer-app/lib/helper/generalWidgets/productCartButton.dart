import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/provider/comboDetailProvider.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class ProductCartButton extends StatefulWidget {
  final int count;
  final String productId;
  final String sellerId;
  final String productVariantId;
  final bool isUnlimitedStock;
  final double maximumAllowedQuantity;
  final double availableStock;
  final String from;
  final bool isGrid;

  const ProductCartButton({
    Key? key,
    required this.count,
    required this.productId,
    required this.productVariantId,
    required this.isUnlimitedStock,
    required this.maximumAllowedQuantity,
    required this.availableStock,
    required this.isGrid,
    required this.from,
    required this.sellerId,
  }) : super(key: key);

  @override
  State<ProductCartButton> createState() => _ProductCartButtonState();
}

class _ProductCartButtonState extends State<ProductCartButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<CartListProvider>(
      builder: (context, cartListProvider, child) {
        final cartCount = int.tryParse(cartListProvider.getItemCartItemQuantity(
              widget.productId,
              widget.productVariantId,
            )) ??
            0;

        if (cartCount == 0 && widget.count != -1) {
          // ---------- "ADD" UI ----------
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _onAddTap,
              borderRadius: BorderRadius.circular(10),
              child: Ink(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    width: 1.5,
                    color: colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 100,
                    minHeight: 44,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: _isLoading
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ADD',
                              style: GoogleFonts.inter(
                                color: colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.02,
                                letterSpacing: -0.55,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.add_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        } else if (cartCount > 0) {
          // ---------- COUNTER UI ----------
          return Container(
            constraints: const BoxConstraints(
              minWidth: 100,
              minHeight: 44,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(
                width: 1.5,
                color: colorScheme.primary,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Remove button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _onRemoveTap,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    child: Container(
                      width: 36,
                      height: 44,
                      alignment: Alignment.center,
                      child: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.remove_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                    ),
                  ),
                ),
                // Count
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      '$cartCount',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                  ),
                ),
                // Add button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _onAddTap,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: Container(
                      width: 36,
                      height: 44,
                      alignment: Alignment.center,
                      child: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.add_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Out of stock state
          return Container(
            constraints: const BoxConstraints(
              minWidth: 100,
              minHeight: 44,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ColorsRes.appColorRed.withValues(alpha: 0.05),
              border: Border.all(
                width: 1.5,
                color: ColorsRes.appColorRed.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: CustomTextLabel(
              jsonKey: outOfStockLabel,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ColorsRes.appColorRed,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _onAddTap() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    // Haptic feedback
    HapticFeedback.lightImpact();

    final cartListProvider = context.read<CartListProvider>();
    cartListProvider.currentSelectedProduct = widget.productId;
    cartListProvider.currentSelectedVariant = widget.productVariantId;

    Map<String, String> params = {};
    params[ApiAndParams.productId] = widget.productId;
    params[ApiAndParams.productVariantId] = widget.productVariantId;
    params[ApiAndParams.qty] =
        ((int.tryParse(context.read<CartListProvider>().getItemCartItemQuantity(
                          widget.productId,
                          widget.productVariantId,
                        )) ??
                    0) +
                1)
            .toString();

    try {
      if (Constant.session.isUserLoggedIn()) {
        await cartListProvider.addRemoveCartItem(
          context: context,
          params: params,
          isUnlimitedStock: widget.isUnlimitedStock,
          maximumAllowedQuantity: widget.maximumAllowedQuantity,
          availableStock: widget.availableStock,
          actionFor: "add",
          from: widget.from,
          sellerId: widget.sellerId,
        );
      } else {
        await cartListProvider.addRemoveGuestCartItem(
          context: context,
          params: params,
          isUnlimitedStock: widget.isUnlimitedStock,
          maximumAllowedQuantity: widget.maximumAllowedQuantity,
          availableStock: widget.availableStock,
          actionFor: "add",
          from: widget.from,
          sellerId: widget.sellerId,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onRemoveTap() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    // Haptic feedback
    HapticFeedback.lightImpact();

    final cartListProvider = context.read<CartListProvider>();
    cartListProvider.currentSelectedProduct = widget.productId;
    cartListProvider.currentSelectedVariant = widget.productVariantId;

    final currentCartQty =
        int.tryParse(cartListProvider.getItemCartItemQuantity(
              widget.productId,
              widget.productVariantId,
            )) ??
            0;

    if (currentCartQty > 0) {
      Map<String, String> params = {};
      params[ApiAndParams.productId] = widget.productId;
      params[ApiAndParams.productVariantId] = widget.productVariantId;
      params[ApiAndParams.qty] = (currentCartQty - 1).toString();

      try {
        if (Constant.session.isUserLoggedIn()) {
          await cartListProvider.addRemoveCartItem(
            context: context,
            params: params,
            isUnlimitedStock: widget.isUnlimitedStock,
            maximumAllowedQuantity: widget.maximumAllowedQuantity,
            availableStock: widget.availableStock,
            actionFor: "add",
            from: widget.from,
            sellerId: widget.sellerId,
          );
        } else {
          await cartListProvider.addRemoveGuestCartItem(
            context: context,
            params: params,
            isUnlimitedStock: widget.isUnlimitedStock,
            maximumAllowedQuantity: widget.maximumAllowedQuantity,
            availableStock: widget.availableStock,
            actionFor: "add",
            from: widget.from,
            sellerId: widget.sellerId,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }
}

class MiniProductCartButton extends StatefulWidget {
  final int count;
  final String productId;
  final String sellerId;
  final String productVariantId;
  final bool isUnlimitedStock;
  final double maximumAllowedQuantity;
  final double availableStock;
  final String from;
  final bool isGrid;
  final int? comboId;

  const MiniProductCartButton({
    Key? key,
    required this.count,
    required this.productId,
    required this.productVariantId,
    required this.isUnlimitedStock,
    required this.maximumAllowedQuantity,
    required this.availableStock,
    required this.isGrid,
    required this.from,
    required this.sellerId,
    this.comboId,
  }) : super(key: key);

  @override
  State<MiniProductCartButton> createState() => _MiniProductCartButtonState();
}

class _MiniProductCartButtonState extends State<MiniProductCartButton> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    // Reactively get cart count based on mode
    final cartCount = widget.comboId != null
        ? _getComboCartCount(context)
        : _getRegularCartCount(context);

    if (cartCount == 0 && widget.count != -1) {
      return _buildAddButton(colorScheme);
    } else if (cartCount > 0) {
      return _buildCounterButton(cartCount, colorScheme);
    } else {
      return _buildOutOfStockButton(colorScheme);
    }
  }

  int _getComboCartCount(BuildContext context) {
    // Use Selector to listen only to this product's quantity in combo
    return context.select<ComboDetailProvider, int>(
      (provider) =>
          provider.productQuantities[int.tryParse(widget.productId)] ?? 0,
    );
  }

  int _getRegularCartCount(BuildContext context) {
    // Use Selector to listen only to this product's cart quantity
    return context.select<CartListProvider, int>(
      (provider) =>
          int.tryParse(provider.getItemCartItemQuantity(
            widget.productId,
            widget.productVariantId,
          )) ??
          0,
    );
  }

  Widget _buildAddButton(AppColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onAddTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            border: Border.all(
              width: 1.2,
              color: colorScheme.primary,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              minHeight: 34,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ADD',
                  style: GoogleFonts.inter(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 6),
                // The plus says the button adds rather than opens — it is the
                // difference between "ADD" reading as a label and as an action.
                Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterButton(int cartCount, AppColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 100,
        minHeight: 34,
      ),
      // Solid once the item is in the cart, where the untouched state is only
      // outlined. The two states were both white with a green border, so "in
      // your cart" and "not in your cart" looked alike at a glance down a grid.
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onRemoveTap,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: Container(
                width: 28,
                height: 34,
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove_rounded,
                  size: 16,
                  color: colorScheme.buttonPrimaryText,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                '$cartCount',
                style: GoogleFonts.inter(
                  color: colorScheme.buttonPrimaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onAddTap,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Container(
                width: 28,
                height: 34,
                alignment: Alignment.center,
                child: Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: colorScheme.buttonPrimaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutOfStockButton(AppColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 78,
        minHeight: 34,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: ColorsRes.appColorRed.withValues(alpha: 0.05),
        border: Border.all(
          width: 1,
          color: ColorsRes.appColorRed.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        "Out of Stock",
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: ColorsRes.appColorRed,
        ),
      ),
    );
  }

  Future<void> _onAddTap() async {
    log("🔵 ADD TAP - comboId: ${widget.comboId}");
    log("🔵 Product ID: ${widget.productId}, Variant ID: ${widget.productVariantId}");

    if (widget.comboId != null) {
      final comboProvider = context.read<ComboDetailProvider>();
      final productIdInt = int.parse(widget.productId);
      final variantIdInt = int.parse(widget.productVariantId);

      // Check if product already exists in combo
      final currentQty = comboProvider.productQuantities[productIdInt] ?? 0;
      final selectedVariant = comboProvider.selectedVariants[productIdInt];

      log("📊 Current Qty: $currentQty");
      log("📊 Selected Variant: ${selectedVariant?.id ?? 'null'}");
      log("📊 All Quantities: ${comboProvider.productQuantities}");
      log("📊 All Selected Variants: ${comboProvider.selectedVariants.keys.toList()}");

      if (currentQty == 0 || selectedVariant == null) {
        log("✅ Product NOT in combo → ADDING new product");

        // Product not in combo yet → ADD it with current variant
        try {
          final result =
              await comboProvider.addOrEditCustomComboProductProvider(
            context: context,
            comboId: widget.comboId!,
            productId: productIdInt,
            variantId: variantIdInt,
            quantity: 1,
          );

          log("✅ Add result: ${result}");

          // Refresh cart to get updated combo data
          if (Constant.session.isUserLoggedIn()) {
            log("🔄 Refreshing cart for logged in user");
            await context
                .read<CartProvider>()
                .getCartListProvider(context: context);
            final combos =
                context.read<CartProvider>().cartData?.data.customCombos ?? [];
            log("🔄 Found ${combos.length} combos in cart");
            if (combos.isNotEmpty) {
              comboProvider.initFromCartCombos(combos);
              log("✅ Initialized combo provider from cart");
            }
          } else {
            log("🔄 Guest mode - refreshing guest cart");
            // Handle guest cart refresh if needed
          }
        } catch (e) {
          log("❌ Error adding product to combo: $e");
        }
      } else {
        log("✅ Product EXISTS in combo → INCREMENTING quantity");

        // Product exists → INCREMENT quantity
        final newQty = currentQty + 1;
        log("📈 New Qty: $currentQty → $newQty");

        comboProvider.updateProductQuantity(
          productIdInt,
          newQty,
        );

        try {
          final result = await comboProvider.updateCartComboProduct(
            context: context,
            comboId: widget.comboId!,
            productId: productIdInt,
          );

          log("✅ Update result: $result");
        } catch (e) {
          log("❌ Error updating combo product: $e");
        }
      }

      log("🏁 Combo add/update complete");
      return;
    }

    log("🛒 Regular cart mode - not combo");

    // Regular cart add logic (unchanged)
    final cartListProvider = context.read<CartListProvider>();
    cartListProvider.currentSelectedProduct = widget.productId;
    cartListProvider.currentSelectedVariant = widget.productVariantId;

    final currentCartQty =
        int.tryParse(cartListProvider.getItemCartItemQuantity(
              widget.productId,
              widget.productVariantId,
            )) ??
            0;

    log("🛒 Current cart qty: $currentCartQty → ${currentCartQty + 1}");

    Map<String, String> params = {
      ApiAndParams.productId: widget.productId,
      ApiAndParams.productVariantId: widget.productVariantId,
      ApiAndParams.qty: (currentCartQty + 1).toString(),
    };

    log("🛒 Cart params: $params");

    try {
      if (Constant.session.isUserLoggedIn()) {
        log("🛒 Adding to logged in user cart");
        await cartListProvider.addRemoveCartItem(
          context: context,
          params: params,
          isUnlimitedStock: widget.isUnlimitedStock,
          maximumAllowedQuantity: widget.maximumAllowedQuantity,
          availableStock: widget.availableStock,
          actionFor: "add",
          from: widget.from,
          sellerId: widget.sellerId,
        );
      } else {
        log("🛒 Adding to guest cart");
        await cartListProvider.addRemoveGuestCartItem(
          context: context,
          params: params,
          isUnlimitedStock: widget.isUnlimitedStock,
          maximumAllowedQuantity: widget.maximumAllowedQuantity,
          availableStock: widget.availableStock,
          actionFor: "add",
          from: widget.from,
          sellerId: widget.sellerId,
        );
      }
      log("✅ Cart add complete");
    } catch (e) {
      log("❌ Error adding to cart: $e");
    }
  }

  Future<void> _onRemoveTap() async {
    log("🔴 REMOVE TAP - comboId: ${widget.comboId}");
    log("🔴 Product ID: ${widget.productId}, Variant ID: ${widget.productVariantId}");

    if (widget.comboId != null) {
      final comboProvider = context.read<ComboDetailProvider>();
      final productIdInt = int.parse(widget.productId);
      final variantIdInt = int.parse(widget.productVariantId);
      final currentQty = comboProvider.productQuantities[productIdInt] ?? 0;

      log("📊 Current Qty: $currentQty");

      if (currentQty > 0) {
        if (currentQty == 1) {
          log("🗑️ Qty is 1 → REMOVING product from combo");
          try {
            // Call delete API directly
            final result = await deleteSingleCustomProduct(
              context: context,
              comboId: widget.comboId!,
              productId: productIdInt,
            );

            log("✅ Delete result: ${result?['status']} - ${result?['message']}");

            if (result != null && result['status'] == 1) {
              // Remove from local state
              comboProvider.selectedVariants.remove(productIdInt);
              comboProvider.productQuantities.remove(productIdInt);
              comboProvider.notifyListeners();

              // Refresh cart
              if (Constant.session.isUserLoggedIn()) {
                log("🔄 Refreshing cart after delete");
                await context
                    .read<CartProvider>()
                    .getCartListProvider(context: context);
                final combos =
                    context.read<CartProvider>().cartData?.data.customCombos ??
                        [];
                if (combos.isNotEmpty) {
                  comboProvider.initFromCartCombos(combos);
                  log("✅ Reinitialized combo provider from cart");
                }
              }
              log("✅ Product removed successfully");
            } else {
              log("❌ Delete failed: ${result?['message']}");
            }
          } catch (e, stackTrace) {
            log("❌ Error removing product: $e");
            log("❌ Stack trace: $stackTrace");
            showMessage(
              context,
              'Failed to remove product',
              MessageType.error,
            );
          }
        } else {
          log("📉 Qty > 1 → DECREMENTING: $currentQty → ${currentQty - 1}");

          final newQty = currentQty - 1;

          // Update local state first
          comboProvider.updateProductQuantity(productIdInt, newQty);

          try {
            // Call API to update quantity
            final result = await addOrEditCustomComboProduct(
              context: context,
              comboId: widget.comboId!,
              productId: productIdInt,
              variantId: variantIdInt,
              quantity: newQty,
            );

            log("✅ Update result: ${result?['status']} - ${result?['message']}");

            if (result == null || result['status'] != 1) {
              log("❌ Update failed - reverting quantity");
              // Revert on failure
              comboProvider.updateProductQuantity(productIdInt, currentQty);
              showMessage(
                context,
                result?['message']?.toString() ?? 'Failed to update quantity',
                MessageType.warning,
              );
            }
          } catch (e, stackTrace) {
            log("❌ Error updating quantity: $e");
            log("❌ Stack trace: $stackTrace");
            // Revert on error
            comboProvider.updateProductQuantity(productIdInt, currentQty);
            showMessage(
              context,
              'Failed to update combo product',
              MessageType.error,
            );
          }
        }
      } else {
        log("⚠️ Current qty is 0, nothing to remove");
      }

      log("🏁 Combo remove complete");
      return;
    }

    log("🛒 Regular cart mode - removing");

    // Regular cart remove logic
    final cartListProvider = context.read<CartListProvider>();
    cartListProvider.currentSelectedProduct = widget.productId;
    cartListProvider.currentSelectedVariant = widget.productVariantId;

    final currentCartQty =
        int.tryParse(cartListProvider.getItemCartItemQuantity(
              widget.productId,
              widget.productVariantId,
            )) ??
            0;

    log("🛒 Current cart qty: $currentCartQty");

    if (currentCartQty > 0) {
      final newQty = currentCartQty - 1;
      log("🛒 Updating cart qty: $currentCartQty → $newQty");

      Map<String, String> params = {
        ApiAndParams.productId: widget.productId,
        ApiAndParams.productVariantId: widget.productVariantId,
        ApiAndParams.qty: newQty.toString(),
      };

      log("🛒 Cart params: $params");

      try {
        if (Constant.session.isUserLoggedIn()) {
          log("🛒 Removing from logged in user cart");
          await cartListProvider.addRemoveCartItem(
            context: context,
            params: params,
            isUnlimitedStock: widget.isUnlimitedStock,
            maximumAllowedQuantity: widget.maximumAllowedQuantity,
            availableStock: widget.availableStock,
            actionFor: "add",
            from: widget.from,
            sellerId: widget.sellerId,
          );
        } else {
          log("🛒 Removing from guest cart");
          await cartListProvider.addRemoveGuestCartItem(
            context: context,
            params: params,
            isUnlimitedStock: widget.isUnlimitedStock,
            maximumAllowedQuantity: widget.maximumAllowedQuantity,
            availableStock: widget.availableStock,
            actionFor: "add",
            from: widget.from,
            sellerId: widget.sellerId,
          );
        }
        log("✅ Cart remove complete");
      } catch (e) {
        log("❌ Error removing from cart: $e");
      }
    } else {
      log("⚠️ Cart qty is 0, nothing to remove");
    }
  }
}

// class ProductCartButton extends StatefulWidget {
//   final int count;
//   final String productId;
//   final String sellerId;
//   final String productVariantId;
//   final bool isUnlimitedStock;
//   final double maximumAllowedQuantity;
//   final double availableStock;
//   final String from;
//   final bool isGrid;

//   const ProductCartButton({
//     Key? key,
//     required this.count,
//     required this.productId,
//     required this.productVariantId,
//     required this.isUnlimitedStock,
//     required this.maximumAllowedQuantity,
//     required this.availableStock,
//     required this.isGrid,
//     required this.from,
//     required this.sellerId,
//   }) : super(key: key);

//   @override
//   State<ProductCartButton> createState() => _ProductCartButtonState();
// }

// class _ProductCartButtonState
//     extends State<ProductCartButton> /*with TickerProviderStateMixin*/ {
//   late AnimationController animationController;
//   late Animation animation;
//   int currentState = 0;

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<CartListProvider>(
//       builder: (context, cartListProvider, child) {
//         return (int.parse(cartListProvider.getItemCartItemQuantity(
//                         widget.productId, widget.productVariantId)) ==
//                     0 &&
//                 widget.count != -1)
//             ? GestureDetector(
//                 onTap: () async {
//                   // =======================
//                   // Check Cart Max Limit
//                   // =======================
//                   final totalItems = context.read<CartProvider>().totalItemsCount;
//                   // if (totalItems >= int.parse(Constant.maxAllowItemsInCart)) {
//                   //   showMessage(
//                   //     context,
//                   //     getTranslatedValue(context, maximumProductsQuantityLimitReachedMessageLabel),
//                   //     MessageType.success,
//                   //   );

//                   //   return; // Stop further execution
//                   // }
//                   if (Constant.session.isUserLoggedIn()) {
//                     cartListProvider.currentSelectedProduct = widget.productId;
//                     cartListProvider.currentSelectedVariant =
//                         widget.productVariantId;

//                     Map<String, String> params = {};
//                     params[ApiAndParams.productId] = widget.productId;
//                     params[ApiAndParams.productVariantId] =
//                         widget.productVariantId;
//                     params[ApiAndParams.qty] = (int.parse(
//                                 cartListProvider.getItemCartItemQuantity(
//                                     widget.productId,
//                                     widget.productVariantId)) +
//                             1)
//                         .toString();
//                     await cartListProvider
//                         .addRemoveCartItem(
//                       context: context,
//                       params: params,
//                       isUnlimitedStock: widget.isUnlimitedStock,
//                       maximumAllowedQuantity: widget.maximumAllowedQuantity,
//                       availableStock: widget.availableStock,
//                       actionFor: "add",
//                       from: widget.from,
//                       sellerId: widget.sellerId,
//                     )
//                         .then((value) {
//                       if (value is String) {
//                         showDialog<String>(
//                           context: context,
//                           builder: (BuildContext context) => AlertDialog(
//                             surfaceTintColor: ColorsRes.appColorTransparent,
//                             backgroundColor: Theme.of(context).cardColor,
//                             content: CustomTextLabel(
//                               jsonKey: sellerMismatchItemLabel,
//                               softWrap: true,
//                             ),
//                             actions: <Widget>[
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context),
//                                 child: CustomTextLabel(
//                                   jsonKey: cancelLabel,
//                                   softWrap: true,
//                                   style: TextStyle(
//                                       color: ColorsRes.subTitleMainTextColor),
//                                 ),
//                               ),
//                               TextButton(
//                                 onPressed: () async {
//                                   context
//                                       .read<CartListProvider>()
//                                       .clearCart(context: context)
//                                       .then((value) async {
//                                     cartListProvider.currentSelectedProduct =
//                                         widget.productId;
//                                     cartListProvider.currentSelectedVariant =
//                                         widget.productVariantId;

//                                     Map<String, String> params = {};
//                                     params[ApiAndParams.productId] =
//                                         widget.productId;
//                                     params[ApiAndParams.productVariantId] =
//                                         widget.productVariantId;
//                                     params[ApiAndParams
//                                         .qty] = (int.parse(cartListProvider
//                                                 .getItemCartItemQuantity(
//                                                     widget.productId,
//                                                     widget.productVariantId)) +
//                                             1)
//                                         .toString();
//                                     await cartListProvider
//                                         .addRemoveCartItem(
//                                       context: context,
//                                       params: params,
//                                       isUnlimitedStock: widget.isUnlimitedStock,
//                                       maximumAllowedQuantity:
//                                           widget.maximumAllowedQuantity,
//                                       availableStock: widget.availableStock,
//                                       actionFor: "add",
//                                       from: widget.from,
//                                       sellerId: widget.sellerId,
//                                     )
//                                         .then((value) {
//                                       Navigator.pop(context);
//                                     });
//                                   });
//                                 },
//                                 child: CustomTextLabel(
//                                   jsonKey: okLabel,
//                                   softWrap: true,
//                                   style: TextStyle(color: ColorsRes.appColor),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       }
//                     });
//                   } else {
//                     // if (Constant.guestCartOptionIsOn == "1") {
//                     cartListProvider.currentSelectedProduct = widget.productId;
//                     cartListProvider.currentSelectedVariant =
//                         widget.productVariantId;

//                     Map<String, String> params = {};
//                     params[ApiAndParams.productId] = widget.productId;
//                     params[ApiAndParams.productVariantId] =
//                         widget.productVariantId;
//                     params[ApiAndParams.qty] = (int.parse(
//                                 cartListProvider.getItemCartItemQuantity(
//                                     widget.productId,
//                                     widget.productVariantId)) +
//                             1)
//                         .toString();
//                     await cartListProvider
//                         .addRemoveGuestCartItem(
//                       context: context,
//                       params: params,
//                       isUnlimitedStock: widget.isUnlimitedStock,
//                       maximumAllowedQuantity: widget.maximumAllowedQuantity,
//                       availableStock: widget.availableStock,
//                       actionFor: "add",
//                       from: widget.from,
//                       sellerId: widget.sellerId,
//                     )
//                         .then((value) {
//                       if (value is String) {
//                         showDialog<String>(
//                           context: context,
//                           builder: (BuildContext context) => AlertDialog(
//                             surfaceTintColor: ColorsRes.appColorTransparent,
//                             backgroundColor: Theme.of(context).cardColor,
//                             content: CustomTextLabel(
//                               jsonKey: sellerMismatchItemLabel,
//                               softWrap: true,
//                             ),
//                             actions: <Widget>[
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context),
//                                 child: CustomTextLabel(
//                                   jsonKey: cancelLabel,
//                                   softWrap: true,
//                                   style: TextStyle(
//                                       color: ColorsRes.subTitleMainTextColor),
//                                 ),
//                               ),
//                               TextButton(
//                                 onPressed: () async {
//                                   context
//                                       .read<CartListProvider>()
//                                       .clearCart(context: context)
//                                       .then((value) async {
//                                     cartListProvider.currentSelectedProduct =
//                                         widget.productId;
//                                     cartListProvider.currentSelectedVariant =
//                                         widget.productVariantId;

//                                     Map<String, String> params = {};
//                                     params[ApiAndParams.productId] =
//                                         widget.productId;
//                                     params[ApiAndParams.productVariantId] =
//                                         widget.productVariantId;
//                                     params[ApiAndParams
//                                         .qty] = (int.parse(cartListProvider
//                                                 .getItemCartItemQuantity(
//                                                     widget.productId,
//                                                     widget.productVariantId)) +
//                                             1)
//                                         .toString();
//                                     await cartListProvider
//                                         .addRemoveCartItem(
//                                       context: context,
//                                       params: params,
//                                       isUnlimitedStock: widget.isUnlimitedStock,
//                                       maximumAllowedQuantity:
//                                           widget.maximumAllowedQuantity,
//                                       availableStock: widget.availableStock,
//                                       actionFor: "add",
//                                       from: widget.from,
//                                       sellerId: widget.sellerId,
//                                     )
//                                         .then((value) {
//                                       Navigator.pop(context);
//                                     });
//                                   });
//                                 },
//                                 child: CustomTextLabel(
//                                   jsonKey: okLabel,
//                                   softWrap: true,
//                                   style: TextStyle(color: ColorsRes.appColor),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       }
//                     });
//                     // } else {
//                     //   loginUserAccount(context, "cart");
//                     // }
//                   }
//                 },
//                 child: Container(
//                   alignment: AlignmentDirectional.center,
//                   padding: EdgeInsets.symmetric(horizontal: Constant.size10),
//                   decoration: BoxDecoration(
//                     color: ColorsRes.appColorLightHalfTransparent,
//                     borderRadius: BorderRadius.circular(5),
//                   ),
//                   height: 35,
//                   width: context.width * 0.25,
//                   child: (cartListProvider.cartListState ==
//                               CartListState.loading &&
//                           cartListProvider.currentSelectedProduct ==
//                               widget.productId &&
//                           cartListProvider.currentSelectedVariant ==
//                               widget.productVariantId)
//                       ? Container(
//                           alignment: AlignmentDirectional.center,
//                           child: Container(
//                             width: 18,
//                             height: 18,
//                             child: CircularProgressIndicator(
//                               color: ColorsRes.appColor,
//                             ),
//                           ),
//                         )
//                       : FittedBox(
//                           fit: BoxFit.fill,
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               defaultImg(
//                                 image: AppAssets.productCartIcon,
//                                 iconColor: ColorsRes.appColor,
//                               ),
//                               getSizedBox(width: 5),
//                               CustomTextLabel(
//                                 jsonKey: addToCartLabel,
//                                 style: TextStyle(
//                                   color:
//                                       ColorsRes.mainTextColor.withValues(alpha: 0.8),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                 ),
//               )
//             : (int.parse(cartListProvider.getItemCartItemQuantity(
//                             widget.productId, widget.productVariantId)) !=
//                         0 &&
//                     widget.count != -1)
//                 ? Container(
//                     height: 35,
//                     width: context.width * 0.25,
//                     decoration: BoxDecoration(
//                       gradient: DesignConfig.linearGradient(
//                           ColorsRes.appColor, ColorsRes.appColor),
//                       borderRadius: BorderRadiusDirectional.all(
//                         Radius.circular(5),
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         Padding(
//                           padding: EdgeInsetsDirectional.only(start: 5),
//                           child: SizedBox(
//                             height: 25,
//                             width: 25,
//                             child: gradientBtnWidget(
//                               context,
//                               50,
//                               color1: ColorsRes.appColorWhite,
//                               color2: ColorsRes.appColorWhite,
//                               callback: () async {
//                                 cartListProvider.currentSelectedProduct =
//                                     widget.productId;
//                                 cartListProvider.currentSelectedVariant =
//                                     widget.productVariantId;

//                                 Map<String, String> params = {};
//                                 params[ApiAndParams.productId] =
//                                     widget.productId;
//                                 params[ApiAndParams.productVariantId] =
//                                     widget.productVariantId;
//                                 params[ApiAndParams.qty] = (int.parse(
//                                             cartListProvider
//                                                 .getItemCartItemQuantity(
//                                                     widget.productId,
//                                                     widget.productVariantId)) -
//                                         1)
//                                     .toString();

//                                 if (Constant.session.isUserLoggedIn()) {
//                                   await cartListProvider.addRemoveCartItem(
//                                     context: context,
//                                     params: params,
//                                     isUnlimitedStock: widget.isUnlimitedStock,
//                                     maximumAllowedQuantity:
//                                         widget.maximumAllowedQuantity,
//                                     availableStock: widget.availableStock,
//                                     from: widget.from,
//                                     sellerId: widget.sellerId,
//                                     actionFor: "add",
//                                   );
//                                 } else {
//                                   // if (Constant.guestCartOptionIsOn == "1") {
//                                   await cartListProvider.addRemoveGuestCartItem(
//                                     context: context,
//                                     params: params,
//                                     isUnlimitedStock: widget.isUnlimitedStock,
//                                     maximumAllowedQuantity:
//                                         widget.maximumAllowedQuantity,
//                                     availableStock: widget.availableStock,
//                                     from: widget.from,
//                                     actionFor: "add",
//                                     sellerId: widget.sellerId,
//                                   );
//                                   // } else {
//                                   //   loginUserAccount(context, "cart");
//                                   // }
//                                 }
//                               },
//                               otherWidgets: int.parse(cartListProvider
//                                           .getItemCartItemQuantity(
//                                               widget.productId,
//                                               widget.productVariantId)) ==
//                                       1
//                                   ? defaultImg(
//                                       image: AppAssets.cartDeleteIcon,
//                                       width: 20,
//                                       height: 20,
//                                       padding:
//                                           const EdgeInsetsDirectional.all(5),
//                                       iconColor: ColorsRes.appColor,
//                                     )
//                                   : defaultImg(
//                                       image: AppAssets.cartRemoveIcon,
//                                       width: 20,
//                                       height: 20,
//                                       padding:
//                                           const EdgeInsetsDirectional.all(5),
//                                       iconColor: ColorsRes.appColor,
//                                     ),
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           child: (cartListProvider.cartListState ==
//                                       CartListState.loading &&
//                                   cartListProvider.currentSelectedProduct ==
//                                       widget.productId &&
//                                   cartListProvider.currentSelectedVariant ==
//                                       widget.productVariantId)
//                               ? Container(
//                                   alignment: AlignmentDirectional.center,
//                                   child: Container(
//                                     width: 18,
//                                     height: 18,
//                                     child: CircularProgressIndicator(
//                                       color: ColorsRes.appColorWhite,
//                                     ),
//                                   ),
//                                 )
//                               : Container(
//                                   alignment: AlignmentDirectional.center,
//                                   width: 35,
//                                   height: 35,
//                                   child: CustomTextLabel(
//                                     text: cartListProvider
//                                         .getItemCartItemQuantity(
//                                             widget.productId,
//                                             widget.productVariantId),
//                                     softWrap: true,
//                                     style: TextStyle(
//                                         color: ColorsRes.appColorWhite),
//                                   ),
//                                 ),
//                         ),
//                         Padding(
//                           padding: EdgeInsetsDirectional.only(end: 5),
//                           child: SizedBox(
//                             width: 25,
//                             height: 25,
//                             child: gradientBtnWidget(
//                               context,
//                               50,
//                               color1: ColorsRes.appColorWhite,
//                               color2: ColorsRes.appColorWhite,
//                               callback: () async {
//                                 cartListProvider.currentSelectedProduct =
//                                     widget.productId;
//                                 cartListProvider.currentSelectedVariant =
//                                     widget.productVariantId;
//                                 Map<String, String> params = {};
//                                 params[ApiAndParams.productId] =
//                                     widget.productId;
//                                 params[ApiAndParams.productVariantId] =
//                                     widget.productVariantId;
//                                 params[ApiAndParams.qty] = (int.parse(
//                                             cartListProvider
//                                                 .getItemCartItemQuantity(
//                                                     widget.productId,
//                                                     widget.productVariantId)) +
//                                         1)
//                                     .toString();

//                                 if (Constant.session.isUserLoggedIn()) {
//                                   await cartListProvider.addRemoveCartItem(
//                                     context: context,
//                                     params: params,
//                                     isUnlimitedStock: widget.isUnlimitedStock,
//                                     maximumAllowedQuantity:
//                                         widget.maximumAllowedQuantity,
//                                     availableStock: widget.availableStock,
//                                     from: widget.from,
//                                     sellerId: widget.sellerId,
//                                     actionFor: "add",
//                                   );
//                                 } else {
//                                   // if (Constant.guestCartOptionIsOn == "1") {
//                                   await cartListProvider.addRemoveGuestCartItem(
//                                     context: context,
//                                     params: params,
//                                     isUnlimitedStock: widget.isUnlimitedStock,
//                                     maximumAllowedQuantity:
//                                         widget.maximumAllowedQuantity,
//                                     availableStock: widget.availableStock,
//                                     from: widget.from,
//                                     actionFor: "add",
//                                     sellerId: widget.sellerId,
//                                   );
//                                   // } else {
//                                   //   loginUserAccount(context, "cart");
//                                   // }
//                                 }
//                               },
//                               otherWidgets: defaultImg(
//                                 image: AppAssets.cartAddIcon,
//                                 width: 20,
//                                 height: 20,
//                                 padding: const EdgeInsetsDirectional.all(5),
//                                 iconColor: ColorsRes.appColor,
//                               ),
//                             ),
//                           ),
//                         )
//                       ],
//                     ),
//                   )
//                 : Container(
//                     alignment: Alignment.center,
//                     padding: EdgeInsets.only(top: 7, bottom: 7),
//                     child: CustomTextLabel(
//                       jsonKey: outOfStockLabel,
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: ColorsRes.appColorRed,
//                       ),
//                     ),
//                   );
//       },
//     );
//   }
// }
