import 'package:flutter/material.dart';
import 'package:zenfoo_partner/utils/order_number.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/payout_history_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';
import 'package:zenfoo_partner/utils/ist_time.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/widgets/shimmer_loading_widget.dart';

class PayoutHistoryScreen extends StatefulWidget {
  const PayoutHistoryScreen({super.key});

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
}

int _currentOffset = 0;
DateTime _selectedWeekStart = DateTime.now();

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  PayoutHistoryResponse? _payoutData;
  bool _isLoading = true;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPayoutHistory();
    });
  }

  Future<void> _fetchPayoutHistory({int offset = 0}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final url = '${AppUrl.payoutHistory}?offset=$offset';

      final response = await apiService.get(url, isToast: false);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.status == 'success' && response.data != null) {
            _payoutData = PayoutHistoryResponse.fromJson(
                response.data as Map<String, dynamic>);
            _currentOffset = offset;
            _errorMessage = null;
          } else {
            _errorMessage = 'Failed to load payout history';
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching payout history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load payout history';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    if (_isLoading) {
      return CustomScaffold(
        backgroundColor: colorScheme.background,
        body: Column(
          children: [
            AppHeader(
              label: languageProvider.getTranslatedText('wallet'),
              title: languageProvider.getTranslatedText('payout'),
              showBackButton: true,
            ),
            Expanded(
              child: ShimmerLoadingWidget(
                colorScheme: colorScheme,
                itemCount: 5,
                height: 80,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _payoutData == null) {
      return CustomScaffold(
        backgroundColor: colorScheme.background,
        body: Column(
          children: [
            AppHeader(
              label: languageProvider.getTranslatedText('wallet'),
              title: languageProvider.getTranslatedText('payout'),
              showBackButton: true,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: GoogleFonts.inter(
                          color: colorScheme.error,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'Failed to load payout history',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _fetchPayoutHistory,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final totalPayout = _payoutData!.payoutSummary.totalPaidOut;
    final transactionCount = _payoutData!.payoutSummary.totalTransactions;
    final transactions = _payoutData!.transactions;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // APP HEADER
          AppHeader(
            label: languageProvider.getTranslatedText('wallet'),
            title: 'Payout',
            showBackButton: true,
          ),

          // CONTENT
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // This Week Payout Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                        vertical: 32, horizontal: 24),
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
                        // Text(
                        //   '${_getWeekLabel()} Payout',
                        //   style: GoogleFonts.inter(
                        //     color: colorScheme.textSecondary,
                        //     fontSize: 13,
                        //     fontWeight: FontWeight.w400,
                        //     height: 1.02,
                        //     letterSpacing: -0.05,
                        //   ),
                        // ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Previous Week Button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _currentOffset--;
                                });
                                _fetchPayoutHistory(offset: _currentOffset);
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
                            const SizedBox(width: 20),
                            Text(
                              '₹$totalPayout',
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 44,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Next Week Button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _currentOffset++;
                                  _fetchPayoutHistory(offset: _currentOffset);
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
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
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
                            _payoutData!.periodName,
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

                  // Payout Details Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Total Paid Out Card
                        Container(
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
                                'Total Paid Out',
                                style: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.05,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${totalPayout.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Transaction Count
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          colorScheme.primary.withAlpha(0x20),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.receipt_long,
                                          size: 16,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$transactionCount Transactions',
                                          style: GoogleFonts.inter(
                                            color: colorScheme.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Payout Transactions List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionRow(
                              transactions[index],
                              colorScheme,
                            );
                          },
                        ),
                        const SizedBox(height: 40),

                        // ZENFOO Branding
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 900),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colorScheme.textSecondary
                                    .withValues(alpha: 0.1),
                                colorScheme.surface.withValues(alpha: 0.2),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'ZENFOO\nDELIVERY PARTNER',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 0.9,
                                letterSpacing: -2.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildTransactionRow(
      PayoutTransaction transaction, dynamic colorScheme) {
    final statusColor = _getStatusColor(transaction.status, colorScheme);
    final statusBgColor = _getStatusBgColor(transaction.status, colorScheme);
    final formattedDate =
        formatIst(transaction.transactionDate, 'dd MMM yyyy, hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${formatOrderNumber(transaction.orderId)}',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.type,
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${transaction.amount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  transaction.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, dynamic colorScheme) {
    switch (status.toLowerCase()) {
      case 'success':
        return const Color(0xFF16A34A);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'failed':
        return const Color(0xFFDC2626);
      default:
        return colorScheme.textSecondary;
    }
  }

  Color _getStatusBgColor(String status, dynamic colorScheme) {
    switch (status.toLowerCase()) {
      case 'success':
        return const Color(0xFFDEFFEA);
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'failed':
        return const Color(0xFFFEE2E2);
      default:
        return colorScheme.surfaceElevated;
    }
  }
}
