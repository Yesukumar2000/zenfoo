import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenfoo_partner/models/referral_tracking_model.dart';
import 'package:zenfoo_partner/providers/referral_provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/shimmer_skeleton.dart';

class ReferralTrackingScreen extends StatefulWidget {
  const ReferralTrackingScreen({super.key});

  @override
  State<ReferralTrackingScreen> createState() => _ReferralTrackingScreenState();
}

class _ReferralTrackingScreenState extends State<ReferralTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferralProvider>().fetchReferralTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final provider = context.watch<ReferralProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          const AppHeader(
            label: 'Referrals',
            title: 'Referral Tracking',
            showBackButton: true,
            showExitButton: false,
          ),
          Expanded(
            child: provider.isLoading
                ? _buildShimmer(colorScheme)
                : provider.error != null && provider.referralData == null
                    ? _buildError(colorScheme, provider)
                    : provider.referralData != null
                        ? _buildContent(colorScheme, provider.referralData!)
                        : _buildEmpty(colorScheme),
          ),
        ],
      ),
    );
  }

  // ─── SHIMMER LOADING ──────────────────────────────────────────────────

  Widget _buildShimmer(AppColorScheme colorScheme) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Referral code card shimmer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.border),
              ),
              child: Column(
                children: [
                  ShimmerBox(
                    width: 140,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  ShimmerBox(
                    width: 100,
                    height: 32,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 12),
                  ShimmerBox(
                    width: 80,
                    height: 36,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats shimmer
            Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: i < 2 ? 8 : 0,
                      left: i > 0 ? 4 : 0,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.border),
                    ),
                    child: Column(
                      children: [
                        ShimmerBox(
                          width: 36,
                          height: 36,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        const SizedBox(height: 10),
                        ShimmerBox(
                          width: 50,
                          height: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        ShimmerBox(
                          width: 70,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Who referred card shimmer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: 130,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ShimmerBox(
                        width: 44,
                        height: 44,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(
                            width: 100,
                            height: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 6),
                          ShimmerBox(
                            width: 70,
                            height: 12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Referral list shimmer
            ShimmerBox(
              width: 120,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerBox(
                            width: 120,
                            height: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          ShimmerBox(
                            width: 60,
                            height: 24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ShimmerBox(
                        width: double.infinity,
                        height: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      ShimmerBox(
                        width: 90,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
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

  // ─── ERROR STATE ──────────────────────────────────────────────────────

  Widget _buildError(AppColorScheme colorScheme, ReferralProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              color: colorScheme.textTertiary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load referral data. Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textTertiary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.fetchReferralTracking(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────

  Widget _buildEmpty(AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedUserGroup,
              color: colorScheme.textTertiary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No Referrals Yet',
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your referral code with friends to start earning bonuses!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textTertiary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DATA CONTENT ─────────────────────────────────────────────────────

  Widget _buildContent(
      AppColorScheme colorScheme, ReferralTrackingModel data) {
    return RefreshIndicator(
      color: colorScheme.primary,
      onRefresh: () =>
          context.read<ReferralProvider>().fetchReferralTracking(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildReferralCodeCard(colorScheme, data.myReferralCode),
            const SizedBox(height: 16),
            _buildStatsRow(colorScheme, data),
            if (data.whoReferredMe != null) ...[
              const SizedBox(height: 16),
              _buildWhoReferredCard(colorScheme, data.whoReferredMe!),
            ],
            const SizedBox(height: 20),
            if (data.myReferrals.isNotEmpty) ...[
              Text(
                'Your Referrals',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...data.myReferrals
                  .map((r) => _buildReferralItemCard(colorScheme, r)),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── REFERRAL CODE CARD ───────────────────────────────────────────────

  void _shareReferralCode(String code) {
    HapticFeedback.lightImpact();
    try {
      Share.share(
        'Join Zenfoo as a delivery partner using my referral code: $code\n\n'
        'Download the app and start earning!\n\n'
        'https://play.google.com/store/apps/details?id=com.zenfoo.partner',
        subject: 'Join Zenfoo Partner - Referral Code: $code',
      );
    } catch (e) {
      debugPrint('Error sharing referral code: $e');
    }
  }

  void _copyReferralCode(AppColorScheme colorScheme, String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Referral code copied!',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: colorScheme.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildReferralCodeCard(AppColorScheme colorScheme, String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.12),
            colorScheme.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Your Referral Code',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Text(
              code,
              style: GoogleFonts.inter(
                color: colorScheme.primary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _copyReferralCode(colorScheme, code),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Copy',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _shareReferralCode(code),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedShare08,
                        color: colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Share',
                        style: GoogleFonts.inter(
                          color: colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── STATS ROW ────────────────────────────────────────────────────────

  Widget _buildStatsRow(
      AppColorScheme colorScheme, ReferralTrackingModel data) {
    return Row(
      children: [
        _buildStatCard(
          colorScheme,
          '${data.totalReferrals}',
          'Total\nReferrals',
          HugeIcons.strokeRoundedUserGroup,
          colorScheme.info,
          colorScheme.infoBg,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          colorScheme,
          '${data.bonusesEarned}',
          'Bonuses\nEarned',
          HugeIcons.strokeRoundedGift,
          colorScheme.success,
          colorScheme.successBg,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          colorScheme,
          '\u20B9${data.totalBonusAmount.toStringAsFixed(0)}',
          'Total\nBonus',
          HugeIcons.strokeRoundedMoney03,
          colorScheme.warning,
          colorScheme.warningBg,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    AppColorScheme colorScheme,
    String value,
    String label,
    dynamic icon,
    Color iconColor,
    Color iconBgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.border.withValues(alpha: 0.3),
          ),
          boxShadow: colorScheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: HugeIcon(icon: icon, color: iconColor, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WHO REFERRED ME ──────────────────────────────────────────────────

  Widget _buildWhoReferredCard(
      AppColorScheme colorScheme, WhoReferredMe referrer) {
    final isPaid = referrer.bonusStatus.toLowerCase() == 'paid';

    return Container(
      width: double.infinity,
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
          Text(
            'Referred By',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    referrer.referringDriverName.isNotEmpty
                        ? referrer.referringDriverName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      color: colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      referrer.referringDriverName,
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${referrer.referringDriverId}  •  ${referrer.myCompletedOrders} orders completed',
                      style: GoogleFonts.inter(
                        color: colorScheme.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPaid
                      ? colorScheme.success.withValues(alpha: 0.12)
                      : colorScheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  referrer.bonusStatus.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: isPaid ? colorScheme.success : colorScheme.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── REFERRAL ITEM CARD ───────────────────────────────────────────────

  Widget _buildReferralItemCard(
      AppColorScheme colorScheme, ReferralItem item) {
    final progress = (item.progressPercentage / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.3),
        ),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + badge row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Center(
                  child: Text(
                    item.referredDriverName.isNotEmpty
                        ? item.referredDriverName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.referredDriverName,
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'ID: ${item.referredDriverId}',
                      style: GoogleFonts.inter(
                        color: colorScheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: item.bonusEarned
                      ? colorScheme.success.withValues(alpha: 0.12)
                      : colorScheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.bonusEarned ? 'EARNED' : 'PENDING',
                  style: GoogleFonts.inter(
                    color: item.bonusEarned
                        ? colorScheme.success
                        : colorScheme.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                item.bonusEarned ? colorScheme.success : colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Progress label + bonus
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.completedOrders}/${item.requiredOrders} orders  •  ${item.progressPercentage.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  color: colorScheme.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\u20B9${item.bonusAmount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  color: item.bonusEarned
                      ? colorScheme.success
                      : colorScheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
