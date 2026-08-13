import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/notification_helper.dart';

class PermissionHandlerBottomSheet extends StatefulWidget {
  final String titleJsonKey;
  final String messageJsonKey;
  final String sessionKeyForAskNeverShowAgain;

  const PermissionHandlerBottomSheet({
    super.key,
    required this.titleJsonKey,
    required this.messageJsonKey,
    required this.sessionKeyForAskNeverShowAgain,
  });

  @override
  State<PermissionHandlerBottomSheet> createState() =>
      _PermissionHandlerBottomSheetState();
}

class _PermissionHandlerBottomSheetState
    extends State<PermissionHandlerBottomSheet> {
  bool isNeverShowAgainChecked = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Center(
              child: Text(
                widget.titleJsonKey,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            // Message
            Text(
              widget.messageJsonKey,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: colorScheme.textSecondary,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 20),

            // Never ask again checkbox
            GestureDetector(
              onTap: () {
                setState(() {
                  isNeverShowAgainChecked = !isNeverShowAgainChecked;
                });
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isNeverShowAgainChecked,
                      onChanged: (value) {
                        setState(() {
                          isNeverShowAgainChecked = value ?? false;
                        });
                      },
                      activeColor: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Never ask again',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textSecondary,
                      letterSpacing: -0.25,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                // Close button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Constant.session.setBoolData(
                        widget.sessionKeyForAskNeverShowAgain,
                        isNeverShowAgainChecked,
                      );
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.border.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Close',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Go to Settings button
                Expanded(
                  child: GestureDetector(
                    onTap: isNeverShowAgainChecked
                        ? null
                        : () async {
                            await openAppSettings();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isNeverShowAgainChecked
                            ? colorScheme.textSecondary.withValues(alpha: 0.3)
                            : colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Go to Settings',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isNeverShowAgainChecked
                                ? colorScheme.textSecondary
                                : colorScheme.surface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
