import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/banner_provider.dart';
import 'package:zenfoo_partner/providers/gig_provider.dart';
import 'package:zenfoo_partner/providers/incentive_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/session_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_image_icon.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/status_toggle_widget.dart';
import 'package:zenfoo_partner/view/screens/home/screens/gig_availability_screen.dart';
import 'package:zenfoo_partner/view/screens/emergency/emergency_support_screen.dart';
import 'package:zenfoo_partner/view/screens/face_verification/face_verification_screen.dart';
import 'package:zenfoo_partner/view/screens/help_center/help_center_screen.dart';
import 'package:zenfoo_partner/providers/incoming_order_provider.dart';
import 'package:zenfoo_partner/view/screens/home/screens/offer_detail_screen.dart';
import 'package:zenfoo_partner/view/screens/home/widgets/home_banner_carousel.dart';
import 'package:zenfoo_partner/view/screens/profile/profile_screen.dart';

class GigsBookingsScreen extends StatefulWidget {
  const GigsBookingsScreen({super.key});

  @override
  State<GigsBookingsScreen> createState() => _GigsBookingsScreenState();
}

class _GigsBookingsScreenState extends State<GigsBookingsScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  bool _isTogglingStatus = false;

  @override
  void initState() {
    super.initState();

    // Initialize shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGigsForMonth();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadGigsForMonth() async {
    final incentiveProvider = context.read<IncentiveProvider>();
    final gigProvider = context.read<GigProvider>();

    // Load active offers and my bookings
    await Future.wait([
      incentiveProvider.getActiveOffers(),
      gigProvider.getMyBookings(),
    ]);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    });
    _loadGigsForMonth();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final sessionProvider = context.watch<SessionProvider>();
    final incentiveProvider = context.watch<IncentiveProvider>();
    final gigProvider = context.watch<GigProvider>();
    final authProvider = context.watch<AuthProvider>();
    final deliveryBoy = authProvider.currentDeliveryBoy;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER (same as home screen)
          AppHeader(
            label: context
                .watch<LanguageProvider>()
                .getTranslatedText('dashboard'),
            title: context
                .watch<LanguageProvider>()
                .getTranslatedText('gigs_bookings'),
            showBackButton: false,
            showExitButton: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  child: const CustomImageIcon(imagePath: AppImages.headPhone),
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
                        ? NetworkImage(deliveryBoy!.profileImageUrl!)
                        : const AssetImage(AppImages.profilePerson)
                            as ImageProvider,
                    child: deliveryBoy?.profileImageUrl == null
                        ? Text(
                            deliveryBoy?.name.isNotEmpty == true
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
              onRefresh: _loadGigsForMonth,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    /// BANNER CAROUSEL (same as home)
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

                    const SizedBox(height: 24),

                    /// GIGS BOOKINGS TITLE
                    Text(
                      'Gigs Bookings',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF4B5563),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// DATE LIST VIEW
                    _buildDateListView(
                        incentiveProvider, gigProvider, colorScheme),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 STATUS TOGGLE (OFFLINE / ONLINE)
  /// ⚠️ DEPRECATED: Use StatusToggleWidget instead
  /// This method has been replaced with a reusable StatusToggleWidget
  /// for consistency across all screens.
  /// See: lib/view/custom_widgets/status_toggle_widget.dart
  /*
  Widget _statusToggle(
      AppColorScheme colorScheme, SessionProvider sessionProvider) {
    final isOnline = sessionProvider.isOnline;

    return GestureDetector(
      onTap: () {
        // Toggle functionality can be added here if needed
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isOnline ? colorScheme.success : colorScheme.error,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // When offline, button is on the left
            if (!isOnline) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
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
              isOnline ? "Online" : "Offline",
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
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
          ],
        ),
      ),
    );
  }
  */

  /// Handle status toggle - start or end session
  Future<void> _handleStatusToggle(SessionProvider sessionProvider) async {
    if (_isTogglingStatus) return;

    if (sessionProvider.isOnline) {
      // Go offline
      await _endSession(sessionProvider);
    } else {
      // Go online - with face verification
      await _startSession(sessionProvider);
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context
                .read<LanguageProvider>()
                .getTranslatedText('now_online')),
            backgroundColor: Colors.green[600],
          ),
        );

        // Start listening for incoming orders
        if (deliveryBoyId != null) {
          debugPrint('✅ Session started, starting Firebase order listener');
          incomingOrderProvider.startListening(deliveryBoyId);
        }
      }
    } catch (e) {
      setState(() => _isTogglingStatus = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${context.read<LanguageProvider>().getTranslatedText('error')}: ${e.toString()}'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  /// End the active session
  Future<void> _endSession(SessionProvider sessionProvider) async {
    setState(() => _isTogglingStatus = true);

    // Get provider before async gap
    final incomingOrderProvider = context.read<IncomingOrderProvider>();

    try {
      // Show confirmation dialog
      if (mounted) {
        final shouldLogout = await showDialog<bool>(
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
                        context
                            .watch<LanguageProvider>()
                            .getTranslatedText('cancel'),
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
                        context
                            .watch<LanguageProvider>()
                            .getTranslatedText('go_offline'),
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

        if (!shouldLogout) {
          setState(() => _isTogglingStatus = false);
          return;
        }
      }

      // End session
      final success = await sessionProvider.endSession(
        latitude: 0,
        longitude: 0,
      );

      setState(() => _isTogglingStatus = false);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context
                .read<LanguageProvider>()
                .getTranslatedText('now_offline')),
            backgroundColor: Colors.green[600],
          ),
        );

        // Stop listening for incoming orders
        incomingOrderProvider.stopListening();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context
                .read<LanguageProvider>()
                .getTranslatedText('failed_end_session')),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } catch (e) {
      setState(() => _isTogglingStatus = false);
      if (!mounted) return;
      debugPrint('Error ending session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${context.read<LanguageProvider>().getTranslatedText('error')}: ${e.toString()}'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  Widget _monthSelector(AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: colorScheme.textPrimary,
              size: 20,
            ),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: colorScheme.textPrimary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateListView(IncentiveProvider incentiveProvider,
      GigProvider gigProvider, AppColorScheme colorScheme) {
    if (incentiveProvider.activeOffersState.status == ApiStatus.loading) {
      return _buildShimmerLoading(colorScheme);
    }

    if (incentiveProvider.activeOffersState.status == ApiStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            incentiveProvider.activeOffersState.message ??
                context
                    .watch<LanguageProvider>()
                    .getTranslatedText('failed_load_offers'),
            style: GoogleFonts.inter(
              color: colorScheme.error,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Get active offers and bookings
    final offers = incentiveProvider.activeOffers;
    final bookings = gigProvider.myBookings;

    // Generate dates for the current month
    final lastDayOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final today = DateTime.now();
    final daysInMonth = lastDayOfMonth.day;

    // Build list of date cards
    return Column(
      children: List.generate(daysInMonth, (index) {
        final day = index + 1;
        final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
        final isPast =
            date.isBefore(DateTime(today.year, today.month, today.day));

        // Skip past dates
        if (isPast) return const SizedBox.shrink();

        // Check if there's an offer for this date
        final hasOffer = offers.any((offer) {
          final validFrom = offer.startDate;
          final validUntil = offer.endDate;
          return date.isAfter(validFrom.subtract(const Duration(days: 1))) &&
              date.isBefore(validUntil.add(const Duration(days: 1)));
        });

        // Check if there are any bookings for this date
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final dateBookings = bookings.where((booking) {
          // Extract date portion from slotDate (handles both "2026-01-03" and "2026-01-03T00:00:00.000000Z")
          final bookingDateStr = booking.slotDate.split('T').first;
          return bookingDateStr == dateStr &&
              (booking.bookingStatus == 'booked' ||
                  booking.bookingStatus == 'active');
        }).toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildDateCard(
              date, hasOffer, dateBookings, offers, gigProvider, colorScheme),
        );
      }),
    );
  }

  Widget _buildDateCard(
    DateTime date,
    bool hasOffer,
    List dateBookings,
    List offers,
    GigProvider gigProvider,
    AppColorScheme colorScheme,
  ) {
    final dayOfWeek = DateFormat('EEE').format(date);
    final dateFormatted = DateFormat('dd MMM').format(date);
    final hasBookings = dateBookings.isNotEmpty;

    return GestureDetector(
      onTap: () => _handleDateClick(date, hasOffer, offers),
      child: Container(
        width: double.infinity,
        // padding: const EdgeInsets.all(4),
        decoration: ShapeDecoration(
          color: hasBookings ? const Color(0xFF3B82F6) : colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(12),
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date section
            Container(
              width: 88,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: ShapeDecoration(
                color: colorScheme.primary,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    dateFormatted,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: hasBookings || hasOffer
                          ? Colors.black
                          : colorScheme.surface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.29,
                      letterSpacing: -0.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: ShapeDecoration(
                      color: hasBookings || hasOffer
                          ? const Color(0xFFEDEDED)
                          : colorScheme.surface.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        dayOfWeek,
                        style: GoogleFonts.inter(
                          color: hasBookings || hasOffer
                              ? Colors.black
                              : colorScheme.surface,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: -0.05,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child:
                    _buildAvailableContent(hasOffer, colorScheme, hasBookings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableContent(
      bool hasOffer, AppColorScheme colorScheme, bool hasBookings) {
    final textColor = hasBookings ? Colors.white : colorScheme.textPrimary;
    final subtextColor = hasBookings ? Colors.white : colorScheme.textSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasOffer
                    ? context
                        .watch<LanguageProvider>()
                        .getTranslatedText('offer_available')
                    : context
                        .watch<LanguageProvider>()
                        .getTranslatedText('bookings_open'),
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -0.05,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasOffer
                    ? context
                        .watch<LanguageProvider>()
                        .getTranslatedText('complete_gigs_unlock_rewards')
                    : context
                        .watch<LanguageProvider>()
                        .getTranslatedText('book_gig_start_earning'),
                style: GoogleFonts.inter(
                  color: subtextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: -0.05,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: subtextColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
                color: subtextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleDateClick(DateTime date, bool hasOffer, List offers) {
    if (hasOffer) {
      // Find the offer for this date
      final offer = offers.firstWhere((o) {
        final validFrom = o.startDate;
        final validUntil = o.endDate;
        return date.isAfter(validFrom.subtract(const Duration(days: 1))) &&
            date.isBefore(validUntil.add(const Duration(days: 1)));
      });

      // Navigate to offer details screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OfferDetailsScreen(
            offerId: offer.offerId,
            selectedDate: date,
          ),
        ),
      );
    } else {
      // Navigate directly to gig availability screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GigAvailabilityScreen(
            selectedDate: date,
          ),
        ),
      );
    }
  }

  Widget _buildShimmerLoading(AppColorScheme colorScheme) {
    return Column(
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            decoration: ShapeDecoration(
              color: colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
            child: Row(
              children: [
                // Date shimmer section
                Container(
                  width: 88,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildShimmerBox(60, 14, 4, colorScheme),
                      const SizedBox(height: 10),
                      _buildShimmerBox(50, 24, 12, colorScheme),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Content shimmer section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildShimmerBox(24, 24, 4, colorScheme),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildShimmerBox(
                                  double.infinity, 16, 4, colorScheme),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildShimmerBox(180, 12, 4, colorScheme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        );
      }),
    );
  }

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
}
