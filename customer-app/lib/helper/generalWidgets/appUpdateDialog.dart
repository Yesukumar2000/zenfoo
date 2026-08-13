import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/appUpdateProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class AppUpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String newVersion;
  final bool isForceUpdate;
  final VoidCallback onUpdatePressed;
  final VoidCallback? onLaterPressed;

  const AppUpdateDialog({
    Key? key,
    required this.currentVersion,
    required this.newVersion,
    this.isForceUpdate = false,
    required this.onUpdatePressed,
    this.onLaterPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return Dialog(
          backgroundColor: colorScheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  getTranslatedValue(context, 'update_available'),
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  getTranslatedValue(context, 'new_version_available'),
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Version info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.border,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            getTranslatedValue(context, 'current_version'),
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'v$currentVersion',
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.border,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            getTranslatedValue(context, 'new_version'),
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'v$newVersion',
                            style: GoogleFonts.inter(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: Consumer<AppUpdateProvider>(
                    builder: (context, updateProvider, _) {
                      return Column(
                        children: [
                          ElevatedButton(
                            onPressed:
                                updateProvider.isCheckingForUpdate ? null : onUpdatePressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor:
                                  colorScheme.primary.withValues(alpha: 0.5),
                            ),
                            child: updateProvider.isCheckingForUpdate
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        colorScheme.cardBackground,
                                      ),
                                    ),
                                  )
                                : Text(
                                    getTranslatedValue(context, 'update_now'),
                                    style: GoogleFonts.inter(
                                      color: colorScheme.cardBackground,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                          ),
                          if (!isForceUpdate) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: onLaterPressed ??
                                    () {
                                      Navigator.pop(context);
                                    },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: colorScheme.border,
                                    width: 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  getTranslatedValue(context, 'later'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ),
                          ] else
                            const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Update available banner widget for showing at top of profile screen
class UpdateAvailableBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onUpdate;

  const UpdateAvailableBanner({
    Key? key,
    required this.onDismiss,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.system_update,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getTranslatedValue(context, 'update_available'),
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      getTranslatedValue(context, 'new_version_available'),
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onUpdate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        getTranslatedValue(context, 'update_now'),
                        style: GoogleFonts.inter(
                          color: colorScheme.cardBackground,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
