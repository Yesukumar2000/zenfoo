import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/userOffersProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/models/user_offers.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({Key? key}) : super(key: key);

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      context.read<UserOffersProvider>().fetchUserOffers(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: "",
          title: getTranslatedValue(context, 'your_rewards'),
          showBackButton: true,
        ),
      ),
      body: Consumer<UserOffersProvider>(
        builder: (context, provider, _) {
          if (provider.state == UserOffersState.loading) {
            return _buildLoadingState(colorScheme);
          }

          if (provider.state == UserOffersState.error) {
            return _buildErrorState(provider.message, colorScheme);
          }

          return Column(
            children: [
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Section
                      if (provider.banners.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: provider.banners.first.imageUrl ?? "",
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: double.infinity,
                                height: 160,
                                color: colorScheme.surfaceVariant,
                              ),
                              errorWidget: (context, url, error) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),

                      // Progress Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          getTranslatedValue(
                                  context, 'complete_orders_unlock_reward')
                              .replaceAll('{orderCount}',
                                  '${provider.nextMilestone?.orderCount ?? 0}')
                              .replaceAll('{amount}',
                                  '${provider.nextMilestone?.amount ?? "0"}'),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),

                      // Milestone Progress Indicators
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount:
                              (provider.offersData?.lastMilestone?.orderCount ??
                                  0),
                          itemBuilder: (context, index) {
                            final orderNumber = index + 1;
                            final completedOrders = provider.completedOrders;
                            final isCompleted = orderNumber <= completedOrders;

                            // Find milestone where completing it unlocks offer at THIS position
                            // Example: order_count=2 milestone shows offer at position 3
                            // When user completes 2 orders, on order #3 they see "Free up to ₹50"
                            Milestone? milestoneForOffer;
                            for (var m in provider.milestones) {
                              if ((m.orderCount ?? 0) + 1 == orderNumber) {
                                milestoneForOffer = m;
                                break;
                              }
                            }

                            // Check if this exact order number completes a milestone
                            final exactMilestone =
                                provider.milestones.firstWhere(
                              (m) => m.orderCount == orderNumber,
                              orElse: () => Milestone(),
                            );

                            final hasOfferHere = milestoneForOffer != null &&
                                milestoneForOffer.amount != null &&
                                milestoneForOffer.amount!.isNotEmpty;

                            // Show checkmark if this order number completed a milestone
                            final showCheckmark =
                                exactMilestone.isClaimed ?? false;

                            return Padding(
                              padding: EdgeInsets.only(
                                right: hasOfferHere ? 14 : 14,
                                left: index == 0 ? 0 : 0,
                              ),
                              child: hasOfferHere
                                  ? // Show offer amount instead of circle
                                  Container(
                                      width: 57,
                                      height: 70,
                                      // decoration: BoxDecoration(
                                      //   color: Colors.white,
                                      //   borderRadius: BorderRadius.circular(12),
                                      //   boxShadow: [
                                      //     BoxShadow(
                                      //       color: Colors.black.withValues(alpha: 0.1),
                                      //       blurRadius: 8,
                                      //       offset: const Offset(0, 2),
                                      //     ),
                                      //   ],
                                      // ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.card_giftcard,
                                            color: colorScheme.textPrimary,
                                            size: 20,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            getTranslatedValue(
                                                context, 'free_up_to'),
                                            style: GoogleFonts.inter(
                                              color: colorScheme.textPrimary,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              height: 1.2,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(
                                            '₹${milestoneForOffer.amount ?? "0"}',
                                            style: GoogleFonts.inter(
                                              color: colorScheme.textPrimary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              height: 1.2,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  : // Show circle with number/checkmark
                                  Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? const Color(0xFF9AC444)
                                            : const Color(0xFF9D9898),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: showCheckmark
                                            ? Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 20,
                                              )
                                            : Text(
                                                orderNumber.toString(),
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1,
                                                ),
                                              ),
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Unlocked Rewards Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(
                          getTranslatedValue(context, 'unlocked_rewards'),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),

                      // Claimed Milestones Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 160 / 180,
                          ),
                          itemCount: provider.claimedMilestones.length,
                          itemBuilder: (context, index) {
                            final claimed = provider.claimedMilestones[index];
                            return _RewardCard(
                              orderCount: claimed.milestoneOrderCount,
                              amount: claimed.rewardAmount ?? "0",
                              colorScheme: colorScheme,
                              claimableBannerUrl: provider.claimableBannerUrl,
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(dynamic colorScheme) {
    return Column(
      children: [
        AppHeader(
          label: "",
          title: getTranslatedValue(context, 'your_rewards'),
          showBackButton: true,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner shimmer
                _ShimmerBanner(),
                const SizedBox(height: 24),

                // Progress header shimmer
                _ShimmerBox(width: 280, height: 20, colorScheme: colorScheme),
                const SizedBox(height: 16),

                // Milestone indicators shimmer
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 8,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      return _ShimmerCircle(size: 44, colorScheme: colorScheme);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Section title shimmer
                _ShimmerBox(width: 180, height: 20, colorScheme: colorScheme),
                const SizedBox(height: 12),

                // Reward cards grid shimmer
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 160 / 180,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return _ShimmerRewardCard();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message, dynamic colorScheme) {
    return Column(
      children: [
        AppHeader(
          label: "",
          title: getTranslatedValue(context, 'your_rewards'),
          showBackButton: true,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.2),
                        width: 6,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.error_outline,
                        size: 56,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    getTranslatedValue(context, 'something_went_wrong'),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message.isEmpty
                        ? getTranslatedValue(context, 'failed_to_load_rewards')
                        : message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Shimmer Components
class _ShimmerBanner extends StatefulWidget {
  const _ShimmerBanner({Key? key}) : super(key: key);

  @override
  State<_ShimmerBanner> createState() => _ShimmerBannerState();
}

class _ShimmerBannerState extends State<_ShimmerBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.surfaceVariant,
                colorScheme.surfaceVariant.withValues(alpha: 0.5),
                colorScheme.surfaceVariant,
              ],
              stops: [
                _animation.value - 1,
                _animation.value,
                _animation.value + 1,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final dynamic colorScheme;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.colorScheme,
    Key? key,
  }) : super(key: key);

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.colorScheme.surfaceVariant,
                widget.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                widget.colorScheme.surfaceVariant,
              ],
              stops: [
                _animation.value - 1,
                _animation.value,
                _animation.value + 1,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerCircle extends StatefulWidget {
  final double size;
  final dynamic colorScheme;

  const _ShimmerCircle({
    required this.size,
    required this.colorScheme,
    Key? key,
  }) : super(key: key);

  @override
  State<_ShimmerCircle> createState() => _ShimmerCircleState();
}

class _ShimmerCircleState extends State<_ShimmerCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.colorScheme.surfaceVariant,
                widget.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                widget.colorScheme.surfaceVariant,
              ],
              stops: [
                _animation.value - 1,
                _animation.value,
                _animation.value + 1,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerRewardCard extends StatefulWidget {
  const _ShimmerRewardCard({Key? key}) : super(key: key);

  @override
  State<_ShimmerRewardCard> createState() => _ShimmerRewardCardState();
}

class _ShimmerRewardCardState extends State<_ShimmerRewardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GradientBorderCard(
          width: 160,
          height: 180,
          borderRadius: 18,
          gradient: colorScheme.cardGradient,
          borderGradient: colorScheme.borderGradient,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner shimmer
              Container(
                width: 160,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      colorScheme.surfaceVariant,
                      colorScheme.surfaceVariant.withValues(alpha: 0.5),
                      colorScheme.surfaceVariant,
                    ],
                    stops: [
                      _animation.value - 1,
                      _animation.value,
                      _animation.value + 1,
                    ].map((e) => e.clamp(0.0, 1.0)).toList(),
                  ),
                ),
              ),
              // Content shimmer
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                colorScheme.surfaceVariant,
                                colorScheme.surfaceVariant
                                    .withValues(alpha: 0.5),
                                colorScheme.surfaceVariant,
                              ],
                              stops: [
                                _animation.value - 1,
                                _animation.value,
                                _animation.value + 1,
                              ].map((e) => e.clamp(0.0, 1.0)).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 90,
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                colorScheme.surfaceVariant,
                                colorScheme.surfaceVariant
                                    .withValues(alpha: 0.5),
                                colorScheme.surfaceVariant,
                              ],
                              stops: [
                                _animation.value - 1,
                                _animation.value,
                                _animation.value + 1,
                              ].map((e) => e.clamp(0.0, 1.0)).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 11,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            colorScheme.surfaceVariant,
                            colorScheme.surfaceVariant.withValues(alpha: 0.5),
                            colorScheme.surfaceVariant,
                          ],
                          stops: [
                            _animation.value - 1,
                            _animation.value,
                            _animation.value + 1,
                          ].map((e) => e.clamp(0.0, 1.0)).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 110,
                      height: 11,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            colorScheme.surfaceVariant,
                            colorScheme.surfaceVariant.withValues(alpha: 0.5),
                            colorScheme.surfaceVariant,
                          ],
                          stops: [
                            _animation.value - 1,
                            _animation.value,
                            _animation.value + 1,
                          ].map((e) => e.clamp(0.0, 1.0)).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RewardCard extends StatelessWidget {
  final int orderCount;
  final String amount;
  final dynamic colorScheme;
  final String claimableBannerUrl;

  const _RewardCard({
    required this.orderCount,
    required this.amount,
    required this.colorScheme,
    required this.claimableBannerUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBorderCard(
      width: 160,
      height: 180,
      borderRadius: 18,
      gradient: colorScheme.cardGradient,
      borderGradient: colorScheme.borderGradient,
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image Section with Badges
          SizedBox(
            // width: 160,
            height: 90,
            child: Stack(
              children: [
                // Banner Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: claimableBannerUrl,
                    // width: 160,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 160,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.surfaceVariant,
                            colorScheme.surfaceVariant.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => imgErrorWidget(width: 160, height: 90, icon: Icons.card_giftcard_rounded),
                  ),
                ),
                // Order Count Badge (Top Left)
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.border,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          orderCount.toString(),
                          style: GoogleFonts.inter(
                            color: colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.shopping_bag_rounded,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                // Claimed Badge (Bottom Left)
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.success,
                          colorScheme.success.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.success.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          getTranslatedValue(context, 'claimed_badge'),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.savings_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              getTranslatedValue(context, 'saved_amount').replaceAll('{amount}', amount),
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        getTranslatedValue(context, 'earned_reward_description')
                            .replaceAll('{amount}', amount)
                            .replaceAll('{orderCount}', '$orderCount'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
