# Theme System

A comprehensive theme system with dark mode support, Google Fonts, and consistent styling.

## Features

- ✅ Light and Dark mode support
- ✅ Persistent theme preference using SharedPreferences
- ✅ Google Fonts (Inter) with custom letter spacing (-0.55) and line height (1.02)
- ✅ Comprehensive color schemes with semantic colors
- ✅ Provider-based state management
- ✅ Easy theme toggling widgets

## File Structure

```
lib/theme/
├── app_color_scheme.dart      # Color definitions for light/dark modes
├── app_theme.dart              # Theme configurations
├── theme_provider.dart         # State management for themes
├── theme_toggle_widget.dart    # Ready-to-use toggle widgets
└── README.md                   # This file
```

## Usage

### 1. Accessing Colors

```dart
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';

// In your widget
Widget build(BuildContext context) {
  final colorScheme = context.watch<ThemeProvider>().colorScheme;

  return Container(
    color: colorScheme.background,
    child: Text(
      'Hello',
      style: TextStyle(color: colorScheme.textPrimary),
    ),
  );
}
```

### 2. Using Theme Colors

Available color properties:

**Primary Colors:**

- `primary`, `primaryLight`, `primaryDark`

**Text Colors:**

- `textPrimary`, `textSecondary`, `textTertiary`, `textDisabled`

**Background Colors:**

- `background`, `surface`, `surfaceElevated`, `surfaceContainer`

**Border Colors:**

- `border`, `borderStrong`, `divider`

**Status Colors:**

- `success`, `warning`, `error`, `info`
- `successBg`, `warningBg`, `errorBg`, `infoBg`

**Input Colors:**

- `inputBackground`, `inputBorder`, `inputPlaceholder`, `inputFocusBorder`

**Icon Colors:**

- `iconPrimary`, `iconSecondary`, `iconDisabled`

**Button Colors:**

- `buttonPrimaryBg`, `buttonPrimaryText`
- `buttonSecondaryBg`, `buttonSecondaryText`
- `buttonDisabledBg`, `buttonDisabledText`

**Card Colors:**

- `cardBackground`, `cardBorder`, `cardShadow`

**Overlay Colors:**

- `overlay`, `scrim`

### 3. Using Google Fonts

The theme automatically applies Google Fonts (Inter) with:

- Letter spacing: -0.55
- Line height: 1.02

```dart
// Use theme text styles (recommended)
Text(
  'Hello',
  style: Theme.of(context).textTheme.bodyLarge,
)

// Or use directly
Text(
  'Hello',
  style: GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.55,
    height: 1.02,
  ),
)
```

### 4. Toggle Theme

**Simple Icon Button:**

```dart
import 'package:zenfoo_partner/theme/theme_toggle_widget.dart';

// In AppBar actions
AppBar(
  actions: [
    ThemeToggleButton(),
  ],
)
```

**Switch Widget:**

```dart
import 'package:zenfoo_partner/theme/theme_toggle_widget.dart';

ThemeToggleSwitch()
```

**List Tile (for settings page):**

```dart
import 'package:zenfoo_partner/theme/theme_toggle_widget.dart';

ThemeToggleListTile()
```

**Programmatically:**

```dart
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';

// Toggle
context.read<ThemeProvider>().toggleTheme();

// Set specific mode
context.read<ThemeProvider>().setThemeMode(ThemeMode.dark);

// Check current mode
bool isDark = context.read<ThemeProvider>().isDarkMode;
```

### 5. Check Current Theme

```dart
final themeProvider = context.watch<ThemeProvider>();

if (themeProvider.isDarkMode) {
  // Dark mode specific code
} else {
  // Light mode specific code
}
```

## Examples

### Example 1: Custom Container with Theme Colors

```dart
Widget build(BuildContext context) {
  final colorScheme = context.watch<ThemeProvider>().colorScheme;

  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colorScheme.cardBackground,
      border: Border.all(color: colorScheme.cardBorder),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: colorScheme.cardShadow,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      'Card Content',
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}
```

### Example 2: Status Badge

```dart
Widget buildStatusBadge(String status) {
  final colorScheme = context.watch<ThemeProvider>().colorScheme;

  Color bgColor;
  Color textColor;

  switch (status) {
    case 'success':
      bgColor = colorScheme.successBg;
      textColor = colorScheme.success;
      break;
    case 'warning':
      bgColor = colorScheme.warningBg;
      textColor = colorScheme.warning;
      break;
    case 'error':
      bgColor = colorScheme.errorBg;
      textColor = colorScheme.error;
      break;
    default:
      bgColor = colorScheme.infoBg;
      textColor = colorScheme.info;
  }

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      status.toUpperCase(),
      style: GoogleFonts.inter(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.55,
        height: 1.02,
      ),
    ),
  );
}
```

### Example 3: Settings Screen with Theme Toggle

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ThemeToggleListTile(),
          // Other settings...
        ],
      ),
    );
  }
}
```

## Best Practices

1. **Always use color scheme colors** instead of hardcoded colors for dark mode compatibility
2. **Use Theme.of(context).textTheme** for text styles to maintain consistency
3. **Test both light and dark modes** when designing new screens
4. **Use semantic colors** (success, warning, error, info) for status indicators
5. **Leverage the provider pattern** to access theme colors efficiently

## Customization

### To add new colors:

1. Add to `AppColorScheme` class in both light and dark schemes
2. Update the constructor and const declarations
3. Use the new color via `context.watch<ThemeProvider>().colorScheme.yourNewColor`

### To change default fonts:

1. Update `AppTheme._buildTextTheme()` in `app_theme.dart`
2. Replace `GoogleFonts.inter` with your preferred font

### To modify letter spacing or line height:

1. Update constants in `AppTheme` class:
   ```dart
   static const double letterSpacing = -0.55;  // Change this
   static const double lineHeight = 1.02;       // Change this
   ```
