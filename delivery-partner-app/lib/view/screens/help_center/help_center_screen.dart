import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/banner_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/home/widgets/home_banner_carousel.dart';
import 'package:zenfoo_partner/view/screens/help_center/rain_mode_activation_screen.dart';
import 'package:zenfoo_partner/view/screens/help_center/support_chat_screen.dart';
import 'package:zenfoo_partner/view/screens/help_center/update_personal_info_screen.dart';
import 'package:zenfoo_partner/view/screens/help_center/payout_issues_list_screen.dart';
import 'package:zenfoo_partner/view/screens/help_center/floating_cash_issues_list_screen.dart';
import 'package:zenfoo_partner/view/screens/help_center/duty_issues_list_screen.dart';
import 'package:zenfoo_partner/view/screens/emergency/emergency_support_screen.dart';

import 'order_earning_issues_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  late List<HelpCategoryItem> helpCategories;

  void _initializeCategories(
    AppColorScheme colorScheme,
    LanguageProvider languageProvider,
  ) {
    helpCategories = [
      HelpCategoryItem(
        title:
            languageProvider.getTranslatedText('update_personal_information'),
        icon: HugeIcons.strokeRoundedUserEdit01,
        description:
            languageProvider.getTranslatedText('help_with_updating_profile'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UpdatePersonalInfoScreen(),
          ),
        ),
      ),
      HelpCategoryItem(
        title: languageProvider.getTranslatedText('call_to_us'),
        icon: HugeIcons.strokeRoundedCall,
        description:
            languageProvider.getTranslatedText('get_direct_support_phone'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmergencySupportScreen(),
          ),
        ),
      ),
      HelpCategoryItem(
        title: languageProvider.getTranslatedText('chat_with_us'),
        icon: HugeIcons.strokeRoundedComment01,
        description:
            languageProvider.getTranslatedText('chat_with_support_team'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SupportChatScreen(),
            ),
          );
        },
      ),
      HelpCategoryItem(
        title: languageProvider.getTranslatedText('order_earning_issues'),
        icon: HugeIcons.strokeRoundedMoneyReceive01,
        description:
            languageProvider.getTranslatedText('resolve_earning_problems'),
      ),
      HelpCategoryItem(
        title: languageProvider.getTranslatedText('payout_issues'),
        icon: HugeIcons.strokeRoundedCreditCard,
        description:
            languageProvider.getTranslatedText('get_help_payment_issues'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PayoutIssuesListScreen(),
          ),
        ),
      ),
      HelpCategoryItem(
        title: languageProvider.getTranslatedText('floating_cash_issues'),
        icon: HugeIcons.strokeRoundedWallet01,
        description:
            languageProvider.getTranslatedText('resolve_wallet_problems'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FloatingCashIssuesListScreen(),
          ),
        ),
      ),
      HelpCategoryItem(
        title: languageProvider.getTranslatedText('duty_issues'),
        icon: HugeIcons.strokeRoundedClock02,
        description:
            languageProvider.getTranslatedText('help_shift_management'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DutyIssuesListScreen(),
          ),
        ),
      ),
      HelpCategoryItem(
        title: languageProvider.getTranslatedText('rain_mode_activation'),
        icon: HugeIcons.strokeRoundedCloudLittleRain,
        description:
            languageProvider.getTranslatedText('help_weather_features'),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const RainModeActivationScreen())),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    // Initialize categories with translated text
    _initializeCategories(colorScheme, languageProvider);

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // Header
          AppHeader(
            label: languageProvider.getTranslatedText('support'),
            title: languageProvider.getTranslatedText('help_center'),
            onBackPressed: () => Navigator.pop(context),
            showBackButton: true,
            showExitButton: false,
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic Banner
                  Consumer<BannerProvider>(
                    builder: (context, bannerProvider, _) {
                      if (bannerProvider.isLoading) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: AppDimensions.getHeight(14),
                              color: colorScheme.surface,
                            ),
                          ),
                        );
                      }
                      if (bannerProvider.hasError || !bannerProvider.hasData) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: HomeBannerCarousel(
                            banners: bannerProvider.banners,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      languageProvider.getTranslatedText('solve_your_issues'),
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Help Categories List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        helpCategories.length,
                        (index) => _buildHelpCategoryItem(
                          context,
                          helpCategories[index],
                          colorScheme,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCategoryItem(
    BuildContext context,
    HelpCategoryItem item,
    AppColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _onHelpCategoryTap(context, item);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: colorScheme.border.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.border.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: HugeIcon(
                  icon: item.icon,
                  color: colorScheme.textSecondary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Title
            Expanded(
              child: Text(
                item.title,
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.textSecondary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _onHelpCategoryTap(BuildContext context, HelpCategoryItem item) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    // Call the custom onTap callback if defined
    if (item.onTap != null) {
      item.onTap!();
    } else {
      // Default: show help bottom sheet with contact options
      _showDefaultHelpBottomSheet(context, item, colorScheme);
    }
  }

  void _showDefaultHelpBottomSheet(
    BuildContext context,
    HelpCategoryItem item,
    AppColorScheme colorScheme,
  ) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const OrderEarningIssuesScreen()));
  }
}

class HelpCategoryItem {
  final String title;
  final dynamic icon; // Can be IconData or HugeIcons
  final String description;
  final bool isMaterialIcon;
  final VoidCallback? onTap;

  HelpCategoryItem({
    required this.title,
    required this.icon,
    required this.description,
    this.isMaterialIcon = false,
    this.onTap,
  });
}
