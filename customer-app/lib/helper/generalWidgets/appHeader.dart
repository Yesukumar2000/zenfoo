import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

/// Universal app header with consistent design
/// Used across all screens for a unified look and feel
class AppHeader extends StatelessWidget {
  /// Small eyebrow above the title. Optional: on screens whose title already
  /// says where you are ("Manage Your Profile"), an eyebrow reading "Profile"
  /// only prints the same word twice, so those pass nothing and the header
  /// renders the title alone.
  final String label;
  final String title;
  final VoidCallback? onBackPressed;
  final Widget? trailing;
  final bool showBackButton;

  const AppHeader({
    Key? key,
    this.label = '',
    required this.title,
    this.onBackPressed,
    this.trailing,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final isDarkMode = context.watch<app_theme.ThemeProvider>().isDarkMode;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary,
            colorScheme.background,
          ],
          stops: const [0, 0.85],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (showBackButton) ...[
                GestureDetector(
                  onTap: onBackPressed ??
                      () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: !isDarkMode
                          ? Colors.black.withValues(alpha: 0.25)
                          : colorScheme.buttonPrimaryText
                              .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !isDarkMode
                            ? Colors.black
                            : colorScheme.buttonPrimaryText
                                .withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: !isDarkMode
                            ? Colors.black
                            : colorScheme.buttonPrimaryText,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label.isNotEmpty) ...[
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: !isDarkMode
                              ? Colors.black
                              : colorScheme.buttonPrimaryText
                                  .withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: -0.55,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: !isDarkMode
                            ? Colors.black
                            : colorScheme.buttonPrimaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
