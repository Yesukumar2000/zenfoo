import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';

class AppTheme {
  static const double letterSpacing = -0.55;
  static const double lineHeight = 1.02;

  /// Get Light Theme
  static ThemeData get lightTheme {
    const colorScheme = AppColorScheme.light;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: colorScheme.primary,
        onPrimary: colorScheme.buttonPrimaryText,
        secondary: colorScheme.primaryLight,
        onSecondary: colorScheme.buttonPrimaryText,
        error: colorScheme.error,
        onError: Colors.white,
        surface: colorScheme.surface,
        onSurface: colorScheme.textPrimary,
      ),

      // Scaffold
      scaffoldBackgroundColor: colorScheme.background,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          color: colorScheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.iconPrimary,
        ),
      ),

      // Text Theme
      textTheme: _buildTextTheme(colorScheme.textPrimary),

      // Icon Theme
      iconTheme: IconThemeData(
        color: colorScheme.iconPrimary,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: colorScheme.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.cardBorder),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.buttonPrimaryBg,
          foregroundColor: colorScheme.buttonPrimaryText,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: letterSpacing,
            height: lineHeight,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: letterSpacing,
            height: lineHeight,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.textPrimary,
          side: BorderSide(color: colorScheme.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: letterSpacing,
            height: lineHeight,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.inputFocusBorder, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: GoogleFonts.inter(
          color: colorScheme.inputPlaceholder,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.divider,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.iconSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: colorScheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: colorScheme.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        contentTextStyle: GoogleFonts.inter(
          color: colorScheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Get Dark Theme
  static ThemeData get darkTheme {
    const colorScheme = AppColorScheme.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: colorScheme.primary,
        onPrimary: colorScheme.buttonPrimaryText,
        secondary: colorScheme.primaryLight,
        onSecondary: colorScheme.buttonPrimaryText,
        error: colorScheme.error,
        onError: Colors.white,
        surface: colorScheme.surface,
        onSurface: colorScheme.textPrimary,
      ),

      // Scaffold
      scaffoldBackgroundColor: colorScheme.background,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          color: colorScheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.iconPrimary,
        ),
      ),

      // Text Theme
      textTheme: _buildTextTheme(colorScheme.textPrimary),

      // Icon Theme
      iconTheme: IconThemeData(
        color: colorScheme.iconPrimary,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: colorScheme.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.cardBorder),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.buttonPrimaryBg,
          foregroundColor: colorScheme.buttonPrimaryText,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: letterSpacing,
            height: lineHeight,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: letterSpacing,
            height: lineHeight,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.textPrimary,
          side: BorderSide(color: colorScheme.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: letterSpacing,
            height: lineHeight,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.inputFocusBorder, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: GoogleFonts.inter(
          color: colorScheme.inputPlaceholder,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.divider,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.iconSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: colorScheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: colorScheme.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        contentTextStyle: GoogleFonts.inter(
          color: colorScheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Build Text Theme with Google Fonts
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      // Display styles
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),

      // Headline styles
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),

      // Title styles
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),

      // Body styles
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),

      // Label styles
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: textColor,
      ),
    );
  }
}
