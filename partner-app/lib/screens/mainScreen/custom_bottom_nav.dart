import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/mainScreen/bottom_nav_provider.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

// Main navigation container
class CustomBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final selected = context.watch<BottomNavProvider>().selected;
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(color: colorScheme.cardBackground),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(
              icon: HugeIcons.strokeRoundedHome01,
              label: 'Home',
              isActive: selected == 0,
              
              onTap: () => context.read<BottomNavProvider>().select(0),
            ),
            _NavItem(
              icon: HugeIcons.strokeRoundedPackageProcess,
              label: 'Return',
              isActive: selected == 1,
              onTap: () => context.read<BottomNavProvider>().select(1),
            ),
            _NavItem(
              icon: HugeIcons.strokeRoundedFile02,
              label: 'Orders',
              isActive: selected == 2,
              onTap: () => context.read<BottomNavProvider>().select(2),
            ),
            _NavItem(
              icon: HugeIcons.strokeRoundedProfile,
              label: 'Products',
              isActive: selected == 3,
              onTap: () => context.read<BottomNavProvider>().select(3),
            ),
            _NavItem(
              icon: HugeIcons.strokeRoundedUserCircle,
              label: 'Profile',
              isActive: selected == 4,
              onTap: () => context.read<BottomNavProvider>().select(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final color = isActive ? Color(0xFF32962C) : colorScheme.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Color(0xFF32962C).withValues(alpha: 0.1),
        highlightColor: Color(0xFF32962C).withValues(alpha: 0.05),
        // Increase tap area with padding
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                size: 24,
                color: color,
                strokeWidth: 1.8,
              ),
              SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
