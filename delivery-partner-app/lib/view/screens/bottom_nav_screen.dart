import 'package:flutter/material.dart';
import 'package:zenfoo_partner/utils/order_number.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/incoming_order_model.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/incoming_order_provider.dart';
import 'package:zenfoo_partner/services/fcm_token_service.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/view/screens/delivery/delivery_progress_screen.dart';
import 'package:zenfoo_partner/view/screens/earnings/earnings_screen.dart';
import 'package:zenfoo_partner/view/screens/home/home_screen.dart';
import 'package:zenfoo_partner/view/screens/home/screens/gig_availability_screen.dart';
import 'package:zenfoo_partner/view/screens/home/screens/gigs_bookings_screen.dart';
import 'package:zenfoo_partner/view/screens/learning/learning_screen.dart';

import '../../theme/theme_provider.dart';
import '../../theme/app_color_scheme.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});
 
  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int currentIndex = 0;

  final List<Widget> screens = [
    const HomeScreen(),
    const EarningsScreen(),
    const GigsBookingsScreen(),
    const LearningScreen(fromBottomNav: true),
  ];

  final List<String> labels = ["Home", "Earnings", "Gigs", "Learning"];

  @override
  void initState() {
    super.initState();
    // Load current accepted order when bottom nav screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentAcceptedOrder();
      _updateFcmToken();
    });
  }

  /// Update FCM token to backend every time user navigates to bottom nav screen
  Future<void> _updateFcmToken() async {
    debugPrint('📱 Updating FCM token on bottom nav screen load...');
    final fcmTokenService = FcmTokenService();
    await fcmTokenService.updateFcmToken();
  }

  /// Load current accepted order from Firebase
  Future<void> _loadCurrentAcceptedOrder() async {
    final incomingOrderProvider = context.read<IncomingOrderProvider>();
    final authProvider = context.read<AuthProvider>();

    final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

    if (deliveryBoyId == null) {
      debugPrint('❌ Cannot load order: Delivery boy ID is null');
      return;
    }

    // Always check for existing accepted order (order was already accepted, regardless of online status)
    debugPrint(
        '📦 Loading current accepted order for delivery boy $deliveryBoyId...');
    await incomingOrderProvider.getCurrentAcceptedOrder(deliveryBoyId);
  }

  void _changeTab(int newIndex) {
    if (newIndex == currentIndex) return;
    setState(() {
      currentIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final incomingOrderProvider = context.watch<IncomingOrderProvider>();
    final currentOrder = incomingOrderProvider.currentAcceptedOrder;

    final icons = [
      HugeIcons.strokeRoundedHome01,
      HugeIcons.strokeRoundedWallet04,
      HugeIcons.strokeRoundedCircleArrowDown01,
      HugeIcons.strokeRoundedAiVideo,
    ];

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: screens[currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active order widget (above bottom nav)
          if (currentOrder != null)
            _buildActiveOrderWidget(colorScheme, currentOrder),

          // Bottom navigation bar
          Container(
            padding: const EdgeInsets.only(top: 10, bottom: 14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  blurRadius: 6,
                  color: colorScheme.border.withValues(alpha: 0.3),
                  offset: const Offset(0, -3),
                )
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _bottomItem(
                    icon: icons[0],
                    label: labels[0],
                    index: 0,
                    colorScheme: colorScheme,
                  ),
                  _bottomItem(
                    icon: icons[1],
                    label: labels[1],
                    index: 1,
                    colorScheme: colorScheme,
                  ),
                  _bottomItem(
                    icon: icons[2],
                    label: labels[2],
                    index: 2,
                    colorScheme: colorScheme,
                  ),
                  _bottomItem(
                    icon: icons[3],
                    label: labels[3],
                    index: 3,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build active order widget shown above bottom nav
  Widget _buildActiveOrderWidget(
      AppColorScheme colorScheme, IncomingOrder order) {
    final stopCount = order.sellersVisitOrder.length;
    final hasMultipleStops = stopCount > 1;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryProgressScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryProgressScreen(order: order),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    /// Left section: Icon and badge
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.15),
                            colorScheme.primary.withValues(alpha: 0.08),
                          ]
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                            angle: 1.5708,
                            child: Image.asset(
                              AppImages.bikeMap,
                              width: 26,
                              height: 26,
                              color: colorScheme.primary,
                            ),
                          ),
                          if (hasMultipleStops)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${stopCount}x',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    /// Middle section: Order details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  order.pickupLocation?.storeName ??
                                      'Order ${formatOrderNumber(order.orderId)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),

                              /// Earnings badge - compact
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '₹${order.totalEarnings.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              /// Stop indicator
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.success.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Delivery in Progress',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.success,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              /// Distance or delivery count
                              Text(
                                hasMultipleStops
                                    ? '$stopCount stops total'
                                    : '1 delivery',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    /// Right section: Arrow
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colorScheme.textSecondary,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoOnlineButton(colorScheme) {
    return Container(
      height: 64,
      width: 64,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GigAvailabilityScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.power_settings_new_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(height: 2),
              Text(
                'Go',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomItem({
    required dynamic icon,
    required String label,
    required int index,
    required colorScheme,
  }) {
    final bool active = index == currentIndex;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _changeTab(index);
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 80, minHeight: 70),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: icon,
              size: 26,
              color: active ? colorScheme.primary : colorScheme.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? colorScheme.primary : colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
