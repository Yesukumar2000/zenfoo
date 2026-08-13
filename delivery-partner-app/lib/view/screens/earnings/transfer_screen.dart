import 'dart:io';
import 'package:zenfoo_partner/utils/order_number.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/deposit_cash_model.dart';
import 'package:zenfoo_partner/providers/admin_payment_details_provider.dart';
import 'package:zenfoo_partner/models/admin_payment_details_model.dart';
import 'package:zenfoo_partner/providers/deposit_cash_provider.dart';
import 'package:zenfoo_partner/providers/payment_proof_provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  DateTime _selectedWeekStart = DateTime.now();

  // Dummy transfer data
  final List<TransferTransaction> _transactions = [
    TransferTransaction(
      id: '#1445',
      date: '10/03/2025',
      time: '12:24 AM',
      amount: 150,
      status: 'Completed',
      accountNumber: '****4567',
      dateRange: '09/05/2025 - 15/05/2025',
      earnings: 150,
    ),
    TransferTransaction(
      id: '#1446',
      date: '13/03/2025',
      time: '03:15 PM',
      amount: 200,
      status: 'Completed',
      accountNumber: '****4567',
      dateRange: '10/05/2025 - 16/05/2025',
      earnings: 200,
    ),
    TransferTransaction(
      id: '#1447',
      date: '14/03/2025',
      time: '10:30 AM',
      amount: 180,
      status: 'Processing',
      accountNumber: '****4567',
      dateRange: '11/05/2025 - 17/05/2025',
      earnings: 180,
    ),
    TransferTransaction(
      id: '#1448',
      date: '15/03/2025',
      time: '05:45 PM',
      amount: 160,
      status: 'Failed',
      accountNumber: '****4567',
      dateRange: '12/05/2025 - 18/05/2025',
      earnings: 160,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();
    final totalTransferred = _transactions
        .where((t) => t.status == 'Completed')
        .fold(0, (sum, t) => sum + t.amount);

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // APP HEADER
          AppHeader(
            label: languageProvider.getTranslatedText('wallet'),
            title: 'Transfer',
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
                                '₹$totalTransferred',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
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

                // Deposit Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showDepositBottomSheet(context, colorScheme);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Deposit Cash',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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

  void _showDepositBottomSheet(BuildContext context, dynamic colorScheme) {
    final adminProvider = context.read<AdminPaymentDetailsProvider>();
    if (adminProvider.data == null && !adminProvider.isLoading) {
      adminProvider.fetchAdminPaymentDetails();
    }
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
                  _showUPIOrdersBottomSheet(context, colorScheme);
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
    dynamic colorScheme, {
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

  void _showZenfooQRDetailsBottomSheet(BuildContext context, dynamic colorScheme) {
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

  void _showBankDepositDetailsBottomSheet(BuildContext context, dynamic colorScheme) {
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
                      // Bank Info
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
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
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

  void _showUploadProofBottomSheet(BuildContext context, dynamic colorScheme) {
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
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                    ),
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
                            // Handle bar
                            Center(
                              child: Container(
                                width: 40, height: 4,
                                decoration: BoxDecoration(
                                  color: colorScheme.border.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Upload Payment Proof',
                                  style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
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
                            // Transaction ID field
                            Text('Transaction ID / UTR Number', style: GoogleFonts.inter(color: colorScheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: txController,
                              style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'e.g. UTR202603111234567',
                                hintStyle: GoogleFonts.inter(color: colorScheme.textSecondary.withValues(alpha: 0.6), fontSize: 13),
                                filled: true,
                                fillColor: colorScheme.surfaceElevated,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Amount field
                            Text('Amount (₹)', style: GoogleFonts.inter(color: colorScheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'e.g. 500',
                                hintStyle: GoogleFonts.inter(color: colorScheme.textSecondary.withValues(alpha: 0.6), fontSize: 13),
                                filled: true,
                                fillColor: colorScheme.surfaceElevated,
                                prefixText: '₹ ',
                                prefixStyle: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Image picker
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
                                  border: Border.all(
                                    color: selectedImage != null ? colorScheme.primary : colorScheme.border,
                                    style: selectedImage != null ? BorderStyle.solid : BorderStyle.solid,
                                  ),
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
                            // Error
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
                            // Submit button
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

  void _showProofSuccessDialog(BuildContext context, dynamic colorScheme) {
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

  void _showUPIOrdersBottomSheet(BuildContext context, dynamic colorScheme) {
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
                                  child: Icon(
                                    Icons.close,
                                    color: colorScheme.textPrimary,
                                    size: 20,
                                  ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Checkbox(
                            value: p.isAllNotSettledSelected(),
                            onChanged: (val) =>
                                p.toggleAllNotSettled(val ?? false),
                            activeColor: colorScheme.primary,
                          ),
                          Text(
                            'Select All Transactions',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Orders list
                    Expanded(
                      child: p.isDepositLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              itemCount: p.depositTransactions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, index) {
                                final tx = p.depositTransactions[index];
                                final isSelected = p.selectedTransactionIds
                                    .contains(tx.id);
                                return GestureDetector(
                                  onTap: () =>
                                      p.toggleTransactionSelection(tx.id!),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.primary
                                              .withValues(alpha: 0.05)
                                          : colorScheme.background,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.border
                                                .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (_) => p
                                              .toggleTransactionSelection(
                                                  tx.id!),
                                          activeColor: colorScheme.primary,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Order ${formatOrderNumber(tx.orderId)}',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                _formatTxDate(tx),
                                                style: GoogleFonts.inter(
                                                  color: colorScheme
                                                      .textSecondary,
                                                  fontSize: 12,
                                                ),
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
                        onPressed:
                            p.selectedTransactionIds.isEmpty ||
                                    p.isPaymentProcessing
                                ? null
                                : () => _handleUPIPayment(
                                    sheetContext, p, colorScheme),
                        boxShadow: const [BoxShadow()],
                        elevation: 0,
                        borderRadius: 12,
                        child: Center(
                          child: Text(
                            p.isPaymentProcessing
                                ? 'Processing...'
                                : 'Pay ₹${p.selectedAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              color: colorScheme.surface,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

  Future<void> _handleUPIPayment(BuildContext context,
      DepositCashProvider provider, dynamic colorScheme) async {
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

  Widget _buildStepItem(dynamic colorScheme, String number, String text) {
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

  Widget _buildTransactionItem(TransferTransaction transaction, colorScheme) {
    Color statusColor;
    Color statusBgColor;

    switch (transaction.status) {
      case 'Completed':
        statusColor = const Color(0xFF16A34A);
        statusBgColor = const Color(0xFFDEFFEA);
        break;
      case 'Processing':
        statusColor = colorScheme.warning;
        statusBgColor = colorScheme.warning.withAlpha(0x1F);
        break;
      case 'Failed':
        statusColor = colorScheme.error;
        statusBgColor = colorScheme.error.withAlpha(0x1F);
        break;
      default:
        statusColor = colorScheme.textSecondary;
        statusBgColor = colorScheme.surfaceElevated;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showTransferDetailsBottomSheet(context, transaction, colorScheme);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x14000000),
              blurRadius: 22,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First Row: Status Badge and Date/Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        transaction.status,
                        style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${transaction.date}, ${transaction.time}',
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Date Range Title
            Text(
              transaction.dateRange,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            // Earnings Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Earnings',
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${transaction.earnings}',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferDetailsBottomSheet(
      BuildContext context, TransferTransaction transaction, colorScheme) {
    Color statusColor;
    Color statusBgColor;

    switch (transaction.status) {
      case 'Completed':
        statusColor = const Color(0xFF16A34A);
        statusBgColor = const Color(0xFFDEFFEA);
        break;
      case 'Processing':
        statusColor = colorScheme.warning;
        statusBgColor = colorScheme.warning.withAlpha(0x1F);
        break;
      case 'Failed':
        statusColor = colorScheme.error;
        statusBgColor = colorScheme.error.withAlpha(0x1F);
        break;
      default:
        statusColor = colorScheme.textSecondary;
        statusBgColor = colorScheme.surfaceElevated;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.only(
          top: 13,
          left: 24,
          right: 24,
          bottom: 24,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
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
                  'Transfer',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: -0.16,
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

            // Amount and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${transaction.amount}',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.20,
                    letterSpacing: -0.05,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        transaction.status,
                        style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.33,
                          letterSpacing: -0.12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date Range
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date Range',
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  transaction.dateRange,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.43,
                    letterSpacing: -0.16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Date & Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date & Time',
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${transaction.date}, ${transaction.time}',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payment Mode
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Mode',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.43,
                    letterSpacing: -0.16,
                  ),
                ),
                Text(
                  'Bank',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                    letterSpacing: -0.16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bank Details Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank Details',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.43,
                    letterSpacing: -0.16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                    'Bank Name', 'State Bank of India', colorScheme),
                const SizedBox(height: 12),
                _buildDetailRow('Account Holder', 'Sumanth Gulla', colorScheme),
                const SizedBox(height: 12),
                _buildDetailRow('Account No', '********4547', colorScheme),
                const SizedBox(height: 12),
                _buildDetailRow('IFSC No', 'SBI00043536', colorScheme),
                const SizedBox(height: 12),
                _buildDetailRow('Transaction ID', 'TXN124XYZ9004', colorScheme),
                const SizedBox(height: 12),
                _buildDetailRow(
                    'Amount Status', transaction.status, colorScheme),
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

  Widget _buildDetailRow(String label, String value, colorScheme) {
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
}

class TransferTransaction {
  final String id;
  final String date;
  final String time;
  final int amount;
  final String status;
  final String accountNumber;
  final String dateRange;
  final int earnings;

  TransferTransaction({
    required this.id,
    required this.date,
    required this.time,
    required this.amount,
    required this.status,
    required this.accountNumber,
    required this.dateRange,
    required this.earnings,
  });
}
