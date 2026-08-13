import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/incentive_offer_model.dart';
import 'package:zenfoo_partner/providers/incentive_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/home/home_screen.dart';
import 'package:zenfoo_partner/view/screens/home/screens/offer_detail_screen.dart'
    hide OfferBanner;

class AllOffersScreen extends StatefulWidget {
  const AllOffersScreen({super.key});

  @override
  State<AllOffersScreen> createState() => _AllOffersScreenState();
}

class _AllOffersScreenState extends State<AllOffersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  int _selectedFilterIndex = 0; // 0=All, 1=This Week, 2=Next Week, 3=Select Date
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncentiveProvider>().getAllOffersGrouped();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final languageProvider = context.watch<LanguageProvider>();
    final incentiveProvider = context.watch<IncentiveProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: languageProvider.getTranslatedText('offers'),
            title: languageProvider.getTranslatedText('your_offers'),
            showBackButton: true,
            showExitButton: false,
          ),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _buildFilterChip(0, 'All', colorScheme),
                const SizedBox(width: 8),
                _buildFilterChip(1, 'This Week', colorScheme),
                const SizedBox(width: 8),
                _buildFilterChip(2, 'Next Week', colorScheme),
                const SizedBox(width: 8),
                _buildFilterChip(
                  3,
                  _selectedDate != null
                      ? DateFormat('dd MMM').format(_selectedDate!)
                      : 'Select Date',
                  colorScheme,
                  isDatePicker: true,
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(colorScheme, incentiveProvider, languageProvider),
          ),
        ],
      ),
    );
  }

  void _onFilterSelected(int index, AppColorScheme colorScheme) {
    if (index == 3) {
      // Select Date - show date picker
      _showDatePicker(colorScheme);
      return;
    }
    setState(() {
      _selectedFilterIndex = index;
      _selectedDate = null;
    });

    String? filter;
    switch (index) {
      case 1:
        filter = 'weekly';
        break;
      case 2:
        filter = 'next_week';
        break;
      default:
        filter = null;
    }
    context.read<IncentiveProvider>().getAllOffersGrouped(filter: filter);
  }

  Future<void> _showDatePicker(AppColorScheme colorScheme) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colorScheme.primary,
              onPrimary: Colors.white,
              surface: colorScheme.background,
              onSurface: colorScheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedFilterIndex = 3;
        _selectedDate = picked;
      });
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      context
          .read<IncentiveProvider>()
          .getAllOffersGrouped(filter: 'daily', date: dateStr);
    }
  }

  Widget _buildFilterChip(
    int index,
    String label,
    AppColorScheme colorScheme, {
    bool isDatePicker = false,
  }) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _onFilterSelected(index, colorScheme);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.border.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDatePicker && !isSelected) ...[
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: colorScheme.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : colorScheme.textSecondary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppColorScheme colorScheme, IncentiveProvider provider, LanguageProvider languageProvider) {
    if (provider.groupedOffersStatus == ApiStatus.loading) {
      return _buildShimmerLoading(colorScheme);
    }

    if (provider.groupedOffersStatus == ApiStatus.error) {
      return _buildErrorState(
          colorScheme,
          provider.groupedOffersError.isNotEmpty
              ? provider.groupedOffersError
              : languageProvider.getTranslatedText('failed_load_offers'));
    }

    final activeOffers = provider.groupedActiveOffers;

    if (activeOffers.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    return RefreshIndicator(
      color: colorScheme.primary,
      backgroundColor: colorScheme.cardBackground,
      onRefresh: () {
        String? filter;
        String? date;
        switch (_selectedFilterIndex) {
          case 1:
            filter = 'weekly';
            break;
          case 2:
            filter = 'next_week';
            break;
          case 3:
            filter = 'daily';
            date = _selectedDate != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                : null;
            break;
        }
        return provider.getAllOffersGrouped(filter: filter, date: date);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 20),
          _offersSection(
            context,
            colorScheme,
            activeOffers,
            provider.activeOffersState.status == ApiStatus.loading,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _offersSection(BuildContext context, AppColorScheme colorScheme,
      List<IncentiveOffer> offers, bool isLoading,
      {bool isExpired = false}) {
    // Debug logging
    debugPrint('🎨 UI: Building offers section');
    debugPrint('🎨 UI: Loading state: $isLoading');
    debugPrint('🎨 UI: Offers count: ${offers.length}');
    if (offers.isNotEmpty) {
      debugPrint('🎨 UI: First offer: ${offers.first.name}');
      debugPrint('🎨 UI: First offer active: ${offers.first.isActive}');
      debugPrint('🎨 UI: First offer tiers: ${offers.first.tiers.length}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// OFFER CARD

        ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: offers.length,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final offer = offers[index];
            if (isLoading) {
              return Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.border.withValues(alpha: 0.3),
                  ),
                  boxShadow: colorScheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildShimmerBox(140, 18, 4, colorScheme),
                        _buildShimmerBox(80, 28, 8, colorScheme),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: colorScheme.border.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),

                    // Content row with icon
                    Row(
                      children: [
                        _buildShimmerBox(40, 40, 10, colorScheme),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildShimmerBox(60, 12, 4, colorScheme),
                              const SizedBox(height: 6),
                              _buildShimmerBox(120, 20, 4, colorScheme),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bottom progress bar
                    _buildShimmerBox(double.infinity, 8, 4, colorScheme),
                  ],
                ),
              );
            } else if (offers.isEmpty) {
              return Container(
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
              );
            } else {
              return Container(
                padding: EdgeInsets.only(
                  top: AppDimensions.getHeight(1),
                  bottom: AppDimensions.getHeight(0.5),
                  left: AppDimensions.getWidth(3),
                  right: AppDimensions.getWidth(3),
                ),
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
                    /// OFFER BANNER
                    OfferBanner(
                      colorScheme: colorScheme,
                      date:
                          '${offer.startDate.day.toString().padLeft(2, '0')} ${_getMonthName(offer.startDate.month)}',
                      title: offer.name,
                      timeSlot: '${offer.daysRemaining} days left',
                      amount: offer.tiers.isNotEmpty
                          ? '₹${offer.tiers.last.incentiveAmount.toStringAsFixed(0)}'
                          : '₹0',
                      amountLabel: "Extra",
                      isLive: offer.isActive,
                    ),

                    const SizedBox(height: 18),

                    /// INCENTIVES ROW (positioned like home screen)
                    if (offer.tiers.isNotEmpty)
                      Builder(
                        builder: (context) {
                          final containerWidth =
                              MediaQuery.of(context).size.width -
                                  32 -
                                  (AppDimensions.getWidth(3) * 2);
                          return SizedBox(
                            height: 16,
                            width: double.infinity,
                            child: Stack(
                              children: offer.tiers.map(
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
                                      (tier.tierPercentage / 100)
                                          .clamp(0.0, 1.0);
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
                        final containerWidth =
                            MediaQuery.of(context).size.width -
                                32 -
                                (AppDimensions.getWidth(3) * 2);
                        final progressFill = (offer
                                    .myProgress.overallProgressPercentage /
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
                                          width:
                                              containerWidth * progressFill,
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
                              // Lock/check icons at milestones
                              ...offer.tiers.map((tier) {
                                if (tier.minEarnings == 0) {
                                  return const SizedBox.shrink();
                                }
                                final isAchieved =
                                    offer.myProgress.currentTier != null &&
                                        tier.tierLevel <=
                                            offer.myProgress.currentTier!
                                                .tierLevel;
                                final tierPos =
                                    (tier.tierPercentage / 100)
                                        .clamp(0.0, 1.0);
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
                                      isAchieved
                                          ? Icons.check
                                          : Icons.lock,
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

                    /// EARNINGS LABELS (positioned like home screen)
                    if (offer.tiers.isNotEmpty)
                      Builder(
                        builder: (context) {
                          final containerWidth =
                              MediaQuery.of(context).size.width -
                                  32 -
                                  (AppDimensions.getWidth(3) * 2);
                          return SizedBox(
                            height: 24,
                            width: double.infinity,
                            child: Stack(
                              children: offer.tiers.map((tier) {
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
                                    (tier.tierPercentage / 100)
                                        .clamp(0.0, 1.0);
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
                      "Conditions",
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (offer.description.isNotEmpty)
                      Text(
                        '•  ${offer.description}',
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
                    if (offer.conditions != null) ...[
                      if (offer.conditions!.minGigsRequired > 0)
                        Text(
                          '•  Minimum ${offer.conditions!.minGigsRequired} gigs required',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.textSecondary,
                            letterSpacing: -0.3,
                            height: 1.5,
                          ),
                        ),
                      if (offer.conditions!.maxGigsSkip > 0)
                        Text(
                          '•  Max ${offer.conditions!.maxGigsSkip} gigs skip allowed',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.textSecondary,
                            letterSpacing: -0.3,
                            height: 1.5,
                          ),
                        ),
                      if (offer.conditions!.maxOrdersCancel > 0)
                        Text(
                          '•  Max ${offer.conditions!.maxOrdersCancel} orders cancel allowed',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.textSecondary,
                            letterSpacing: -0.3,
                            height: 1.5,
                          ),
                        ),
                      if (offer.conditions!.loginMandatory)
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

                    /// VIEW DETAILS BUTTON
                    if (!isExpired)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OfferDetailsScreen(
                                offerId: offer.offerId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 43,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(120),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "View Details",
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }
          },
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

  Widget _buildShimmerLoading(AppColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 20),
        _buildShimmerBox(140, 20, 4, colorScheme),
        const SizedBox(height: 12),
        _buildShimmerOfferCard(colorScheme),
        _buildShimmerOfferCard(colorScheme),
      ],
    );
  }

  Widget _buildShimmerOfferCard(AppColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(
        vertical: AppDimensions.getHeight(1),
        horizontal: AppDimensions.getWidth(3),
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppDimensions.getWidth(3)),
            decoration: BoxDecoration(
              color: colorScheme.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildShimmerBox(60, 40, 8, colorScheme),
                _buildShimmerBox(120, 40, 8, colorScheme),
                _buildShimmerBox(50, 40, 8, colorScheme),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildShimmerBox(double.infinity, 8, 4, colorScheme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.border.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.card_giftcard,
                size: 40, color: colorScheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Text('No Offers Available',
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                  letterSpacing: -0.55,
                  height: 1.3)),
          const SizedBox(height: 8),
          Text('Check back later for exciting offers',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.textSecondary,
                  letterSpacing: -0.2,
                  height: 1.5),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppColorScheme colorScheme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.error_outline, size: 40, color: colorScheme.error),
          ),
          const SizedBox(height: 16),
          Text('Error Loading Offers',
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                  letterSpacing: -0.55,
                  height: 1.3)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.textSecondary,
                    letterSpacing: -0.2,
                    height: 1.5),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _onFilterSelected(_selectedFilterIndex,
                  context.read<ThemeProvider>().colorScheme);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: colorScheme.buttonShadow,
              ),
              child: Text('Retry',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.25,
                      height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}
