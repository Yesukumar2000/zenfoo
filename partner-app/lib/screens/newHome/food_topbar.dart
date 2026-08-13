import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/widgets/custom_status_switch.dart';
import 'package:provider/provider.dart';

class FoodHomeHeader extends StatelessWidget {
  final String businessName;
  final String storeName;
  final String address;
  final bool switchValue;
  final ValueChanged<bool> onSwitchChanged;
  final VoidCallback? onHelp;
  final VoidCallback? onLocationTap;
  final bool isUpdatingStatus;

  const FoodHomeHeader({
    Key? key,
    required this.businessName,
    required this.storeName,
    required this.address,
    required this.switchValue,
    required this.onSwitchChanged,
    this.onHelp,
    this.onLocationTap,
    this.isUpdatingStatus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorScheme.primary, colorScheme.surface],
          stops: const [0.0, 0.6],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT COLUMN
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      businessName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                        height: 1.02,
                        letterSpacing: -0.33,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      storeName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.55,
                        height: 0.95,
                      ),
                    ),
                    GestureDetector(
                      onTap: onLocationTap,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.textPrimary,
                                height: 0.85,
                                letterSpacing: -0.55,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: colorScheme.iconPrimary,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // RIGHT ACTIONS
              Row(
                children: [
                  // Custom Status Switch
                  CustomStatusSwitch(
                    isOnline: switchValue,
                    isUpdating: isUpdatingStatus,
                    onChanged: onSwitchChanged,
                    primaryColor: colorScheme.primary,
                    surfaceColor: colorScheme.surface,
                    textColor: colorScheme.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  // Circular Help
                  Material(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onHelp,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.headset_mic_rounded,
                          color: colorScheme.iconPrimary,
                          size: 24,
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
    );
  }
}
