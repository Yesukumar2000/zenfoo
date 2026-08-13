import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class OrderItemContainer extends StatelessWidget {
  final Order order;
  final String from;

  const OrderItemContainer({
    super.key,
    required this.order,
    required this.from,
  });

  bool get isDelivered => order.activeStatus.toString() == "5";

  bool get _hasPreOrderItems {
    final stores = order.groupedByStore ?? [];
    for (final store in stores) {
      for (final item in store.items ?? []) {
        if (item is Map && (item['is_pre_order_item'] == 1 || item['is_pre_order_item'] == '1')) return true;
      }
      for (final seller in store.sellers ?? []) {
        for (final item in seller.items ?? []) {
          if (item is Map && (item['is_pre_order_item'] == 1 || item['is_pre_order_item'] == '1')) return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;
        // Calculate total items from grouped_by_store structure
        int totalItemsFromStores = 0;
        String storeName = 'Store';
        String? storeIcon;
        Map<String, dynamic>? firstItem;

        if (order.groupedByStore != null && order.groupedByStore!.isNotEmpty) {
          final firstStore = order.groupedByStore![0];
          storeName = firstStore.storeName ?? 'Store';
          storeIcon = firstStore.storeIcon;

          // Count items from all sellers in all stores
          for (var store in order.groupedByStore!) {
            // Count items from store level (admin-managed items)
            if (store.items != null) {
              totalItemsFromStores += store.items!.length;
              // Get first item for preview
              if (firstItem == null &&
                  store.items!.isNotEmpty &&
                  store.items![0] is Map<String, dynamic>) {
                firstItem = store.items![0] as Map<String, dynamic>;
              }
            }

            // Count items from sellers
            if (store.sellers != null) {
              for (var seller in store.sellers!) {
                if (seller.items != null) {
                  totalItemsFromStores += seller.items!.length;
                  // Get first item for preview
                  if (firstItem == null &&
                      seller.items!.isNotEmpty &&
                      seller.items![0] is Map<String, dynamic>) {
                    firstItem = seller.items![0] as Map<String, dynamic>;
                  }
                }
              }
            }
          }
        }

        // Calculate total items including combos
        int totalComboItems = 0;
        if (order.customCombos != null) {
          for (var combo in order.customCombos!) {
            if (combo is Map<String, dynamic>) {
              final products = combo['products'];
              if (products is List) {
                totalComboItems += products.length;
              }
            }
          }
        }

        final totalItems = totalItemsFromStores + totalComboItems;

        // Items of this order that currently have no cancel option, with the
        // reason (seller setting vs. cancellation window already passed).
        final List<ItemCancelNote> cancelNotes = collectOrderCancelNotes(order);

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              orderDetailScreen,
              arguments: [order.id, from],
            ).then((value) {
              if (value != null) {
                context
                    .read<ActiveOrdersProvider>()
                    .updateOrder(value as Order);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.cardShadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Order ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Order ${order.displayNumber}',
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                        if (_hasPreOrderItems) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFD700), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF856404)),
                                const SizedBox(width: 4),
                                Text(
                                  'Pre-Order',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF856404),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.activeStatus ?? '')
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(order.activeStatus ?? '', context),
                        style: GoogleFonts.inter(
                          color: _getStatusColor(order.activeStatus ?? ''),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          height: 1.02,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Divider
                Container(
                  height: 1,
                  color: colorScheme.border,
                ),
                const SizedBox(height: 16),

                // Store header with icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      // Store Icon
                      if (storeIcon != null && storeIcon.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: setNetworkImg(
                            image: storeIcon,
                            width: 40,
                            height: 40,
                            boxFit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: colorScheme.iconSecondary,
                            size: 24,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$totalItems item${totalItems > 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.3,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // First item preview with icon
                if (firstItem != null)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${firstItem['quantity']}x',
                                    style: GoogleFonts.inter(
                                      color: colorScheme.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    firstItem['product_name']?.toString() ?? '',
                                    style: GoogleFonts.inter(
                                      color: colorScheme.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                      height: 1.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${firstItem['measurement']} ${firstItem['unit']}',
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.3,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${firstItem['price']}',
                        style: GoogleFonts.inter(
                          color: colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),

                // More items indicator
                if (totalItems > 1) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '+${totalItems - 1} ${getTranslatedValue(context, moreItemsLabel)}${totalItems - 1 > 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              orderDetailScreen,
                              arguments: [order.id, from],
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  getTranslatedValue(context, viewAllLabel),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.buttonPrimaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: colorScheme.buttonPrimaryText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Non-cancellable items note
                if (cancelNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final ItemCancelNote note = cancelNotes.first;
                      final bool sameReason = cancelNotes.every((element) =>
                          element.reason == note.reason &&
                          element.tillStatusCode == note.tillStatusCode);
                      final String text;
                      if (cancelNotes.length == 1) {
                        text = note.message(context);
                      } else if (sameReason) {
                        text =
                            "${cancelNotes.length} ${getTranslatedValue(context, itemsLabel)} · ${note.message(context)}";
                      } else {
                        text =
                            "${cancelNotes.length} ${getTranslatedValue(context, itemsCannotBeCancelledLabel)}";
                      }
                      return ItemCancelNoteRow(
                        note: note,
                        overrideText: text,
                        margin: EdgeInsets.zero,
                        fontSize: 12,
                      );
                    },
                  ),
                ],

                const SizedBox(height: 14),

                // Total and Date with icons
                Row(
                  children: [
                    // Total Amount Section
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getTranslatedValue(context, totalBillLabel),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.3,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.finalTotal.toString().currency,
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Date Section
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.access_time_rounded,
                              color: Color(0xFF3B82F6),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getTranslatedValue(context, orderDateLabel),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.3,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.date.toString().formatDate(),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                    height: 1.2,
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

                const SizedBox(height: 14),

                // Reorder button
                if (from == "previousOrders")
                  GestureDetector(
                    onTap: () {
                      _handleReorder(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reorder',
                            style: GoogleFonts.inter(
                              color: colorScheme.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                          ),
                        ],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case '1': // Pending
        return const Color(0xFFFFA726);
      case '2': // Confirmed
        return const Color(0xFF42A5F5);
      case '3': // Processing
        return const Color(0xFF9C27B0);
      case '4': // Out for delivery
        return const Color(0xFF26C6DA);
      case '5': // Delivered
        return const Color(0xFF66BB6A);
      case '6': // Cancelled
        return const Color(0xFFEF5350);
      case '7': // Returned
        return const Color(0xFFFF7043);
      default:
        return const Color(0xFF757575);
    }
  }

  String _getStatusText(String status, BuildContext context) {
    return Constant.getOrderActiveStatusLabelFromCode(status, context);
  }

  void _handleReorder(BuildContext context) {
    // reuse your existing reorder logic here
  }
}

class _ExpandableNameAddress extends StatefulWidget {
  final String title;
  final String subtitle;

  const _ExpandableNameAddress({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  State<_ExpandableNameAddress> createState() => _ExpandableNameAddressState();
}

class _ExpandableNameAddressState extends State<_ExpandableNameAddress> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _expanded = !_expanded);
            },
            behavior: HitTestBehavior.translucent,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name (always single line)
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.21,
                      letterSpacing: -0.10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Address collapsible
                  Text(
                    widget.subtitle,
                    maxLines: _expanded ? null : 1,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.42,
                      letterSpacing: -0.10,
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
}






//   final Order order;
//   final String from;

//   const OrderItemContainer(
//       {super.key, required this.order, required this.from});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.pushNamed(context, orderDetailScreen,
//             arguments: [order.id, from]).then((value) {
//           if (value != null) {
//             context.read<ActiveOrdersProvider>().updateOrder(value as Order);
//           }
//         });
//       },
//       child: Container(
//         margin: EdgeInsetsDirectional.only(start: 10, end: 10, top: 10),
//         decoration: BoxDecoration(
//           color: Theme.of(context).cardColor,
//           borderRadius: BorderRadius.circular(10),
//         ),
//         padding: EdgeInsetsDirectional.all(15),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       CustomTextLabel(
//                         text:
//                             "${getTranslatedValue(context, orderLabel)} #${order.id}",
//                         softWrap: true,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: ColorsRes.mainTextColor,
//                         ),
//                       ),
//                       CustomTextLabel(
//                         text: "${order.date.toString().formatDate()}",
//                         softWrap: true,
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: ColorsRes.subTitleMainTextColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: EdgeInsetsDirectional.all(10),
//                   decoration: BoxDecoration(
//                     color: ColorsRes
//                         .statusBgColor[order.activeStatus.toString().toInt - 1],
//                     borderRadius: BorderRadius.circular(5),
//                     border: Border.all(
//                       color: ColorsRes.statusTextColor[
//                           order.activeStatus.toString().toInt - 1],
//                       width: 1,
//                     ),
//                   ),
//                   child: CustomTextLabel(
//                     jsonKey: Constant.getOrderActiveStatusLabelFromCode(
//                       order.activeStatus.toString(),
//                       context,
//                     ),
//                     style: TextStyle(
//                       color: ColorsRes.statusTextColor[
//                           order.activeStatus.toString().toInt - 1],
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             getSizedBox(
//               height: 10,
//             ),
//             getDivider(
//               color: ColorsRes.subTitleMainTextColor.withValues(alpha: 0.3),
//               height: 1,
//               thickness: 1,
//             ),
//             getSizedBox(
//               height: 10,
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 ...List.generate(
//                   order.items!.length >= 3 ? 3 : order.items!.length,
//                   (itemIndex) {
//                     return Row(
//                       children: [
//                         Icon(
//                           Icons.circle_rounded,
//                           size: 7,
//                           color: ColorsRes.subTitleMainTextColor,
//                         ),
//                         getSizedBox(
//                           width: 5,
//                         ),
//                         Expanded(
//                           child: CustomTextLabel(
//                             text: order.items?[itemIndex].productName,
//                             style: TextStyle(
//                               color: ColorsRes.subTitleMainTextColor,
//                             ),
//                           ),
//                         ),
//                         CustomTextLabel(
//                           text:
//                               "${order.items?[itemIndex].measurement} ${order.items?[itemIndex].unit}",
//                           style: TextStyle(
//                             color: ColorsRes.subTitleMainTextColor,
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//                 if (order.items!.length > 3) ...[
//                   getSizedBox(
//                     height: 10,
//                   ),
//                   Container(
//                     padding: EdgeInsetsDirectional.only(
//                         start: 15, end: 15, top: 5, bottom: 5),
//                     decoration: BoxDecoration(
//                       color: ColorsRes.subTitleMainTextColor
//                           .withValues(alpha: 0.3),
//                       borderRadius: BorderRadius.circular(50),
//                     ),
//                     child: CustomTextLabel(
//                       text:
//                           "+ ${order.items!.length - 3} ${(order.items!.length - 3) == 1 ? getTranslatedValue(context, itemLabel) : getTranslatedValue(context, itemsLabel)}",
//                       style: TextStyle(
//                         color: ColorsRes.mainTextColor,
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   )
//                 ]
//               ],
//             ),
//             getSizedBox(
//               height: 10,
//             ),
//             getDivider(
//               color: ColorsRes.subTitleMainTextColor.withValues(alpha: 0.3),
//               height: 1,
//               thickness: 1,
//             ),
//             getSizedBox(
//               height: 10,
//             ),
//             Row(
//               children: [
//                 Expanded(
//                   child: CustomTextLabel(
//                     jsonKey: totalPayLabel,
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: ColorsRes.mainTextColor,
//                     ),
//                   ),
//                 ),
//                 CustomTextLabel(
//                   jsonKey: order.finalTotal.toString().currency,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: ColorsRes.appColor,
//                   ),
//                 ),
//               ],
//             ),
//             getSizedBox(
//               height: 10,
//             ),
//             getDivider(
//               color: ColorsRes.subTitleMainTextColor.withValues(alpha: 0.3),
//               height: 1,
//               thickness: 1,
//             ),
//             getSizedBox(
//               height: 10,
//             ),
//             Row(
//               children: [
//                 Expanded(
//                   child: Container(
//                     alignment: Alignment.center,
//                     padding: EdgeInsetsDirectional.all(10),
//                     child: CustomTextLabel(
//                       jsonKey: showMoreLabel,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: ColorsRes.mainTextColor,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 5),
//                 Expanded(
//                   child: GestureDetector(
//                     onTap: () {
//                       List<CartList> cartList = [];
//                       String? variantIds = order.items
//                           ?.map((e) => e.variantId)
//                           .toList()
//                           .join(',')
//                           .toString();
//                       String? quantity = order.items
//                           ?.map((e) => e.quantity)
//                           .toList()
//                           .join(',')
//                           .toString();
//                       String? productIds = order.items
//                           ?.map((e) => e.productId)
//                           .toList()
//                           .join(',')
//                           .toString();
//                       String? sellerIds = order.items
//                           ?.map((e) => e.sellerId)
//                           .toList()
//                           .join(',')
//                           .toString();

//                       print(
//                           ">>>> ${variantIds}--${quantity}--${productIds}--${sellerIds}");

//                       for (int i = 0; i < order.items!.length; i++) {
//                         CartList cartListItem = CartList(
//                           productId: order.items![i].productId.toString(),
//                           productVariantId:
//                               order.items![i].variantId.toString(),
//                           sellerId: order.items![i].sellerId.toString(),
//                           qty: order.items![i].quantity.toString(),
//                         );
//                         cartList.add(cartListItem);
//                       }

//                       showDialog<String>(
//                         context: context,
//                         builder: (BuildContext context) => AlertDialog(
//                           backgroundColor: Theme.of(context).cardColor,
//                           surfaceTintColor: ColorsRes.appColorTransparent,
//                           title: CustomTextLabel(
//                             jsonKey: reorderLabel,
//                             softWrap: true,
//                           ),
//                           content: CustomTextLabel(
//                             jsonKey: reorderWarningLabel,
//                             softWrap: true,
//                           ),
//                           actions: <Widget>[
//                             TextButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: CustomTextLabel(
//                                 jsonKey: cancelLabel,
//                                 softWrap: true,
//                                 style: TextStyle(
//                                     color: ColorsRes.subTitleMainTextColor),
//                               ),
//                             ),
//                             TextButton(
//                               onPressed: () async {
//                                 await addGuestCartBulkToCartWhileLogin(
//                                     context: context,
//                                     params: {
//                                       ApiAndParams.quantities: quantity,
//                                       ApiAndParams.variant_ids: variantIds,
//                                     }).then(
//                                   (value) async {
//                                     if (value[ApiAndParams.status].toString() ==
//                                         "1") {
//                                       await context
//                                           .read<CartProvider>()
//                                           .getCartListProvider(
//                                               context: context);

//                                       await context
//                                           .read<CartListProvider>()
//                                           .getAllCartItems(context: context);
//                                     } else {
//                                       showMessage(
//                                           context,
//                                           getTranslatedValue(context,
//                                               value[ApiAndParams.message]),
//                                           MessageType.warning);
//                                     }
//                                   },
//                                 );

//                                 Navigator.pop(context);
//                               },
//                               child: CustomTextLabel(
//                                 jsonKey: okLabel,
//                                 softWrap: true,
//                                 style: TextStyle(color: ColorsRes.appColor),
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(5),
//                         border: Border.all(
//                           color: Theme.of(context).scaffoldBackgroundColor,
//                           width: 1,
//                         ),
//                       ),
//                       alignment: Alignment.center,
//                       padding: EdgeInsetsDirectional.all(10),
//                       child: CustomTextLabel(
//                         jsonKey: reorderLabel,
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: ColorsRes.mainTextColor,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 if (from != "previousOrders") ...[
//                   SizedBox(width: 5),
//                   Expanded(
//                     child: GestureDetector(
//                       onTap: () {
//                         if (order.status!.isNotEmpty &&
//                             order.activeStatus.toString() != "5") {
//                           showModalBottomSheet(
//                             backgroundColor: Theme.of(context).cardColor,
//                             isScrollControlled: true,
//                             shape: const RoundedRectangleBorder(
//                               borderRadius: BorderRadius.only(
//                                 topLeft: Radius.circular(15),
//                                 topRight: Radius.circular(15),
//                               ),
//                             ),
//                             context: context,
//                             builder: (context) {
//                               return OrderTrackingHistoryBottomSheet(
//                                 listOfStatus: order.status ?? [],
//                               );
//                             },
//                           );
//                         } else if (order.activeStatus.toString() == "5") {
//                           Navigator.pushNamed(
//                             context,
//                             orderTrackerScreen,
//                             arguments: [
//                               order.latitude?.toDouble,
//                               order.longitude?.toDouble,
//                               order.orderAddress.toString(),
//                               order.id.toString(),
//                               order.deliveryBoyName.toString(),
//                               order.deliveryBoyNumber.toString(),
//                             ],
//                           );
//                         } else {
//                           showMessage(
//                               context,
//                               getTranslatedValue(context,
//                                   orderAwaitingPaymentTrackLabel),
//                               MessageType.warning);
//                         }
//                       },
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: ColorsRes.mainTextColorLight,
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                         padding: EdgeInsetsDirectional.all(10),
//                         alignment: Alignment.center,
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Expanded(
//                               child: CustomTextLabel(
//                                 jsonKey: trackMyOrderLabel,
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: ColorsRes.mainTextColorDark,
//                                 ),
//                                 softWrap: true,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                             SizedBox(width: 5),
//                             Icon(
//                               Icons.arrow_forward_rounded,
//                               size: 18,
//                               color: ColorsRes.mainTextColorDark,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ]
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }