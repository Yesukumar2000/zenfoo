import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomStatusSwitch extends StatelessWidget {
  final bool isOnline;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;
  final Color primaryColor;
  final Color surfaceColor;
  final Color textColor;

  const CustomStatusSwitch({
    Key? key,
    required this.isOnline,
    required this.isUpdating,
    required this.onChanged,
    required this.primaryColor,
    required this.surfaceColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color statusColor = isOnline
        ? const Color(0xFF10B981) // Green for online
        : const Color(0xFFEF4444); // Red for offline

    return GestureDetector(
      onTap: isUpdating ? null : () => onChanged(!isOnline),
      child: AnimatedOpacity(
        opacity: isUpdating ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.3),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: isUpdating
                      ? SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFFEF4444),
                            ),
                          ),
                        )
                      : Text(
                          "Off",
                          style: GoogleFonts.inter(
                            color: const Color(0xFFEF4444),
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
                isUpdating
                    ? (isOnline ? "Going offline..." : "Going online...")
                    : (isOnline ? "Online" : "Offline"),
                style: GoogleFonts.inter(
                  color: surfaceColor,
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: isUpdating
                      ? SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF10B981),
                            ),
                          ),
                        )
                      : Text(
                          "On",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            height: 1.2,
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
}
