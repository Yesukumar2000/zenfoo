import 'package:flutter/material.dart';
import 'package:zenfoo_partner/utils/order_number.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/incoming_order_model.dart';
import 'package:zenfoo_partner/models/cash_collection_model.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/incoming_order_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/firebase_order_service.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class DeliverySuccessScreen extends StatefulWidget {
  final IncomingOrder order;
  final CashCollectionData? cashCollectionData;
  final dynamic deliveryData;

  const DeliverySuccessScreen({
    super.key,
    required this.order,
    this.cashCollectionData,
    this.deliveryData,
  });

  @override
  State<DeliverySuccessScreen> createState() => _DeliverySuccessScreenState();
}

class _DeliverySuccessScreenState extends State<DeliverySuccessScreen> {
  late FirebaseOrderService _firebaseService;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseOrderService();
    _clearFirebaseData();
  }

  /// Clear Firebase data after successful delivery
  Future<void> _clearFirebaseData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final deliveryBoyId = authProvider.currentDeliveryBoy?.id ?? 0;

      if (deliveryBoyId > 0) {
        await _firebaseService.clearCurrentOrder(deliveryBoyId);
        debugPrint('✅ Firebase data cleared after delivery');
      }
    } catch (e) {
      debugPrint('❌ Error clearing Firebase data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: 'DELIVERY',
            title: 'Successfully Delivered',
            showBackButton: false,
            trailing: HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
              color: colorScheme.success,
              size: 24,
            ),
          ),

          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  /// Success Image
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/sd.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// Success Message
                  Text(
                    'Order completed!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Your earnings have been updated',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// Earnings Breakdown Card
                  widget.cashCollectionData != null
                      ? _buildCashCollectionCard(
                          colorScheme, widget.cashCollectionData!)
                      : _buildDefaultEarningsCard(colorScheme),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          /// Bottom Navigation Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.border,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Prevent multiple rapid clicks
                    if (_isNavigating) return;
                    _isNavigating = true;

                    try {
                      // Clear the current accepted order from provider
                      final incomingOrderProvider =
                          context.read<IncomingOrderProvider>();
                      final authProvider = context.read<AuthProvider>();
                      final deliveryBoyId =
                          authProvider.currentDeliveryBoy?.id ?? 0;

                      if (deliveryBoyId > 0) {
                        // Clear current order from Firebase and provider
                        await incomingOrderProvider
                            .clearCurrentAcceptedOrder(deliveryBoyId);

                        // Stay online and ready for new orders
                        // (home screen handles auto-offline at <15% battery)
                        incomingOrderProvider.startListening(deliveryBoyId);
                        debugPrint('✅ Ready to listen for new orders');
                      }
//////////////////////////
                      // Pop all manually-pushed delivery screens back to
                      // GoRouter's base route (bottomNavScreen). context.go()
                      // alone doesn't work because delivery screens sit on top
                      // of GoRouter's stack as raw Navigator pages.
                      if (mounted) {
                        Navigator.of(context).popUntil(
                          (route) => route.isFirst,
                        );
                      }
                    } finally {
                      _isNavigating = false;
                    }
                  },
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedHome02,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    'Back to Home',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show low battery dialog after ride completion
  Future<void> _showLowBatteryDialog() async {
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.battery_alert_rounded,
                  color: colorScheme.error, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Low Battery',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Your phone battery is below 35%. You have been taken offline. Please charge your phone to at least 35% before going online again.',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  color: colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultEarningsCard(AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          /// Order ID
          _buildSummaryRow(
            'Order ID',
            formatOrderNumber(widget.order.orderId),
            colorScheme,
          ),

          Divider(
            color: colorScheme.border,
            height: 1,
          ),

          /// Total Amount
          _buildSummaryRow(
            'Order Total',
            '₹${widget.order.totalOrderValue.toStringAsFixed(2)}',
            colorScheme,
            isAmount: true,
          ),

          Divider(
            color: colorScheme.border,
            height: 1,
          ),

          /// Delivery Charge
          _buildSummaryRow(
            'Delivery Charge',
            '₹${widget.order.deliveryCharge.toStringAsFixed(2)}',
            colorScheme,
            isAmount: true,
          ),

          Divider(
            color: colorScheme.border,
            height: 1,
          ),

          /// Delivery Tip
          _buildSummaryRow(
            'Delivery Tip',
            '₹${widget.order.deliveryTip.toStringAsFixed(2)}',
            colorScheme,
            isAmount: true,
          ),

          Divider(
            color: colorScheme.border,
            height: 1,
          ),

          /// Multi Order Bonus
          _buildSummaryRow(
            'Multi Order Bonus',
            '₹${widget.order.multiOrderBonus.toStringAsFixed(2)}',
            colorScheme,
            isAmount: true,
          ),

          if (_summaryWaitCharge > 0) ...[
            Divider(
              color: colorScheme.border,
              height: 1,
            ),

            /// Vendor Waiting Charge bonus
            _buildSummaryRow(
              'Waiting Charge Bonus',
              '₹${_summaryWaitCharge.toStringAsFixed(2)}',
              colorScheme,
              isAmount: true,
            ),
          ],

          const SizedBox(height: 12),

          Divider(
            color: colorScheme.primary,
            height: 2,
            thickness: 1.5,
          ),

          /// Total Earnings (Highlighted)
          _buildSummaryRow(
            'Total Earnings',
            '₹${(widget.order.totalEarnings + _summaryWaitCharge).toStringAsFixed(2)}',
            colorScheme,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  /// Returns the vendor_wait_charge from whichever response (cash collection or
  /// prepaid delivery) populated it for this order. Zero when neither has it.
  double get _summaryWaitCharge {
    final cashCharge = widget.cashCollectionData?.vendorWaitCharge ?? 0.0;
    if (cashCharge > 0) return cashCharge;
    try {
      final dynamicCharge = widget.deliveryData?.vendorWaitCharge;
      if (dynamicCharge is num) return dynamicCharge.toDouble();
    } catch (_) {}
    return 0.0;
  }

  Widget _buildCashCollectionCard(
      AppColorScheme colorScheme, CashCollectionData cashData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          /// Order ID
          _buildSummaryRow(
            'Order ID',
            formatOrderNumber(cashData.orderId),
            colorScheme,
          ),

          Divider(
            color: colorScheme.border,
            height: 1,
          ),

          /// Total Collected
          _buildSummaryRow(
            'Total Collected',
            '₹${cashData.totalCollected.toStringAsFixed(0)}',
            colorScheme,
            isAmount: true,
          ),

          Divider(
            color: colorScheme.border,
            height: 1,
          ),

          /// Delivery Charge
          _buildSummaryRow(
            'Delivery Charge',
            '₹${cashData.deliveryCharge.toStringAsFixed(0)}',
            colorScheme,
            isAmount: true,
          ),

          Divider(
            color: colorScheme.border,
            height: 1,
          ),

          /// Delivery Tip
          _buildSummaryRow(
            'Delivery Tip',
            '₹${cashData.deliveryTip.toStringAsFixed(0)}',
            colorScheme,
            isAmount: true,
          ),

          Divider(
            color: colorScheme.border,
            height: 1,
          ),

          /// Bonus Amount
          _buildSummaryRow(
            'Bonus Amount',
            '₹${cashData.bonusAmount.toStringAsFixed(0)}',
            colorScheme,
            isAmount: true,
          ),

          if (cashData.vendorWaitCharge > 0) ...[
            Divider(
              color: colorScheme.border,
              height: 1,
            ),

            /// Vendor Waiting Charge bonus
            _buildSummaryRow(
              'Waiting Charge Bonus',
              '₹${cashData.vendorWaitCharge.toStringAsFixed(2)}',
              colorScheme,
              isAmount: true,
            ),
          ],

          const SizedBox(height: 12),

          Divider(
            color: colorScheme.primary,
            height: 2,
            thickness: 1.5,
          ),

          /// Driver Earnings (Highlighted)
          _buildSummaryRow(
            'Your Earnings',
            '₹${cashData.driverEarnings.toStringAsFixed(0)}',
            colorScheme,
            isTotal: true,
          ),

          const SizedBox(height: 12),

          Divider(
            color: colorScheme.border,
            height: 1,
          ),

          /// Admin Cash
          // _buildSummaryRow(
          //   'Admin Cash',
          //   '₹${cashData.adminCash.toStringAsFixed(0)}',
          //   colorScheme,
          //   isAmount: true,
          // ),

          // Divider(
          //   color: colorScheme.border,
          //   height: 1,
          // ),

          /// Cash to Settle
          _buildSummaryRow(
            'Cash to Settle',
            '₹${cashData.adminCash.toStringAsFixed(0)}',
            colorScheme,
            isAmount: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    AppColorScheme colorScheme, {
    bool isAmount = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? colorScheme.primary : colorScheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal ? colorScheme.primary : colorScheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
