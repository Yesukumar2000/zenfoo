import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/styles/appColorScheme.dart';

enum ThemeMode {
  system,
  light,
  dark,
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  /// Get the current color scheme based on theme mode
  AppColorScheme get colorScheme => AppColorScheme(isDark: _isDarkMode);

  ThemeProvider() {
    _loadThemeFromPreferences();
  }

  /// Load theme from shared preferences
  void _loadThemeFromPreferences() {
    // System and Dark options are disabled for now — always force Light,
    // ignoring any previously-saved preference.
    _themeMode = ThemeMode.light;
    _isDarkMode = false;

    // Persist Light as the active theme.
    Constant.session.setData(
      SessionManager.appThemeName,
      Constant.themeList[1], // "Light"
      false,
    );

    // Update session
    Constant.session.setBoolData(SessionManager.isDarkTheme, _isDarkMode, false);

    // Update ColorsRes for backward compatibility
    _updateColorsRes();
  }

  /// Change theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    String themeName;
    switch (mode) {
      case ThemeMode.system:
        themeName = Constant.themeList[0]; // "System default"
        var brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        _isDarkMode = brightness == Brightness.dark;
        break;
      case ThemeMode.light:
        themeName = Constant.themeList[1]; // "Light"
        _isDarkMode = false;
        break;
      case ThemeMode.dark:
        themeName = Constant.themeList[2]; // "Dark"
        _isDarkMode = true;
        break;
    }

    // Save to preferences
    Constant.session.setData(SessionManager.appThemeName, themeName, false);
    Constant.session.setBoolData(SessionManager.isDarkTheme, _isDarkMode, false);

    // Update ColorsRes for backward compatibility
    _updateColorsRes();

    notifyListeners();
  }

  /// Update ColorsRes static colors for backward compatibility with existing code
  void _updateColorsRes() {
    if (_isDarkMode) {
      ColorsRes.mainTextColor = ColorsRes.mainTextColorDark;
      ColorsRes.subTitleMainTextColor = ColorsRes.subTitleTextColorDark;
      ColorsRes.shimmerBaseColor = ColorsRes.shimmerBaseColorDark;
      ColorsRes.shimmerHighlightColor = ColorsRes.shimmerHighlightColorDark;
      ColorsRes.shimmerContentColor = ColorsRes.shimmerContentColorDark;
    } else {
      ColorsRes.mainTextColor = ColorsRes.mainTextColorLight;
      ColorsRes.subTitleMainTextColor = ColorsRes.subTitleTextColorLight;
      ColorsRes.shimmerBaseColor = ColorsRes.shimmerBaseColorLight;
      ColorsRes.shimmerHighlightColor = ColorsRes.shimmerHighlightColorLight;
      ColorsRes.shimmerContentColor = ColorsRes.shimmerContentColorLight;
    }
  }

  /// Get ThemeData for MaterialApp
  ThemeData getThemeData() {
    return colorScheme.toThemeData();
  }

  /// Update theme based on system brightness change
  void updateSystemBrightness(Brightness brightness) {
    if (_themeMode == ThemeMode.system) {
      bool newIsDark = brightness == Brightness.dark;
      if (newIsDark != _isDarkMode) {
        _isDarkMode = newIsDark;
        Constant.session.setBoolData(SessionManager.isDarkTheme, _isDarkMode, false);
        _updateColorsRes();
        notifyListeners();
      }
    }
  }

  /// Get theme mode display name
  String getThemeModeName(ThemeMode mode, [BuildContext? context]) {
    switch (mode) {
      case ThemeMode.system:
        return context != null ? getTranslatedValue(context, 'system_default') : "System Default";
      case ThemeMode.light:
        return context != null ? getTranslatedValue(context, 'light_mode') : "Light Mode";
      case ThemeMode.dark:
        return context != null ? getTranslatedValue(context, 'dark_mode') : "Dark Mode";
    }
  }

  /// Get theme mode icon
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

  /// Get theme mode description
  String getThemeModeDescription(ThemeMode mode, [BuildContext? context]) {
    switch (mode) {
      case ThemeMode.system:
        return context != null ? getTranslatedValue(context, 'automatically_adjust_theme_based_on_system_settings') : "Automatically adjust theme based on system settings";
      case ThemeMode.light:
        return context != null ? getTranslatedValue(context, 'use_light_theme_all_the_time') : "Use light theme all the time";
      case ThemeMode.dark:
        return context != null ? getTranslatedValue(context, 'use_dark_theme_all_the_time') : "Use dark theme all the time";
    }
  }
}
