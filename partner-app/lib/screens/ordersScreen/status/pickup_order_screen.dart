import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/screens/ordersScreen/order_list_view.dart';
import 'package:project/screens/ordersScreen/widgets/driver_avatar.dart';
import 'package:project/repositories/newOrdersApi.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/services/firebase_eta_service.dart';
import 'package:project/provider/eta_provider.dart';
import 'package:project/models/invoice_model.dart';
import 'package:project/services/invoice_pdf_service.dart';
import 'package:project/services/bluetooth_printer_service.dart';
import 'package:provider/provider.dart';

// Animated wrapper for order card
class AnimatedOrderCard extends StatefulWidget {
  final Order order;
  final ValueChanged<int> onTimeChanged;
  final VoidCallback onAdvance;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback? onConfirmOtp;
  final VoidCallback? onPrepTimeSet;
  final VoidCallback? onStatusChanged;
  final VoidCallback? onStatusUpdateSuccess;

  const AnimatedOrderCard({
    required this.order,
    required this.onTimeChanged,
    required this.onAdvance,
    this.onCall,
    this.onChat,
    this.onConfirmOtp,
    this.onPrepTimeSet,
    this.onStatusChanged,
    this.onStatusUpdateSuccess,
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedOrderCard> createState() => AnimatedOrderCardState();
}

class AnimatedOrderCardState extends State<AnimatedOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void animateOut() async {
    if (!_isRemoving) {
      setState(() {
        _isRemoving = true;
      });
      await _animationController.forward();
      if (mounted) {
        widget.onStatusChanged?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: OrderCardUnified(
        order: widget.order,
        onTimeChanged: widget.onTimeChanged,
        onAdvance: widget.onAdvance,
        onCall: widget.onCall,
        onChat: widget.onChat,
        onConfirmOtp: widget.onConfirmOtp,
        onPrepTimeSet: widget.onPrepTimeSet,
        onStatusChanged: animateOut,
        onStatusUpdateSuccess: widget.onStatusUpdateSuccess,
      ),
    );
  }
}

class OrderCardUnified extends StatefulWidget {
  final Order order;
  final ValueChanged<int> onTimeChanged;
  final VoidCallback onAdvance;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback? onConfirmOtp;
  final List<String>? otpDigits;
  final VoidCallback? onPrepTimeSet;
  final VoidCallback? onStatusChanged;
  final VoidCallback? onStatusUpdateSuccess;

  const OrderCardUnified({
    required this.order,
    required this.onTimeChanged,
    required this.onAdvance,
    this.onCall,
    this.onChat,
    this.onConfirmOtp,
    this.otpDigits,
    this.onPrepTimeSet,
    this.onStatusChanged,
    this.onStatusUpdateSuccess,
    Key? key,
  }) : super(key: key);

  @override
  State<OrderCardUnified> createState() => _OrderCardUnifiedState();
}

class _OrderCardUnifiedState extends State<OrderCardUnified> {
  bool _showAllItems = false;
  bool _isSettingPrepTime = false;
  bool _isDownloadingInvoice = false;
  bool _isPrintingInvoice = false;
  Timer? _countdownTimer;
  Duration _remainingDuration = Duration.zero;
  String _enteredOtp = '';

  // Local state for countdown (primary display source)
  DateTime? _localPrepStartTime;
  int? _localPrepMinutes;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _remainingDuration = _calculateRemainingDuration();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingDuration = _calculateRemainingDuration();
          if (_remainingDuration.inSeconds <= 0) {
            timer.cancel();
          }
        });
      }
    });
  }

  Duration _calculateRemainingDuration() {
    // Primary: Use local state for countdown display
    if (_localPrepStartTime != null && _localPrepMinutes != null) {
      final now = DateTime.now();
      final prepEndTime =
          _localPrepStartTime!.add(Duration(minutes: _localPrepMinutes!));
      final remaining = prepEndTime.difference(now);

      if (remaining.isNegative) {
        return Duration.zero;
      }
      return remaining;
    }

    // Fallback to order model data
    return widget.order.getRemainingDuration();
  }

  @override
  void didUpdateWidget(OrderCardUnified oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.prepTime != widget.order.prepTime ||
        oldWidget.order.prepTimeString != widget.order.prepTimeString ||
        oldWidget.order.prepTimeMinutes != widget.order.prepTimeMinutes) {
      _startCountdown();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get seller count from Firebase ETA document, defaults to 1 if not found
  Future<int> _getSellerCountFromFirebase(int orderId) async {
    try {
      final eta = await FirebaseEtaService().getOrderEta(orderId: orderId);
      if (eta != null) {
        debugPrint('📊 Seller count from Firebase: ${eta.sellerCount}');
        return eta.sellerCount;
      }
    } catch (e) {
      debugPrint('⚠️ Error getting seller count from Firebase: $e');
    }
    // Default to 1 if not found or error occurs
    debugPrint('📊 Seller count defaulting to: 1');
    return 1;
  }

  Future<void> _handleSetPrepTime() async {
    if (widget.order.orderId == null) return;

    setState(() {
      _isSettingPrepTime = true;
    });

    try {
      final now = DateTime.now();
      final hour =
          now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final timeString =
          '$hour:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

      debugPrint('📋 Setting preparation time: 15 mins at $timeString');

      // Set local state for countdown display
      setState(() {
        _localPrepStartTime = now;
        _localPrepMinutes = 15;
      });

      _startCountdown();

      // Update backend API
      final response = await updatePrepTime(
        orderId: widget.order.orderId!,
        prepTime: [15, timeString],
        context: context,
        isPreparation: 1,
      );

      if (response['status'] == 1) {
        debugPrint('✅ Preparation time set successfully at $timeString');

        // Update Firebase with proper calculation accounting for existing ETA
        debugPrint('🔄 Preparing Firebase ETA update with 15 min addition');
        _getSellerCountFromFirebase(widget.order.orderId!).then((sellerCount) {
          // Use updateEta() to add 15 minutes considering existing ETA and elapsed time
          // This calculates: remaining + (15 / seller_count)
          FirebaseEtaService()
              .updateEta(
            orderId: widget.order.orderId!,
            adjustmentMinutes: 15,
            sellerCount: sellerCount,
          )
              .then((success) {
            if (success) {
              debugPrint('✅ Firebase ETA updated with 15 min addition');
            } else {
              debugPrint(
                  '❌ Firebase ETA update failed - attempting setEta fallback');
              // Fallback to setEta if updateEta fails (document doesn't exist)
              FirebaseEtaService().setEta(
                orderId: widget.order.orderId!,
                etaMinutes: 15,
                sellerCount: sellerCount,
              );
            }
          }).catchError((e) {
            debugPrint('❌ Firebase ETA error: $e');
          });
        });

        widget.onPrepTimeSet?.call();
      } else {
        debugPrint('❌ Failed to set prep time via API');
        if (mounted) {
          setState(() {
            _localPrepStartTime = null;
            _localPrepMinutes = null;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error setting prep time: $e');
      if (mounted) {
        setState(() {
          _localPrepStartTime = null;
          _localPrepMinutes = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSettingPrepTime = false;
        });
      }
    }
  }

  Future<void> _updatePrepTime(int newMinutes) async {
    if (widget.order.orderId == null) return;

    try {
      final now = DateTime.now();
      final hour =
          now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final timeString =
          '$hour:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

      debugPrint('📋 Updating prep time to $newMinutes minutes at $timeString');

      // Update local state for countdown display (reset start time to now)
      setState(() {
        _localPrepStartTime = now;
        _localPrepMinutes = newMinutes;
      });

      _startCountdown();

      // Update backend API
      final response = await updatePrepTime(
        orderId: widget.order.orderId!,
        prepTime: [newMinutes, timeString],
        context: context,
        isPreparation: 1,
      );

      if (response['status'] == 1) {
        debugPrint(
            '✅ Prep time updated successfully via API to $newMinutes minutes');

        // Replace Firebase ETA with the new prep time value directly.
        // We must NOT use setEta() here because when a document already exists,
        // setEta() adds newMinutes to the remaining time (remaining + newMinutes),
        // which causes ETA to increase when the seller reduces prep time.
        // Instead, we overwrite the ETA field with newMinutes and reset stored_at to now.
        debugPrint('🔄 Replacing Firebase ETA with newEta=$newMinutes');
        _getSellerCountFromFirebase(widget.order.orderId!).then((sellerCount) {
          FirebaseEtaService()
              .replaceEta(
            orderId: widget.order.orderId!,
            etaMinutes: newMinutes,
            sellerCount: sellerCount,
          )
              .then((success) {
            if (success) {
              debugPrint(
                  '✅ Firebase ETA replaced successfully to $newMinutes minutes');
            } else {
              debugPrint('❌ Firebase ETA replace failed');
            }
          }).catchError((e) {
            debugPrint('❌ Firebase ETA replace error: $e');
          });
        });

        widget.onPrepTimeSet?.call();
      } else {
        debugPrint('❌ Failed to update prep time via API');
        if (mounted) {
          setState(() {
            _localPrepStartTime = null;
            _localPrepMinutes = null;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating prep time: $e');
      if (mounted) {
        setState(() {
          _localPrepStartTime = null;
          _localPrepMinutes = null;
        });
      }
    }
  }

  Future<void> _downloadInvoice() async {
    if (widget.order.orderId == null || _isDownloadingInvoice) return;

    setState(() {
      _isDownloadingInvoice = true;
    });

    try {
      final response = await getOrderInvoice(
        orderId: widget.order.orderId!,
        context: context,
      );

      if (response['status'] == 1 && response['invoice'] != null) {
        final invoiceModel = InvoiceModel.fromJson(response);
        if (invoiceModel.invoice != null && mounted) {
          await InvoicePdfService.generateAndShareInvoice(
            context,
            invoiceModel.invoice!,
            settlementInfo: widget.order.settlementInfo,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(response['message'] ?? 'Failed to download invoice'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error downloading invoice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingInvoice = false;
        });
      }
    }
  }

  Future<void> _printInvoice() async {
    if (widget.order.orderId == null || _isPrintingInvoice) return;

    // Show print options bottom sheet
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    final printOption = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Print Option',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF9AC444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedPrinter,
                  color: const Color(0xFF9AC444),
                  size: 24,
                ),
              ),
              title: Text(
                'System Print (PDF)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textPrimary,
                ),
              ),
              subtitle: Text(
                'Print using system printer dialog',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.textSecondary,
                ),
              ),
              trailing:
                  Icon(Icons.chevron_right, color: colorScheme.iconPrimary),
              onTap: () => Navigator.pop(context, 'system'),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3183F4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedBluetooth,
                  color: const Color(0xFF3183F4),
                  size: 24,
                ),
              ),
              title: Text(
                'Bluetooth Printer',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textPrimary,
                ),
              ),
              subtitle: Text(
                'Print to thermal receipt printer',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.textSecondary,
                ),
              ),
              trailing:
                  Icon(Icons.chevron_right, color: colorScheme.iconPrimary),
              onTap: () => Navigator.pop(context, 'bluetooth'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (printOption == null) return;

    setState(() {
      _isPrintingInvoice = true;
    });

    try {
      final response = await getOrderInvoice(
        orderId: widget.order.orderId!,
        context: context,
      );

      if (response['status'] == 1 && response['invoice'] != null) {
        final invoiceModel = InvoiceModel.fromJson(response);
        if (invoiceModel.invoice != null && mounted) {
          if (printOption == 'bluetooth') {
            // Use Bluetooth thermal printer
            await BluetoothPrinterService.showPrinterSelectionAndPrint(
              context,
              invoiceModel.invoice!,
            );
          } else {
            // Use system print dialog (PDF)
            await InvoicePdfService.generateAndPrintInvoice(
              context,
              invoiceModel.invoice!,
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to print invoice'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error printing invoice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrintingInvoice = false;
        });
      }
    }
  }

  Widget _actionRow(
      BuildContext context, app_theme.AppColorScheme colorScheme) {
    if (widget.order.status == OrderStatus.otp) {
      final hasDeliveryPartner = widget.order.deliveryPerson.isNotEmpty;
      final deliveryPerson = hasDeliveryPartner
          ? widget.order.deliveryPerson
          : "Delivery Partner Not Assigned";
      final deliveryPersonSubtitle = hasDeliveryPartner
          ? widget.order.deliveryPersonSubtitle.isEmpty
              ? "Delivery Partner"
              : widget.order.deliveryPersonSubtitle
          : "Looking for a delivery partner...";

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: !hasDeliveryPartner
                    ? Icon(
                        Icons.person_outline,
                        color: colorScheme.iconPrimary,
                        size: 28,
                      )
                    : widget.order.deliveryPersonImage != null &&
                            widget.order.deliveryPersonImage!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(27),
                            child: Image.network(
                              widget.order.deliveryPersonImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to first letter if image fails to load
                                return Container(
                                  color: colorScheme.primary,
                                  child: Center(
                                    child: Text(
                                      deliveryPerson[0].toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(27),
                            child: Container(
                              color: colorScheme.primary,
                              child: Center(
                                child: Text(
                                  deliveryPerson[0].toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deliveryPerson,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: hasDeliveryPartner
                            ? colorScheme.textPrimary
                            : colorScheme.textTertiary,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      deliveryPersonSubtitle,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: colorScheme.textSecondary,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasDeliveryPartner)
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.surfaceVariant,
                      radius: 20,
                      child: IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCall02,
                          size: 20,
                          color: colorScheme.iconPrimary,
                          strokeWidth: 2.0,
                        ),
                        onPressed: widget.onCall ?? () {},
                      ),
                    ),
                    SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: colorScheme.surfaceVariant,
                      radius: 20,
                      child: IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedMessage01,
                          size: 20,
                          color: colorScheme.iconPrimary,
                          strokeWidth: 2.0,
                        ),
                        onPressed: widget.onChat ?? () {},
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 16),
          if (hasDeliveryPartner) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Enter PIN",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: colorScheme.textPrimary,
                  height: 1.02,
                  letterSpacing: -0.55,
                ),
              ),
            ),
            SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Collect PIN from delivery partner to complete order status.",
                style: GoogleFonts.inter(
                  fontSize: 12.7,
                  color: colorScheme.textSecondary,
                  fontWeight: FontWeight.w400,
                  height: 1.02,
                  letterSpacing: -0.55,
                ),
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OtpTextField(
                  numberOfFields: 4,
                  borderColor: colorScheme.border,
                  focusedBorderColor: Color(0xFF3183F4),
                  showFieldAsBox: true,
                  fieldWidth: 50,
                  borderRadius: BorderRadius.circular(10),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                  cursorColor: colorScheme.textPrimary,
                  textStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: colorScheme.textPrimary,
                    height: 1.02,
                    letterSpacing: -0.55,
                  ),
                  onCodeChanged: (String code) {
                    setState(() {
                      _enteredOtp = code;
                    });
                  },
                  onSubmit: (String completedCode) {
                    setState(() {
                      _enteredOtp = completedCode;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 23),
            SwipeToConfirmOtpButton(
              orderId: widget.order.orderId,
              otp: _enteredOtp,
              onConfirmed: () {
                widget.onStatusUpdateSuccess?.call();
                widget.onStatusChanged?.call();
              },
            ),
            SizedBox(height: 10),
          ] else ...[
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFFFFE0B2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    color: Color(0xFFFF9800),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Waiting for delivery partner assignment...",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF795548),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
          ],
        ],
      );
    }

    if (widget.order.status == OrderStatus.picked) {
      final deliveryPerson = widget.order.deliveryPerson.isEmpty
          ? "Delivery Partner"
          : widget.order.deliveryPerson;
      final deliveryPersonSubtitle = widget.order.deliveryPersonSubtitle.isEmpty
          ? "Delivery Partner"
          : widget.order.deliveryPersonSubtitle;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DriverAvatar(
                imageUrl: widget.order.deliveryPersonImage,
                name: deliveryPerson,
                colorScheme: colorScheme,
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deliveryPerson,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: colorScheme.textPrimary,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      deliveryPersonSubtitle,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: colorScheme.textSecondary,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.surfaceVariant,
                    radius: 20,
                    child: IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCall02,
                        size: 20,
                        color: colorScheme.iconPrimary,
                        strokeWidth: 2.0,
                      ),
                      onPressed: widget.onCall ?? () {},
                    ),
                  ),
                  SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: colorScheme.surfaceVariant,
                    radius: 20,
                    child: IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedMessage01,
                        size: 20,
                        color: colorScheme.iconPrimary,
                        strokeWidth: 2.0,
                      ),
                      onPressed: widget.onChat ?? () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFFDDFCEA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "Order Picked by Delivery Partner",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10823F),
                  fontSize: 17,
                  height: 1.5,
                  letterSpacing: -0.55,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
        ],
      );
    }

    if (widget.order.status == OrderStatus.outForDelivery) {
      final deliveryPerson = widget.order.deliveryPerson.isEmpty
          ? "Delivery Partner"
          : widget.order.deliveryPerson;
      final deliveryPersonSubtitle = widget.order.deliveryPersonSubtitle.isEmpty
          ? "On the way"
          : widget.order.deliveryPersonSubtitle;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DriverAvatar(
                imageUrl: widget.order.deliveryPersonImage,
                name: deliveryPerson,
                colorScheme: colorScheme,
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deliveryPerson,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: colorScheme.textPrimary,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      deliveryPersonSubtitle,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: colorScheme.textSecondary,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.surfaceVariant,
                    radius: 20,
                    child: IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCall02,
                        size: 20,
                        color: colorScheme.iconPrimary,
                        strokeWidth: 2.0,
                      ),
                      onPressed: widget.onCall ?? () {},
                    ),
                  ),
                  SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: colorScheme.surfaceVariant,
                    radius: 20,
                    child: IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedMessage01,
                        size: 20,
                        color: colorScheme.iconPrimary,
                        strokeWidth: 2.0,
                      ),
                      onPressed: widget.onChat ?? () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedDeliveryTruck01,
                    color: Color(0xFF1976D2),
                    size: 20,
                    strokeWidth: 2.5,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Out for Delivery",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1976D2),
                      fontSize: 17,
                      height: 1.02,
                      letterSpacing: -0.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
        ],
      );
    }

    if (widget.order.status == OrderStatus.delivered) {
      final deliveryPerson = widget.order.deliveryPerson.isEmpty
          ? "Delivery Partner"
          : widget.order.deliveryPerson;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Color(0xFFDDFCEA),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF10823F),
                  size: 32,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Delivered by $deliveryPerson",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: colorScheme.textPrimary,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Order completed successfully",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: colorScheme.textSecondary,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFFDDFCEA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedTick02,
                    color: Color(0xFF10823F),
                    size: 20,
                    strokeWidth: 2.5,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Order Delivered",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10823F),
                      fontSize: 17,
                      height: 1.02,
                      letterSpacing: -0.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
        ],
      );
    }

    if (widget.order.status == OrderStatus.cancelled) {
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFFFFF2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "Order Cancelled",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Color(0xFFE24336),
                fontSize: 18,
                height: 1.02,
                letterSpacing: -0.55,
              ),
            ),
          ),
        ),
      );
    }

    Color buttonColor;
    String buttonText;
    switch (widget.order.status) {
      case OrderStatus.readyForPickup:
        buttonColor = Color(0xFF3183F4);
        buttonText = 'Ready for Pickup';
        break;
      case OrderStatus.preparing:
      default:
        buttonColor = Color(0xFF9AC444);
        buttonText = 'Preparing';
        break;
    }

    return Row(
      children: [
        Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(width: 1, color: colorScheme.border),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget
                    .onTimeChanged((widget.order.minutes - 5).clamp(5, 99)),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedMinusSign,
                  color: colorScheme.iconPrimary,
                  size: 24,
                  strokeWidth: 2.2,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '${widget.order.minutes} Mins',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                  height: 1.02,
                  letterSpacing: -0.55,
                ),
              ),
              SizedBox(width: 6),
              GestureDetector(
                onTap: () => widget
                    .onTimeChanged((widget.order.minutes + 5).clamp(5, 99)),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01,
                  color: colorScheme.iconPrimary,
                  size: 24,
                  strokeWidth: 2.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: widget.onAdvance,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.02,
                      letterSpacing: -0.55,
                    ),
                  ),
                  SizedBox(width: 10),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    color: Colors.white,
                    size: 28,
                    strokeWidth: 2.2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    List<OrderItemRow> getItemRows() {
      return widget.order.items.map((product) {
        String variantInfo = '';
        if (product.measurement != null && product.unitShortCode != null) {
          variantInfo = '${product.measurement} ${product.unitShortCode}';
        } else if (product.variantName != null &&
            product.variantName!.isNotEmpty) {
          variantInfo = product.variantName!;
        }

        return OrderItemRow(
          qty: '${product.quantity ?? 1}X',
          name: product.productName ?? 'Product',
          unit: variantInfo,
          price: '₹${product.subTotal ?? product.price ?? 0}',
        );
      }).toList();
    }

    final bool hasPrepTime = widget.order.prepTime != null;
    final bool isPreparingStatus = widget.order.status == OrderStatus.preparing;
    final bool isUrgent = hasPrepTime &&
        isPreparingStatus &&
        _remainingDuration.inMinutes <= 5 &&
        _remainingDuration.inMinutes > 0;
    final bool isExpired =
        hasPrepTime && isPreparingStatus && _remainingDuration.inSeconds <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 23),
      decoration: BoxDecoration(
        color: isExpired ? Color(0xFFFFF5F5) : colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: isUrgent || isExpired
            ? Border.all(
                color: isExpired ? Color(0xFFE24336) : Color(0xFFFF9800),
                width: 2,
              )
            : Border.all(color: colorScheme.border, width: 1),
        boxShadow: isUrgent || isExpired
            ? [
                BoxShadow(
                  color: (isExpired ? Color(0xFFE24336) : Color(0xFFFF9800))
                      .withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: Offset(0, 0),
                  spreadRadius: 0,
                )
              ]
            : colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUrgent || isExpired) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isExpired ? Color(0xFFE24336) : Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: isExpired
                        ? HugeIcons.strokeRoundedAlert02
                        : HugeIcons.strokeRoundedAlert01,
                    color: Colors.white,
                    size: 16,
                    strokeWidth: 2.5,
                  ),
                  SizedBox(width: 6),
                  Text(
                    isExpired ? 'TIME UP!' : 'URGENT',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.02,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID: ${widget.order.orderId}',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.02,
                  letterSpacing: -0.55,
                ),
              ),
              Row(
                children: [
                  // Print Button
                  GestureDetector(
                    onTap: _isPrintingInvoice ? null : _printInvoice,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isPrintingInvoice
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF9AC444),
                                ),
                              ),
                            )
                          : HugeIcon(
                              icon: HugeIcons.strokeRoundedPrinter,
                              color: colorScheme.iconPrimary,
                              size: 20,
                              strokeWidth: 2.0,
                            ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Download Button
                  GestureDetector(
                    onTap: _isDownloadingInvoice ? null : _downloadInvoice,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isDownloadingInvoice
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF9AC444),
                                ),
                              ),
                            )
                          : HugeIcon(
                              icon: HugeIcons.strokeRoundedDownload04,
                              color: colorScheme.iconPrimary,
                              size: 20,
                              strokeWidth: 2.0,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 5),
          Text(
            'Order Details',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.02,
              letterSpacing: -0.55,
            ),
          ),
          SizedBox(height: 9),
          ...(_showAllItems || getItemRows().length <= 2
              ? getItemRows()
              : getItemRows().take(2).toList()),
          if (!_showAllItems && getItemRows().length > 2) ...[
            SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAllItems = true;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View ${getItemRows().length - 2} more ${getItemRows().length - 2 == 1 ? 'product' : 'products'}',
                      style: GoogleFonts.inter(
                        color: Color(0xFF9AC444),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF9AC444),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 8),
          Container(
            height: 1,
            color: colorScheme.border,
          ),
          if (widget.order.status != OrderStatus.cancelled) ...[
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Price',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.02,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${widget.order.payable.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      color: Color(0xFF10B981),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.02,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (widget.order.notes.isNotEmpty)
              Text(
                'Instruction :   ${widget.order.notes}',
                style: GoogleFonts.inter(
                  color: Color(0xFF3B82F6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.55,
                  height: 1.02,
                ),
              ),
            SizedBox(height: 14),
          ],
          if (widget.order.prepTime == null &&
              widget.order.status != OrderStatus.otp &&
              widget.order.status != OrderStatus.picked &&
              widget.order.status != OrderStatus.cancelled &&
              widget.order.status != OrderStatus.delivered &&
              widget.order.orderData.activeStatus?.toLowerCase() != 'cancelled' &&
              widget.order.orderData.activeStatus?.toLowerCase() != 'returned' &&
              widget.order.orderData.statusData?.id != 7 &&
              widget.order.orderData.statusData?.id != 8) ...[
            GestureDetector(
              onTap: _isSettingPrepTime ? null : _handleSetPrepTime,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Color(0xFF9AC444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isSettingPrepTime
                    ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedClock01,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Set Preparation Time (${widget.order.minutes} mins)',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.02,
                              letterSpacing: -0.55,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 14),
          ],
          if (widget.order.prepTime != null &&
              widget.order.status == OrderStatus.preparing) ...[
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.border, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final currentMinutes = _remainingDuration.inMinutes;
                      final newMinutes = (currentMinutes - 5).clamp(5, 99);
                      await _updatePrepTime(newMinutes);
                    },
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.border, width: 1),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedMinusSign,
                        color: colorScheme.iconPrimary,
                        size: 20,
                        strokeWidth: 2.2,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedClock01,
                          color: _remainingDuration.inMinutes <= 5
                              ? Color(0xFFE24336)
                              : Color(0xFF9AC444),
                          size: 20,
                          strokeWidth: 2.0,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _formatDuration(_remainingDuration),
                          style: GoogleFonts.inter(
                            color: _remainingDuration.inMinutes <= 5
                                ? Color(0xFFE24336)
                                : colorScheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.55,
                            height: 1.02,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'remaining',
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            letterSpacing: -0.55,
                            height: 1.02,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final currentMinutes = _remainingDuration.inMinutes;
                      final newMinutes = (currentMinutes + 5).clamp(5, 99);
                      await _updatePrepTime(newMinutes);
                    },
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.border, width: 1),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: colorScheme.iconPrimary,
                        size: 20,
                        strokeWidth: 2.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            SwipeToConfirmButton(
              orderId: widget.order.orderId,
              apiPrepTime: _localPrepMinutes,
              onConfirmed: () {
                widget.onStatusUpdateSuccess?.call();
                widget.onStatusChanged?.call();
              },
            ),
            SizedBox(height: 14),
          ],
          if (widget.order.status == OrderStatus.otp ||
              widget.order.status == OrderStatus.picked ||
              widget.order.status == OrderStatus.outForDelivery ||
              widget.order.status == OrderStatus.delivered ||
              widget.order.status == OrderStatus.cancelled)
            _actionRow(context, colorScheme),
          SizedBox(height: 12),
          Visibility(
            visible: widget.order.status == OrderStatus.preparing,
            child: Text(
              'Note : \nTime starts at 15 minutes. You can increase it by 5 minutes each time.',
              style: GoogleFonts.inter(
                color: colorScheme.textTertiary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 1.02,
                letterSpacing: -0.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// OrderItemRow with variant name below product name
class OrderItemRow extends StatelessWidget {
  final String qty, name, unit, price;
  const OrderItemRow({
    required this.qty,
    required this.name,
    required this.unit,
    required this.price,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF9AC444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              qty,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colorScheme.textPrimary,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (unit.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text(
                    unit,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
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
          Text(
            price,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
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

// Swipe to confirm button widget
class SwipeToConfirmButton extends StatefulWidget {
  final int? orderId;
  final int? apiPrepTime;
  final VoidCallback onConfirmed;

  const SwipeToConfirmButton({
    required this.orderId,
    this.apiPrepTime,
    required this.onConfirmed,
    Key? key,
  }) : super(key: key);

  @override
  State<SwipeToConfirmButton> createState() => _SwipeToConfirmButtonState();
}

class _SwipeToConfirmButtonState extends State<SwipeToConfirmButton> {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  bool _isUpdating = false;

  /// Get seller count from Firebase ETA document, defaults to 1 if not found
  Future<int> _getSellerCountFromFirebase(int orderId) async {
    try {
      final eta = await FirebaseEtaService().getOrderEta(orderId: orderId);
      if (eta != null) {
        debugPrint('📊 Seller count from Firebase: ${eta.sellerCount}');
        return eta.sellerCount;
      }
    } catch (e) {
      debugPrint('⚠️ Error getting seller count from Firebase: $e');
    }
    // Default to 1 if not found or error occurs
    debugPrint('📊 Seller count defaulting to: 1');
    return 1;
  }

  Future<void> _handleConfirm() async {
    if (widget.orderId == null || _isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // Get seller count from Firebase and reduce ETA when marking as prepared
      final sellerCount = await _getSellerCountFromFirebase(widget.orderId!);
      final etaProvider = context.read<EtaProvider>();
      await etaProvider.reduceEtaOnPrepared(
        orderId: widget.orderId!,
        apiPrepTime: widget.apiPrepTime ?? 0,
        sellerCount: sellerCount,
      );

      // Update tracking status in backend
      final response = await updateTrackingStatus(
        orderId: widget.orderId!,
        status: 'packed_by_seller',
        context: context,
      );

      if (response['status'] == 1) {
        setState(() {
          _isConfirmed = true;
        });

        await Future.delayed(Duration(milliseconds: 500));
        widget.onConfirmed();
      } else {
        setState(() {
          _dragPosition = 0.0;
        });
      }
    } catch (e) {
      debugPrint('Error updating tracking status: $e');
      setState(() {
        _dragPosition = 0.0;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final maxDrag = MediaQuery.of(context).size.width - 120;
    final threshold = maxDrag * 0.85;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Color(0xFF9AC444),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(
            child: _isUpdating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isConfirmed ? 'Order Ready!' : 'Swipe to mark ready',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.02,
                      letterSpacing: -0.55,
                    ),
                  ),
          ),
          if (!_isUpdating)
            Positioned(
              left: _dragPosition,
              top: 4,
              bottom: 4,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (!_isConfirmed) {
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx)
                          .clamp(0.0, maxDrag);
                    });
                  }
                },
                onHorizontalDragEnd: (details) {
                  if (!_isConfirmed) {
                    if (_dragPosition >= threshold) {
                      setState(() {
                        _dragPosition = maxDrag;
                      });
                      _handleConfirm();
                    } else {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isConfirmed
                          ? HugeIcon(
                              icon: HugeIcons.strokeRoundedTick02,
                              color: Color(0xFF9AC444),
                              size: 24,
                              strokeWidth: 2.5,
                            )
                          : HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              color: Color(0xFF9AC444),
                              size: 24,
                              strokeWidth: 2.5,
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
}

// Swipe to Confirm OTP Button
class SwipeToConfirmOtpButton extends StatefulWidget {
  final int? orderId;
  final String otp;
  final VoidCallback onConfirmed;

  const SwipeToConfirmOtpButton({
    required this.orderId,
    required this.otp,
    required this.onConfirmed,
    Key? key,
  }) : super(key: key);

  @override
  State<SwipeToConfirmOtpButton> createState() =>
      _SwipeToConfirmOtpButtonState();
}

class _SwipeToConfirmOtpButtonState extends State<SwipeToConfirmOtpButton> {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  bool _isUpdating = false;

  Future<void> _handleConfirm() async {
    if (widget.orderId == null || _isUpdating) return;

    if (widget.otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a 4-digit PIN'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _dragPosition = 0.0;
      });
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await verifyOtpAndUpdateStatus(
        orderId: widget.orderId!,
        otp: widget.otp,
        context: context,
      );

      final success = response['success']?.toString() ?? '0';
      if (success == '1') {
        setState(() {
          _isConfirmed = true;
        });

        await Future.delayed(Duration(milliseconds: 500));
        widget.onConfirmed();
      } else {
        setState(() {
          _dragPosition = 0.0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Invalid PIN'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      setState(() {
        _dragPosition = 0.0;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final maxDrag = MediaQuery.of(context).size.width - 120;
    final threshold = maxDrag * 0.85;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Color(0xFFFF7900),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(
            child: _isUpdating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isConfirmed ? 'Confirmed!' : 'Swipe to confirm handover',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.02,
                      letterSpacing: -0.55,
                    ),
                  ),
          ),
          if (!_isUpdating)
            Positioned(
              left: _dragPosition,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (!_isConfirmed) {
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx)
                          .clamp(0.0, maxDrag);
                    });
                  }
                },
                onHorizontalDragEnd: (details) {
                  if (!_isConfirmed) {
                    if (_dragPosition >= threshold) {
                      setState(() {
                        _dragPosition = maxDrag;
                      });
                      _handleConfirm();
                    } else {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4.0, vertical: 4.0),
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isConfirmed
                          ? HugeIcon(
                              icon: HugeIcons.strokeRoundedTick02,
                              color: Color(0xFFFF7900),
                              size: 24,
                              strokeWidth: 2.5,
                            )
                          : HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              color: Color(0xFFFF7900),
                              size: 24,
                              strokeWidth: 2.5,
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
}
