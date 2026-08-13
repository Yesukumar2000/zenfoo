import 'package:flutter/material.dart';
import 'package:project/utils/order_number.dart';
import 'package:flutter/services.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/screens/ordersScreen/order_list_view.dart';
import 'package:project/screens/ordersScreen/widgets/driver_avatar.dart';
import 'package:project/screens/ordersScreen/chat_with_admin_for_order.dart';
import 'package:project/repositories/newOrdersApi.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/services/firebase_eta_service.dart';
import 'package:project/provider/eta_provider.dart';

// ==== ORDER DETAILS SCREEN (FULL SCREEN) ====
class OrderDetailsScreen extends StatefulWidget {
  final Order order;
  final ValueChanged<int> onTimeChanged;
  final VoidCallback? onAdvance;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final ValueChanged<String>? onSubmitOtp;

  const OrderDetailsScreen({
    Key? key,
    required this.order,
    required this.onTimeChanged,
    this.onAdvance,
    this.onCall,
    this.onChat,
    this.onSubmitOtp,
  }) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  String _otp = '';

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // HEADER
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return AppHeader(
                label: getTranslatedValue(context, orderDetailsLabel),
                title: "Order ${formatOrderNumber(widget.order.orderId)}",
                showBackButton: true,
                trailing: SizedBox(
                  width: 170,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 1. Call Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: widget.onCall,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF059669).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Color(0xFF059669),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.call_rounded,
                              size: 16,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      // 2. Chat with Driver Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: widget.onChat,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF059669),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              Icons.message_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      // 3. Chat with Admin (Firebase)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            final sellerIdStr = Constant.session
                                .getData(SessionManager.keyUserId);
                            final sellerId = int.tryParse(sellerIdStr) ?? 0;
                            if (sellerId != 0) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatWithAdminScreen(
                                    orderId: widget.order.orderId ?? 0,
                                    sellerId: sellerId,
                                  ),
                                ),
                              );
                            } else {
                              _showError('Seller ID not found');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF3183F4),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              Icons.support_agent_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // SCROLLABLE CONTENT WITH CARD
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: OrderCardUnified(
                order: widget.order,
                onTimeChanged: widget.onTimeChanged,
                onAdvance: widget.onAdvance ?? () {},
                onCall: widget.onCall,
                onChat: () {
                  // Get seller_id from session
                  final sellerIdStr =
                      Constant.session.getData(SessionManager.keyUserId);
                  final sellerId = int.tryParse(sellerIdStr) ?? 0;

                  if (sellerId != 0) {
                    Navigator.pushNamed(
                      context,
                      'chat_with_admin',
                      arguments: {
                        'orderId': widget.order.orderId,
                        'sellerId': sellerId,
                      },
                    );
                  } else {
                    _showError('Seller ID not found');
                  }
                },
                onSubmitOtp: widget.onSubmitOtp,
              ),
            ),
          ),

          // URGENCY ALERT (above bottom navigation if preparing)
          if (widget.order.prepTime != null &&
              widget.order.status == OrderStatus.preparing)
            _buildUrgencyAlert(context, widget.order),

          // BOTTOM NAVIGATION - TIMER/SWIPE & EARNINGS
          _buildBottomNavigation(context, widget.order),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildUrgencyAlert(BuildContext context, Order order) {
    final remainingDuration = order.getRemainingDuration();
    final bool isUrgent =
        remainingDuration.inMinutes <= 5 && remainingDuration.inMinutes > 0;
    final bool isExpired = remainingDuration.inSeconds <= 0;

    if (!isUrgent && !isExpired) {
      return SizedBox.shrink();
    }

    return _UrgencyAlertAnimated(
      order: order,
    );
  }

  Widget _buildBottomNavigation(BuildContext context, Order order) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final hasDeliveryPartner = order.deliveryPerson.isNotEmpty;

    // Show timer and swipe for preparing status
    if (order.prepTime != null && order.status == OrderStatus.preparing) {
      final timerWidget = _TimerAndSwipeWidget(order: order);

      return Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colorScheme.border, width: 1),
          ),
          color: colorScheme.background,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Earnings Row
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            // getTranslatedValue(context, yourEarningsLabel),
                            "Total Price",
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.02,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₹${order.payable.toStringAsFixed(2)}',
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
                      );
                    },
                  ),
                  SizedBox(height: 12),
                  // Timer and Swipe Button (urgency alerts now above earnings)
                  timerWidget,
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Show OTP and delivery for OTP/Pickup/OutForDelivery/Delivered status
    if (order.status == OrderStatus.otp ||
        order.status == OrderStatus.picked ||
        order.status == OrderStatus.outForDelivery ||
        order.status == OrderStatus.delivered) {
      return Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Earnings Row
              Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getTranslatedValue(context, yourEarningsLabel),
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.02,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${order.payable.toStringAsFixed(2)}',
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
                  );
                },
              ),
              SizedBox(height: 12),
              // Status-based UI
              if (order.status == OrderStatus.otp && hasDeliveryPartner) ...[
                _buildDeliverySection(context, colorScheme),
                SizedBox(height: 12),
                _buildOtpSection(context, colorScheme),
              ] else if (order.status == OrderStatus.picked) ...[
                _buildPickedStatusUI(context, colorScheme, order),
              ] else if (order.status == OrderStatus.outForDelivery) ...[
                _buildOutForDeliveryStatusUI(context, colorScheme, order),
              ] else if (order.status == OrderStatus.delivered) ...[
                _buildDeliveredStatusUI(context, colorScheme, order),
              ] else if (!hasDeliveryPartner) ...[
                // Waiting for delivery partner (OTP status without partner)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.border, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary),
                        ),
                      ),
                      SizedBox(width: 10),
                      Consumer<LanguageProvider>(
                        builder: (context, languageProvider, child) {
                          return Text(
                            getTranslatedValue(
                                context, waitingForDeliveryPartnerLabel),
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.02,
                              letterSpacing: -0.3,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Hide bottom navigation for cancelled orders
    if (order.status == OrderStatus.cancelled) {
      return SizedBox.shrink();
    }

    // Default: Just show earnings
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslatedValue(context, yourEarningsLabel),
                style: GoogleFonts.inter(
                  color: Colors.black,
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
                  '₹${order.payable.toStringAsFixed(2)}',
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
          );
        },
      ),
    );
  }

  Widget _buildOtpSection(
      BuildContext context, app_theme.AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, enterPINLabel),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: colorScheme.textPrimary,
            height: 1.02,
            letterSpacing: -0.55,
          ),
        ),
        SizedBox(height: 5),
        Text(
          getTranslatedValue(context, collectPINLabel),
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colorScheme.textSecondary,
            fontWeight: FontWeight.w400,
            height: 1.02,
            letterSpacing: -0.55,
          ),
        ),
        SizedBox(height: 12),
        Align(
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
                _otp = code;
              });
            },
            onSubmit: (String completedCode) {
              setState(() {
                _otp = completedCode;
              });
            },
          ),
        ),
        SizedBox(height: 12),
        SwipeToConfirmOtpButton(
          orderId: widget.order.orderId,
          otp: _otp,
          apiPrepTime: widget.order.prepTimeMinutes,
          onConfirmed: () {
            widget.onAdvance?.call();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildDeliverySection(
      BuildContext context, app_theme.AppColorScheme colorScheme) {
    final deliveryPerson = widget.order.deliveryPerson.isNotEmpty
        ? widget.order.deliveryPerson
        : getTranslatedValue(context, deliveryPartnerLabel);

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
              size: 48,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deliveryPerson,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: colorScheme.textPrimary,
                      height: 1.02,
                      letterSpacing: -0.55,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    getTranslatedValue(context, deliveryPartnerLabel),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: colorScheme.textSecondary,
                      height: 1.02,
                      letterSpacing: -0.55,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.order.deliveryPerson.isNotEmpty) ...[
              CircleAvatar(
                backgroundColor: colorScheme.surfaceVariant,
                radius: 18,
                child: IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCall02,
                    size: 18,
                    color: colorScheme.iconPrimary,
                    strokeWidth: 2.0,
                  ),
                  onPressed: widget.onCall ?? () {},
                  padding: EdgeInsets.zero,
                ),
              ),
              SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: colorScheme.surfaceVariant,
                radius: 18,
                child: IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedMessage01,
                    size: 18,
                    color: colorScheme.iconPrimary,
                    strokeWidth: 2.0,
                  ),
                  onPressed: widget.onChat ?? () {},
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ==== PICKED STATUS UI ====
Widget _buildPickedStatusUI(
    BuildContext context, app_theme.AppColorScheme colorScheme, Order order) {
  final deliveryPerson = order.deliveryPerson.isNotEmpty
      ? order.deliveryPerson
      : getTranslatedValue(context, deliveryPartnerLabel);

  return Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DriverAvatar(
            imageUrl: order.deliveryPersonImage,
            name: deliveryPerson,
            colorScheme: colorScheme,
            size: 48,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deliveryPerson,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: colorScheme.textPrimary,
                    height: 1.02,
                    letterSpacing: -0.55,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  getTranslatedValue(context, deliveryPartnerLabel),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: colorScheme.textSecondary,
                    height: 1.02,
                    letterSpacing: -0.55,
                  ),
                ),
              ],
            ),
          ),
          if (order.deliveryPerson.isNotEmpty) ...[
            CircleAvatar(
              backgroundColor: colorScheme.surfaceVariant,
              radius: 18,
              child: IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCall02,
                  size: 18,
                  color: colorScheme.iconPrimary,
                  strokeWidth: 2.0,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
              ),
            ),
            SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: colorScheme.surfaceVariant,
              radius: 18,
              child: IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedMessage01,
                  size: 18,
                  color: colorScheme.iconPrimary,
                  strokeWidth: 2.0,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
      SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xFFD4EDDA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Color(0xFF28A745), width: 1),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
              size: 18,
              color: Color(0xFF28A745),
              strokeWidth: 2.0,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                getTranslatedValue(context, orderPickedLabel),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Color(0xFF155724),
                  height: 1.02,
                  letterSpacing: -0.55,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ==== OUT FOR DELIVERY STATUS UI ====
