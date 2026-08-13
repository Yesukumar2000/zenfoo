import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/payment_history_model.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/payment_history_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  int _offset = 0;
  int _selectedFilterIndex = 0; // 0=Today, 1=Weekly, 2=Monthly
  final List<String> _filters = ['Today', 'Weekly', 'Monthly'];
  final List<String> _periods = ['daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<PaymentHistoryProvider>();
    provider.fetchHistory(
      period: _periods[_selectedFilterIndex],
      offset: _offset,
    );
  }

  void _onFilterChanged(int index) {
    setState(() {
      _selectedFilterIndex = index;
      _offset = 0;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();
    final provider = context.watch<PaymentHistoryProvider>();
    final data = provider.currentHistory;
    final isLoading = provider.historyState.status == ApiStatus.loading;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: languageProvider.getTranslatedText('earnings'),
            title: languageProvider.getTranslatedText('payment_history'),
            showBackButton: true,
          ),
          Expanded(
            child: Column(
              children: [
                // Filter Tabs
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildFilterTabs(colorScheme),
                ),
                const SizedBox(height: 16),
                // Summary Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSummaryCard(colorScheme, data),
                ),
                const SizedBox(height: 16),
                // Payments List
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: colorScheme.primary))
                      : data == null || data.data.payments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_long_outlined,
                                      size: 56,
                                      color: colorScheme.textSecondary
                                          .withValues(alpha: 0.4)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No payment history yet',
                                    style: GoogleFonts.inter(
                                      color: colorScheme.textSecondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: data.data.payments.length,
                              itemBuilder: (context, index) {
                                return _buildPaymentCard(
                                    data.data.payments[index], colorScheme);
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

  Widget _buildFilterTabs(AppColorScheme colorScheme) {
    return Row(
      children: List.generate(_filters.length, (index) {
        final isSelected = _selectedFilterIndex == index;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _onFilterChanged(index);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.textPrimary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.textPrimary
                      : colorScheme.border,
                  width: 1,
                ),
              ),
              child: Text(
                _filters[index],
                style: GoogleFonts.inter(
                  color: isSelected
                      ? colorScheme.surface
                      : colorScheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(
      AppColorScheme colorScheme, PaymentHistoryResponse? data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Column(
        children: [
          Text(
            'Total Payments',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data != null
                ? '₹${data.data.summary.totalAmount}'
                : '₹0',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
      PaymentHistoryItem item, AppColorScheme colorScheme) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (item.isApproved) {
      statusColor = colorScheme.success;
      statusLabel = 'Approved';
      statusIcon = Icons.check_circle_rounded;
    } else if (item.isRejected) {
      statusColor = colorScheme.error;
      statusLabel = 'Rejected';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = colorScheme.warning;
      statusLabel = 'Pending';
      statusIcon = Icons.access_time_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Column(
        children: [
          // Top row: amount + status badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${double.tryParse(item.amount)?.toStringAsFixed(0) ?? item.amount}',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: GoogleFonts.inter(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.border),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                    colorScheme, 'Transaction ID', item.transactionId),
                const SizedBox(height: 10),
                _buildInfoRow(colorScheme, 'Submitted', item.submittedAt),
                if (item.approvedAt != null) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      colorScheme, 'Approved At', item.approvedAt!),
                ],
                if (item.adminNotes != null &&
                    item.adminNotes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      colorScheme, 'Admin Notes', item.adminNotes!),
                ],
              ],
            ),
          ),
          // Proof image thumbnail
          if (item.proofImage != null && item.proofImage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Proof',
                      style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.proofImage!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorScheme.border),
                        ),
                        child: Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: colorScheme.textSecondary)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(AppColorScheme colorScheme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400)),
        ),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
