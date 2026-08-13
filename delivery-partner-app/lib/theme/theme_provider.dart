import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  AppColorScheme get colorScheme {
    return _themeMode == ThemeMode.dark
        ? AppColorScheme.dark
        : AppColorScheme.light;
  }

  Future<void> _loadThemeMode() async {
    try {
      // Dark mode is disabled for now — always force Light, ignoring any
      // previously-saved preference, and persist Light as the active theme.
      _themeMode = ThemeMode.light;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, ThemeMode.light.toString());
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.toString());
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  Future<void> toggleTheme() async {
    final newMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }
}
