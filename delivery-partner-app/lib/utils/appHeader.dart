import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/document_provider.dart';
import 'package:zenfoo_partner/providers/session_provider.dart';
import 'package:zenfoo_partner/router/app_router_name.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';

/// Universal app header with consistent design
/// Used across all screens for a unified look and feel
class AppHeader extends StatefulWidget {
  final String label;
  final String title;
  final VoidCallback? onBackPressed;
  final Widget? trailing;
  final bool showBackButton;
  final bool showExitButton;

  const AppHeader({
    super.key,
    required this.label,
    required this.title,
    this.onBackPressed,
    this.trailing,
    this.showBackButton = false,
    this.showExitButton = false,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final isDarkMode = themeProvider.isDarkMode;

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
              if (widget.showBackButton) ...[
                GestureDetector(
                  onTap: widget.onBackPressed ??
                      () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                  child: Hero(
                    tag: 'arrow_${widget.title}',
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: !isDarkMode
                            ? Colors.black.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !isDarkMode
                              ? Colors.black
                              : Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: !isDarkMode
                              ? Colors.black
                              : Colors.white.withValues(alpha: 0.9),
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
                    if (widget.label.isNotEmpty) ...[
                      Hero(
                        tag: widget.label,
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            widget.label,
                            style: GoogleFonts.inter(
                              color: !isDarkMode
                                  ? Colors.black
                                  : Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: -0.55,
                              height: 1.02,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Hero(
                      tag: widget.title,
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            color: !isDarkMode
                                ? Colors.black
                                : Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: -0.55,
                            height: 1.02,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                widget.trailing!,
              ],
              if (widget.showExitButton) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showLogoutBottomSheet(context);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: !isDarkMode
                          ? Colors.black.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !isDarkMode
                            ? Colors.black
                            : Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.logout_rounded,
                        color: !isDarkMode
                            ? Colors.black
                            : Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext bottomSheetContext) {
        return _LogoutBottomSheet();
      },
    );
  }
}

class _LogoutBottomSheet extends StatefulWidget {
  @override
  State<_LogoutBottomSheet> createState() => _LogoutBottomSheetState();
}

class _LogoutBottomSheetState extends State<_LogoutBottomSheet> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);

    try {
      // Get providers
      final authProvider = context.read<AuthProvider>();
      final sessionProvider = context.read<SessionProvider>();
      final documentProvider = context.read<DocumentProvider>();

      // Clear all data
      await authProvider.clearUserData();

      if (!mounted) return;

      sessionProvider.resetStates();
      documentProvider.clearAll();

      debugPrint('✅ All data cleared successfully');

      // Close bottom sheet and navigate to login screen
      if (mounted) {
        Navigator.pop(context);
        context.go(AppRouterName.login);
      }
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.logout_rounded,
              color: colorScheme.error,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Logout',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: colorScheme.border.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Logout button
              Expanded(
                child: GestureDetector(
                  onTap: _isLoading ? null : _handleLogout,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              'Logout',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.getHeight(2)),
        ],
      ),
    );
  }
}
