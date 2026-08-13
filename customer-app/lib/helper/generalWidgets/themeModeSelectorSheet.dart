import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/utils/generalImports.dart';

/// Modern Theme Mode Selector Bottom Sheet
/// Allows users to switch between System, Light, and Dark themes
class ThemeModeSelectorSheet extends StatelessWidget {
  const ThemeModeSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, child) {
        final colorScheme = themeProvider.colorScheme;
        
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.palette_outlined,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getTranslatedValue(context, 'choose_theme'),
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.textPrimary,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              getTranslatedValue(context, 'select_your_preferred_appearance'),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.textSecondary,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Theme Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Commented out System and Dark theme options for now.
                      // _buildThemeOption(
                      //   context: context,
                      //   themeProvider: themeProvider,
                      //   colorScheme: colorScheme,
                      //   mode: app_theme.ThemeMode.system,
                      // ),
                      // const SizedBox(height: 12),
                      _buildThemeOption(
                        context: context,
                        themeProvider: themeProvider,
                        colorScheme: colorScheme,
                        mode: app_theme.ThemeMode.light,
                      ),
                      // const SizedBox(height: 12),
                      // _buildThemeOption(
                      //   context: context,
                      //   themeProvider: themeProvider,
                      //   colorScheme: colorScheme,
                      //   mode: app_theme.ThemeMode.dark,
                      // ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required app_theme.ThemeProvider themeProvider,
    required dynamic colorScheme,
    required app_theme.ThemeMode mode,
  }) {
    final isSelected = themeProvider.themeMode == mode;
    final name = themeProvider.getThemeModeName(mode, context);
    final description = themeProvider.getThemeModeDescription(mode, context);
    final icon = themeProvider.getThemeModeIcon(mode);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        themeProvider.setThemeMode(mode);
        // Close bottom sheet after a brief delay for visual feedback
        Future.delayed(const Duration(milliseconds: 200), () {
          if (context.mounted) {
            Navigator.pop(context);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : colorScheme.iconSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Check Icon
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show the theme selector bottom sheet
void showThemeSelector(BuildContext context) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const ThemeModeSelectorSheet(),
  );
}
