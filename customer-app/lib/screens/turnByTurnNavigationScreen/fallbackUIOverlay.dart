import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/provider/turnByTurnNavigationProvider.dart';
import 'package:provider/provider.dart';

/// Overlay UI for fallback map view with two action buttons
/// Allows user to switch between fit bounds and driver-focused views
class FallbackUIOverlay extends StatelessWidget {
  final VoidCallback? onFitBoundsPressed;
  final VoidCallback? onDriverFocusPressed;
  final String? errorMessage;

  const FallbackUIOverlay({
    Key? key,
    this.onFitBoundsPressed,
    this.onDriverFocusPressed,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final provider = context.watch<TurnByTurnNavigationProvider>();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              colorScheme.background,
              colorScheme.background.withValues(alpha: 0.95),
              colorScheme.background.withValues(alpha: 0.85),
              colorScheme.background.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error message
                if (errorMessage != null && errorMessage!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Action buttons
                Row(
                  children: [
                    // Fit Bounds Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          provider.switchToFitBoundsView();
                          onFitBoundsPressed?.call();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: provider.currentViewMode == ViewMode.fitBounds
                                ? colorScheme.primary
                                : colorScheme.surface,
                            border: Border.all(
                              color: provider.currentViewMode == ViewMode.fitBounds
                                  ? colorScheme.primary
                                  : colorScheme.border,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: provider.currentViewMode == ViewMode.fitBounds
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fit_screen_rounded,
                                color: provider.currentViewMode ==
                                        ViewMode.fitBounds
                                    ? Colors.white
                                    : colorScheme.iconPrimary,
                                size: 20,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Fit Bounds',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: provider.currentViewMode ==
                                          ViewMode.fitBounds
                                      ? Colors.white
                                      : colorScheme.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Driver Focus Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          provider.switchToDriverFocusedView();
                          onDriverFocusPressed?.call();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: provider.currentViewMode ==
                                    ViewMode.driverFocused
                                ? colorScheme.primary
                                : colorScheme.surface,
                            border: Border.all(
                              color: provider.currentViewMode ==
                                      ViewMode.driverFocused
                                  ? colorScheme.primary
                                  : colorScheme.border,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: provider.currentViewMode ==
                                    ViewMode.driverFocused
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.navigation_rounded,
                                color: provider.currentViewMode ==
                                        ViewMode.driverFocused
                                    ? Colors.white
                                    : colorScheme.iconPrimary,
                                size: 20,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Driver Focus',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: provider.currentViewMode ==
                                          ViewMode.driverFocused
                                      ? Colors.white
                                      : colorScheme.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
