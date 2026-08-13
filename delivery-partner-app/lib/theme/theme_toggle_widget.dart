import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';

/// A simple theme toggle widget that can be placed anywhere
class ThemeToggleButton extends StatelessWidget {
  final double? iconSize;
  final Color? color;

  const ThemeToggleButton({
    super.key,
    this.iconSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return IconButton(
          icon: Icon(
            themeProvider.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            size: iconSize,
            color: color,
          ),
          onPressed: () => themeProvider.toggleTheme(),
          tooltip: themeProvider.isDarkMode
              ? 'Switch to Light Mode'
              : 'Switch to Dark Mode',
        );
      },
    );
  }
}

/// A themed switch widget for theme toggling
class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.light_mode_rounded,
              size: 20,
              color: themeProvider.isDarkMode
                  ? Colors.grey
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Switch(
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.dark_mode_rounded,
              size: 20,
              color: themeProvider.isDarkMode
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
          ],
        );
      },
    );
  }
}

/// A list tile for settings page
class ThemeToggleListTile extends StatelessWidget {
  const ThemeToggleListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: Text(
            themeProvider.isDarkMode ? 'Enabled' : 'Disabled',
          ),
          secondary: Icon(
            themeProvider.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
          ),
          value: themeProvider.isDarkMode,
          onChanged: (_) => themeProvider.toggleTheme(),
        );
      },
    );
  }
}
