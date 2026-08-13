import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class EarningsPerformanceDetailsScreen extends StatefulWidget {
  const EarningsPerformanceDetailsScreen({super.key});

  @override
  State<EarningsPerformanceDetailsScreen> createState() =>
      _EarningsPerformanceDetailsScreenState();
}

class _EarningsPerformanceDetailsScreenState
    extends State<EarningsPerformanceDetailsScreen> {
  int _monthOffset = 0;

  DateTime get _selectedMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset);
  }

  String get _monthLabel {
    final now = DateTime.now();
    final selected = _selectedMonth;

    if (selected.year == now.year && selected.month == now.month) {
      return 'This Month';
    } else if (selected.year == now.year && selected.month == now.month - 1 ||
        (now.month == 1 &&
            selected.year == now.year - 1 &&
            selected.month == 12)) {
      return 'Last Month';
    } else {
      return DateFormat('MMMM yyyy').format(selected);
    }
  }

  String get _monthSubtitle {
    return 'Fine';
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    final selected = _selectedMonth;
    return selected.year == now.year && selected.month == now.month;
  }

  void _navigatePrevious() {
    HapticFeedback.lightImpact();
    setState(() {
      _monthOffset--;
    });
  }

  void _navigateNext() {
    if (_isCurrentMonth) return;
    HapticFeedback.lightImpact();
    setState(() {
      _monthOffset++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: 'Earnings',
            title: 'Performance Details',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monthly Filter Navigation
                  _buildMonthlyFilter(colorScheme),
                  const SizedBox(height: 24),

                  // Month Info Card
                  _buildMonthInfoCard(colorScheme),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyFilter(AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _navigatePrevious,
              borderRadius: BorderRadius.circular(17),
              child: Ink(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_left,
                    size: 18,
                    color: colorScheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Month Label
          Expanded(
            child: Column(
              children: [
                Text(
                  _monthLabel,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.05,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _monthSubtitle,
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.05,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Next Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isCurrentMonth ? null : _navigateNext,
              borderRadius: BorderRadius.circular(17),
              child: Ink(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _isCurrentMonth
                      ? colorScheme.surfaceElevated.withValues(alpha: 0.5)
                      : colorScheme.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: _isCurrentMonth
                        ? colorScheme.textSecondary.withValues(alpha: 0.5)
                        : colorScheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthInfoCard(AppColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _monthLabel,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _monthSubtitle,
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.05,
            ),
          ),
        ],
      ),
    );
  }
}
