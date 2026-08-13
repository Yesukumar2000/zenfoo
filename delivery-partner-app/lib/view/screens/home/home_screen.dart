import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/daily_tracking_model.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/booking_provider.dart';
import 'package:zenfoo_partner/providers/incentive_provider.dart';
import 'package:zenfoo_partner/providers/incoming_order_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/session_provider.dart';
import 'package:zenfoo_partner/providers/weather_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/customCard.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_image_icon.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/status_toggle_widget.dart';
import 'package:zenfoo_partner/view/screens/face_verification/face_verification_screen.dart';
import 'package:zenfoo_partner/view/screens/emergency/emergency_support_screen.dart';
import 'package:zenfoo_partner/view/screens/help_center/help_center_screen.dart';
import 'package:zenfoo_partner/view/screens/home/screens/offer_detail_screen.dart';
import 'package:zenfoo_partner/view/screens/home/widgets/home_banner_carousel.dart';
import 'package:zenfoo_partner/view/screens/home/widgets/order_banner_listener.dart';
import 'package:zenfoo_partner/view/screens/home/widgets/payment_blocking_widget.dart';
import 'package:zenfoo_partner/view/screens/home/widgets/weather_animation_widget.dart';
import 'package:zenfoo_partner/view/screens/home/widgets/deposit_modal.dart';
import 'package:zenfoo_partner/view/screens/profile/all_offers_screen.dart';
import 'package:zenfoo_partner/providers/banner_provider.dart';
import 'package:zenfoo_partner/providers/deposit_cash_provider.dart';
import 'package:zenfoo_partner/providers/payment_status_provider.dart';
import 'package:zenfoo_partner/view/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isTogglingStatus = false;
  Timer? _timeFormatTimer;
  Timer? _weatherTimer;
  bool _showClockFormat = true; // true = HH:MM:SS, false = Xd Yh Zm
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  String? _currentCityName;

  // Battery monitoring
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  Timer? _batteryCheckTimer;
  bool _isShowingBatteryDialog = false;

  @override
  void initState() {
    super.initState();

    // Add observer for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Initialize shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _getCurrentCityName();
      _setupIncomingOrderListener();
      _startBatteryMonitoring();
    });

    // Re-check rain periodically so the icon disappears once rain stops.
    // 10 min lines up with the backend's 5 min weather cache.
    _weatherTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _refreshWeather(),
    );

    // Timer to swap format every 5 seconds (ONLY this timer is needed now)
    _timeFormatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _showClockFormat = !_showClockFormat;
        });
      }
    });

    // NOTE: Removed _realtimeTimer that was rebuilding entire screen every second
    // Instead, time display is now handled by _TimeDisplay widget using its own timer
    // This reduces unnecessary rebuilds of the entire home screen
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shimmerController.dispose();
    _timeFormatTimer?.cancel();
    _weatherTimer?.cancel();
    _batteryStateSubscription?.cancel();
    _batteryCheckTimer?.cancel();
    super.dispose();
  }

  /// Handle app lifecycle changes - restart listener when app comes to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed - restarting Firebase order listener');
      _setupIncomingOrderListener();
      // Weather may have changed while backgrounded
      _refreshWeather();
    }
  }

  Future<void> _loadData() async {
    final sessionProvider = context.read<SessionProvider>();
    final incentiveProvider = context.read<IncentiveProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final paymentStatusProvider = context.read<PaymentStatusProvider>();
    final authProvider = context.read<AuthProvider>();

    // ONLY load stats if the account is officially approved and we have a valid delivery boy ID
    final isApproved = authProvider.currentDeliveryBoy?.status == 1;
    final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

    if (!isApproved || deliveryBoyId == null || deliveryBoyId == 0) {
      debugPrint(
          '⏸️ Skipping HomeScreen data load - Delivery boy not approved or ID missing');
      return;
    }

    debugPrint('🚀 Loading HomeScreen data for delivery boy $deliveryBoyId...');

    final depositCashProvider = context.read<DepositCashProvider>();

    // Load today's stats, active offers, bookings, payment status, and hand cash in parallel
    await Future.wait([
      sessionProvider.getTodayStats(),
      incentiveProvider.getActiveOffers(),
      bookingProvider.fetchMyBookings(),
      paymentStatusProvider.fetchPaymentStatus(),
      depositCashProvider.fetchHandCash(),
    ]);
  }

  Future<void> _refreshData() async {
    debugPrint('🔄 Refreshing homepage data...');

    // Refresh all data
    await Future.wait([
      _loadData(),
      _getCurrentCityName(),
    ]);

    // Restart Firebase listeners on refresh to fetch latest orders
    debugPrint('🔄 Restarting Firebase listeners on refresh');
    final incomingOrderProvider = context.read<IncomingOrderProvider>();
    // Clear local state and processed orders cache to ensure fresh orders are detected
    debugPrint('🗑️ Clearing local orders and processed cache');
    incomingOrderProvider.clearOrders();
    debugPrint('✅ Restarting Firebase listeners with fresh state');
    _setupIncomingOrderListener();
  }

  /// Get current city name from GPS coordinates
  Future<void> _getCurrentCityName() async {
    try {
      final position = await _getCurrentPosition();
      if (position == null) return;

      // Reuse the same fix for the rain check so we only hit GPS once
      _fetchWeather(position);

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        // Build a detailed location like the customer app:
        // "Madhapur, Hyderabad, Telangana" (area, city, state).
        final area = placemark.subLocality;
        final city =
            placemark.locality ?? placemark.subAdministrativeArea;
        final state = placemark.administrativeArea;

        final parts = <String>[];
        for (final part in [area, city, state]) {
          if (part != null &&
              part.trim().isNotEmpty &&
              !parts.contains(part.trim())) {
            parts.add(part.trim());
          }
        }
        final cityName = parts.isNotEmpty ? parts.join(', ') : 'Home';

        if (mounted) {
          setState(() {
            _currentCityName = cityName;
          });
        }
      }
    } catch (e) {
      // Silently fail - keep showing default
      if (mounted) {
        setState(() {
          _currentCityName = null;
        });
      }
    }
  }

  /// Check rain status at the driver's location (drives the header rain icon)
  void _fetchWeather(Position position) {
    if (!mounted) return;
    context.read<WeatherProvider>().fetchWeather(
          latitude: position.latitude,
          longitude: position.longitude,
        );
  }

  /// Re-check rain in the background so the icon clears once rain stops.
  /// Silent by design - never prompts or snackbars, unlike _getCurrentPosition().
  Future<void> _refreshWeather() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      // Last-known fix is plenty for weather (backend buckets to ~1km) and
      // avoids waking the GPS radio on every tick.
      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );

      if (!mounted) return;
      _fetchWeather(position);
    } catch (e) {
      debugPrint('🌧️ Background weather refresh skipped: $e');
    }
  }

  /// Setup incoming order listener
  void _setupIncomingOrderListener() async {
    final incomingOrderProvider = context.read<IncomingOrderProvider>();
    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();

    final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

    if (deliveryBoyId == null) {
      debugPrint('❌ Cannot setup order listener: Delivery boy ID is null');
      return;
    }

    // First check if there's an existing accepted order
    if (sessionProvider.isOnline) {
      debugPrint('📦 Checking for existing accepted order...');
      await incomingOrderProvider.getCurrentAcceptedOrder(deliveryBoyId);
      // The order will be stored in provider state and shown in bottom widget
    }

    // NOTE: Dialog showing is now handled by OrderListenerWidget wrapper
    // which prevents duplicate dialogs and manages dialog state properly

    // Start Firebase listener if user is online and no current accepted order
    if (sessionProvider.isOnline &&
        incomingOrderProvider.currentAcceptedOrder == null) {
      debugPrint('✅ User is online, starting Firebase order listener');
      incomingOrderProvider.startListening(deliveryBoyId);
    }

    // Always listen for current_order updates from Firebase
    // This detects when Firebase directly adds current_order (e.g., from backend)
    debugPrint('🎧 Starting real-time listener for current_order updates');
    incomingOrderProvider.startListeningToCurrentOrder(deliveryBoyId);
  }

  /// Calculate and format total login time from total_login_minutes
  /// Combines total_login_minutes with active session real-time duration
  /// Alternates between two formats:
  /// - Clock format: "81:21:57" (HH:MM:SS)
  /// - Human format: "3d 9h 47m" (days/hours/minutes)
  String _calculateTotalLoginTime(DailyTracking stats) {
    // Start with total_login_minutes converted to seconds
    int totalSeconds = stats.totalLoginMinutes * 60;

    // If there's an active session and user is online, add current_duration_minutes from API
    if (stats.activeSession != null && stats.isOnline) {
      final sessionDuration = stats.activeSession!.currentDurationMinutes * 60;
      totalSeconds += sessionDuration;
    }

    if (_showClockFormat) {
      // Clock format: HH:MM:SS (can go beyond 24 hours, e.g., 81:21:57)
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      final seconds = totalSeconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      // Human readable format: "3d 9h 47m"
      final days = totalSeconds ~/ 86400; // 86400 seconds in a day
      final hours = (totalSeconds % 86400) ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;

      // Build the formatted string
      List<String> parts = [];
      if (days > 0) parts.add('${days}d');
      if (hours > 0) parts.add('${hours}h');
      if (minutes > 0 || parts.isEmpty) parts.add('${minutes}m');

      return parts.join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final sessionProvider = context.watch<SessionProvider>();
    final authProvider = context.watch<AuthProvider>();
    final deliveryBoy = authProvider.currentDeliveryBoy;

    return OrderBannerListener(
      child: CustomScaffold(
        backgroundColor: colorScheme.background,
        body: Column(
          children: [
            /// APP HEADER
            AppHeader(
              label: "",
              title: _currentCityName ?? "Home",
              showBackButton: false,
              showExitButton: false,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// RAIN INDICATOR (only visible while it's raining)
                  const WeatherAnimationWidget(),
                  StatusToggleWidget(
                    sessionProvider: sessionProvider,
                    isTogglingStatus: _isTogglingStatus,
                    onToggle: () => _handleStatusToggle(sessionProvider),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpCenterScreen(),
                        ),
                      );
                    },
                    child:
                        const CustomImageIcon(imagePath: AppImages.headPhone),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmergencySupportScreen(),
                        ),
                      );
                    },
                    child: const CustomImageIcon(imagePath: AppImages.bulb),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: colorScheme.surface,
                      radius: 18,
                      backgroundImage: deliveryBoy?.profileImageUrl != null
                          ? ResizeImage(
                              NetworkImage(deliveryBoy!.profileImageUrl!),
                              width: 108,
                              height: 108,
                            )
                          : const ResizeImage(
                              AssetImage(AppImages.profilePerson),
                              width: 108,
                              height: 108,
                            ) as ImageProvider,
                      child: deliveryBoy?.profileImageUrl == null
                          ? Text(
                              (deliveryBoy?.name ?? '').isNotEmpty
                                  ? deliveryBoy!.name[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            /// BODY
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      /// PAYMENT BLOCKING WIDGET (if applicable)
                      PaymentBlockingWidget(
                        onDepositTap: () {
                          // showModalBottomSheet(
                          //   context: context,
                          //   isScrollControlled: true,
                          //   builder: (context) => const DepositModal(),give give
                          // );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DepositModal(),
                            ),
                          );
                        },
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            /// GREETING HEADER
                            _greetingHeader(colorScheme, deliveryBoy?.name),

                            const SizedBox(height: 16),

                            /// TODAY'S PROGRESS CARD
                            _todaysProgressCard(context, colorScheme, textTheme,
                                sessionProvider),

                            const SizedBox(height: 24),

                            /// OFFERS SECTION
                            _offersSection(context, colorScheme, textTheme),

                            const SizedBox(height: 24),

                            /// DYNAMIC BANNER CAROUSEL
                            Consumer<BannerProvider>(
                              builder: (context, bannerProvider, _) {
                                if (bannerProvider.isLoading) {
                                  return SizedBox(
                                    height: AppDimensions.getHeight(14),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          AppDimensions.borderRadius),
                                      child: Container(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  );
                                }
                                if (bannerProvider.hasError ||
                                    !bannerProvider.hasData) {
                                  return const SizedBox.shrink();
                                }
                                return HomeBannerCarousel(
                                  banners: bannerProvider.banners,
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            /// TODAY'S BOOKINGS SECTION
                            _todaysBookingsSection(
                                context, colorScheme, textTheme),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatEarnings(double value) {
    return value.round().toString();
  }

  /// Time-of-day aware greeting
  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Time-of-day aware icon for the greeting badge
  IconData _greetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_twilight_rounded;
    if (hour < 17) return Icons.wb_sunny_rounded;
    return Icons.nightlight_round;
  }

  /// Time-of-day aware accent color for the greeting badge
  Color _greetingAccent(AppColorScheme colorScheme) {
    final hour = DateTime.now().hour;
    if (hour < 12) return colorScheme.warning;
    if (hour < 17) return const Color(0xFFFFB300);
    return colorScheme.info;
  }

  /// Friendly formatted date, e.g. "Wed, 18 JUN"
  String _formattedToday() {
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[now.weekday - 1]}, ${now.day.toString().padLeft(2, '0')} ${_getMonthName(now.month)}';
  }

  /// GREETING HEADER — personalized welcome + today's date
  /// Styled to match the premium "Pending Cash Deposit" card: a soft
  /// gradient-tinted surface, tinted border, glow shadow and a gradient
  /// icon badge.
  Widget _greetingHeader(AppColorScheme colorScheme, String? name) {
    final firstName = (name ?? '').trim().split(' ').first;
    final accent = _greetingAccent(colorScheme);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.10),
            colorScheme.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// TIME-OF-DAY ICON BADGE
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent,
                  accent.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Icon(
              _greetingIcon(),
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greetingText(),
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  firstName.isNotEmpty ? '$firstName 👋' : 'Welcome 👋',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          /// DATE PILL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.border.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formattedToday(),
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _todaysProgressCard(BuildContext context, AppColorScheme colorScheme,
      TextTheme textTheme, SessionProvider sessionProvider) {
    final stats = sessionProvider.todayStats;
    final isLoading =
        sessionProvider.todayStatsState.status == ApiStatus.loading;

    /// A self-contained tinted stat card — icon badge, value and label.
    Widget statCard(
        IconData icon, Color accent, String value, String label) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.10),
              accent.withValues(alpha: 0.035),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accent.withValues(alpha: 0.14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent,
                    accent.withValues(alpha: 0.78),
                  ],
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 19),
            ),
            const SizedBox(height: 14),
            if (isLoading)
              _buildShimmerBox(56, 22, 4, colorScheme)
            else
              Text(
                value,
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                  height: 1.05,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                height: 1.05,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return CustomCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.getWidth(3),
        vertical: AppDimensions.getWidth(4),
      ),
      margin: EdgeInsets.all(AppDimensions.getWidth(0)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          ...colorScheme.cardShadow,
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
            spreadRadius: -7,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER — clean light row: badge + title + live status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context
                      .watch<LanguageProvider>()
                      .getTranslatedText('todays_progress'),
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
              ),
              if (sessionProvider.isOnline)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.success.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Live',
                        style: GoogleFonts.inter(
                          color: colorScheme.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: AppDimensions.getHeight(2.2)),

          /// STAT GRID — Orders | Earnings
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: statCard(
                    Icons.shopping_bag_rounded,
                    colorScheme.primary,
                    stats != null ? '${stats.ordersDelivered}' : '0',
                    "Orders",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: statCard(
                    Icons.account_balance_wallet_rounded,
                    colorScheme.success,
                    stats != null
                        ? '₹${formatEarnings(stats.totalEarnings)}'
                        : '₹0',
                    "Earnings",
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// STAT GRID — Trips | Gigs
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: statCard(
                    Icons.two_wheeler_rounded,
                    colorScheme.info,
                    stats != null
                        ? '${stats.totalDistanceKm.toStringAsFixed(1)} Kms'
                        : '0 Kms',
                    "Trips",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: statCard(
                    Icons.work_history_rounded,
                    colorScheme.warning,
                    stats != null ? '${stats.gigsCompleted}' : '0',
                    "Gigs History",
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// LOGIN TIME FOOTER (self-updating, see _TimeDisplay)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.border.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.textSecondary.withValues(alpha: 0.16),
                        colorScheme.textSecondary.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: colorScheme.textSecondary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    Icons.timer_outlined,
                    color: colorScheme.textSecondary,
                    size: 19,
                  ),
                ),
                const Spacer(),
                _TimeDisplay(
                  stats: stats,
                  calculateTotalLoginTime: _calculateTotalLoginTime,
                  showClockFormat: _showClockFormat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 STATUS TOGGLE (OFFLINE / ONLINE)
  /// ⚠️ DEPRECATED: Use StatusToggleWidget instead
  /// This method has been replaced with a reusable StatusToggleWidget
  /// for consistency across home and earnings screens.
  /// See: lib/view/custom_widgets/status_toggle_widget.dart
  /*
  Widget _statusToggle(TextTheme textTheme, AppColorScheme colorScheme,
      SessionProvider sessionProvider) {
    final isOnline = sessionProvider.isOnline;

    return GestureDetector(
      onTap:
          _isTogglingStatus ? null : () => _handleStatusToggle(sessionProvider),
      child: AnimatedOpacity(
        opacity: _isTogglingStatus ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          // height: 36,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isOnline ? colorScheme.success : colorScheme.error,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: isOnline
                    ? colorScheme.success.withValues(alpha: 0.3)
                    : colorScheme.error.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // When offline, button is on the left
              if (!isOnline) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isTogglingStatus
                      ? SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.error,
                            ),
                          ),
                        )
                      : Text(
                          "Off",
                          style: GoogleFonts.inter(
                            color: colorScheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
              ],

              // Label text in the middle
              Text(
                _isTogglingStatus
                    ? (isOnline ? "Going offline..." : "Going online...")
                    : (isOnline ? "Online" : "Offline"),
                style: GoogleFonts.inter(
                  color: colorScheme.surface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),

              // When online, button is on the right
              if (isOnline) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isTogglingStatus
                      ? SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.success,
                            ),
                          ),
                        )
                      : Text(
                          "On",
                          style: GoogleFonts.inter(
                            color: colorScheme.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                ),
              ],

              // const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
  */

  /// Start continuous battery monitoring while driver is online
  void _startBatteryMonitoring() {
    // Listen to battery state changes (charging/discharging)
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((_) {
      _checkBatteryAndGoOffline();
    });

    // Also check every 30 seconds as a safety net
    _batteryCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkBatteryAndGoOffline();
    });
  }

  /// Check battery level and auto go offline if < 15% and not on a ride
  Future<void> _checkBatteryAndGoOffline() async {
    if (!mounted) return;
    if (_isShowingBatteryDialog) return;

    final sessionProvider = context.read<SessionProvider>();
    if (!sessionProvider.isOnline) return;

    // Don't interrupt if driver is on an active ride
    final incomingOrderProvider = context.read<IncomingOrderProvider>();
    if (incomingOrderProvider.currentAcceptedOrder != null) return;

    try {
      final batteryLevel = await _battery.batteryLevel;
      if (batteryLevel < 15) {
        debugPrint('🔋 Battery at $batteryLevel% - auto going offline');
        _isShowingBatteryDialog = true;

        // End session
        await _endSession(sessionProvider);

        // Show dialog
        if (mounted) {
          _showLowBatteryDialog();
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking battery: $e');
    }
  }

  /// Check battery level - returns true if battery is OK (>=15%)
  Future<bool> _isBatteryLevelOk() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      return batteryLevel >= 15;
    } catch (e) {
      // If we can't read battery, allow going online
      return true;
    }
  }

  /// Show low battery dialog
  void _showLowBatteryDialog() {
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
            'Your phone battery is below 15%. Please charge your phone to at least 15% before going online to ensure uninterrupted deliveries.',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _isShowingBatteryDialog = false;
              },
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

  /// Handle status toggle tap - start or end session
  Future<void> _handleStatusToggle(SessionProvider sessionProvider) async {
    if (_isTogglingStatus) return;

    final isOnline = sessionProvider.isOnline;

    if (isOnline) {
      // Block going offline if there is an active order
      final activeOrder =
          context.read<IncomingOrderProvider>().currentAcceptedOrder;
      if (activeOrder != null) {
        _showActiveOrderBlockDialog();
        return;
      }

      // Show confirmation dialog before going offline
      final shouldGoOffline = await _showOfflineConfirmationDialog();
      if (!shouldGoOffline) return;

      // End session
      await _endSession(sessionProvider);
    } else {
      // Check battery level before allowing to go online
      final batteryOk = await _isBatteryLevelOk();
      if (!batteryOk) {
        _showLowBatteryDialog();
        return;
      }

      // Start session
      await _startSession(sessionProvider);
    }
  }

  /// Show confirmation dialog before going offline
  Future<bool> _showOfflineConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            final colorScheme = context.watch<ThemeProvider>().colorScheme;
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                context
                    .watch<LanguageProvider>()
                    .getTranslatedText('go_offline'),
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                context
                    .watch<LanguageProvider>()
                    .getTranslatedText('offline_confirmation'),
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'No',
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Yes',
                    style: GoogleFonts.inter(
                      color: colorScheme.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Show blocking dialog when driver tries to go offline with an active order
  void _showActiveOrderBlockDialog() {
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.delivery_dining_rounded,
                color: colorScheme.warning, size: 22),
            const SizedBox(width: 8),
            Text(
              'Active Delivery',
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'You have an ongoing delivery. Please complete or hand over the order before going offline.',
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'OK, Continue Delivery',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Start a new session - Navigate to face verification
  Future<void> _startSession(SessionProvider sessionProvider) async {
    setState(() => _isTogglingStatus = true);

    // Get providers before async gap
    final incomingOrderProvider = context.read<IncomingOrderProvider>();
    final authProvider = context.read<AuthProvider>();
    final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

    try {
      // Navigate to face verification screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FaceVerificationScreen(),
        ),
      );

      setState(() => _isTogglingStatus = false);
      if (!mounted) return;

      // If face verification was successful and session started
      if (result == true) {
        _showSuccessSnackBar('You are now online!');
        await _loadData();

        // Start listening for incoming orders
        if (deliveryBoyId != null) {
          debugPrint('✅ Session started, starting Firebase order listener');
          incomingOrderProvider.startListening(deliveryBoyId);
        }
      }
    } catch (e) {
      setState(() => _isTogglingStatus = false);
      if (!mounted) return;
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  /// End the active session
  Future<void> _endSession(SessionProvider sessionProvider) async {
    setState(() => _isTogglingStatus = true);

    // Get provider before async gap
    final incomingOrderProvider = context.read<IncomingOrderProvider>();

    try {
      // Get current location
      final position = await _getCurrentPosition();
      if (position == null) {
        setState(() => _isTogglingStatus = false);
        if (!mounted) return;
        _showErrorSnackBar('Unable to get your location. Please enable GPS.');
        return;
      }

      // End session
      final success = await sessionProvider.endSession(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() => _isTogglingStatus = false);
      if (!mounted) return;

      if (success) {
        _showSuccessSnackBar('You are now offline.');
        await _loadData();

        // Stop listening for incoming orders
        debugPrint('🛑 Session ended, stopping Firebase order listener');
        incomingOrderProvider.stopListening();
      } else {
        _showErrorSnackBar('Failed to end session. Please try again.');
      }
    } catch (e) {
      setState(() => _isTogglingStatus = false);
      if (!mounted) return;
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  /// Get current GPS position
  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permission denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar(
            'Location permission permanently denied. Enable in settings.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _showErrorSnackBar('Failed to get location: ${e.toString()}');
      return null;
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: colorScheme.surface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: colorScheme.surface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// TODAY'S BOOKINGS SECTION
  Widget _todaysBookingsSection(
      BuildContext context, AppColorScheme colorScheme, TextTheme textTheme) {
    final bookingProvider = context.watch<BookingProvider>();
    final isLoading = bookingProvider.isLoading;
    final todaysBookings = bookingProvider.todaysBookings;

    // If no bookings today and not loading, don't show anything
    if (!isLoading && todaysBookings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context
                      .watch<LanguageProvider>()
                      .getTranslatedText('todays_bookings'),
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            if (!isLoading && todaysBookings.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${todaysBookings.length} ${todaysBookings.length == 1 ? context.watch<LanguageProvider>().getTranslatedText('slot') : context.watch<LanguageProvider>().getTranslatedText('slots')}',
                  style: GoogleFonts.inter(
                    color: colorScheme.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        /// BOOKINGS LIST
        if (isLoading)
          Column(
            children: List.generate(
              2,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBookingShimmer(colorScheme),
              ),
            ),
          )
        else
          Column(
            children: todaysBookings.map((booking) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBookingCard(booking, colorScheme),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// Build shimmer skeleton for booking card
  Widget _buildBookingShimmer(AppColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.border.withValues(alpha: 0.3),
            ),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildShimmerBox(32, 32, 10, colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(120, 16, 4, colorScheme),
                        const SizedBox(height: 6),
                        _buildShimmerBox(80, 13, 4, colorScheme),
                      ],
                    ),
                  ),
                  _buildShimmerBox(60, 28, 14, colorScheme),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: colorScheme.border.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(50, 12, 4, colorScheme),
                        const SizedBox(height: 6),
                        _buildShimmerBox(70, 15, 4, colorScheme),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildShimmerBox(50, 12, 4, colorScheme),
                        const SizedBox(height: 6),
                        _buildShimmerBox(60, 15, 4, colorScheme),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build booking card
  Widget _buildBookingCard(dynamic booking, AppColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// LEFT ACCENT STRIP
              Container(width: 4, color: colorScheme.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          /// HEADER ROW
          Row(
            children: [
              /// ICON
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: colorScheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),

              /// GIG NAME & TIME
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.gigName,
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.startTime} - ${booking.endTime}',
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              /// STATUS BADGE
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context
                          .watch<LanguageProvider>()
                          .getTranslatedText('booked'),
                      style: GoogleFonts.inter(
                        color: colorScheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// DIVIDER
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.border.withValues(alpha: 0),
                  colorScheme.border.withValues(alpha: 0.1),
                  colorScheme.border.withValues(alpha: 0),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// INFO ROW
          Row(
            children: [
              /// EARNINGS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context
                          .watch<LanguageProvider>()
                          .getTranslatedText('earnings'),
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${booking.baseEarnings.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        color: colorScheme.success,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              /// REMINDER
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context
                          .watch<LanguageProvider>()
                          .getTranslatedText('remember'),
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context
                            .watch<LanguageProvider>()
                            .getTranslatedText('go_online'),
                        style: GoogleFonts.inter(
                          color: colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _offersSection(
      BuildContext context, AppColorScheme colorScheme, TextTheme textTheme) {
    final incentiveProvider = context.watch<IncentiveProvider>();
    final isLoading =
        incentiveProvider.activeOffersState.status == ApiStatus.loading;
    final offers = incentiveProvider.activeOffers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.watch<LanguageProvider>().getTranslatedText('offers'),
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllOffersScreen(),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.border.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context
                          .watch<LanguageProvider>()
                          .getTranslatedText('view_all'),
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        /// OFFER CARD
        if (isLoading)
          Container(
            padding: EdgeInsets.symmetric(
                vertical: AppDimensions.getHeight(1),
                horizontal: AppDimensions.getWidth(3)),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.border.withValues(alpha: 0.3),
              ),
              boxShadow: colorScheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// OFFER BANNER SKELETON
                Container(
                  padding: EdgeInsets.all(AppDimensions.getWidth(3)),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.border.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// LEFT: DATE & STATUS
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildShimmerBox(45, 15, 4, colorScheme),
                            const SizedBox(height: 8),
                            _buildShimmerBox(45, 20, 20, colorScheme),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      /// CENTER: TITLE & TIME
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildShimmerBox(120, 15, 4, colorScheme),
                            const SizedBox(height: 4),
                            _buildShimmerBox(80, 13, 4, colorScheme),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      /// RIGHT: AMOUNT
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildShimmerBox(45, 15, 4, colorScheme),
                            const SizedBox(height: 2),
                            _buildShimmerBox(30, 13, 4, colorScheme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// INCENTIVES ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmerBox(70, 12, 4, colorScheme),
                    _buildShimmerBox(40, 13, 4, colorScheme),
                    _buildShimmerBox(40, 13, 4, colorScheme),
                    _buildShimmerBox(40, 13, 4, colorScheme),
                    _buildShimmerBox(40, 13, 4, colorScheme),
                  ],
                ),

                const SizedBox(height: 10),

                /// PROGRESS BAR WITH BIKE
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(28, 28, 4, colorScheme),
                        Container(
                          height: 4,
                          width: AppDimensions.getWidth(30),
                          decoration: BoxDecoration(
                            color: colorScheme.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 25)
                      ],
                    ),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              4,
                              (index) => Container(
                                height: 18,
                                width: 18,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// EARNINGS ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmerBox(60, 12, 4, colorScheme),
                    _buildShimmerBox(35, 12, 4, colorScheme),
                    _buildShimmerBox(35, 12, 4, colorScheme),
                    _buildShimmerBox(35, 12, 4, colorScheme),
                    _buildShimmerBox(35, 12, 4, colorScheme),
                  ],
                ),

                const SizedBox(height: 14),

                /// CONDITIONS
                _buildShimmerBox(90, 15, 4, colorScheme),
                const SizedBox(height: 6),
                _buildShimmerBox(double.infinity, 12, 4, colorScheme),
                const SizedBox(height: 4),
                _buildShimmerBox(200, 12, 4, colorScheme),

                const SizedBox(height: 14),

                /// VIEW DETAILS BUTTON
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(120),
                  ),
                  child: Center(
                    child: _buildShimmerBox(100, 15, 4, colorScheme),
                  ),
                ),
              ],
            ),
          )
        else if (offers.isEmpty)
          Container(
            height: 200,
            padding: EdgeInsets.symmetric(
                vertical: AppDimensions.getHeight(1),
                horizontal: AppDimensions.getWidth(3)),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.border.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 48, color: colorScheme.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    context
                        .watch<LanguageProvider>()
                        .getTranslatedText('no_active_offers'),
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: EdgeInsets.only(
                top: AppDimensions.getHeight(1),
                bottom: AppDimensions.getHeight(0.5),
                left: AppDimensions.getWidth(3),
                right: AppDimensions.getWidth(3)),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
              boxShadow: [
                ...colorScheme.cardShadow,
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                  spreadRadius: -7,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// OFFER BANNER
                OfferBanner(
                  colorScheme: colorScheme,
                  date: offers.first.startDate.day.toString().padLeft(2, '0') +
                      ' ' +
                      _getMonthName(offers.first.startDate.month),
                  title: offers.first.name,
                  timeSlot: '${offers.first.daysRemaining} days left',
                  amount: offers.first.tiers.isNotEmpty
                      ? '₹${offers.first.tiers.last.incentiveAmount.toStringAsFixed(0)}'
                      : '₹0',
                  amountLabel: "Extra",
                  isLive: offers.first.isActive,
                ),

                const SizedBox(height: 18),

                if (offers.first.tiers.isNotEmpty)
                  Builder(
                    builder: (context) {
                      final containerWidth = MediaQuery.of(context).size.width -
                          (AppDimensions.getWidth(3) * 2);
                      return SizedBox(
                        height: 16,
                        width: double.infinity,
                        child: Stack(
                          children: offers.first.tiers.map(
                            (tier) {
                              if (tier.minEarnings == 0) {
                                return Positioned(
                                  left: 0,
                                  child: Text(
                                    'Inc',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: colorScheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.55,
                                      height: 1.02,
                                    ),
                                  ),
                                );
                              }
                              final tierPos =
                                  (tier.tierPercentage / 100).clamp(0.0, 1.0);
                              final isLastTier = tierPos >= 0.95;
                              final leftPos = isLastTier
                                  ? containerWidth - 75
                                  : containerWidth * tierPos - 20;
                              return Positioned(
                                left: leftPos,
                                child: SizedBox(
                                  width: 40,
                                  child: Text(
                                    '₹${tier.incentiveAmount.toStringAsFixed(0)}',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.textPrimary,
                                      letterSpacing: -0.55,
                                      height: 1.02,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 4),

                /// PROGRESS BAR WITH BIKE & MILESTONES
                Builder(
                  builder: (context) {
                    final containerWidth = MediaQuery.of(context).size.width -
                        (AppDimensions.getWidth(3) * 2);

                    final progressFill =
                        (offers.first.myProgress.overallProgressPercentage /
                                100)
                            .clamp(0.0, 1.0);

                    return SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Progress bar (track + green fill)
                          Positioned(
                            top: 17,
                            left: 0,
                            right: 0,
                            child: SizedBox(
                              height: 6,
                              width: double.infinity,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Stack(
                                  children: [
                                    Container(
                                      color: colorScheme.border,
                                      width: double.infinity,
                                    ),
                                    Container(
                                      width: containerWidth * progressFill,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Bike riding at the leading edge of the green fill
                          Positioned(
                            left: (containerWidth * progressFill - 16)
                                .clamp(0.0, containerWidth - 32),
                            top: -2,
                            child: Image.asset(
                              'assets/images/bike.png',
                              width: 32,
                              height: 32,
                            ),
                          ),
                          // Lock / check icons at milestones
                          ...offers.first.tiers.map((tier) {
                            // Skip icon for first tier with 0 earnings
                            if (tier.minEarnings == 0) {
                              return const SizedBox.shrink();
                            }

                            final isAchieved =
                                offers.first.myProgress.currentTier != null &&
                                    tier.tierLevel <=
                                        offers.first.myProgress.currentTier!
                                            .tierLevel;

                            final tierPos =
                                (tier.tierPercentage / 100).clamp(0.0, 1.0);
                            final isLastTier = tierPos >= 0.95;
                            final leftPos = isLastTier
                                ? containerWidth - 52
                                : containerWidth * tierPos - 9;

                            return Positioned(
                              left: leftPos,
                              top: 11,
                              child: Container(
                                height: 18,
                                width: 18,
                                decoration: BoxDecoration(
                                  color: isAchieved
                                      ? colorScheme.success
                                      : colorScheme.textPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isAchieved ? Icons.check : Icons.lock,
                                  size: 10,
                                  color: colorScheme.surface,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                /// EARNINGS LABELS
                if (offers.first.tiers.isNotEmpty)
                  Builder(
                    builder: (context) {
                      final containerWidth = MediaQuery.of(context).size.width -
                          (AppDimensions.getWidth(3) * 2);
                      return SizedBox(
                        height: 24,
                        width: double.infinity,
                        child: Stack(
                          children: offers.first.tiers.map((tier) {
                            if (tier.minEarnings == 0) {
                              return Positioned(
                                left: 0,
                                child: Text(
                                  'Ear',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: colorScheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.55,
                                    height: 1.02,
                                  ),
                                ),
                              );
                            }
                            final tierPos =
                                (tier.tierPercentage / 100).clamp(0.0, 1.0);
                            final isLastTier = tierPos >= 0.95;
                            final leftPos = isLastTier
                                ? containerWidth - 75
                                : containerWidth * tierPos - 20;
                            return Positioned(
                              left: leftPos,
                              child: SizedBox(
                                width: 40,
                                child: Text(
                                  '₹${tier.minEarnings.toStringAsFixed(0)}',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: colorScheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.55,
                                    height: 1.02,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 14),

                /// CONDITIONS
                Text(
                  context
                      .watch<LanguageProvider>()
                      .getTranslatedText('conditions'),
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.55,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 6),
                if (offers.first.description.isNotEmpty)
                  Text(
                    '•  ${offers.first.description}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.textSecondary,
                      letterSpacing: -0.3,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (offers.first.conditions != null) ...[
                  if (offers.first.conditions!.minGigsRequired > 0)
                    Text(
                      '•  Minimum ${offers.first.conditions!.minGigsRequired} gigs required',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.textSecondary,
                        letterSpacing: -0.3,
                        height: 1.5,
                      ),
                    ),
                  if (offers.first.conditions!.maxGigsSkip > 0)
                    Text(
                      '•  Max ${offers.first.conditions!.maxGigsSkip} gigs skip allowed',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.textSecondary,
                        letterSpacing: -0.3,
                        height: 1.5,
                      ),
                    ),
                  if (offers.first.conditions!.maxOrdersCancel > 0)
                    Text(
                      '•  Max ${offers.first.conditions!.maxOrdersCancel} orders cancel allowed',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.textSecondary,
                        letterSpacing: -0.3,
                        height: 1.5,
                      ),
                    ),
                  if (offers.first.conditions!.loginMandatory)
                    Text(
                      '•  Login is mandatory',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.textSecondary,
                        letterSpacing: -0.3,
                        height: 1.5,
                      ),
                    ),
                ],

                const SizedBox(height: 14),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OfferDetailsScreen(
                          offerId: offers.first.offerId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(120),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context
                              .watch<LanguageProvider>()
                              .getTranslatedText('view_details'),
                          style: GoogleFonts.inter(
                            color: colorScheme.primaryDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: colorScheme.primaryDark,
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build shimmer box with custom gradient animation
  Widget _buildShimmerBox(
      double width, double height, double radius, AppColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.surfaceVariant,
                colorScheme.surface,
                colorScheme.surfaceVariant,
              ],
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[month - 1];
  }
}

/// Reusable Offer Banner Widget
class OfferBanner extends StatelessWidget {
  final AppColorScheme colorScheme;
  final String date;
  final String title;
  final String timeSlot;
  final String amount;
  final String amountLabel;
  final bool isLive;

  const OfferBanner({
    required this.colorScheme,
    required this.date,
    required this.title,
    required this.timeSlot,
    required this.amount,
    required this.amountLabel,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.getWidth(3)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF22402D),
            Color(0xFF12241A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LEFT: DATE & STATUS
          Expanded(
            flex: 1,
            child: _buildDateSection(context),
          ),

          const SizedBox(width: 12),

          /// CENTER: TITLE & TIME
          Expanded(
            flex: 3,
            child: _buildTitleSection(),
          ),

          const SizedBox(width: 12),

          /// RIGHT: AMOUNT
          Expanded(
            flex: 1,
            child: _buildAmountSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          date,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        if (isLive) _buildLiveBadge(colorScheme, ctx),
      ],
    );
  }

  Widget _buildLiveBadge(AppColorScheme colorScheme, BuildContext ctx) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(
                width: 1.5,
                color: colorScheme.success,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  color: colorScheme.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            ctx.watch<LanguageProvider>().getTranslatedText('live'),
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          timeSlot,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            height: 1.3,
          ),
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          amountLabel,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}

/// Optimized time display widget
/// Only rebuilds itself every second instead of rebuilding entire home screen
/// This significantly reduces unnecessary rebuilds
class _TimeDisplay extends StatefulWidget {
  final DailyTracking? stats;
  final String Function(DailyTracking) calculateTotalLoginTime;
  final bool showClockFormat;

  const _TimeDisplay({
    required this.stats,
    required this.calculateTotalLoginTime,
    required this.showClockFormat,
  });

  @override
  State<_TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<_TimeDisplay> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // Timer updates only this widget, not the entire home screen
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Rebuild to recalculate elapsed time
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>();

    // Recalculate time on each rebuild (only once per second now)
    final timeText = widget.stats != null
        ? widget.calculateTotalLoginTime(widget.stats!)
        : '00:00:00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          timeText,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme?.textPrimary ?? Colors.black,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          context.watch<LanguageProvider>().getTranslatedText('login_hours'),
          style: GoogleFonts.inter(
            color: colorScheme?.textSecondary ?? Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}
