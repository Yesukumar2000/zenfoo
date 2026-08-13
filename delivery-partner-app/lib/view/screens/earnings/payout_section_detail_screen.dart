import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/payout_sections_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class PayoutSectionDetailScreen extends StatefulWidget {
  final String sectionKey;
  final String sectionLabel;

  const PayoutSectionDetailScreen({
    super.key,
    required this.sectionKey,
    required this.sectionLabel,
  });

  @override
  State<PayoutSectionDetailScreen> createState() =>
      _PayoutSectionDetailScreenState();
}

class _PayoutSectionDetailScreenState extends State<PayoutSectionDetailScreen> {
  static const String _apiUrl =
      '${AppUrl.baseUrl}/api/delivery-boy/performance/earnings-sections';

  String _selectedPeriod = 'weekly';
  int _offset = 0;
  PayoutSectionsData? _data;
  PayoutSection? _section;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final url =
          '$_apiUrl?period=$_selectedPeriod&offset=$_offset';

      final response = await apiService.get(url, isToast: false);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.status == 'success' && response.data != null) {
            final parsed = PayoutSectionsResponse.fromJson(
                response.data as Map<String, dynamic>);
            if (parsed.status == 1 && parsed.data != null) {
              _data = parsed.data;
              _section = _data!.sections.firstWhere(
                (s) => s.key == widget.sectionKey,
                orElse: () => PayoutSection(
                  key: widget.sectionKey,
                  label: widget.sectionLabel,
                  total: 0,
                  count: 0,
                  transactions: [],
                ),
              );
              _errorMessage = null;
            } else {
              _errorMessage = parsed.message.isNotEmpty
                  ? parsed.message
                  : 'No data available';
            }
          } else {
            _errorMessage = 'Failed to load data';
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching section data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data';
        });
      }
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _offset = 0;
    });
    _fetchData();
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'daily':
        return 'Today';
      case 'weekly':
        return 'This week';
      case 'monthly':
        return 'This month';
      default:
        return 'Period';
    }
  }

  String _formatDateRange() {
    if (_data == null) return '';
    try {
      final start = DateTime.parse(_data!.startDate);
      final end = DateTime.parse(_data!.endDate);
      return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}';
    } catch (e) {
      return '${_data!.startDate} - ${_data!.endDate}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: '',
            title: widget.sectionLabel,
            showBackButton: true,
            showExitButton: false,
          ),

          /// CONTENT
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorState(colorScheme)
                    : _buildContent(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _fetchData,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppColorScheme colorScheme) {
    return Column(
      children: [
        /// Summary Card
        _buildSummaryCard(colorScheme),

        /// Transactions List
        Expanded(
          child: _section == null || _section!.transactions.isEmpty
              ? Center(
                  child: Text(
                    'No transactions found',
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _section!.transactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionItem(
                      _section!.transactions[index],
                      colorScheme,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(AppColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Column(
        children: [
          // Offset navigation row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _offset--);
                  _fetchData();
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.border, width: 1),
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

              // Period label + Amount
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getPeriodLabel(),
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${_section?.total.toInt() ?? 0}',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Next button (disabled at offset 0)
              GestureDetector(
                onTap: _offset < 0
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _offset++);
                        _fetchData();
                      }
                    : null,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.border, width: 1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: _offset < 0
                          ? colorScheme.textSecondary
                          : colorScheme.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date range dropdown
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showPeriodPicker(colorScheme);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDateRange(),
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: colorScheme.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
      PayoutSectionTransaction txn, AppColorScheme colorScheme) {
    final isSettled = txn.isSettled == 1;
    final statusText = isSettled ? 'Settled' : 'Pending';
    final statusColor =
        isSettled ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
    final hasRef =
        txn.payoutReference != null && txn.payoutReference!.isNotEmpty;
    final hasSettledAt = txn.settledAt != null && txn.settledAt!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          iconColor: colorScheme.textSecondary,
          collapsedIconColor: colorScheme.textSecondary,
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: colorScheme.textSecondary,
              ),
            ],
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${txn.orderId ?? txn.id}',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.02,
                  letterSpacing: -0.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                txn.date,
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '+ ₹${txn.amount.toInt()}',
                style: GoogleFonts.inter(
                  color: colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.02,
                  letterSpacing: -0.05,
                ),
              ),
            ],
          ),
          children: [
            if (hasRef || hasSettledAt)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasRef)
                      Row(
                        children: [
                          Text(
                            'Ref: ',
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              txn.payoutReference!,
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (hasRef && hasSettledAt) const SizedBox(height: 8),
                    if (hasSettledAt)
                      Row(
                        children: [
                          Text(
                            'Settled: ',
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            txn.settledAt!,
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPeriodPicker(AppColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Period',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildPeriodOption('Daily', 'daily', colorScheme),
              _buildPeriodOption('Weekly', 'weekly', colorScheme),
              _buildPeriodOption('Monthly', 'monthly', colorScheme),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(
      String label, String value, AppColorScheme colorScheme) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        _changePeriod(value);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? colorScheme.primary : colorScheme.textPrimary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
