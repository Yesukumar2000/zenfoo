import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/user_offers.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/provider/userOffersProvider.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/screens/rewardsScreen/rewards_screen.dart';

class MilestoneRewardsBottomSheet extends StatelessWidget {
  const MilestoneRewardsBottomSheet({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) async {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const MilestoneRewardsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<UserOffersProvider>(
      builder: (context, provider, _) {
        // Calculate progress
        final completedOrders = provider.completedOrders;
        final nextMilestone = provider.nextMilestone;
        final totalOrders = provider.offersData?.lastMilestone?.orderCount ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with close button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.card_giftcard_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Loyalty Rewards',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.textPrimary,
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your milestone progress',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.textSecondary,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: colorScheme.iconSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Milestone Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.border,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress Title
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Complete ${nextMilestone?.orderCount ?? 0} Orders, Unlock ₹${nextMilestone?.amount ?? "0"} OFF!',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.textPrimary,
                                    height: 1.4,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Milestone Progress Circles
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: (provider
                                      .offersData?.lastMilestone?.orderCount ??
                                  0),
                              itemBuilder: (context, index) {
                                final orderNumber = index + 1;
                                final completedOrders =
                                    provider.completedOrders;
                                final isCompleted =
                                    orderNumber <= completedOrders;

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

                                final hasOfferHere =
                                    milestoneForOffer != null &&
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
                                                'Free up to',
                                                style: GoogleFonts.inter(
                                                  color:
                                                      colorScheme.textPrimary,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.2,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                '₹${milestoneForOffer.amount ?? "0"}',
                                                style: GoogleFonts.inter(
                                                  color:
                                                      colorScheme.textPrimary,
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
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      height: 1,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // View All Rewards Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: gradientBtnWidget(
                        context,
                        20,
                        callback: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          // Navigator.pushNamed(context, );
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return MultiProvider(providers: [
                              ChangeNotifierProvider(
                                  create: (context) => UserOffersProvider()),
                            ], child: const RewardsScreen());
                          }));
                        },
                        otherWidgets: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'View All Rewards',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dismiss Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.border,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Maybe Later',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.textSecondary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      },
    );
  }
}
