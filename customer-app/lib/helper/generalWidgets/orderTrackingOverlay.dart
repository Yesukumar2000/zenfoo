import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/orderTrackingProvider.dart';
import 'package:project/screens/orderTrackingScreen.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class OrderTrackingOverlay extends StatefulWidget {
  const OrderTrackingOverlay({Key? key}) : super(key: key);

  @override
  State<OrderTrackingOverlay> createState() => _OrderTrackingOverlayState();
}

class _OrderTrackingOverlayState extends State<OrderTrackingOverlay> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '1':
        return const Color(0xFF2196F3); // Blue - Placed
      case '2':
        return const Color(0xFFFF9800); // Orange - Processing
      case '3':
        return const Color(0xFF9AC444); // Green - Out for delivery
      default:
        return const Color(0xFF9AC444);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case '1':
        return 'Order Placed';
      case '2':
        return 'Processing';
      case '3':
        return 'Out for Delivery';
      default:
        return 'Preparing';
    }
  }

  String _getEstimatedTime(String status) {
    switch (status) {
      case '1':
        return 'Preparing order';
      case '2':
        return 'Est. 15-20 min';
      case '3':
        return 'Arriving soon';
      default:
        return 'Processing';
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
      case '4':
        return Icons.check_circle_outline;
      default:
        return Icons.schedule_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<OrderTrackingProvider>(
      builder: (context, provider, child) {
        if (!provider.shouldShowOverlay()) {
          return const SizedBox.shrink();
        }

        final orders = provider.activeOrders;
        if (orders.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsetsDirectional.fromSTEB(6, 0, 6, 12),
          // height: orders.length > 1 ? 90 : 72,
          height: 72,
          child: Column(
            children: [
              // Order cards carousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: orders.length,
                  onPageChanged: (index) {
                    provider.setOrderIndex(index);
                  },
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final statusColor =
                        _getStatusColor(order.activeStatus ?? '1');
                    final statusText =
                        _getStatusText(order.activeStatus ?? '1');

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiProvider(
                              providers: [
                                ChangeNotifierProvider(
                                  create: (context) => CurrentOrderProvider(),
                                ),
                              ],
                              child: OrderTrackingScreen(orderId: order.id),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsetsDirectional.symmetric(
                            horizontal: 4),
                        padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: colorScheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            // Status icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIconForStatus(order.activeStatus ?? '1'),
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Order info - Symmetric layout
                            Expanded(
                              child: Row(
                                children: [
                                  // Left side - Status and Order info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          statusText,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.textPrimary,
                                            letterSpacing: -0.1,
                                            height: 1.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          order.deliveryBoyName != null &&
                                                  order.deliveryBoyName!.isNotEmpty &&
                                                  order.deliveryBoyName != 'null'
                                              ? order.deliveryBoyName!
                                              : 'Order ${order.displayNumber}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: colorScheme.textSecondary,
                                            fontWeight: FontWeight.w400,
                                            height: 1.2,
                                            letterSpacing: 0,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Right side - Time and Arrow
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (orders.length > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Text(
                                            '${index + 1}/${orders.length}',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: colorScheme.textSecondary,
                                              fontWeight: FontWeight.w500,
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getEstimatedTime(
                                              order.activeStatus ?? '1'),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                            height: 1.2,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Track arrow
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: colorScheme.iconSecondary,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Page indicators (if multiple orders)
              // if (orders.length > 1)
              //   Padding(
              //     padding: const EdgeInsets.only(top: 10),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: List.generate(
              //         orders.length,
              //         (index) => AnimatedContainer(
              //           duration: const Duration(milliseconds: 300),
              //           margin: const EdgeInsets.symmetric(horizontal: 4),
              //           width: provider.currentOrderIndex == index ? 24 : 8,
              //           height: 8,
              //           decoration: BoxDecoration(
              //             color: provider.currentOrderIndex == index
              //                 ? _getStatusColor(
              //                     orders[index].activeStatus ?? '1')
              //                 : const Color(0xFFD0D0D0),
              //             borderRadius: BorderRadius.circular(4),
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
            
            ],
          ),
        );
      },
    );
  }
}
