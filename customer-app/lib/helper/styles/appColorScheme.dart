import 'package:flutter/material.dart';

/// App Color Scheme - Centralized color management for light and dark themes
/// This provides easy access to theme-aware colors throughout the app
class AppColorScheme {
  final bool isDark;

  AppColorScheme({required this.isDark});

  // Primary Brand Colors
  Color get primary => const Color(0xFF9AC444);
  Color get primaryLight => const Color(0xFFBDE17E);
  Color get primaryDark => const Color(0xFF7DA635);

  // Background Colors
  Color get background => isDark ? const Color(0xFF0F1419) : Colors.white;
  Color get surface => isDark ? const Color(0xFF1A1F26) : Colors.white;
  Color get surfaceVariant =>
      isDark ? const Color(0xFF242B33) : const Color(0xFFF5F5F5);

  // Text Colors
  Color get textPrimary =>
      isDark ? const Color(0xFFE8EAED) : const Color(0xFF111827);
  Color get textSecondary =>
      isDark ? const Color(0xFFBDC1C6) : const Color(0xFF6B7280);
  Color get textTertiary =>
      isDark ? const Color(0xFF9AA0A6) : const Color(0xFF9E9E9E);
  Color get textDisabled =>
      isDark ? const Color(0xFF5F6368) : const Color(0xFFBDBDBD);

  // Border Colors
  Color get border =>
      isDark ? const Color(0xFF2D3339) : const Color(0xFFF0F0F0);
  Color get borderStrong =>
      isDark ? const Color(0xFF3C4248) : const Color(0xFFE0E0E0);

  // Pack-size field on the product card — the "QTY: 500 g" selector.
  //
  // Deliberately the one blue in the card: it is the only control in a stack
  // of otherwise static text, and the tint is what separates it from the price
  // and name above and below it. Kept here rather than hardcoded in the card so
  // it survives theming — the dark values are muted so the field reads as a
  // control without glowing.
  Color get packSizeFieldBackground =>
      isDark ? const Color(0xFF20263A) : const Color(0xFFEDF0FD);
  Color get packSizeFieldBorder =>
      isDark ? const Color(0xFF49528C) : const Color(0xFF9FAEEC);

  // Icon Colors
  Color get iconPrimary =>
      isDark ? const Color(0xFFE8EAED) : const Color(0xFF111827);
  Color get iconSecondary =>
      isDark ? const Color(0xFF9AA0A6) : const Color(0xFF6B7280);
  Color get iconDisabled =>
      isDark ? const Color(0xFF5F6368) : const Color(0xFFBDBDBD);

  // Action Colors
  Color get success => const Color(0xFF10B981);
  Color get warning => const Color(0xFFF59E0B);
  Color get error => const Color(0xFFEF4444);
  Color get info => const Color(0xFF3B82F6);

