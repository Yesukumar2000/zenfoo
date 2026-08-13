import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme Mode Enum
enum ThemeMode {
  system,
  light,
  dark,
}

// Color Scheme Class
class AppColorScheme {
  // Core Colors
  final Color primary;
  final Color surface;
  final Color background;
  final Color cardBackground;
  final Color surfaceVariant;

  // Text Colors
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Border & Divider
  final Color border;
  final Color divider;

  // Icon Colors
  final Color iconPrimary;
  final Color iconSecondary;

  // Shadows
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> buttonShadow;

  // Status Colors
  final Color success;
  final Color error;
  final Color warning;
  final Color info;

  const AppColorScheme({
    required this.primary,
    required this.surface,
    required this.background,
    required this.cardBackground,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.cardShadow,
    required this.buttonShadow,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
  });

  // Light Theme Color Scheme
  static const light = AppColorScheme(
    primary: Color(0xFF9AC444),
    surface: Colors.white,
    background: Color(0xFFFAFAFA),
    cardBackground: Colors.white,
    surfaceVariant: Color(0xFFF9FAFB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    border: Color(0xFFF0F0F0),
    divider: Color(0xFFF0F0F0),
    iconPrimary: Color(0xFF111827),
    iconSecondary: Color(0xFF6B7280),
    cardShadow: [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 12,
        offset: Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
    buttonShadow: [
      BoxShadow(
        color: Color(0x4D9AC444),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    success: Color(0xFF10B981),
    error: Color(0xFFEF4444),
    warning: Color(0xFFF97316),
    info: Color(0xFF3B82F6),
  );

  // Dark Theme Color Scheme
  static const dark = AppColorScheme(
    primary: Color(0xFF9AC444),
    surface: Color(0xFF1F2937),
    background: Color(0xFF111827),
    cardBackground: Color(0xFF1F2937),
    surfaceVariant: Color(0xFF374151),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFFD1D5DB),
    textTertiary: Color(0xFF9CA3AF),
    border: Color(0xFF374151),
    divider: Color(0xFF374151),
    iconPrimary: Color(0xFFF9FAFB),
    iconSecondary: Color(0xFFD1D5DB),
    cardShadow: [
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 12,
        offset: Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
    buttonShadow: [
      BoxShadow(
        color: Color(0x4D9AC444),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    success: Color(0xFF10B981),
    error: Color(0xFFEF4444),
    warning: Color(0xFFF97316),
    info: Color(0xFF3B82F6),
  );
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;
  Brightness _systemBrightness = Brightness.light;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  // Get current color scheme based on theme mode and system brightness
  AppColorScheme get colorScheme {
    switch (_themeMode) {
      case ThemeMode.light:
        return AppColorScheme.light;
      case ThemeMode.dark:
        return AppColorScheme.dark;
      case ThemeMode.system:
        return _systemBrightness == Brightness.dark
            ? AppColorScheme.dark
            : AppColorScheme.light;
    }
  }

  // Get Flutter ThemeData
  ThemeData get themeData {
    final scheme = colorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness:
          scheme == AppColorScheme.dark ? Brightness.dark : Brightness.light,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: scheme.background,
      cardColor: scheme.cardBackground,
      dividerColor: scheme.divider,
      colorScheme: ColorScheme(
        brightness:
            scheme == AppColorScheme.dark ? Brightness.dark : Brightness.light,
        primary: scheme.primary,
        onPrimary: Colors.white,
        secondary: scheme.primary,
        onSecondary: Colors.white,
        error: scheme.error,
        onError: Colors.white,
        surface: scheme.surface,
        onSurface: scheme.textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: scheme.textPrimary,
          letterSpacing: -0.8,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: scheme.textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: scheme.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: scheme.textPrimary,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: scheme.textPrimary,
          letterSpacing: -0.3,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.textPrimary,
          letterSpacing: -0.2,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: scheme.textPrimary,
          letterSpacing: -0.2,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: scheme.textSecondary,
          letterSpacing: -0.2,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: scheme.textSecondary,
          letterSpacing: -0.2,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: scheme.textPrimary,
          letterSpacing: -0.2,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.textSecondary,
          letterSpacing: -0.2,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.textTertiary,
          letterSpacing: -0.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        elevation: 0,
        surfaceTintColor: scheme.surface,
        iconTheme: IconThemeData(color: scheme.iconPrimary),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: scheme.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.border, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Update system brightness (called from main.dart)
  void updateSystemBrightness(Brightness brightness) {
    if (_systemBrightness != brightness) {
      _systemBrightness = brightness;
      Future.microtask(() => notifyListeners());
    }
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      await _saveThemeMode(mode);
    }
  }

  // Load saved theme mode
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);
      if (savedMode != null) {
        // System and Dark options are disabled for now — always resolve to
        // Light regardless of any previously-saved preference.
        _themeMode = ThemeMode.light;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading theme mode: $e');
    }
  }

  // Save theme mode
  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.toString());
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }

  // Get theme mode name
  String getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  // Get theme mode description
  String getThemeModeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow system settings';
      case ThemeMode.light:
        return 'Light appearance';
      case ThemeMode.dark:
        return 'Dark appearance';
    }
  }

  // Get theme mode icon
  IconData getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }
}
