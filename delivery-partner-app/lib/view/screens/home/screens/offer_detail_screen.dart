import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/incentive_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/screens/home/screens/gig_availability_screen.dart';
import 'package:zenfoo_partner/providers/banner_provider.dart';
import 'package:zenfoo_partner/view/screens/home/widgets/home_banner_carousel.dart';
import 'package:zenfoo_partner/view/screens/profile/all_offers_screen.dart';

class OfferDetailsScreen extends StatefulWidget {
  final int offerId;
  final DateTime? selectedDate;

  const OfferDetailsScreen({
    super.key,
    required this.offerId,
    this.selectedDate,
  });

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

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
      _loadOfferDetails();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadOfferDetails() async {
    final incentiveProvider = context.read<IncentiveProvider>();
    // Offer details already includes progress data, so we only need one call
    await incentiveProvider.getOfferDetails(offerId: widget.offerId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final colorScheme = theme.colorScheme;
    final incentiveProvider = context.watch<IncentiveProvider>();

    final offerDetailsState = incentiveProvider.offerDetailsState;

    final isLoading = offerDetailsState.status == ApiStatus.loading;
    final hasError = offerDetailsState.status == ApiStatus.error;

    final offer = incentiveProvider.currentOfferDetails;
    final progress = offer?.myProgress; // Use progress from the offer itself

    if (isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Column(
          children: [
            AppHeader(
              label: 'Loading...',
              title: 'Offer Details',
              showBackButton: true,
              trailing: _buildShimmerBox(80, 28, 20, colorScheme),
            ),
            const SizedBox(height: 16),

            /// DESCRIPTION SKELETON
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium),
              child: Column(
                children: [
                  _buildShimmerBox(double.infinity, 13, 4, colorScheme),
                  const SizedBox(height: 4),
                  _buildShimmerBox(200, 13, 4, colorScheme),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// FLOATING BADGE SKELETON
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: colorScheme.border.withValues(alpha: 0.3),
                ),
                boxShadow: colorScheme.cardShadow,
              ),
              child: Center(
                child: _buildShimmerBox(220, 15, 4, colorScheme),
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// INCENTIVES ROW SKELETON
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
                    const SizedBox(height: 12),

                    /// PROGRESS BAR SKELETON
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                    const SizedBox(height: 12),

                    /// EARNINGS ROW SKELETON
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
                    const SizedBox(height: 20),

                    /// BLUE INFO BOX SKELETON
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            _buildShimmerBox(250, 13, 4, colorScheme),
                            const SizedBox(height: 4),
                            _buildShimmerBox(180, 13, 4, colorScheme),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// CONDITIONS SKELETON
                    ...List.generate(
                      4,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildShimmerBox(120, 14, 4, colorScheme),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  height: 6,
                                  width: 6,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildShimmerBox(150, 13, 4, colorScheme),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// G CUT IMAGES SKELETON
                    Row(
                      children: List.generate(
                        9,
                        (_) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _buildShimmerBox(30, 30, 4, colorScheme),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// BANNER SKELETON
                    _buildShimmerBox(double.infinity, 180, 16, colorScheme),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (hasError || offer == null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Column(
          children: [
            const AppHeader(
              label: 'Error',
              title: 'Offer Details',
              showBackButton: true,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load offer details',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Retry',
                      onPressed: _loadOfferDetails,
                      height: 48,
                      width: 120,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Get the maximum incentive amount from the last tier
    final maxIncentive =
        offer.tiers.isNotEmpty ? offer.tiers.last.incentiveAmount : 0.0;

    // Format the date range
    final startDate = DateFormat('dd MMM').format(offer.startDate);
    final endDate = DateFormat('dd MMM').format(offer.endDate);

    // Determine if offer is currently active
    final now = DateTime.now();
    final isActive =
        now.isAfter(offer.startDate) && now.isBefore(offer.endDate);

    return Scaffold(
      backgroundColor: colorScheme.background,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// GO ONLINE BUTTON
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingSmall,
              ),
              child: CustomButton(
                text: 'Book Gigs',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GigAvailabilityScreen(
                        selectedDate: widget.selectedDate,
                      ),
                    ),
                  );
                },
                height: 52,
              ),
            ),
          ),
          SizedBox(height : 10)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOfferDetails,
        color: colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= HEADER + OVERLAPPING BADGE =================
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Green header with extra bottom padding for badge overlap
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                        child: Column(
                          children: [
                            // Top row: back arrow + date
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(context);
                                  },
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.selectedDate != null
                                      ? DateFormat('dd MMM yyyy').format(widget.selectedDate!).toUpperCase()
                                      : '${startDate.toUpperCase()} - ${endDate.toUpperCase()}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: -0.3,
                                    height: 1.02,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Centered Live/Ended badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 10,
                                    width: 10,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? colorScheme.success
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isActive ? 'Live' : 'Ended',
                                    style: GoogleFonts.inter(
                                      color: Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.3,
                                      height: 1.02,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Centered offer name
                            Text(
                              offer.name,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Centered description (time slot)
                            Text(
                              offer.description,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.3,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Floating badge - overlapping half on header, half below
                  Positioned(
                    bottom: 0,
                    left: AppDimensions.paddingMedium,
                    right: AppDimensions.paddingMedium,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: colorScheme.border.withValues(alpha: 0.3),
                        ),
                        boxShadow: colorScheme.cardShadow,
                      ),
                      child: Center(
                        child: Text(
                          'Get an extra upto ₹${maxIncentive.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.55,
                            height: 1.02,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _offersSection(
                context,
                colorScheme,
                theme,
              ),
              const SizedBox(height: 24),

              /// ================= CONTENT BELOW =================
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// BLUE INFO (Dynamic based on next tier)
                    if (progress != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            progress.nextTier != null
                                ? 'Earn ₹${(progress.nextTier!.minEarnings - progress.currentEarnings).toStringAsFixed(0)} more  to to unlock ₹${progress.nextTier!.incentiveAmount.toStringAsFixed(0)}'
                                : 'All milestones achieved!',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF3B82F6),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.55,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    /// CONDITIONS from offer
                    if (offer.conditions != null) ...[
                      if (offer.conditions!.loginMandatory)
                        _condition(
                          colorScheme,
                          'Login is mandatory',
                          offer.description,
                        ),
                      const SizedBox(height: 16),
                      _condition(
                        colorScheme,
                        "You're allowed",
                        '${offer.conditions!.maxGigsSkip} order Denial',
                      ),
                      const SizedBox(height: 16),
                      _condition(
                        colorScheme,
                        "You're allowed",
                        '${offer.conditions!.maxOrdersCancel} order cancellation',
                      ),
                      const SizedBox(height: 16),
                      _condition(
                        colorScheme,
                        "You're allowed",
                        '${offer.conditions!.minGigsRequired} incomplete Gigs',
                      ),
                    ] else ...[
                      _condition(
                        colorScheme,
                        'Offer Period',
                        '$startDate to $endDate',
                      ),
                    ],

                    const SizedBox(height: 24),

                    /// G CUT IMAGES ROW
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        children: List.generate(
                          9,
                          (_) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Image.asset(
                              AppImages.gCut,
                              height: 30,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// BANNER CAROUSEL
                    Consumer<BannerProvider>(
                      builder: (context, bannerProvider, _) {
                        if (!bannerProvider.hasData) {
                          return const SizedBox.shrink();
                        }
                        return HomeBannerCarousel(
                          banners: bannerProvider.banners,
                        );
                      },
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= SHIMMER BOX =================
  Widget _buildShimmerBox(
      double width, double height, double radius, colorScheme) {
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

  /// ================= REUSABLE CONDITION ROW =================
  Widget _condition(colorScheme, String title, String subTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: CircleAvatar(
                radius: 3,
                backgroundColor: colorScheme.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                subTitle,
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.55,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ================= OFFERS SECTION =================
  Widget _offersSection(
      BuildContext context, AppColorScheme colorScheme, ThemeProvider theme) {
    final incentiveProvider = context.watch<IncentiveProvider>();
    final isLoading =
        incentiveProvider.activeOffersState.status == ApiStatus.loading;
    final offers = incentiveProvider.activeOffers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    'No active offers',
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
            padding: EdgeInsets.symmetric(
                vertical: AppDimensions.getHeight(1),
                horizontal: AppDimensions.getWidth(5)),
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
                const SizedBox(height: 10),

                if (offers.first.tiers.isNotEmpty)
                  Builder(
                    builder: (context) {
                      final containerWidth = MediaQuery.of(context).size.width -
                          (AppDimensions.getWidth(5) * 2);
                      final tiersWithEarnings = offers.first.tiers
                          .where((t) => t.minEarnings > 0)
                          .toList();
                      final tierCount = tiersWithEarnings.length;
                      const labelWidth = 40.0;

                      return SizedBox(
                        height: 20,
                        width: double.infinity,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // "Inc" label on the left
                            Positioned(
                              left: 0,
                              top: 0,
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
                            ),
                            // Tier incentive amounts
                            ...List.generate(tierCount, (i) {
                              final tier = tiersWithEarnings[i];
                              final segmentWidth =
                                  (containerWidth - 40) / tierCount;
                              final leftPos =
                                  40 + (segmentWidth * i) + (segmentWidth / 2) - (labelWidth / 2);
                              return Positioned(
                                left: leftPos.clamp(40, containerWidth - labelWidth),
                                top: 0,
                                child: SizedBox(
                                  width: labelWidth,
                                  child: Text(
                                    '₹${tier.incentiveAmount.toStringAsFixed(0)}',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.textPrimary,
                                      letterSpacing: -0.55,
                                      height: 1.02,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 6),

                /// PROGRESS BAR WITH BIKE & MILESTONES
                Builder(
                  builder: (context) {
                    final containerWidth = MediaQuery.of(context).size.width -
                        (AppDimensions.getWidth(5) * 2);
                    final tiersWithEarnings = offers.first.tiers
                        .where((t) => t.minEarnings > 0)
                        .toList();
                    final tierCount = tiersWithEarnings.length;

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
                          // Background progress bar
                          Positioned(
                            top: 17,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: colorScheme.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          // Green fill
                          Positioned(
                            top: 17,
                            left: 0,
                            child: Container(
                              height: 6,
                              width: containerWidth * progressFill,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          // Bike icon at the green fill end
                          Positioned(
                            left: (containerWidth * progressFill - 16)
                                .clamp(0, containerWidth - 32),
                            top: -2,
                            child: Image.asset(
                              'assets/images/bike.png',
                              width: 32,
                              height: 32,
                            ),
                          ),
                          // Milestone icons (check/lock)
                          ...List.generate(tierCount, (i) {
                            final tier = tiersWithEarnings[i];
                            final isAchieved =
                                offers.first.myProgress.currentTier != null &&
                                    tier.tierLevel <=
                                        offers.first.myProgress.currentTier!
                                            .tierLevel;
                            final segmentWidth =
                                (containerWidth - 40) / tierCount;
                            final leftPos =
                                40 + (segmentWidth * i) + (segmentWidth / 2) - 9;

                            return Positioned(
                              left: leftPos.clamp(0, containerWidth - 18),
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

                const SizedBox(height: 6),

                /// EARNINGS LABELS
                if (offers.first.tiers.isNotEmpty)
                  Builder(
                    builder: (context) {
                      final containerWidth = MediaQuery.of(context).size.width -
                          (AppDimensions.getWidth(5) * 2);
                      final tiersWithEarnings = offers.first.tiers
                          .where((t) => t.minEarnings > 0)
                          .toList();
                      final tierCount = tiersWithEarnings.length;
                      const labelWidth = 50.0;

                      return SizedBox(
                        height: 20,
                        width: double.infinity,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // "Earn" label on the left
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Text(
                                'Earn',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: colorScheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.55,
                                  height: 1.02,
                                ),
                              ),
                            ),
                            // Tier earnings amounts
                            ...List.generate(tierCount, (i) {
                              final tier = tiersWithEarnings[i];
                              final segmentWidth =
                                  (containerWidth - 40) / tierCount;
                              final leftPos =
                                  40 + (segmentWidth * i) + (segmentWidth / 2) - (labelWidth / 2);
                              return Positioned(
                                left: leftPos.clamp(40, containerWidth - labelWidth),
                                top: 0,
                                child: SizedBox(
                                  width: labelWidth,
                                  child: Text(
                                    '₹${tier.minEarnings.toStringAsFixed(0)}',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: colorScheme.textSecondary,
                                      letterSpacing: -0.55,
                                      height: 1.02,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// ================= GET MONTH NAME =================
  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

/// ================= OFFER BANNER WIDGET =================
class OfferBanner extends StatelessWidget {
  final AppColorScheme colorScheme;
  final String date;
  final String title;
  final String timeSlot;
  final String amount;
  final String amountLabel;
  final bool isLive;

  const OfferBanner({
    super.key,
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
            child: _buildDateSection(),
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

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          date,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        if (isLive) _buildLiveBadge(),
      ],
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.success.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceElevated,
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
            'Live',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
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
            color: colorScheme.textPrimary,
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
            color: colorScheme.textSecondary,
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
            color: colorScheme.textPrimary,
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
            color: colorScheme.textSecondary,
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
