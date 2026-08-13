import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/incoming_order_model.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/incoming_order_provider.dart';
import 'package:zenfoo_partner/services/sound_service.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/order_route_map.dart';
import 'package:zenfoo_partner/view/screens/bottom_nav_screen.dart';

class IncomingOrderDialog extends StatefulWidget {
  final IncomingOrder order;

  const IncomingOrderDialog({
    super.key,
    required this.order,
  });

  @override
  State<IncomingOrderDialog> createState() => _IncomingOrderDialogState();
}

class _IncomingOrderDialogState extends State<IncomingOrderDialog> {
  bool _isProcessing = false;
  Timer? _autoRejectTimer;

  @override
  void initState() {
    super.initState();

    // Play notification sound when dialog appears
    SoundService().playOrderSound();

    // START AUTO REJECT TIMER (60 seconds)
    _autoRejectTimer = Timer(const Duration(seconds: 60), () {
      debugPrint('⏱️ 60 seconds passed - auto rejecting order');
      _handleReject(authProviderId()); // helper function below
    });
  }

  int authProviderId() {
    final authProvider = context.read<AuthProvider>();
    return authProvider.currentDeliveryBoy?.id ?? 0;
  }

  @override
  void dispose() {
    // Stop sound when dialog is closed/disposed
    _autoRejectTimer?.cancel();
    SoundService().stopSound();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final authProvider = context.read<AuthProvider>();
    final deliveryBoyId = authProvider.currentDeliveryBoy?.id ?? 0;
    final orderProvider = context.watch<IncomingOrderProvider>();

    // Check if this order still exists in the provider
    // This runs on every build, so it immediately detects deletions
    final orderExists = orderProvider.incomingOrders
        .any((order) => order.orderId == widget.order.orderId);

    if (!orderExists && mounted) {
      debugPrint(
          '🗑️ Order ${widget.order.orderId} was deleted - closing bottom sheet');
      // Use addPostFrameCallback to close the bottom sheet dialog safely
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Close the bottom sheet by popping the dialog route from the navigator
          // This only affects the modal bottom sheet, not the home screen
          try {
            Navigator.of(context).maybePop();
          } catch (e) {
            debugPrint('⚠️ Could not close dialog: $e');
          }
        }
      });
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: colorScheme.background,
        child: Column(
          children: [
            /// APP HEADER WITH REJECT BUTTON
            AppHeader(
              label: 'New Order',
              title: widget.order.pickupLocation?.storeName ?? 'Incoming Order',
              trailing: GestureDetector(
                onTap:
                    _isProcessing ? null : () => _handleReject(deliveryBoyId),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Reject',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.close,
                        size: 16,
                        color: colorScheme.error,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// ROUTE MAP WITH DELIVERY POINTS
            Padding(
              padding: const EdgeInsets.all(16),
              child: OrderRouteMap(
                order: widget.order,
                height: 240,
              ),
            ),

            /// BOTTOM CARD - ORDER DETAILS
            _buildOrderCard(colorScheme, deliveryBoyId),
          ],
        ),
      ),
    );
  }

  /// Build order details card
  Widget _buildOrderCard(AppColorScheme colorScheme, int deliveryBoyId) {
    return Container(
      padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: colorScheme.cardShadow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ORDER TYPE & PRICE
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.order.isMultiOrder ? 'MULTI ORDER' : 'SINGLE ORDER',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹${widget.order.deliveryCharge.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.8,
                      ),
                    ),
                    if (widget.order.multiOrderBonus > 0)
                      Text(
                        '+ ₹${widget.order.multiOrderBonus.toStringAsFixed(0)}  Multi Order',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// DISTANCE & TIP
            Row(
              children: [
                Text(
                  'Total Distance  ${widget.order.totalRouteDistanceKm.toStringAsFixed(1)} kms',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textSecondary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (widget.order.deliveryTip > 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.success.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Tip: ₹${widget.order.deliveryTip.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.success,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            /// PICKUP LOCATION BADGE
            if (widget.order.pickupLocation != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Pickup location',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                    letterSpacing: -0.15,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// STORE ADDRESS
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Store Address',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textSecondary,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.order.pickupLocation!.storeName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.25,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],

            /// POTENTIAL EARNINGS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
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
                        'Potential Earnings',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textSecondary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total amount you\'ll earn',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.textTertiary,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${(widget.order.deliveryCharge + widget.order.multiOrderBonus + widget.order.deliveryTip).toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ACCEPT BUTTON
            GestureDetector(
              onTap: _isProcessing ? null : () => _handleAccept(deliveryBoyId),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isProcessing
                      ? colorScheme.primary.withValues(alpha: 0.6)
                      : colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFEFEFE),
                            ),
                          ),
                        )
                      : Text(
                          'Accept',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFEFEFE),
                            letterSpacing: -0.3,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle accept order
  Future<void> _handleAccept(int deliveryBoyId) async {
    if (_isProcessing) return;

    _autoRejectTimer?.cancel();

    setState(() => _isProcessing = true);

    // Stop notification sound
    await SoundService().stopSound();

    // Get current GPS location
    double driverLat = widget.order.driver.latitude;
    double driverLng = widget.order.driver.longitude;
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      driverLat = position.latitude;
      driverLng = position.longitude;
    } catch (e) {
      debugPrint('⚠️ Could not get current location, using order driver location: $e');
    }

    final provider = context.read<IncomingOrderProvider>();
    final success = await provider.acceptOrder(
      orderId: widget.order.orderId,
      deliveryBoyId: deliveryBoyId,
      driverLat: driverLat,
      driverLng: driverLng,
    );

    if (!mounted) return;

    if (success) {
      debugPrint(
          '✅ Order accepted successfully, clearing all navigation and showing BottomNavBarScreen');

      // Remove all other overlays/snackbars if any
      ScaffoldMessenger.of(context).clearSnackBars();

      // Clear all navigation stack and show BottomNavBarScreen using pushAndRemoveUntil
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const BottomNavBarScreen(),
          ),
          (route) => false, // Remove all previous routes
        );
      }

      // Show success snackbar after navigation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order accepted successfully!',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: context.read<ThemeProvider>().colorScheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Failed to accept order',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: context.read<ThemeProvider>().colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle reject order
  Future<void> _handleReject(int deliveryBoyId) async {
    if (_isProcessing) return;

    _autoRejectTimer?.cancel();

    setState(() => _isProcessing = true);

    // Capture provider before any awaits to avoid deactivated context issue
    final orderProvider = context.read<IncomingOrderProvider>();

    // Stop notification sound
    await SoundService().stopSound();

    final orderId = widget.order.orderId;

    try {
      // ---- DIRECT FIRESTORE DELETE ONLY ----
      await FirebaseFirestore.instance
          .collection('delivery_boys')
          .doc(deliveryBoyId.toString())
          .update({'orders.$orderId': FieldValue.delete()});

      debugPrint('✅ Order $orderId removed from Firestore after reject');
    } catch (e) {
      debugPrint('❌ Error removing order from Firestore: $e');
    }

    // Notify backend about cancellation
    debugPrint('📡 Calling order-cancelled API for order $orderId');
    final apiSuccess = await orderProvider.cancelOrder(orderId);
    debugPrint('✅ order-cancelled API result: $apiSuccess');

    if (!mounted) return;

    if (apiSuccess) {
      Navigator.of(context).pop(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order rejected',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )
          ),
          backgroundColor:
              context.read<ThemeProvider>().colorScheme.textSecondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to reject order',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: context.read<ThemeProvider>().colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
