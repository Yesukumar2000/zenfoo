import 'package:flutter/material.dart';

/// App Color Scheme for Light and Dark modes
class AppColorScheme {
  // Primary colors
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  // Text colors
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  // Background colors
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceContainer;
  final Color surfaceVariant;

  // Border colors
  final Color border;
  final Color borderStrong;
  final Color divider;

  // Status colors
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  // Status backgrounds
  final Color successBg;
  final Color warningBg;
  final Color errorBg;
  final Color infoBg;

  // Input colors
  final Color inputBackground;
  final Color inputBorder;
  final Color inputPlaceholder;
  final Color inputFocusBorder;

  // Icon colors
  final Color iconPrimary;
  final Color iconSecondary;
  final Color iconDisabled;

  // Button colors
  final Color buttonPrimaryBg;
  final Color buttonPrimaryText;
  final Color buttonSecondaryBg;
  final Color buttonSecondaryText;
  final Color buttonDisabledBg;
  final Color buttonDisabledText;

  // Card colors
  final Color cardBackground;
  final Color cardBorder;
  final List<BoxShadow> cardShadow;

  // Button colors
  final List<BoxShadow> buttonShadow;

  // Overlay colors
  final Color overlay;
  final Color scrim;

  const AppColorScheme({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceContainer,
    required this.surfaceVariant,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.successBg,
    required this.warningBg,
    required this.errorBg,
    required this.infoBg,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputPlaceholder,
    required this.inputFocusBorder,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.iconDisabled,
    required this.buttonPrimaryBg,
    required this.buttonPrimaryText,
    required this.buttonSecondaryBg,
    required this.buttonSecondaryText,
    required this.buttonDisabledBg,
    required this.buttonDisabledText,
    required this.cardBackground,
    required this.cardBorder,
    required this.cardShadow,
    required this.overlay,
    required this.scrim,
    required this.buttonShadow,
  });

