import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/provider/reorderProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/models/reorderableOrder.dart';

class ReorderScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const ReorderScreen({
    Key? key,
    this.scrollController,
  }) : super(key: key);

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((_) {
      context.read<ReorderProvider>().getReorderableOrders(context: context);
    });
  }

  Future<void> _addToCart(ReorderableItem item) async {
    if (!item.isAvailable) return;

    HapticFeedback.lightImpact();

    try {
      if (!Constant.session.isUserLoggedIn()) {
        showMessage(
          context,
          getTranslatedValue(context, 'please_login_to_add_items'),
          MessageType.warning,
        );
        return;
      }

      final cartListProvider = context.read<CartListProvider>();

      // Get current cart quantity for this item
      int currentCartQty = int.parse(
        cartListProvider.getItemCartItemQuantity(
          item.productId.toString(),
          item.variantId.toString(),
        ),
      );

      // Calculate new quantity (current + ordered quantity)
      int orderedQty = (item.orderedQuantity ?? 1).toInt();
      int newQty = currentCartQty + orderedQty;

      Map<String, String> params = {};
      params[ApiAndParams.productId] = item.productId.toString();
      params[ApiAndParams.productVariantId] = item.variantId.toString();
      params[ApiAndParams.qty] = newQty.toString();

      await cartListProvider.addRemoveCartItem(
        context: context,
        params: params,
        isUnlimitedStock: (item.currentStock ?? 0) == 0 ? true : false,
        maximumAllowedQuantity: 100,
        availableStock: (item.currentStock ?? 0).toDouble(),
        actionFor: "add",
        from: "reorder",
        sellerId: item.sellerId.toString(),
      );

      // Show success message
      showMessage(
        context,
        getTranslatedValue(context, 'added_to_cart_success').replaceAll('{qty}', orderedQty.toString()).replaceAll('{productName}', item.productName ?? ''),
        MessageType.success,
      );
    } catch (e) {
      showMessage(
        context,
        getTranslatedValue(context, 'failed_to_add_to_cart'),
        MessageType.error,
      );
    }
  }

  Future<void> _reorderAllItems(ReorderableOrder order) async {
    if (!order.canReorderAll) return;

    HapticFeedback.lightImpact();

    try {
      if (!Constant.session.isUserLoggedIn()) {
        showMessage(
          context,
          getTranslatedValue(context, 'please_login_to_add_items'),
          MessageType.warning,
        );
        return;
      }

      final cartListProvider = context.read<CartListProvider>();
      int addedCount = 0;
      int totalQuantity = 0;

      // Add all available items from this order to cart
      for (var item in order.items ?? []) {
        if (item.isAvailable) {
          try {
            // Get current cart quantity for this item
            int currentCartQty = int.parse(
              cartListProvider.getItemCartItemQuantity(
                item.productId.toString(),
                item.variantId.toString(),
              ),
            );

            // Calculate new quantity (current + ordered quantity)
            int orderedQty = (item.orderedQuantity ?? 1).toInt();
            int newQty = currentCartQty + orderedQty;

            Map<String, String> params = {};
            params[ApiAndParams.productId] = item.productId.toString();
            params[ApiAndParams.productVariantId] = item.variantId.toString();
            params[ApiAndParams.qty] = newQty.toString();

            await cartListProvider.addRemoveCartItem(
              context: context,
              params: params,
              isUnlimitedStock: (item.currentStock ?? 0) == 0 ? true : false,
              maximumAllowedQuantity: 100,
              availableStock: (item.currentStock ?? 0).toDouble(),
              actionFor: "add",
              from: "reorder",
              sellerId: item.sellerId.toString(),
            );

            addedCount++;
            totalQuantity += orderedQty;
          } catch (e) {
            // Continue adding other items even if one fails
            debugPrint('Failed to add item ${item.productName}: $e');
          }
        }
      }

      if (addedCount > 0) {
        showMessage(
          context,
          getTranslatedValue(context, 'added_items_to_cart').replaceAll('{count}', addedCount.toString()).replaceAll('{totalQty}', totalQuantity.toString()),
          MessageType.success,
        );
      } else {
        showMessage(
          context,
          getTranslatedValue(context, 'no_items_added_to_cart'),
          MessageType.warning,
        );
      }
    } catch (e) {
      showMessage(
        context,
        getTranslatedValue(context, 'failed_to_reorder_items'),
        MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Stack(
        children: [
          Column(
            children: [
              // App Header
              AppHeader(
                label: getTranslatedValue(context, 'quick_reorder'),
                title: getTranslatedValue(context, 'reorder_previous_items'),
                showBackButton: false,
              ),

              // Content
              Expanded(
                child: Consumer<ReorderProvider>(
                  builder: (context, reorderProvider, child) {
                    // Loading state
                    if (reorderProvider.state == ReorderState.loading &&
                        !reorderProvider.isDataLoaded) {
                      return _buildLoadingShimmer();
                    }

                    // Error state
                    if (reorderProvider.state == ReorderState.error &&
                        !reorderProvider.isDataLoaded) {
                      return _buildErrorState(
                          colorScheme, reorderProvider.message);
                    }

                    // Empty state
                    if (reorderProvider.orders.isEmpty) {
                      return _buildEmptyState(colorScheme);
                    }

                    // Orders list
                    return ListView.builder(
                      controller: widget.scrollController,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: context.watch<CartProvider>().totalItemsCount > 0
                            ? 100
                            : 16,
                      ),
                      itemCount: reorderProvider.orders.length,
                      itemBuilder: (context, index) {
                        final order = reorderProvider.orders[index];
                        return _buildOrderCard(order, colorScheme);
                      },
                    );
                  },
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildOrderCard(ReorderableOrder order, colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
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
                      Text(
                        '${getTranslatedValue(context, 'order_prefix')}${order.orderId}',
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.55,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.orderDateFormatted ?? '',
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.55,
                          height: 1.02,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.orderStatus, colorScheme)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(order.orderStatus, colorScheme),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    order.orderStatus ?? '',
                    style: GoogleFonts.inter(
                      color: _getStatusColor(order.orderStatus, colorScheme),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.55,
                      height: 1.02,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Order info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildInfoChip(
                  icon: Icons.shopping_bag_outlined,
                  label: '${order.totalItems} items',
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.currency_rupee,
                  label: order.finalTotal ?? '0',
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                if ((order.unavailableItemsCount ?? 0) > 0)
                  _buildInfoChip(
                    icon: Icons.warning_amber_rounded,
                    label: '${order.unavailableItemsCount} unavailable',
                    colorScheme: colorScheme,
                    isWarning: true,
                  ),
              ],
            ),
          ),

          // Items list
          ...((order.items ?? []).map((item) {
            return _buildItemCard(item, colorScheme);
          }).toList()),

          // Reorder all button
          if (order.canReorderAll)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => _reorderAllItems(order),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_shopping_cart_rounded,
                        color: colorScheme.buttonPrimaryText,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        getTranslatedValue(context, 'reorder_all_items'),
                        style: GoogleFonts.inter(
                          color: colorScheme.buttonPrimaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.55,
                          height: 1.02,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ReorderableItem item, colorScheme) {
    final hasPriceChange =
        (double.tryParse(item.priceChangePercentage ?? '0') ?? 0) != 0;
    final priceIncreased =
        (double.tryParse(item.priceDifference ?? '0') ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: item.isAvailable
            ? colorScheme.surface
            : colorScheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isAvailable
              ? colorScheme.border
              : colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Product image with quantity badge
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.productImage != null && item.productImage!.isNotEmpty
                    ? setNetworkImg(
                        boxFit: BoxFit.cover,
                        image: item.productImage!,
                        height: 52,
                        width: 52,
                      )
                    : Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.iconSecondary,
                        size: 20,
                      ),
              ),
              // Quantity badge
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${item.orderedQuantity}',
                    style: GoogleFonts.inter(
                      color: colorScheme.buttonPrimaryText,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1,
                    ),
                  ),
                ),
              ),
              // Not available overlay
              if (!item.isAvailable)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.overlay.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.block_rounded,
                      color: colorScheme.error,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 8),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? '',
                  style: GoogleFonts.inter(
                    color: item.isAvailable
                        ? colorScheme.textPrimary
                        : colorScheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.displayMeasurement,
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    if (hasPriceChange) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (priceIncreased
                                  ? colorScheme.error
                                  : colorScheme.success)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${priceIncreased ? '+' : ''}${item.priceChangePercentage}%',
                          style: GoogleFonts.inter(
                            color: priceIncreased
                                ? colorScheme.error
                                : colorScheme.success,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (!item.isAvailable)
                  Text(
                    (item.availabilityReason != null &&
                            item.availabilityReason!.isNotEmpty &&
                            item.availabilityReason != 'null')
                        ? item.availabilityReason!
                        : getTranslatedValue(context, 'not_available'),
                    style: GoogleFonts.inter(
                      color: colorScheme.error,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  )
                else
                  Row(
                    children: [
                      Text(
                        '₹${item.currentPrice}',
                        style: GoogleFonts.inter(
                          color: colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '× ${item.orderedQuantity}',
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Add to cart button
          GestureDetector(
            onTap: item.isAvailable ? () => _addToCart(item) : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.isAvailable
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_shopping_cart_rounded,
                color: item.isAvailable
                    ? colorScheme.buttonPrimaryText
                    : colorScheme.iconDisabled,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required colorScheme,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isWarning
            ? colorScheme.warning.withValues(alpha: 0.1)
            : colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                isWarning ? colorScheme.warning : colorScheme.iconSecondary,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color:
                  isWarning ? colorScheme.warning : colorScheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.55,
              height: 1.02,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status, colorScheme) {
    switch (status?.toLowerCase()) {
      case 'delivered':
        return colorScheme.success;
      case 'pending':
        return colorScheme.warning;
      case 'cancelled':
        return colorScheme.error;
      default:
        return colorScheme.info;
    }
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header shimmer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomShimmer(
                        height: 20,
                        width: 120,
                        borderRadius: 8,
                      ),
                      const SizedBox(height: 6),
                      CustomShimmer(
                        height: 16,
                        width: 80,
                        borderRadius: 8,
                      ),
                    ],
                  ),
                  CustomShimmer(
                    height: 20,
                    width: 60,
                    borderRadius: 8,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Status chips shimmer
              Row(
                children: [
                  CustomShimmer(
                    height: 24,
                    width: 70,
                    borderRadius: 6,
                  ),
                  const SizedBox(width: 8),
                  CustomShimmer(
                    height: 24,
                    width: 70,
                    borderRadius: 6,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Items shimmer - detailed structure
              ...List.generate(3, (itemIndex) {
                return Container(
                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // Image shimmer
                      CustomShimmer(
                        height: 52,
                        width: 52,
                        borderRadius: 8,
                      ),
                      const SizedBox(width: 8),
                      // Product details shimmer
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomShimmer(
                              height: 12,
                              width: double.infinity,
                              borderRadius: 6,
                            ),
                            const SizedBox(height: 4),
                            CustomShimmer(
                              height: 10,
                              width: 80,
                              borderRadius: 6,
                            ),
                            const SizedBox(height: 4),
                            CustomShimmer(
                              height: 13,
                              width: 60,
                              borderRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Button shimmer
                      CustomShimmer(
                        height: 32,
                        width: 32,
                        borderRadius: 8,
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              // Reorder All button shimmer
              CustomShimmer(
                height: 48,
                width: double.infinity,
                borderRadius: 12,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(colorScheme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              getTranslatedValue(context, 'failed_to_load_orders'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.55,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context
                    .read<ReorderProvider>()
                    .getReorderableOrders(context: context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.buttonPrimaryText,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                getTranslatedValue(context, 'retry_label'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 72,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              getTranslatedValue(context, 'no_previous_orders'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.55,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              getTranslatedValue(context, 'place_first_order_message'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.55,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
