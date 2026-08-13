import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/userOffersProvider.dart';
import 'package:project/screens/mainHomeScreen/homeScreen/widget/milestone_rewards_bottom_sheet.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

/// Progress toward the next milestone reward, inline on the home feed.
///
/// The same data already drives a bottom sheet thrown up once at launch — a
/// modal the customer dismisses before they have any context for it. A strip
/// they can see while shopping is what actually makes the reward motivating,
/// and it reads as an offer rather than an interruption. Tapping opens the
/// existing sheet, which is where claiming happens.
class RewardsProgressStrip extends StatelessWidget {
  const RewardsProgressStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<UserOffersProvider>(
      builder: (context, provider, _) {
        final next = provider.nextMilestone;
        if (next == null) return const SizedBox.shrink();

        final target = next.orderCount ?? 0;
        if (target <= 0) return const SizedBox.shrink();

        final done = provider.completedOrders.clamp(0, target);
        final remaining = provider.ordersUntilNextReward;
        final reward = (next.amount ?? '0').currency;
        // Treat "no orders left to place" as unlocked even if the backend
        // hasn't flipped canClaim yet, otherwise the strip reads
        // "0 more orders to unlock ₹100 off".
        final unlocked = (next.canClaim ?? false) || remaining <= 0;

        // Bottom gap lives inside the widget so that when there is no
        // milestone and this collapses, it takes its spacing with it.
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.lightImpact();
                MilestoneRewardsBottomSheet.show(context);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.card_giftcard_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            unlocked
                                ? '$reward reward ready to claim'
                                : remaining == 1
                                    ? '1 more order to unlock $reward off'
                                    : '$remaining more orders to unlock '
                                        '$reward off',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress is the whole point of the strip — the count on
                    // its own doesn't show how close they are.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: done / target,
                        minHeight: 6,
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$done of $target orders',
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
