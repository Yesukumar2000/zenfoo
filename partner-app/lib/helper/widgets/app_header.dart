import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

/// Universal app header with consistent design
/// Used across all screens for a unified look and feel
class AppHeader extends StatelessWidget {
  final String label;
  final String title;
  final VoidCallback? onBackPressed;
  final Widget? trailing;
  final bool showBackButton;
  final List<Widget>? actions;

  const AppHeader({
    Key? key,
    required this.label,
    required this.title,
    this.onBackPressed,
    this.trailing,
    this.showBackButton = false,
    this.actions,
    }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorsRes.appColor,
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
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (onBackPressed != null) {
                        onBackPressed!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.background.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              colorScheme.textSecondary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: colorScheme.textSecondary,
                          size: 18,
                        ),
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
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
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
              if (actions != null) ...[
                const SizedBox(width: 12),
                ...actions!,
                ],
            ],
          ),
        ),
      ),
    );
  }
}
