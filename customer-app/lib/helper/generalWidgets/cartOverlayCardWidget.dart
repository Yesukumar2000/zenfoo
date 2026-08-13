import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/provider/orderTrackingProvider.dart';
import 'package:project/screens/orderTrackingScreen.dart';

class CartOverlay extends StatefulWidget {
  @override
  State<CartOverlay> createState() => _CartOverlayState();
}

class _CartOverlayState extends State<CartOverlay> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '1':
        return const Color(0xFF2196F3);
      case '2':
        return const Color(0xFFFF9800);
      case '3':
        return const Color(0xFF9AC444);
      default:
        return const Color(0xFF9AC444);
    }
  }

  // Kept for revert: previously used to render the per-order status text in
  // the overlay (e.g. "Preparing", "Out for delivery"). The overlay now shows
  // a static "Your ongoing order" label instead.
  // ignore: unused_element
  String _getStatusText(String status, BuildContext context) {
    switch (status) {
      case '1':
        return getTranslatedValue(context, 'order_placed_status');
      case '2':
        return getTranslatedValue(context, 'processing_status');
      case '3':
        return getTranslatedValue(context, 'out_for_delivery_status');
      default:
        return getTranslatedValue(context, 'preparing_status');
    }
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case '1':
        return Icons.shopping_bag_outlined;
      case '2':
        return Icons.restaurant_outlined;
      case '3':
        return Icons.delivery_dining_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final trackingProvider = context.watch<OrderTrackingProvider>();
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    final hasCart = cartProvider.totalItemsCount > 0;
    final hasActiveOrders = trackingProvider.shouldShowOverlay();
    final activeOrders = trackingProvider.activeOrders;

    return Container(
      color: Colors.white,
      padding: EdgeInsetsDirectional.fromSTEB(6, 6, 6, 20),
      child: Container(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: colorScheme.cardShadow,
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active Orders Section (scrollable if multiple)
          if (hasActiveOrders && activeOrders.isNotEmpty) ...[
            SizedBox(
              height: 40,
              child: PageView.builder(
                controller: _pageController,
                itemCount: activeOrders.length,
                onPageChanged: (index) {
                  trackingProvider.setOrderIndex(index);
                },
                itemBuilder: (context, index) {
                  final order = activeOrders[index];
                  final statusColor =
                      _getStatusColor(order.activeStatus ?? '1');

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(
                        context,
                        orderTrackingScreen,
                        arguments: order.id,
                      );
                    },
                    child: Row(
                      children: [
                        // Order Status Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              _getIconForStatus(order.activeStatus ?? '1'),
                              color: statusColor,
                              size: 18,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        // Order Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Status text replaced with a generic
                              // "Your ongoing order" label. Original status
                              // rendering kept here for easy revert.
                              // Text(
                              //   _getStatusText(
                              //       order.activeStatus ?? '1', context),
                              //   style: GoogleFonts.inter(
                              //     fontSize: 14,
                              //     color: colorScheme.textPrimary,
                              //     fontWeight: FontWeight.w700,
                              //     height: 1.1,
                              //     letterSpacing: -0.3,
                              //   ),
                              // ),
                              Text(
                                'Your ongoing order',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: colorScheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              // Subtext (delivery partner name / order
                              // number) hidden along with the status text.
                              // Kept here commented for easy revert.
                              // SizedBox(height: 2),
                              // Text(
                              //   order.deliveryBoyName != null &&
                              //           order.deliveryBoyName!.isNotEmpty &&
                              //           order.deliveryBoyName != 'null'
                              //       ? order.deliveryBoyName!
                              //       : '${getTranslatedValue(context, 'order_number_prefix')}${order.id}',
                              //   style: GoogleFonts.inter(
                              //     fontSize: 10,
                              //     color: colorScheme.textSecondary,
                              //     fontWeight: FontWeight.w500,
                              //     height: 1.1,
                              //     letterSpacing: -0.1,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                        if (activeOrders.length > 1) ...[
                          SizedBox(width: 4),
                          Text(
                            '${index + 1}/${activeOrders.length}',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              color: colorScheme.textSecondary,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                            ),
                          ),
                        ],
                        SizedBox(width: 6),
                        // Track Button
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: colorScheme.elevatedShadow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                getTranslatedValue(context, 'track_button'),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Divider if both orders and cart exist
            if (hasCart) ...[
              SizedBox(height: 6),
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.border,
              ),
              SizedBox(height: 6),
            ],
          ],

          // Cart Section
          if (hasCart)
            Row(
              children: [
                // Cart Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Cart Info
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, cartScreen);
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context
                                .watch<CartProvider>()
                                .subTotal
                                .toString()
                                .currency,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: colorScheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "${cartProvider.cartData?.data.getTotalItemCount() ?? 0} ${(cartProvider.cartData?.data.getTotalItemCount() ?? 0) > 1 ? getTranslatedValue(context, itemsLabel) : getTranslatedValue(context, itemLabel)}",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: colorScheme.textSecondary,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                // View Cart Button
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, cartScreen);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: colorScheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: colorScheme.elevatedShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          getTranslatedValue(context, viewCartLabel),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.buttonPrimaryText,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: colorScheme.buttonPrimaryText,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 6),
                // Close Button
                GestureDetector(
                  onTap: () {
                    showDialog<String>(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        final dialogColorScheme =
                            context.read<app_theme.ThemeProvider>().colorScheme;
                        return AlertDialog(
                          backgroundColor: dialogColorScheme.cardBackground,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            getTranslatedValue(context, clearCartTitleLabel),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: dialogColorScheme.textPrimary,
                              height: 1.3,
                              letterSpacing: -0.4,
                            ),
                          ),
                          content: Text(
                            getTranslatedValue(context, clearCartMessageLabel),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: dialogColorScheme.textSecondary,
                              height: 1.5,
                              letterSpacing: -0.2,
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                getTranslatedValue(context, cancelLabel),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: dialogColorScheme.textSecondary,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context
                                    .read<CartListProvider>()
                                    .clearCart(context: context);
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                backgroundColor: const Color(0xFFE53E3E)
                                    .withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                getTranslatedValue(context, okLabel),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE53E3E),
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                          actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: colorScheme.iconSecondary,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
    );
  }
}
