import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';

/// A single ready-made message a delivery partner can send with one tap.
///
/// [key] is a translation key resolved through [LanguageProvider] so the sent
/// text is always in the partner's own language.
class QuickChatSuggestion {
  final String key;

  const QuickChatSuggestion(this.key);
}

/// Quick messages offered in support chat — earnings & payout issues only.
const String kQuickChatCategoryTitleKey = 'qc_cat_earnings';

const List<QuickChatSuggestion> kQuickChatSuggestions = [
  QuickChatSuggestion('qc_payout_not_received'),
  QuickChatSuggestion('qc_incorrect_earning'),
  QuickChatSuggestion('qc_incentive_missing'),
  QuickChatSuggestion('qc_floating_cash_issue'),
];

/// Empty-chat state: a short greeting plus the quick messages.
///
/// Tapping a chip hands the translated text to [onSelect], which sends it.
class QuickChatEmptyState extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const QuickChatEmptyState({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// GREETING
          Center(
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.support_agent_outlined,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  languageProvider.getTranslatedText('how_can_we_help_you'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  languageProvider.getTranslatedText('pick_a_quick_message'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          /// EARNINGS & PAYOUT
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 16,
                color: colorScheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                languageProvider.getTranslatedText(kQuickChatCategoryTitleKey),
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in kQuickChatSuggestions)
                QuickChatChip(
                  label: languageProvider.getTranslatedText(suggestion.key),
                  colorScheme: colorScheme,
                  onTap: () => onSelect(
                    languageProvider.getTranslatedText(suggestion.key),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Horizontal strip of the same quick messages, shown just above the input
/// field once the conversation has started.
class QuickChatBar extends StatelessWidget {
  final ValueChanged<String> onSelect;
  final bool enabled;

  const QuickChatBar({
    super.key,
    required this.onSelect,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final suggestion in kQuickChatSuggestions) ...[
            QuickChatChip(
              label: languageProvider.getTranslatedText(suggestion.key),
              colorScheme: colorScheme,
              onTap: enabled
                  ? () => onSelect(
                        languageProvider.getTranslatedText(suggestion.key),
                      )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// Pill-shaped tappable quick message.
class QuickChatChip extends StatelessWidget {
  final String label;
  final AppColorScheme colorScheme;
  final VoidCallback? onTap;

  const QuickChatChip({
    super.key,
    required this.label,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.border.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
