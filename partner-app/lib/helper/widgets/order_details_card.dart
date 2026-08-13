import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/order_detail_item.dart';
import 'package:project/models/new_order.dart' show SettlementItem;
import 'package:project/provider/themeProvider.dart' as app_theme;

class OrderDetailsCard extends StatefulWidget {
  final OrderDetailItem orderDetail;
  final VoidCallback? onPrepTimeSet;
  final VoidCallback? onOtpConfirmed;
  final List<SettlementItem>? settlementInfo;

  const OrderDetailsCard({
    super.key,
    required this.orderDetail,
    this.onPrepTimeSet,
    this.onOtpConfirmed,
    this.settlementInfo,
  });

  @override
  State<OrderDetailsCard> createState() => _OrderDetailsCardState();
}

class _OrderDetailsCardState extends State<OrderDetailsCard> {
  Color _getStatusColor() {
    switch (widget.orderDetail.statusColor.toLowerCase()) {
      case 'green':
        return Color(0xFF10B981);
      case 'red':
        return Color(0xFFEF4444);
      case 'orange':
        return Color(0xFFF97316);
      case 'blue':
        return Color(0xFF3B82F6);
      default:
        return Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.textPrimary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with ID and Status
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            Icons.receipt_long_outlined,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '${getTranslatedValue(context, orderLabel)} ${widget.orderDetail.id}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                            letterSpacing: -0.3,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getStatusColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            widget.orderDetail.status,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(),
                              letterSpacing: -0.2,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Order Details Label
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  getTranslatedValue(context, orderDetailsLabelKey),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                    height: 1.15,
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Products List
              ...widget.orderDetail.products
                  .map((product) => _buildProductItem(product, context)),

              // Divider
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.border,
                ),
              ),

              // Total Amount
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: colorScheme.success,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          getTranslatedValue(context, totalAmountLabel),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                            letterSpacing: -0.3,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${widget.orderDetail.totalAmount}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),

              // Settlement Info
              if (widget.settlementInfo != null &&
                  widget.settlementInfo!.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.border,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Settlement Details',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textSecondary,
                      height: 1.15,
                    ),
                  ),
                ),
                ...widget.settlementInfo!.map((item) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.textSecondary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          item.value is num
                              ? '₹${(item.value as num).toStringAsFixed(2)}'
                              : '${item.value}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductItem(OrderProduct product, BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: colorScheme.primary,
              size: 16,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.quantity,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.3,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  product.weight,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${product.price}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                  letterSpacing: -0.3,
                  height: 1.15,
                ),
              ),
              if (product.earnedAmount != null) ...[
                SizedBox(height: 2),
                Text(
                  'Earned: ₹${product.earnedAmount}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.success,
                    letterSpacing: -0.2,
                    height: 1.15,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Function to show order details dialog
void showOrderDetailsDialog(BuildContext context, OrderDetailItem orderDetail) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24),
        child: OrderDetailsCard(orderDetail: orderDetail),
      );
    },
  );
}

// Function to show order details bottom sheet
void showOrderDetailsBottomSheet(
    BuildContext context, OrderDetailItem orderDetail) {
  final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            OrderDetailsCard(orderDetail: orderDetail),
            SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
