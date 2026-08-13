import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/helper/utils/generalMethods.dart';
import 'package:project/helper/utils/labelKeys.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

/// Appearance Selector Tile for Profile Screen
/// Displays current theme mode and allows users to change it
class AppearanceSelectorTile extends StatelessWidget {
  final app_theme.ThemeProvider themeProvider;

  const AppearanceSelectorTile({
    super.key,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final themeName = themeProvider.getThemeModeName(themeProvider.themeMode);
    final themeIcon = themeProvider.getThemeModeIcon(themeProvider.themeMode);
    final colorScheme = themeProvider.colorScheme;

    return Container(
      width: double.infinity,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: colorScheme.cardBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.border, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: colorScheme.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: icon + label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  themeIcon,
                  size: 20,
                  color: colorScheme.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                getTranslatedValue(context, appearanceLabel),
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          // Right: current theme mode + chevron
          Row(
            children: [
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: colorScheme.border,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: colorScheme.surfaceVariant,
                ),
                alignment: Alignment.center,
                child: Text(
                  themeName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: colorScheme.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
