import 'package:flutter/material.dart';
import 'package:project/utils/order_number.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/soundService.dart';
import 'package:project/models/new_order.dart' as api;
import 'package:project/provider/themeProvider.dart' as app_theme;

class NewOrderNotificationSheet extends StatefulWidget {
  final api.OrderData orderData;
  final VoidCallback onClose;
  final VoidCallback? onTapOpenOrders;

  const NewOrderNotificationSheet({
    required this.orderData,
    required this.onClose,
    this.onTapOpenOrders,
    Key? key,
  }) : super(key: key);

  @override
  State<NewOrderNotificationSheet> createState() =>
      _NewOrderNotificationSheetState();
}

class _NewOrderNotificationSheetState extends State<NewOrderNotificationSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeSheet() async {
    // Stop sound when closing the sheet
    SoundService().stopSound();

    await _animationController.reverse();
    if (mounted) {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.textPrimary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: Offset(0, -4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with close button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedNotification02,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '🎉 New Order!',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _closeSheet,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: colorScheme.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.border,
              // margin: EdgeInsets.zero,
            ),

            // Order Card Content
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: _buildOrderContent(context, colorScheme),
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Open Orders Button
                  GestureDetector(
                    onTap: () {
                      SoundService().stopSound();
                      _closeSheet();
                      Future.delayed(Duration(milliseconds: 300), () {
                        widget.onTapOpenOrders?.call();
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedDocumentCode,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'View All Orders',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Dismiss Button
                  GestureDetector(
                    onTap: _closeSheet,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedUserCheck01,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Dismiss',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderContent(BuildContext context, dynamic colorScheme) {
    final order = widget.orderData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order Header
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ${formatOrderNumber(order.orderId)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'OTP: ${order.otp ?? '--'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      order.activeStatus ?? 'new',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Customer Info
        if (order.user != null) ...[
          Text(
            'Customer',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.user?.name ?? 'Unknown',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                      ),
                    ),
                    Text(
                      order.user?.mobile ?? order.mobile ?? '--',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],

        // Delivery Address
        if (order.address != null && order.address!.isNotEmpty) ...[
          Text(
            'Delivery Address',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedMapPin,
                  color: colorScheme.primary,
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.address ?? '--',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textPrimary,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],

        // Items/Products
        if ((order.items != null && order.items!.isNotEmpty) ||
            (order.products != null && order.products!.isNotEmpty)) ...[
          Text(
            'Items (${(order.items?.length ?? 0) + (order.products?.length ?? 0)})',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          // Show items if available
          if (order.items != null && order.items!.isNotEmpty)
            ...order.items!
                .take(3)
                .map((item) => _buildItemTile(item, context, colorScheme)),
          // Show products if items not available (new API format)
          if ((order.items == null || order.items!.isEmpty) &&
              order.products != null &&
              order.products!.isNotEmpty)
            ...order.products!
                .take(3)
                .map((product) => _buildProductTile(product, context, colorScheme)),
          if ((order.items?.length ?? 0) + (order.products?.length ?? 0) > 3)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '+${((order.items?.length ?? 0) + (order.products?.length ?? 0)) - 3} more items',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ),
          SizedBox(height: 16),
        ],

        // Total Amount
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.border.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textPrimary,
                ),
              ),
              Text(
                '₹${(order.finalTotal ?? 0).toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(
      dynamic item, BuildContext context, dynamic colorScheme) {
    final name =
        item is api.OrderItem ? item.productName : (item.name ?? 'Item');
    final quantity =
        item is api.OrderItem ? item.quantity : (item.quantity ?? 0);
    final price = item is api.OrderItem ? item.price : (item.price ?? 0);

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$name x$quantity',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '₹$price',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(
      api.ProductDetail product, BuildContext context, dynamic colorScheme) {
    final name = product.productName ?? 'Product';
    final quantity = product.quantity ?? 0;
    final price = product.subTotal ?? product.discountedPrice ?? product.price ?? 0;

    // Build variant info (measurement + unit OR variantName)
    String variantInfo = '';
    if (product.measurement != null && product.unitShortCode != null) {
      variantInfo = '${product.measurement} ${product.unitShortCode}';
    } else if (product.variantName != null && product.variantName!.isNotEmpty) {
      variantInfo = product.variantName!;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF9AC444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${quantity}X',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF9AC444),
                height: 1.02,
                letterSpacing: -0.55,
              ),
            ),
          ),
          SizedBox(width: 12),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.textPrimary,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (variantInfo.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text(
                    variantInfo,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: colorScheme.textSecondary,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 12),
          // Price
          Text(
            '₹${price.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: colorScheme.textPrimary,
              height: 1.02,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
