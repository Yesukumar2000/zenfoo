import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class DeductionsScreen extends StatefulWidget {
  const DeductionsScreen({super.key});

  @override
  State<DeductionsScreen> createState() => _DeductionsScreenState();
}

class _DeductionsScreenState extends State<DeductionsScreen> {
  DateTime _selectedWeekStart = DateTime.now();

  // Dummy deduction data
  final List<DeductionTransaction> _transactions = [
    DeductionTransaction(
      id: '#1445',
      date: '10/03/2025',
      time: '12:24 AM',
      amount: 50,
      reason: 'Late Delivery',
      description: 'You reached late to pickup location',
      status: 'Deducted',
    ),
    DeductionTransaction(
      id: '#1446',
      date: '12/03/2025',
      time: '03:15 PM',
      amount: 40,
      reason: 'Order cancellation',
      description: 'Order was cancelled after pickup',
      status: 'Deducted',
    ),
    DeductionTransaction(
      id: '#1447',
      date: '13/03/2025',
      time: '11:30 AM',
      amount: 30,
      reason: 'Customer complaint',
      description: 'Customer reported food spillage',
      status: 'Deducted',
    ),
    DeductionTransaction(
      id: '#1448',
      date: '14/03/2025',
      time: '05:45 PM',
      amount: 50,
      reason: 'Damaged goods',
      description: 'Package was damaged during delivery',
      status: 'Pending',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();
    final totalDeductions = _transactions
        .where((t) => t.status == 'Deducted')
        .fold(0, (sum, t) => sum + t.amount);

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // APP HEADER
          AppHeader(
            label: languageProvider.getTranslatedText('wallet'),
            title: languageProvider.getTranslatedText('deductions'),
            showBackButton: true,
          ),

          // CONTENT
          Expanded(
            child: Column(
              children: [
                // Week Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.border,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Previous Week Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedWeekStart = _selectedWeekStart
                                    .subtract(const Duration(days: 7));
                              });
                            },
                            child: Container(
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
                          const SizedBox(width: 12),
                          // Amount and Label
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getWeekLabel(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  height: 1.71,
                                  letterSpacing: -0.05,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '₹$totalDeductions',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: colorScheme.error,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                  letterSpacing: -0.05,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Next Week Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                final nextWeekStart = _selectedWeekStart
                                    .add(const Duration(days: 7));
                                final now = DateTime.now();
                                final currentWeekStart = now.subtract(
                                    Duration(days: now.weekday - 1));

                                // Only allow navigation if next week is not in the future
                                if (nextWeekStart.isBefore(currentWeekStart
                                    .add(const Duration(days: 1)))) {
                                  _selectedWeekStart = nextWeekStart;
                                }
                              });
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceElevated,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.border,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getWeekDateRange(),
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Transactions List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionItem(
                        _transactions[index],
                        colorScheme,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekDateRange() {
    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
    return '${DateFormat('dd MMM').format(_selectedWeekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}';
  }

  String _getWeekLabel() {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));

    // Normalize to start of day for comparison
    final selectedWeekStartDate = DateTime(_selectedWeekStart.year,
        _selectedWeekStart.month, _selectedWeekStart.day);
    final currentWeekStartDate = DateTime(
        currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);

    final difference =
        selectedWeekStartDate.difference(currentWeekStartDate).inDays ~/ 7;

    if (difference == 0) {
      return 'This week';
    } else if (difference == -1) {
      return 'Last week';
    } else if (difference == 1) {
      return 'Next week';
    } else if (difference < -1) {
      return '${difference.abs()} weeks ago';
    } else {
      return 'In $difference weeks';
    }
  }

  Widget _buildTransactionItem(
      DeductionTransaction transaction, AppColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showDeductionDetailsBottomSheet(context, transaction, colorScheme);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.border,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First Row: ID and Date/Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction.id,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.71,
                    letterSpacing: -0.05,
                  ),
                ),
                Text(
                  '${transaction.date},${transaction.time}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 2,
                    letterSpacing: -0.05,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            // Second Row: Reason and Amount with Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction.reason,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.71,
                      letterSpacing: -0.05,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '- ₹${transaction.amount}',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    color: colorScheme.error,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.50,
                    letterSpacing: -0.05,
                  ),
                ),
                const SizedBox(width: 7),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: colorScheme.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeductionDetailsBottomSheet(BuildContext context,
      DeductionTransaction transaction, AppColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.only(
          top: 18,
          left: 24,
          right: 24,
          bottom: 24,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deductions',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.close,
                    size: 24,
                    color: colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '- ₹${transaction.amount}',
                  style: GoogleFonts.inter(
                    color: colorScheme.error,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.20,
                    letterSpacing: -0.05,
                  ),
                ),
                Text(
                  'Deducted Amount',
                  style: GoogleFonts.inter(
                    color: colorScheme.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.71,
                    letterSpacing: -0.05,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Details Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Reason
                _buildDetailField('Reason', transaction.reason, colorScheme),
                const SizedBox(height: 18),

                // Description
                _buildDetailField('Description',
                    transaction.description ?? 'Des', colorScheme),
                const SizedBox(height: 18),

                // Date & Time
                _buildDetailField('Date & Time', transaction.date, colorScheme),
              ],
            ),
            const SizedBox(height: 24),

            // Support Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'I need Support ?',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Navigate to support/contact screen
                  },
                  child: Text(
                    'Contact us',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF3B82F6),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Okay Button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                height: 47,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Okay',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField(
      String label, String value, AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class DeductionTransaction {
  final String id;
  final String date;
  final String time;
  final int amount;
  final String reason;
  final String description;
  final String status;

  DeductionTransaction({
    required this.id,
    required this.date,
    required this.time,
    required this.amount,
    required this.reason,
    required this.description,
    required this.status,
  });
}