Widget _buildOutForDeliveryStatusUI(
    BuildContext context, app_theme.AppColorScheme colorScheme, Order order) {
  final deliveryPerson = order.deliveryPerson.isNotEmpty
      ? order.deliveryPerson
      : getTranslatedValue(context, deliveryPartnerLabel);

  return Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DriverAvatar(
            imageUrl: order.deliveryPersonImage,
            name: deliveryPerson,
            colorScheme: colorScheme,
            size: 48,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deliveryPerson,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: colorScheme.textPrimary,
                    height: 1.02,
                    letterSpacing: -0.55,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  getTranslatedValue(context, deliveryPartnerLabel),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: colorScheme.textSecondary,
                    height: 1.02,
                    letterSpacing: -0.55,
                  ),
                ),
              ],
            ),
          ),
          if (order.deliveryPerson.isNotEmpty) ...[
            CircleAvatar(
              backgroundColor: colorScheme.surfaceVariant,
              radius: 18,
              child: IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCall02,
                  size: 18,
                  color: colorScheme.iconPrimary,
                  strokeWidth: 2.0,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
              ),
            ),
            SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: colorScheme.surfaceVariant,
              radius: 18,
              child: IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedMessage01,
                  size: 18,
                  color: colorScheme.iconPrimary,
                  strokeWidth: 2.0,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
      SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xFFD1ECF1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Color(0xFF0C5460), width: 1),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedDeliveryTruck01,
              size: 18,
              color: Color(0xFF0C5460),
              strokeWidth: 2.0,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                getTranslatedValue(context, outForDeliveryLabel),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Color(0xFF0C5460),
                  height: 1.02,
                  letterSpacing: -0.55,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ==== DELIVERED STATUS UI ====