  // Special Colors
  Color get overlay => isDark
      ? Colors.black.withValues(alpha: 0.7)
      : Colors.black.withValues(alpha: 0.5);
  Color get overlayLight => isDark
      ? Colors.black.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.2);
  Color get divider =>
      isDark ? const Color(0xFF2D3339) : const Color(0xFFE5E7EB);

  // Shimmer Loading Colors
  Color get shimmerBase =>
      isDark ? const Color(0xFF2D3339) : const Color(0xFFE8E8E8);

  Color get shimmerHighlight =>
      isDark ? const Color(0xFF3C4248) : const Color(0xFFF5F5F5);

  Color get shimmerContent =>
      isDark ? const Color(0xFF242B33) : const Color(0xFFF0F0F0);

  // Card Specific Colors
  Color get cardBackground => isDark ? const Color(0xFF1A1F26) : Colors.white;
  Color get cardShadowColor => isDark
      ? Colors.black.withValues(alpha: 0.2)
      : Colors.black.withValues(alpha: 0.04);

  // Input Colors
  Color get inputBackground => isDark ? const Color(0xFF242B33) : Colors.white;
  Color get inputBorder =>
      isDark ? const Color(0xFF3C4248) : const Color(0xFFE0E0E0);
  Color get inputBorderFocused => primary;
  Color get inputPlaceholder =>
      isDark ? const Color(0xFF9AA0A6) : const Color(0xFFBDBDBD);

  // Button Colors
  Color get buttonPrimaryBackground => primary;
  Color get buttonPrimaryText => Colors.white;
  Color get buttonSecondaryBackground =>
      isDark ? const Color(0xFF242B33) : const Color(0xFFF5F5F5);
  Color get buttonSecondaryText =>
      isDark ? const Color(0xFFE8EAED) : const Color(0xFF111827);
  Color get buttonDisabledBackground =>
      isDark ? const Color(0xFF2D3339) : const Color(0xFFE0E0E0);
  Color get buttonDisabledText =>
      isDark ? const Color(0xFF5F6368) : const Color(0xFF9E9E9E);

  // Status Colors (for orders)
  Color get statusPendingBg =>
      isDark ? const Color(0xFF2C2416) : const Color(0xFFFFF8EC);
  Color get statusPendingText =>
      isDark ? const Color(0xFFFDB022) : const Color(0xFFDD6B20);

  Color get statusReceivedBg =>
      isDark ? const Color(0xFF0F2D2C) : const Color(0xFFF1FFFC);
  Color get statusReceivedText =>
      isDark ? const Color(0xFF4FD1C5) : const Color(0xFF319795);

  Color get statusProcessedBg =>
      isDark ? const Color(0xFF2A1A39) : const Color(0xFFFBF8FF);
  Color get statusProcessedText =>
      isDark ? const Color(0xFFB794F4) : const Color(0xFF805AD5);

  Color get statusShippedBg =>
      isDark ? const Color(0xFF1A2C3D) : const Color(0xFFF2FAFF);
  Color get statusShippedText =>
      isDark ? const Color(0xFF63B3ED) : const Color(0xFF3182CE);

  Color get statusDeliveredBg =>
      isDark ? const Color(0xFF1A2F22) : const Color(0xFFF0FFF4);
  Color get statusDeliveredText =>
      isDark ? const Color(0xFF68D391) : const Color(0xFF38A169);

  Color get statusCancelledBg =>
      isDark ? const Color(0xFF3D1A1A) : const Color(0xFFFFF5F5);
  Color get statusCancelledText =>
      isDark ? const Color(0xFFFB7185) : const Color(0xFFE53E3E);

  // App Bar Colors
  Color get appBarBackground =>
      isDark ? const Color(0xFF1A1F26) : const Color(0xFF9AC444);
  Color get appBarText =>
      isDark ? const Color(0xFFE8EAED) : const Color(0xFF111827);
  Color get appBarIcon => isDark ? const Color(0xFFE8EAED) : Colors.black;

  // Bottom Navigation Colors
  Color get bottomNavBackground =>
      isDark ? const Color(0xFF1A1F26) : Colors.white;
  Color get bottomNavSelected => primary;
  Color get bottomNavUnselected =>
      isDark ? const Color(0xFF9AA0A6) : const Color(0xFF6B7280);

  // Gradient Colors
  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryLight, primary],
      );

  LinearGradient get surfaceGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(
                    0xFF5A7828), // Darker, more saturated green for dark mode
                background,
              ]
            : [
                primary,
                background,
              ],
      );

  // ---------------------------------------------------------------------
  // Decorative gradients (profile / card surfaces)
  //
  // These are intentionally low-contrast: they read as a soft wash on the
  // surface rather than a coloured block, so text keeps its contrast ratio.
  // ---------------------------------------------------------------------

  /// Backdrop behind scrollable content. Fades a faint brand tint into the
  /// plain background so the top of the list doesn't sit on flat white.
  LinearGradient get screenGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF151B22), background]
            : [const Color(0xFFF4FAE9), background],
        stops: const [0, 0.45],
      );

  /// Default card fill — replaces a flat [cardBackground].
  LinearGradient get cardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF1E242C), const Color(0xFF171C22)]
            : [Colors.white, const Color(0xFFF8FCF1)],
      );

  /// Emphasised card fill for hero blocks (profile header, wallet, banners).
  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF26321C), const Color(0xFF1A1F26)]
            : [const Color(0xFFECF7D9), Colors.white],
      );

  /// Hairline card border painted as a gradient — brand tint at the top-left
  /// corner fading into the neutral border colour.
  LinearGradient get borderGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                primary.withValues(alpha: 0.35),
                const Color(0xFF2D3339),
              ]
            : [
                primary.withValues(alpha: 0.45),
                const Color(0xFFE9F1DA),
              ],
      );

  /// Stronger version of [borderGradient] for hero blocks.
  LinearGradient get borderGradientStrong => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                primary.withValues(alpha: 0.6),
                primary.withValues(alpha: 0.12),
              ]
            : [
                primary.withValues(alpha: 0.75),
                primary.withValues(alpha: 0.15),
              ],
      );

  /// Small rounded tiles that hold a row icon.
  LinearGradient get iconTileGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF2B3421), const Color(0xFF242B33)]
            : [const Color(0xFFF0F8E1), const Color(0xFFF4F5F2)],
      );

  /// Ring drawn around the profile avatar.
  LinearGradient get avatarRingGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryLight, primary, primaryDark],
      );

  /// Filled brand buttons / active toggles.
  LinearGradient get buttonGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryLight, primaryDark],
      );

  /// Short accent bar placed before a section heading.
  LinearGradient get accentBarGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primaryLight, primaryDark],
      );

  // Shadow Definition
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.4)
              : primary.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // Helper method to get color with opacity
  Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // Create ThemeData for MaterialApp
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: cardBackground,
      dividerColor: divider,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: primaryLight,
        onSecondary: textPrimary,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarText,
        elevation: 0,
        iconTheme: IconThemeData(color: appBarIcon),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorderFocused, width: 2),
        ),
        hintStyle: TextStyle(color: inputPlaceholder),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bottomNavBackground,
        selectedItemColor: bottomNavSelected,
        unselectedItemColor: bottomNavUnselected,
        elevation: 8,
      ),
      iconTheme: IconThemeData(color: iconPrimary),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        bodySmall: TextStyle(color: textTertiary),
      ),
    );
  }
}