  /// Light Color Scheme
  static const AppColorScheme light = AppColorScheme(
    // Primary colors
    primary: Color(0xFF9AC444), // Lime green accent
    primaryLight: Color(0xFFB8DC6F),
    primaryDark: Color(0xFF7BA82E),

    // Text colors - Apple-inspired hierarchy
    textPrimary: Color(0xFF000000), // True black for maximum contrast
    textSecondary: Color(0xFF3C3C43), // Apple's secondary label
    textTertiary: Color(0xFF8E8E93), // Apple's tertiary label
    textDisabled: Color(0xFFC7C7CC), // Apple's quaternary label

    // Background colors - Clean, minimal Apple aesthetic
    background: Color(0xFFFFFFFF), // Pure white like iOS
    surface: Color(0xFFFFFFFF), // Pure white
    surfaceElevated: Color(0xFFFAFAFA), // Very subtle elevation
    surfaceContainer: Color(0xFFF2F2F7), // Apple's grouped background
    surfaceVariant: Color(0xFFE5E5EA), // Apple's separator color

    // Border colors - Refined and subtle
    border: Color(0xFFE5E5EA), // Apple's separator
    borderStrong: Color(0xFFC6C6C8), // Stronger separator
    divider: Color(0xFFEBEBF0), // Ultra-light divider

    // Status colors - Vibrant but refined
    success: Color(0xFF34C759), // Apple's green
    warning: Color(0xFFFF9500), // Apple's orange
    error: Color(0xFFFF3B30), // Apple's red
    info: Color(0xFF007AFF), // Apple's blue

    // Status backgrounds - Subtle tinted backgrounds
    successBg: Color(0xFFE8F8EC),
    warningBg: Color(0xFFFFF4E6),
    errorBg: Color(0xFFFFECEB),
    infoBg: Color(0xFFE6F2FF),

    // Input colors - Premium feel
    inputBackground: Color(0xFFF2F2F7),
    inputBorder: Color(0xFFE5E5EA),
    inputPlaceholder: Color(0xFF8E8E93),
    inputFocusBorder: Color(0xFF9AC444),

    // Icon colors - Refined hierarchy
    iconPrimary: Color(0xFF000000),
    iconSecondary: Color(0xFF8E8E93),
    iconDisabled: Color(0xFFC7C7CC),

    // Button colors
    buttonPrimaryBg: Color(0xFF9AC444),
    buttonPrimaryText: Color(0xFFFFFFFF),
    buttonSecondaryBg: Color(0xFFF2F2F7),
    buttonSecondaryText: Color(0xFF000000),
    buttonDisabledBg: Color(0xFFF2F2F7),
    buttonDisabledText: Color(0xFFC7C7CC),

    // Card colors - Premium shadows
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE5E5EA),
    cardShadow: [
      BoxShadow(
        color: Color(0x08000000), // Very subtle shadow
        blurRadius: 20,
        offset: Offset(0, 4),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x05000000), // Layered shadow for depth
        blurRadius: 8,
        offset: Offset(0, 1),
        spreadRadius: 0,
      ),
    ],
    buttonShadow: [
      BoxShadow(
        color: Color(0x20000000), // Subtle elevation
        blurRadius: 12,
        offset: Offset(0, 4),
        spreadRadius: -2,
      ),
    ],

    // Overlay colors
    overlay: Color(0x66000000), // 40% opacity
    scrim: Color(0xB3000000), // 70% opacity
  );

  /// Dark Color Scheme - Modern Material You
  /// Optimized for OLED displays with careful contrast ratios (4.5:1 minimum)
  static const AppColorScheme dark = AppColorScheme(
    // Primary colors - Lime green accent (same as light mode)
    primary: Color(0xFF9AC444), // Lime green primary
    primaryLight: Color(0xFFB8DC6F), // Lighter lime green
    primaryDark: Color(0xFF7BA82E), // Darker lime green

    // Text colors - Optimized for dark mode readability
    // Avoid pure white (#FFFFFF) for reduced eye strain
    textPrimary: Color(0xFFF5F5F5), // Soft white (#F5F5F5)
    textSecondary: Color(0xFFA0A0A0), // Medium gray (#A0A0A0)
    textTertiary: Color(0xFF888888), // Muted gray
    textDisabled: Color(0xFF6B6B6B), // Disabled gray (#6B6B6B)

    // Background colors - Layered dark surfaces
    // Base: #0D0D0D (very dark), surface levels build up from there
    background: Color(0xFF0D0D0D), // Base background (#0D0D0D)
    surface: Color(0xFF1E1E1E), // Surface level 1 (#1E1E1E)
    surfaceElevated: Color(0xFF2A2A2A), // Surface level 2 (#2A2A2A)
    surfaceContainer: Color(0xFF333333), // Elevated surface (#333333)
    surfaceVariant: Color(0xFF252525), // Variant surface

    // Border colors - Refined with opacity for subtlety
    // Using rgba(255, 255, 255, opacity) approach
    border: Color(0x1FFFFFFF), // Subtle border (~rgba(255, 255, 255, 0.12))
    borderStrong: Color(0x33FFFFFF), // Default border (~rgba(255, 255, 255, 0.20))
    divider: Color(0x14FFFFFF), // Subtle divider (~rgba(255, 255, 255, 0.08))

    // Status colors - Vibrant but dark-mode optimized
    // High contrast for accessibility
    success: Color(0xFF22C55E), // Green (#22C55E)
    warning: Color(0xFFF59E0B), // Amber/Orange (#F59E0B)
    error: Color(0xFFEF4444), // Red (#EF4444)
    info: Color(0xFF3B82F6), // Blue (#3B82F6)

    // Status backgrounds - Subtle colored surfaces
    // Provide context without being too vibrant
    successBg: Color(0xFF1B3A24), // Dark green background
    warningBg: Color(0xFF3A2F1A), // Dark amber background
    errorBg: Color(0xFF3A1E1C), // Dark red background
    infoBg: Color(0xFF1A2A3A), // Dark blue background

    // Input colors - Premium dark feel
    // Consistent with surface hierarchy
    inputBackground: Color(0xFF1E1E1E), // Input surface (#1E1E1E)
    inputBorder: Color(0x1FFFFFFF), // Subtle input border
    inputPlaceholder: Color(0xFFA0A0A0), // Placeholder text (#A0A0A0)
    inputFocusBorder: Color(0xFF9AC444), // Focus state uses primary lime green

    // Icon colors - Refined hierarchy
    // High contrast for visibility
    iconPrimary: Color(0xFFF5F5F5), // Primary icons (#F5F5F5)
    iconSecondary: Color(0xFFA0A0A0), // Secondary icons (#A0A0A0)
    iconDisabled: Color(0xFF6B6B6B), // Disabled icons (#6B6B6B)

    // Button colors - Clear visual hierarchy
    buttonPrimaryBg: Color(0xFF9AC444), // Lime green primary button
    buttonPrimaryText: Color(0xFF000000), // Black text on lime green for contrast
    buttonSecondaryBg: Color(0xFF2A2A2A), // Dark secondary button
    buttonSecondaryText: Color(0xFFF5F5F5), // Light text on dark
    buttonDisabledBg: Color(0xFF1E1E1E), // Disabled button surface
    buttonDisabledText: Color(0xFF6B6B6B), // Disabled button text

    // Card colors - Depth through color and shadow
    cardBackground: Color(0xFF1E1E1E), // Card surface (#1E1E1E)
    cardBorder: Color(0x1FFFFFFF), // Subtle card border
    cardShadow: [
      // Card shadow: 0 4px 12px rgba(0, 0, 0, 0.4)
      BoxShadow(
        color: Color(0x66000000), // 40% opacity black shadow
        blurRadius: 12,
        offset: Offset(0, 4),
        spreadRadius: 0,
      ),
      // Additional subtle shadow for depth
      BoxShadow(
        color: Color(0x1F000000), // 12% opacity for secondary shadow
        blurRadius: 6,
        offset: Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
    buttonShadow: [
      // Elevated shadow: 0 8px 24px rgba(0, 0, 0, 0.6)
      BoxShadow(
        color: Color(0x99000000), // 60% opacity for elevated elements
        blurRadius: 24,
        offset: Offset(0, 8),
        spreadRadius: 0,
      ),
    ],
    // Overlay colors - Contrast-aware
    overlay: Color(0xA6000000), // ~65% opacity for modal overlay
    scrim: Color(0xD9000000), // ~85% opacity for full scrim
  );
}
