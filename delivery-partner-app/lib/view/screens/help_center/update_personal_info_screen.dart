import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/help_center/change_bank_details_screen.dart';
import 'package:zenfoo_partner/view/screens/help_center/change_driving_license_screen.dart';
import 'package:zenfoo_partner/view/screens/help_center/change_pan_details_screen.dart';
import 'package:zenfoo_partner/view/screens/help_center/change_phone_number_screen.dart';

class UpdatePersonalInfoScreen extends StatelessWidget {
  const UpdatePersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    final options = [
      _OptionItem(
        title: languageProvider.getTranslatedText('change_bank_details'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChangeBankDetailsScreen(),
          ),
        ),
      ),
      _OptionItem(
        title: languageProvider.getTranslatedText('change_driving_license'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChangeDrivingLicenseScreen(),
          ),
        ),
      ),
      _OptionItem(
        title: languageProvider.getTranslatedText('change_pan_details'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChangePanDetailsScreen(),
          ),
        ),
      ),
      _OptionItem(
        title: languageProvider.getTranslatedText('change_phone_number'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChangePhoneNumberScreen(),
          ),
        ),
      ),
    ];

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: languageProvider.getTranslatedText('help_center'),
            title: languageProvider
                .getTranslatedText('update_personal_information'),
            onBackPressed: () => Navigator.pop(context),
            showBackButton: true,
            showExitButton: false,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(
                  options.length,
                  (index) => _buildOptionItem(
                    context,
                    options[index],
                    colorScheme,
                    isLast: index == options.length - 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    _OptionItem item,
    AppColorScheme colorScheme, {
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        item.onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: colorScheme.border.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.43,
                ),
              ),
            ),
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
}

class _OptionItem {
  final String title;
  final VoidCallback onTap;

  _OptionItem({required this.title, required this.onTap});
}
