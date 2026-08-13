import 'dart:convert';
import 'dart:developer';
import 'package:zenfoo_partner/utils/order_number.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/incoming_order_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/services/firebase_order_service.dart';
import 'package:zenfoo_partner/models/cash_collection_model.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/delivery/delivery_success_screen.dart';
import 'dart:io' show File;

class OTPVerificationScreen extends StatefulWidget {
  final IncomingOrder order;
  final String paymentMode; // 'qr' or 'cash'
  final double totalAmount;
  final List<XFile>? deliveryImages; // Images from delivery confirmation

  const OTPVerificationScreen({
    super.key,
    required this.order,
    required this.paymentMode,
    required this.totalAmount,
    this.deliveryImages,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  late TextEditingController _amountController;
  bool _isProcessing = false;

  // QR state
  Uint8List? _qrImageBytes;
  bool _isLoadingQr = false;
  String? _qrError;
  Map<String, dynamic>? _qrData;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();

    if (widget.paymentMode == 'qr') {
      _fetchQrCode();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchQrCode() async {
    setState(() {
      _isLoadingQr = true;
      _qrError = null;
    });

    try {
      final apiService = ApiService();
      final url = '${AppUrl.baseUrl}/api/delivery-boy/orders/generate-qr?order_id=${widget.order.orderId}';
      final response = await apiService.post(
        url,
        data: {},
        isToast: false,
      );

      if (!mounted) return;

      if (response.status == ApiStatus.success && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final base64String = data?['qr_image_base64'] as String?;

        if (base64String != null && base64String.isNotEmpty) {
          // Strip data:image/...;base64, prefix if present
          final pureBase64 = base64String.contains(',')
              ? base64String.split(',').last
              : base64String;

          final bytes = base64Decode(pureBase64);
          debugPrint('📊 QR API data keys: ${data?.keys.toList()}');
          debugPrint('📊 QR API data: $data');
          setState(() {
            _qrImageBytes = bytes;
            _qrData = data;
            _isLoadingQr = false;
          });
        } else {
          setState(() {
            _qrError = 'QR code not available';
            _isLoadingQr = false;
          });
        }
      } else {
        setState(() {
          _qrError = response.message ?? 'Failed to generate QR code';
          _isLoadingQr = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _qrError = 'Something went wrong. Please retry.';
        _isLoadingQr = false;
      });
      debugPrint('❌ QR fetch error: $e');
    }
  }

  void _handleCashCollection() {
    final enteredAmount = double.tryParse(_amountController.text) ?? 0;

    if (enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid amount',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) {
        final colorScheme = context.read<ThemeProvider>().colorScheme;
        return AlertDialog(
          title: Text(
            'Are you sure , you\ncollected cash',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Amount: ₹$enteredAmount',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.textSecondary,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'No',
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _completeDelivery();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
              ),
              child: Text(
                'Yes',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeDelivery() async {
    setState(() => _isProcessing = true);

    try {
      final enteredAmount = double.tryParse(_amountController.text) ?? 0;

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('💳 CASH COLLECTION API REQUEST (OTP Screen)');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔗 Endpoint: /api/delivery-boy/orders/collect-cash');
      debugPrint('🔤 Method: POST');
      debugPrint('');
      debugPrint('📋 Parameters:');
      debugPrint('  • order_id: ${widget.order.orderId}');
      debugPrint('  • amount: $enteredAmount');
      debugPrint('  • images: ${widget.deliveryImages?.length ?? 0} file(s)');
      debugPrint('');

      // Convert XFile images to File objects (all files share same key 'images[]')
      List<MapEntry<String, File>>? multiFiles;
      if (widget.deliveryImages != null && widget.deliveryImages!.isNotEmpty) {
        multiFiles = widget.deliveryImages!.map((xFile) {
          debugPrint('📸 Image: ${xFile.name}');
          return MapEntry('images[]', File(xFile.path));
        }).toList();
      }

      // Call cash collection API
      final apiService = ApiService();
      final endpoint =
          '${AppUrl.baseUrl}/api/delivery-boy/orders/collect-cash?order_id=${widget.order.orderId}&amount=$enteredAmount';

      final response = await apiService.post(
        endpoint,
        multiFiles: multiFiles,
        isToast: false,
      );

      debugPrint('');
      debugPrint('📊 API Response:');
      debugPrint('  • Status: ${response.status}');
      debugPrint('  • Message: ${response.message}');
      debugPrint('═══════════════════════════════════════════════════════');

      if (!mounted) return;

      if (response.status == ApiStatus.success) {
        debugPrint('✅ Cash collected successfully');

        // Update Firebase with delivered status for cash collection
        final authProvider = context.read<AuthProvider>();
        final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

        if (deliveryBoyId != null) {
          final firebaseService = FirebaseOrderService();
          await firebaseService.updateOrderStatusDelivered(
            orderId: widget.order.orderId,
            deliveryBoyId: deliveryBoyId,
          );
        }

        // Parse the response data to CashCollectionData
        final cashData = response.data != null
            ? CashCollectionData.fromJson(response.data['data'])
            : null;

        log("message ${response.data} $cashData ${cashData?.orderId} ${response.toString()}");

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DeliverySuccessScreen(
                order: widget.order,
                cashCollectionData: cashData,
              ),
            ),
          );
        }
      } else {
        setState(() => _isProcessing = false);
        debugPrint('❌ Error: ${response.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message ?? 'Failed to collect cash. Please try again.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);

      debugPrint('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleQrPaymentDone() {
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirm Payment',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.textPrimary,
            ),
          ),
          content: Text(
            'Has the customer completed the payment of ₹${widget.totalAmount.toStringAsFixed(0)}?',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colorScheme.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'No',
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _completeQrDelivery();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Yes, Done',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeQrDelivery() async {
    // Validate images exist
    if (widget.deliveryImages == null || widget.deliveryImages!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delivery proof images are required.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Build multiFiles list — all share 'images[]' key (same as Postman)
      final multiFiles = widget.deliveryImages!
          .map((image) => MapEntry('images[]', File(image.path)))
          .toList();

      debugPrint('📡 [mark-delivered] order_id=${widget.order.orderId}, images=${widget.deliveryImages!.length}');

      final apiService = ApiService();
      final response = await apiService.post(
        AppUrl.markDelivered,
        data: {'order_id': widget.order.orderId},
        multiFiles: multiFiles,
        isToast: false,
      );

      debugPrint('📡 [mark-delivered] status=${response.status} message=${response.message}');
      debugPrint('📡 [mark-delivered] data=${response.data}');

      if (!mounted) return;

      if (response.status == ApiStatus.success) {
        // Update Firebase delivered status
        final authProvider = context.read<AuthProvider>();
        final deliveryBoyId = authProvider.currentDeliveryBoy?.id;
        if (deliveryBoyId != null) {
          final firebaseService = FirebaseOrderService();
          await firebaseService.updateOrderStatusDelivered(
            orderId: widget.order.orderId,
            deliveryBoyId: deliveryBoyId,
          );
        }

        // Map mark-delivered response to CashCollectionData for success screen
        final data = response.data?['data'] as Map<String, dynamic>?;
        final cashData = data == null
            ? null
            : CashCollectionData(
                orderId: (data['order_id'] as num?)?.toInt() ?? widget.order.orderId,
                totalCollected: (data['driver_earnings'] as num?)?.toDouble() ?? 0,
                deliveryCharge: (data['delivery_charge'] as num?)?.toDouble() ?? 0,
                deliveryTip: (data['delivery_tip'] as num?)?.toDouble() ?? 0,
                bonusAmount: (data['bonus_amount'] as num?)?.toDouble() ?? 0,
                driverEarnings: (data['driver_earnings'] as num?)?.toDouble() ?? 0,
                adminCash: 0, // No cash to settle for online payments
                transactionId: (data['transaction_id'] as num?)?.toInt() ?? 0,
                cashToSettleWithAdmin: 0,
                travelTimeMinutes: (data['travel_time_minutes'] as num?)?.toInt() ?? 0,
              );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DeliverySuccessScreen(
                order: widget.order,
                cashCollectionData: cashData,
              ),
            ),
          );
        }
      } else {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message ?? 'Failed to complete delivery.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      debugPrint('❌ [mark-delivered] error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final isQRMode = widget.paymentMode == 'qr';

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: context.watch<LanguageProvider>().getTranslatedText('payment'),
            title: isQRMode
                ? context.watch<LanguageProvider>().getTranslatedText('show_qr')
                : context.watch<LanguageProvider>().getTranslatedText('collect_cash'),
            showBackButton: true,
            trailing: HugeIcon(
              icon: isQRMode
                  ? HugeIcons.strokeRoundedQrCode
                  : HugeIcons.strokeRoundedMoneyReceive02,
              color: colorScheme.textPrimary,
              size: 24,
            ),
          ),

          /// CONTENT
          Expanded(
            child: isQRMode
                ? _buildQrContent(colorScheme)
                : _buildCashContent(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildQrContent(AppColorScheme colorScheme) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                /// AMOUNT CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount to Collect',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.textSecondary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            '₹${((_qrData?['amount'] as num?) ?? (_qrData?['total_amount'] as num?) ?? (_qrData?['order_amount'] as num?) ?? widget.totalAmount).toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      if (_qrData != null) ...[
                        const SizedBox(height: 12),
                        Divider(color: colorScheme.primary.withValues(alpha: 0.15), height: 1),
                        const SizedBox(height: 12),
                        _buildAmountRow('Order ID', formatOrderNumber(_qrData!['order_id'] ?? widget.order.orderId), colorScheme),
                        if (_qrData!['delivery_charge'] != null) ...[
                          const SizedBox(height: 6),
                          _buildAmountRow('Delivery Charge', '₹${((_qrData!['delivery_charge'] as num?)?.toStringAsFixed(0) ?? '0')}', colorScheme),
                        ],
                        if (_qrData!['order_amount'] != null) ...[
                          const SizedBox(height: 6),
                          _buildAmountRow('Order Amount', '₹${((_qrData!['order_amount'] as num?)?.toStringAsFixed(0) ?? '0')}', colorScheme),
                        ],
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// QR CODE CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: colorScheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Scan to Pay',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ask the customer to scan using any UPI app',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.textSecondary,
                          letterSpacing: -0.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      /// QR IMAGE
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.border.withValues(alpha: 0.5),
                          ),
                        ),
                        child: _buildQrImage(colorScheme),
                      ),

                      const SizedBox(height: 16),

                      /// UPI BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.success.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: colorScheme.success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Works with all UPI apps',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// INSTRUCTIONS
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._qrInstructions.map(
                        (instruction) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: colorScheme.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  instruction,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: colorScheme.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        /// PAYMENT DONE BUTTON
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_qrImageBytes == null || _isProcessing) ? null : _handleQrPaymentDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor:
                      colorScheme.primary.withValues(alpha: 0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Payment Done',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<String> get _qrInstructions {
    // Use instructions from API if available
    final apiInstructions = _qrData?['instructions'];
    if (apiInstructions is List && apiInstructions.isNotEmpty) {
      return apiInstructions.map((e) => e.toString()).toList();
    }
    // Default instructions
    return [
      'Ask customer to scan QR using any UPI app',
      'Payment will go directly to Zenfoo',
      'Tap "Payment Done" once customer confirms payment',
    ];
  }

  Widget _buildAmountRow(String label, String value, AppColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildQrImage(AppColorScheme colorScheme) {
    if (_isLoadingQr) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 12),
            Text(
              'Generating QR...',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_qrError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: colorScheme.error,
            ),
            const SizedBox(height: 10),
            Text(
              _qrError!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colorScheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _fetchQrCode,
              icon: Icon(Icons.refresh_rounded,
                  size: 16, color: colorScheme.primary),
              label: Text(
                'Retry',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_qrImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          _qrImageBytes!,
          fit: BoxFit.contain,
          width: 220,
          height: 220,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCashContent(AppColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          /// Cash Amount Display
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '₹${widget.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'After collecting the cash, enter\nthe exact amount to complete the\ndelivery.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorScheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          /// Cash Input Field
          TextField(
            controller: _amountController,
            enabled: !_isProcessing,
            decoration: InputDecoration(
              hintText: 'Enter collected amount',
              hintStyle: GoogleFonts.inter(
                color: colorScheme.textSecondary,
              ),
              filled: true,
              fillColor: colorScheme.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Note : Enter the collected cash amount to complete the Delivery.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 40),

          /// Cash Collected Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleCashCollection,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                disabledBackgroundColor:
                    colorScheme.primary.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isProcessing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    )
                  : Text(
                      'Cash Collected',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
