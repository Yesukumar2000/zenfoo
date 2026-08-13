import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/session_provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';

class StatusToggleWidget extends StatelessWidget {
  final SessionProvider sessionProvider;
  final bool isTogglingStatus;
  final VoidCallback onToggle;

  const StatusToggleWidget({
    super.key,
    required this.sessionProvider,
    required this.isTogglingStatus,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = sessionProvider.isOnline;
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return GestureDetector(
      onTap: isTogglingStatus ? null : onToggle,
      child: AnimatedOpacity(
        opacity: isTogglingStatus ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          // height: 36,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isOnline ? colorScheme.success : colorScheme.error,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: isOnline
                    ? colorScheme.success.withValues(alpha: 0.3)
                    : colorScheme.error.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // When offline, button is on the left
              if (!isOnline) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: isTogglingStatus
                      ? SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.error,
                            ),
                          ),
                        )
                      : Text(
                          "Off",
                          style: GoogleFonts.inter(
                            color: colorScheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
              ],

              // Label text in the middle
              Text(
                isTogglingStatus
                    ? (isOnline ? "Going offline..." : "Going online...")
                    : (isOnline ? "Online" : "Offline"),
                style: GoogleFonts.inter(
                  color: colorScheme.surface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),

              // When online, button is on the right
              if (isOnline) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: isTogglingStatus
                      ? SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.success,
                            ),
                          ),
                        )
                      : Text(
                          "On",
                          style: GoogleFonts.inter(
                            color: colorScheme.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                ),
              ],

              // const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