Widget _buildDeliveredStatusUI(
    BuildContext context, app_theme.AppColorScheme colorScheme, Order order) {
  final deliveryPerson = order.deliveryPerson.isNotEmpty
      ? order.deliveryPerson
      : getTranslatedValue(context, deliveryPartnerLabel);

  return Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DriverAvatar(
            imageUrl: order.deliveryPersonImage,
            name: deliveryPerson,
            colorScheme: colorScheme,
            size: 48,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${getTranslatedValue(context, deliveredByLabel)} $deliveryPerson',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: colorScheme.textPrimary,
                    height: 1.02,
                    letterSpacing: -0.55,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  getTranslatedValue(context, orderHasBeenDeliveredLabel),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
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
      SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xFFD4EDDA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Color(0xFF28A745), width: 1),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
              size: 18,
              color: Color(0xFF28A745),
              strokeWidth: 2.0,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                getTranslatedValue(context, orderDeliveredLabel),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Color(0xFF155724),
                  height: 1.02,
                  letterSpacing: -0.55,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ==== TIMER AND SWIPE WIDGET ====
class _TimerAndSwipeWidget extends StatefulWidget {
  final Order order;

  const _TimerAndSwipeWidget({required this.order});

  @override
  State<_TimerAndSwipeWidget> createState() => _TimerAndSwipeWidgetState();
}

class _TimerAndSwipeWidgetState extends State<_TimerAndSwipeWidget> {
  Timer? _countdownTimer;
  Duration _remainingDuration = Duration.zero;
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

    return widget.order.getRemainingDuration();
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

  Future<void> _updatePrepTime(int newMinutes) async {
    if (widget.order.orderId == null) return;

    try {
      final now = DateTime.now();
      final hour =
          now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final timeString =
          '$hour:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

      debugPrint('📋 Updating prep time to $newMinutes minutes at $timeString');

      setState(() {
        _localPrepStartTime = now;
        _localPrepMinutes = newMinutes;
      });

      _startCountdown();

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
        // Must NOT use setEta() — when doc exists, setEta adds to remaining time,
        // causing ETA to increase when seller reduces prep time.
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
      } else {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer Container
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
        // Swipe Button
        SwipeToConfirmButton(
          orderId: widget.order.orderId,
          apiPrepTime: _localPrepMinutes,
          onConfirmed: () {
            // Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

// ==== UNIFIED ORDER CARD (FROM PICKUP SCREEN) ====
class OrderCardUnified extends StatefulWidget {
  final Order order;
  final ValueChanged<int> onTimeChanged;
  final VoidCallback onAdvance;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final ValueChanged<String>? onSubmitOtp;

  const OrderCardUnified({
    required this.order,
    required this.onTimeChanged,
    required this.onAdvance,
    this.onCall,
    this.onChat,
    this.onSubmitOtp,
    Key? key,
  }) : super(key: key);

  @override
  State<OrderCardUnified> createState() => _OrderCardUnifiedState();
}

class _OrderCardUnifiedState extends State<OrderCardUnified> {
  bool _isSettingPrepTime = false;
  Timer? _countdownTimer;
  Duration _remainingDuration = Duration.zero;

  DateTime? _localPrepStartTime;
  int? _localPrepMinutes;

  String _enteredOtp = '';

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

    return widget.order.getRemainingDuration();
  }

  @override
  void didUpdateWidget(OrderCardUnified oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.prepTime != widget.order.prepTime ||
        oldWidget.order.prepTimeString != widget.order.prepTimeString ||
        oldWidget.order.prepTimeMinutes != widget.order.prepTimeMinutes) {
      _localPrepStartTime = null;
      _localPrepMinutes = null;
      _startCountdown();
    }
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

  // API CALLS
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

      debugPrint(
          '📋 Preparation time set: start $timeString, ${widget.order.minutes} mins duration');

      setState(() {
        _localPrepStartTime = now;
        _localPrepMinutes = widget.order.minutes;
      });

      _startCountdown();

      final response = await updatePrepTime(
        orderId: widget.order.orderId!,
        prepTime: [widget.order.minutes, timeString],
        context: context,
        isPreparation: 1,
      );

      if (response['status'] == 1) {
        debugPrint('✅ Preparation time set successfully via API');

        // Update Firebase with proper calculation accounting for existing ETA
        debugPrint(
            '🔄 Preparing Firebase ETA update with ${widget.order.minutes} min addition');
        _getSellerCountFromFirebase(widget.order.orderId!).then((sellerCount) {
          // Use updateEta() to add minutes considering existing ETA and elapsed time
          // This calculates: remaining + (minutes / seller_count)
          FirebaseEtaService()
              .updateEta(
            orderId: widget.order.orderId!,
            adjustmentMinutes: widget.order.minutes,
            sellerCount: sellerCount,
          )
              .then((success) {
            if (success) {
              debugPrint(
                  '✅ Firebase ETA updated with ${widget.order.minutes} min addition');
            } else {
              debugPrint(
                  '❌ Firebase ETA update failed - attempting setEta fallback');
              // Fallback to setEta if updateEta fails (document doesn't exist)
              FirebaseEtaService().setEta(
                orderId: widget.order.orderId!,
                etaMinutes: widget.order.minutes,
                sellerCount: sellerCount,
              );
            }
          }).catchError((e) {
            debugPrint('❌ Firebase ETA error: $e');
          });
        });

        Navigator.pop(context);
      } else {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 23),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ORDER ID & DETAILS
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
          SizedBox(height: 5),
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return Text(
                getTranslatedValue(context, orderDetailsLabel),
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.02,
                  letterSpacing: -0.55,
                ),
              );
            },
          ),
          SizedBox(height: 9),

          // ITEMS LIST
          ...getItemRows(),
          SizedBox(height: 8),
          Container(height: 1, color: colorScheme.border),
          SizedBox(height: 12),

          // SETTLEMENT INFO
          if (widget.order.settlementInfo != null &&
              widget.order.settlementInfo!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.border,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settlement Details',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...widget.order.settlementInfo!.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.label,
                            style: GoogleFonts.inter(
                              fontSize: 12,
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
                              fontSize: 12,
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
              ),
            ),
            SizedBox(height: 14),
          ],

          // SELLER NOTES FROM BACKEND
          if (widget.order.notes.isNotEmpty &&
              widget.order.status != OrderStatus.cancelled)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.border,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${getTranslatedValue(context, instructionLabel)}:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textSecondary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    widget.order.notes,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.3,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          if (widget.order.notes.isNotEmpty &&
              widget.order.status != OrderStatus.cancelled)
            SizedBox(height: 14),

          // PREP TIME SECTION
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
                            '${getTranslatedValue(context, setPrepTimeLabel)} (${widget.order.minutes} mins)',
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

          // // OTP SECTION (when status is OTP)
          // if (widget.order.status == OrderStatus.otp) ...[
          //   _buildOtpSection(context, colorScheme),
          //   SizedBox(height: 14),
          // ],

          // DELIVERY PARTNER SECTION
          // if (widget.order.status == OrderStatus.otp ||
          //     widget.order.status == OrderStatus.picked ||
          //     widget.order.status == OrderStatus.outForDelivery ||
          //     widget.order.status == OrderStatus.delivered)
          //   _buildDeliverySection(context, colorScheme),

          // NOTES
          if (widget.order.status == OrderStatus.preparing)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${getTranslatedValue(context, noteLabel)}: ${getTranslatedValue(context, timeStartsAtLabel)} ${widget.order.minutes} ${getTranslatedValue(context, minutesLabel)}. ${getTranslatedValue(context, youCanAdjustLabel)}',
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

// ==== ORDER ITEM ROW ====
class OrderItemRow extends StatelessWidget {
  final String qty, name, unit, price;

  const OrderItemRow({
    required this.qty,
    required this.name,
    required this.unit,
    required this.price,
    Key? key,
  }) : super(key: key);

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

// ==== SWIPE TO CONFIRM BUTTON ====
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
        Navigator.pop(context);
      } else {
        setState(() {
          _dragPosition = 0.0;
        });
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
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
                    _isConfirmed
                        ? getTranslatedValue(context, orderReadyLabel)
                        : getTranslatedValue(context, swipeToMarkReadyLabel),
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

// ==== SWIPE TO CONFIRM OTP BUTTON ====
class SwipeToConfirmOtpButton extends StatefulWidget {
  final int? orderId;
  final String otp;
  final int? apiPrepTime;
  final VoidCallback onConfirmed;

  const SwipeToConfirmOtpButton({
    required this.orderId,
    required this.otp,
    this.apiPrepTime,
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
      // Get seller count from Firebase and reduce ETA when marking as prepared
      final sellerCount = await _getSellerCountFromFirebase(widget.orderId!);
      final etaProvider = context.read<EtaProvider>();
      await etaProvider.reduceEtaOnPrepared(
        orderId: widget.orderId!,
        apiPrepTime: widget.apiPrepTime ?? 0,
        sellerCount: sellerCount,
      );

      final response = await verifyOtpAndUpdateStatus(
        orderId: widget.orderId!,
        otp: widget.otp,
        context: context,
      );

      final success = response['success'];
      debugPrint('✅ Response: $response');
      debugPrint('✅ Success: $success');
      if (success == '1' || success == 1) {
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
      debugPrint('❌ Error: $e');
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
                    _isConfirmed
                        ? getTranslatedValue(context, confirmedLabel)
                        : getTranslatedValue(context, swipeToConfirmLabel),
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

// ==== ANIMATED URGENCY ALERT WITH RIPPLE PULSE ====
class _UrgencyAlertAnimated extends StatefulWidget {
  final Order order;

  const _UrgencyAlertAnimated({required this.order});

  @override
  State<_UrgencyAlertAnimated> createState() => _UrgencyAlertAnimatedState();
}

class _UrgencyAlertAnimatedState extends State<_UrgencyAlertAnimated>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  Timer? _heartbeatTimer;
  Timer? _updateTimer;

  bool get _isExpired => widget.order.getRemainingDuration().inSeconds <= 0;

  @override
  void initState() {
    super.initState();

    // Ripple animation controller - continuous pulse
    _rippleController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _rippleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Start continuous heartbeat vibration if expired
    if (_isExpired) {
      _startHeartbeatVibration();
    }

    // Update alert state every second to reflect time changes
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _startHeartbeatVibration() {
    // Heartbeat pattern: quick-quick-pause-pause (like a heartbeat)
    _heartbeatTimer = Timer.periodic(Duration(milliseconds: 1200), (timer) {
      if (mounted) {
        // First beat
        HapticFeedback.vibrate();
        Future.delayed(Duration(milliseconds: 150), () {
          if (mounted) HapticFeedback.vibrate(); // Second beat
        });
        // Pause 600ms, then repeat
      }
    });
  }

  @override
  void didUpdateWidget(_UrgencyAlertAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart heartbeat vibration if expired status changed
    if (_isExpired && !oldWidget.order.getRemainingDuration().isNegative) {
      _startHeartbeatVibration();
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _heartbeatTimer?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertColor = _isExpired ? Color(0xFFE24336) : Color(0xFFFF9800);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripple pulses (outside)
            if (_isExpired) ..._buildRipplePulses(alertColor),

            // Main alert container
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: alertColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: alertColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: _isExpired
                        ? HugeIcons.strokeRoundedAlert02
                        : HugeIcons.strokeRoundedAlert01,
                    color: Colors.white,
                    size: 16,
                    strokeWidth: 2.5,
                  ),
                  SizedBox(width: 6),
                  Text(
                    _isExpired
                        ? getTranslatedValue(context, timeUpLabel)
                        : getTranslatedValue(context, urgentLabel),
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
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRipplePulses(Color alertColor) {
    return List.generate(2, (index) {
      return AnimatedBuilder(
        animation: _rippleAnimation,
        builder: (context, child) {
          final delay = index * 0.25;
          final animValue = (_rippleAnimation.value - delay).clamp(0, 1);

          return Container(
            width: 50 + (animValue * 20),
            height: 50 + (animValue * 20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: alertColor.withValues(
                  alpha: (1 - animValue) * 0.3,
                ),
                width: 1,
              ),
            ),
          );
        },
      );
    });
  }
}
