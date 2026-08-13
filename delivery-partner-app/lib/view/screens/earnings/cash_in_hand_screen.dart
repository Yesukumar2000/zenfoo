import 'dart:io';
import 'package:zenfoo_partner/utils/order_number.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/deposit_cash_model.dart';
import 'package:zenfoo_partner/models/floating_cash_model.dart';
import 'package:zenfoo_partner/providers/admin_payment_details_provider.dart';
import 'package:zenfoo_partner/models/admin_payment_details_model.dart';
import 'package:zenfoo_partner/providers/deposit_cash_provider.dart';
import 'package:zenfoo_partner/providers/floating_cash_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/payment_proof_provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class CashInHandScreen extends StatefulWidget {
  const CashInHandScreen({super.key});

  @override
  State<CashInHandScreen> createState() => _CashInHandScreenState();
}

class _CashInHandScreenState extends State<CashInHandScreen> {
  int _weeklyOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFloatingCashData();
    });
  }

  void _loadFloatingCashData() {
    final provider = context.read<FloatingCashProvider>();
    provider.getFloatingCash(period: 'weekly', offset: _weeklyOffset);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();
    final floatingCashProvider = context.watch<FloatingCashProvider>();
    final floatingCashData = floatingCashProvider.currentFloatingCash;
    final totalPendingCash =
        floatingCashData?.data.summary.totalPendingCash ?? 0;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // APP HEADER
          AppHeader(
            label: languageProvider.getTranslatedText('wallet'),
            title: languageProvider.getTranslatedText('cash_in_hand'),
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
                    color: colorScheme.surfaceElevated,
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
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _weeklyOffset--;
                                });
                                _loadFloatingCashData();
                              },
                              borderRadius: BorderRadius.circular(17),
                              child: Ink(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
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
                          const SizedBox(width: 12),
                          // Amount and Label
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                floatingCashData != null
                                    ? _getWeekLabel(
                                        floatingCashData.data.startDate)
                                    : 'Loading...',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  height: 1.71,
                                  letterSpacing: -0.05,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹$totalPendingCash',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  height: 1.02,
                                  letterSpacing: -0.05,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Next Week Button (Disabled for future weeks)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _weeklyOffset < 0 ? () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _weeklyOffset++;
                                });
                                _loadFloatingCashData();
                              } : null,
                              borderRadius: BorderRadius.circular(17),
                              child: Ink(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _weeklyOffset < 0
                                      ? colorScheme.surface
                                      : colorScheme.surface.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: _weeklyOffset < 0
                                        ? colorScheme.textSecondary
                                        : colorScheme.textSecondary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Week Date Range Display
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
                          floatingCashData != null
                              ? floatingCashData.data.periodName
                              : 'Loading...',
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

                // Deposit Button - hidden when admin has disabled every deposit method
                Builder(
                  builder: (context) {
                    final adminMethods =
                        context.watch<AdminPaymentDetailsProvider>().data?.methods;
                    // While details are loading we keep the button visible (legacy default).
                    if (adminMethods != null && adminMethods.allDisabled) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: totalPendingCash <= 0 ? null : () {
                                HapticFeedback.lightImpact();
                                _showDepositBottomSheet(context, colorScheme);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Ink(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: totalPendingCash <= 0
                                      ? colorScheme.primary.withValues(alpha: 0.4)
                                      : colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Deposit Cash',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

                // Transactions List
                Expanded(
                  child: floatingCashData == null ||
                          floatingCashData.data.transactions.isEmpty
                      ? Center(
                          child: Text(
                            'No transactions',
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: floatingCashData.data.transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionItem(
                              floatingCashData.data.transactions[index],
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

  String _getWeekLabel(String startDateStr) {
    try {
      final startDate = DateTime.parse(startDateStr);
      final now = DateTime.now();
      final weekStartDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final currentWeekStartDate = DateTime(
          currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);

      final difference =
          weekStartDate.difference(currentWeekStartDate).inDays ~/ 7;

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
    } catch (e) {
      return 'Week';
    }
  }

  Widget _buildTransactionItem(
      FloatingCashTransaction transaction, AppColorScheme colorScheme) {
    final isSettled = transaction.isSettled;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Row(
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
                    fontWeight: FontWeight.w700,
                    height: 1.02,
                    letterSpacing: -0.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  transaction.transactionDate,
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.02,
                    letterSpacing: -0.05,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '₹${transaction.adminCash}',
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
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSettled
                  ? colorScheme.primary.withAlpha(0x1F)
                  : colorScheme.error.withAlpha(0x1F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isSettled ? 'Settled' : 'Pending',
              style: GoogleFonts.inter(
                color: isSettled ? colorScheme.primary : colorScheme.error,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.02,
                letterSpacing: -0.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDepositBottomSheet(BuildContext context, AppColorScheme colorScheme) {
    final adminProvider = context.read<AdminPaymentDetailsProvider>();
    if (adminProvider.data == null && !adminProvider.isLoading) {
      adminProvider.fetchAdminPaymentDetails();
    }
    // Fall back to bank + upi enabled when details aren't loaded yet (legacy default).
    final methods = adminProvider.data?.methods ??
        DepositMethods(bank: true, upi: true, qr: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomCtx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deposit Cash',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(bottomCtx);
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

            // Subtitle
            Text(
              'Choose how to deposit cash into your account',
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Bank Deposit Option
            if (methods.bank) ...[
              _buildDepositOption(
                bottomCtx,
                colorScheme,
                icon: Icons.account_balance,
                title: 'Bank Deposit',
                subtitle: 'Deposit via CDM/ATM',
                onTap: () {
                  Navigator.pop(bottomCtx);
                  _showBankDepositDetailsBottomSheet(context, colorScheme);
                },
              ),
              const SizedBox(height: 16),
            ],

            // UPI Transfer Option
            if (methods.upi) ...[
              _buildDepositOption(
                bottomCtx,
                colorScheme,
                icon: Icons.phone_android,
                title: 'UPI Transfer',
                subtitle: 'Send via UPI',
                onTap: () {
                  Navigator.pop(bottomCtx);
                  _showUPITransferDetailsBottomSheet(context, colorScheme);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Zenfoo QR Option
            if (methods.qr) ...[
              _buildDepositOption(
                bottomCtx,
                colorScheme,
                icon: Icons.qr_code_2,
                title: 'Zenfoo QR',
                subtitle: 'Pay to Zenfoo QR',
                onTap: () {
                  Navigator.pop(bottomCtx);
                  _showZenfooQRDetailsBottomSheet(context, colorScheme);
                },
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositOption(
    BuildContext context,
    AppColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(0x20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 24,
              color: colorScheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showZenfooQRDetailsBottomSheet(BuildContext context, AppColorScheme colorScheme) {
    final adminProvider = context.read<AdminPaymentDetailsProvider>();
    if (adminProvider.data == null && !adminProvider.isLoading) {
      adminProvider.fetchAdminPaymentDetails();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: adminProvider,
        child: Consumer<AdminPaymentDetailsProvider>(
          builder: (_, prov, __) {
            final qrImage = prov.data?.qrImage ?? '';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pay to Zenfoo QR',
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(sheetContext),
                          child: Icon(Icons.close, size: 24, color: colorScheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan this QR with any UPI app, pay the amount, then upload the payment screenshot.',
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // QR Image
                    if (prov.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      )
                    else if (qrImage.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'QR not available right now. Please contact support.',
                          style: GoogleFonts.inter(color: colorScheme.textSecondary, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            qrImage,
                            width: 240,
                            height: 240,
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, progress) => progress == null
                                ? child
                                : const SizedBox(
                                    width: 240,
                                    height: 240,
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                            errorBuilder: (_, __, ___) => SizedBox(
                              width: 240,
                              height: 240,
                              child: Center(
                                child: Text(
                                  'Failed to load QR',
                                  style: GoogleFonts.inter(color: colorScheme.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // I've Paid - Upload Proof
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showUploadProofBottomSheet(context, colorScheme);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'I\'ve Paid - Upload Proof',
                            style: GoogleFonts.inter(
                              color: colorScheme.surface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showBankDepositDetailsBottomSheet(BuildContext context, AppColorScheme colorScheme) {
    final adminProvider = context.read<AdminPaymentDetailsProvider>();
    if (adminProvider.data == null && !adminProvider.isLoading) {
      adminProvider.fetchAdminPaymentDetails();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: adminProvider,
        child: Consumer<AdminPaymentDetailsProvider>(
          builder: (_, prov, __) {
            final paymentDetails = prov.data;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bank Deposit',
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(sheetContext);
                          },
                          child: Icon(Icons.close, size: 24, color: colorScheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (prov.isLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(),
                      ))
                    else ...[
                      // Bank Info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.border, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withAlpha(0x20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.account_balance, size: 20, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    paymentDetails?.bankDetails.bankName ?? '-',
                                    style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Account Available', style: GoogleFonts.inter(color: colorScheme.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Use below account number for depositing cash into the CDM',
                        style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
                      ),
                      const SizedBox(height: 12),

                      // Account Number Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FFEF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF9AC444), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              paymentDetails?.bankDetails.accountNumber ?? '-',
                              style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Clipboard.setData(ClipboardData(text: paymentDetails?.bankDetails.accountNumber ?? ''));
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: Text('Account number copied', style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                                    backgroundColor: colorScheme.primary,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Icon(Icons.copy, size: 20, color: colorScheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Minimum deposit ₹100, ₹500 notes accepted', style: GoogleFonts.inter(color: colorScheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 24),
                      Text('Bank Details:', style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _buildDetailRow('Bank Name', paymentDetails?.bankDetails.bankName ?? '-', colorScheme),
                      const SizedBox(height: 12),
                      _buildDetailRow('Account Holder', paymentDetails?.bankDetails.accountHolderName ?? '-', colorScheme),
                      const SizedBox(height: 12),
                      _buildDetailRow('IFSC Code', paymentDetails?.bankDetails.ifscCode ?? '-', colorScheme),
                      const SizedBox(height: 28),
                      Text('Steps to deposit:', style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _buildStepItem(colorScheme, '1', 'Visit ATM'),
                      _buildStepItem(colorScheme, '2', 'Click on Cardless Cash Deposit'),
                      _buildStepItem(colorScheme, '3', 'Use above account number'),
                      _buildStepItem(colorScheme, '4', 'Complete deposit'),
                      _buildStepItem(colorScheme, '5', 'Collect receipt'),
                      const SizedBox(height: 24),
                      // Upload Proof Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(sheetContext);
                          _showUploadProofBottomSheet(context, colorScheme);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(16)),
                          child: Center(child: Text('I\'ve Paid - Upload Proof', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () { HapticFeedback.lightImpact(); Navigator.pop(sheetContext); },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.border),
                          ),
                          child: Center(child: Text('Close', style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showUploadProofBottomSheet(BuildContext context, AppColorScheme colorScheme) {
    final proofProvider = context.read<PaymentProofProvider>();
    proofProvider.reset();

    final txController = TextEditingController();
    final amountController = TextEditingController();
    File? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ChangeNotifierProvider.value(
          value: proofProvider,
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return Consumer<PaymentProofProvider>(
                builder: (_, prov, __) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40, height: 4,
                                decoration: BoxDecoration(color: colorScheme.border.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Upload Payment Proof', style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                                GestureDetector(
                                  onTap: () => Navigator.pop(sheetContext),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: colorScheme.surfaceElevated, borderRadius: BorderRadius.circular(8)),
                                    child: Icon(Icons.close, color: colorScheme.textPrimary, size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text('Transaction ID / UTR Number', style: GoogleFonts.inter(color: colorScheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: txController,
                              style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'e.g. UTR202603111234567',
                                hintStyle: GoogleFonts.inter(color: colorScheme.textSecondary.withValues(alpha: 0.6), fontSize: 13),
                                filled: true, fillColor: colorScheme.surfaceElevated,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Amount (₹)', style: GoogleFonts.inter(color: colorScheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'e.g. 500',
                                hintStyle: GoogleFonts.inter(color: colorScheme.textSecondary.withValues(alpha: 0.6), fontSize: 13),
                                filled: true, fillColor: colorScheme.surfaceElevated,
                                prefixText: '₹ ', prefixStyle: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Payment Screenshot', style: GoogleFonts.inter(color: colorScheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
                                if (picked != null) {
                                  setSheetState(() => selectedImage = File(picked.path));
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                height: selectedImage != null ? null : 110,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: selectedImage != null ? colorScheme.primary : colorScheme.border),
                                ),
                                child: selectedImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Stack(
                                          children: [
                                            Image.file(selectedImage!, width: double.infinity, fit: BoxFit.cover),
                                            Positioned(
                                              top: 8, right: 8,
                                              child: GestureDetector(
                                                onTap: () => setSheetState(() => selectedImage = null),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.upload_file_rounded, size: 32, color: colorScheme.textSecondary),
                                          const SizedBox(height: 8),
                                          Text('Tap to select screenshot', style: GoogleFonts.inter(color: colorScheme.textSecondary, fontSize: 13)),
                                          Text('JPG / PNG, max 5MB', style: GoogleFonts.inter(color: colorScheme.textSecondary.withValues(alpha: 0.6), fontSize: 11)),
                                        ],
                                      ),
                              ),
                            ),
                            if (prov.error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: colorScheme.error, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(prov.error!, style: GoogleFonts.inter(color: colorScheme.error, fontSize: 12))),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            CustomButton(
                              text: 'Submit Proof',
                              isLoading: prov.isLoading,
                              onPressed: prov.isLoading ? null : () async {
                                final txId = txController.text.trim();
                                final amtText = amountController.text.trim();
                                if (txId.isEmpty || amtText.isEmpty || selectedImage == null) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(content: Text('Please fill all fields and select a screenshot', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: colorScheme.error),
                                  );
                                  return;
                                }
                                final amount = double.tryParse(amtText);
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(content: Text('Please enter a valid amount', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: colorScheme.error),
                                  );
                                  return;
                                }
                                await prov.submitPaymentProof(transactionId: txId, amount: amount, proofImage: selectedImage!);
                                if (!sheetContext.mounted) return;
                                if (prov.isSuccess) {
                                  Navigator.pop(sheetContext);
                                  _showProofSuccessDialog(context, colorScheme);
                                }
                              },
                              boxShadow: const [BoxShadow()],
                              elevation: 0,
                              borderRadius: 12,
                              child: Center(
                                child: Text(
                                  prov.isLoading ? 'Submitting...' : 'Submit Proof',
                                  style: GoogleFonts.inter(color: colorScheme.surface, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showProofSuccessDialog(BuildContext context, AppColorScheme colorScheme) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: colorScheme.success.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded, color: colorScheme.success, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Proof Submitted!', style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Your payment proof has been submitted successfully. Awaiting admin approval.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: colorScheme.textSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('Done', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUPITransferDetailsBottomSheet(BuildContext context, AppColorScheme colorScheme) {
    final provider = context.read<DepositCashProvider>();
    provider.prepareForDeposit();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: Consumer<DepositCashProvider>(
            builder: (sheetContext, p, _) {
              return Container(
                height: MediaQuery.of(sheetContext).size.height * 0.85,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.border.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Deposit Cash',
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(sheetContext),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.close, color: colorScheme.textPrimary, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Select All
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Checkbox(
                            value: p.isAllNotSettledSelected(),
                            onChanged: (val) => p.toggleAllNotSettled(val ?? false),
                            activeColor: colorScheme.primary,
                          ),
                          Text(
                            'Select All Transactions',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colorScheme.textPrimary),
                          ),
                        ],
                      ),
                    ),

                    // Orders list
                    Expanded(
                      child: p.isDepositLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: p.depositTransactions.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, index) {
                                final tx = p.depositTransactions[index];
                                final isSelected = p.selectedTransactionIds.contains(tx.id);
                                return GestureDetector(
                                  onTap: () => p.toggleTransactionSelection(tx.id!),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.primary.withValues(alpha: 0.05)
                                          : colorScheme.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.border.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (_) => p.toggleTransactionSelection(tx.id!),
                                          activeColor: colorScheme.primary,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Order ${formatOrderNumber(tx.orderId)}',
                                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                                              ),
                                              Text(
                                                _formatTxDate(tx),
                                                style: GoogleFonts.inter(color: colorScheme.textSecondary, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '₹${tx.adminCash.toStringAsFixed(0)}',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Pay button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: CustomButton(
                        text: 'Pay ₹${p.selectedAmount.toStringAsFixed(0)}',
                        isLoading: p.isPaymentProcessing,
                        onPressed: p.selectedTransactionIds.isEmpty || p.isPaymentProcessing
                            ? null
                            : () => _handleUPIPayment(sheetContext, p, colorScheme),
                        boxShadow: const [BoxShadow()],
                        elevation: 0,
                        borderRadius: 12,
                        child: Center(
                          child: Text(
                            p.isPaymentProcessing ? 'Processing...' : 'Pay ₹${p.selectedAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(color: colorScheme.surface, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showUploadProofBottomSheet(context, colorScheme);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: Center(
                            child: Text(
                              'I\'ve Paid - Upload Proof',
                              style: GoogleFonts.inter(
                                color: colorScheme.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTxDate(Transaction tx) {
    DateTime? dateToUse;
    if (tx.settledWithAdmin == 1) {
      if (tx.settledAt != null) {
        if (tx.settledAt is String) {
          dateToUse = DateTime.tryParse(tx.settledAt);
        } else if (tx.settledAt is DateTime) {
          dateToUse = tx.settledAt;
        }
      }
      dateToUse ??= tx.transactionDate;
    } else {
      dateToUse = tx.transactionDate;
    }
    if (dateToUse == null) return '';
    return "${dateToUse.day.toString().padLeft(2, '0')}-${dateToUse.month.toString().padLeft(2, '0')}-${dateToUse.year}";
  }

  Future<void> _handleUPIPayment(BuildContext context, DepositCashProvider provider, AppColorScheme colorScheme) async {
    provider.clearPaymentState();
    await provider.processPayment();
    if (!context.mounted) return;
    if (provider.paymentSuccess) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful! Transactions settled.', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: colorScheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      provider.fetchHandCash();
    } else if (provider.paymentError != null) {
      final msg = provider.paymentError == 'Payment is Cancelled' ? 'Payment is Cancelled' : 'Payment is Failed';
      provider.clearPaymentState();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value, AppColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.43,
            letterSpacing: -0.16,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.43,
            letterSpacing: -0.16,
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(AppColorScheme colorScheme, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(0x20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.inter(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.43,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
