import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenfoo_partner/providers/admin_payment_details_provider.dart';
import 'package:zenfoo_partner/models/admin_payment_details_model.dart';
import 'package:zenfoo_partner/providers/deposit_cash_provider.dart';
import 'package:zenfoo_partner/providers/payment_proof_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

import '../../../../utils/appHeader.dart';
import 'package:zenfoo_partner/models/deposit_cash_model.dart';

class DepositModal extends StatefulWidget {
  const DepositModal({super.key});

  @override
  State<DepositModal> createState() => _DepositModalState();
}

class _DepositModalState extends State<DepositModal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepositCashProvider>().fetchHandCash();
    });
  }

  String _formatDate(Transaction tx) {
    DateTime? dateToUse;
    if (tx.settledWithAdmin == 1) {
      if (tx.settledAt != null) {
        if (tx.settledAt is String) {
          dateToUse = DateTime.tryParse(tx.settledAt);
        } else if (tx.settledAt is DateTime) {
          dateToUse = tx.settledAt;
        }
      }
      // Fallback
      dateToUse ??= tx.transactionDate;
    } else {
      dateToUse = tx.transactionDate;
    }

    if (dateToUse == null) return '';
    return "${dateToUse.day.toString().padLeft(2, '0')}-${dateToUse.month.toString().padLeft(2, '0')}-${dateToUse.year}";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return ChangeNotifierProvider.value(
      value: context.read<DepositCashProvider>(),
      child: Consumer<DepositCashProvider>(
        builder: (context, provider, child) {
          final summary = provider.summary;

          return CustomScaffold(
            backgroundColor: colorScheme.background,
            body: Column(
              children: [
                AppHeader(
                  label: 'Hand Cash',
                  title: 'Deposit Cash',
                  showBackButton: true,
                  onBackPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        /// HEADER

                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: Row(
                            children: [
                              _buildSummaryCard(
                                context,
                                'Total',
                                summary?.totalHandCash ?? 0,
                                0,
                                provider.selectedFilterIndex == 0,
                                colorScheme,
                                () => provider.setFilter(0),
                              ),
                              const SizedBox(width: 10),
                              _buildSummaryCard(
                                context,
                                'Settled',
                                summary?.settledWithAdminTotal ?? 0,
                                2, // Filter index for settled
                                provider.selectedFilterIndex == 2,
                                colorScheme,
                                () => provider.setFilter(2),
                              ),
                              const SizedBox(width: 10),
                              _buildSummaryCard(
                                context,
                                'Not Settled',
                                summary?.notSettledWithAdminTotal ?? 0,
                                1, // Filter index for not settled
                                provider.selectedFilterIndex == 1,
                                colorScheme,
                                () => provider.setFilter(1),
                              ),
                            ],
                          ),
                        ),

                        /// CONTENT
                        if (provider.handCashResponse.status ==
                            ApiStatus.loading)
                          const Expanded(
                              child: Center(child: CircularProgressIndicator()))
                        else if (provider.handCashResponse.status ==
                            ApiStatus.error)
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(provider.handCashResponse.message ??
                                    'Error'),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: provider.transactions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final tx = provider.transactions[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.border
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Order #${tx.orderId ?? ""}',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            '₹${tx.adminCash.toStringAsFixed(0)}',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(tx),
                                        style: GoogleFonts.inter(
                                          color: colorScheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (tx.settledWithAdmin == 1
                                                  ? colorScheme.success
                                                  : colorScheme.warning)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tx.settledWithAdmin == 1
                                              ? 'Settled'
                                              : 'Not Settled',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: tx.settledWithAdmin == 1
                                                ? colorScheme.success
                                                : colorScheme.warning,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                        /// BUTTONS
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Cancel',
                                  onPressed: () => Navigator.pop(context),
                                  boxShadow: const [BoxShadow()],
                                  elevation: 0,
                                  borderRadius: 12,
                                  backgroundColor: colorScheme.surfaceElevated,
                                  textColor: colorScheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomButton(
                                  text: 'Proceed',
                                  onPressed: () {
                                    _showPaymentMethodSelector(context, provider);
                                  },
                                  boxShadow: const [BoxShadow()],
                                  elevation: 0,
                                  borderRadius: 12,
                                ),
                              ),
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
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic colorScheme) {
    return Padding(
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
                onTap: () => Navigator.pop(context),
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
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    double amount,
    int index,
    bool isSelected,
    dynamic colorScheme,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : colorScheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.border.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentMethodSelector(
      BuildContext context, DepositCashProvider provider) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    final adminProvider = context.read<AdminPaymentDetailsProvider>();
    // Always refresh so a stale/failed earlier fetch (e.g. while the server was
    // briefly down) doesn't leave us on the bank+upi fallback forever.
    if (!adminProvider.isLoading) {
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
            // Rebuilds when the fetch completes, so the QR option appears as
            // soon as the admin config loads (instead of being captured once).
            final bool stillLoading = prov.isLoading && prov.data == null;
            final methods = prov.data?.methods ??
                DepositMethods(bank: true, upi: true, qr: false);
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                          Navigator.pop(sheetContext);
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
                  if (stillLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: CircularProgressIndicator(),
                    )
                  else ...[
                    // Bank Deposit
                    if (methods.bank) ...[
                      _buildDepositOption(
                        colorScheme,
                        icon: Icons.account_balance,
                        title: 'Bank Deposit',
                        subtitle: 'Deposit via CDM/ATM',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showBankDepositDetailsBottomSheet(
                              context, colorScheme);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    // UPI
                    if (methods.upi) ...[
                      _buildDepositOption(
                        colorScheme,
                        icon: Icons.phone_android,
                        title: 'UPI Transfer',
                        subtitle: 'Pay via UPI',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showDepositBottomSheet(context, provider);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Zenfoo QR
                    if (methods.qr) ...[
                      _buildDepositOption(
                        colorScheme,
                        icon: Icons.qr_code_2,
                        title: 'Zenfoo QR',
                        subtitle: 'Pay to Zenfoo QR',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showZenfooQRDetailsBottomSheet(context, colorScheme);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (methods.allDisabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No deposit methods are available right now. Please contact support.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDepositOption(
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
          border: Border.all(color: colorScheme.border, width: 1),
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
              child: Icon(icon, size: 24, color: colorScheme.primary),
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
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 24, color: colorScheme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showZenfooQRDetailsBottomSheet(
      BuildContext context, dynamic colorScheme) {
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
                    // Share the QR so the driver can send it to their own UPI
                    // app (or save it), pay, then upload the payment proof.
                    if (qrImage.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () =>
                            _downloadQrImage(context, qrImage, colorScheme),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.ios_share,
                                  size: 18, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Share QR',
                                style: GoogleFonts.inter(
                                  color: colorScheme.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
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

  /// Downloads the Zenfoo QR image and opens the system share sheet so the
  /// driver can send it straight to their UPI app (or save it), pay, then
  /// upload the payment screenshot. Uses temp storage — no extra permissions.
  Future<void> _downloadQrImage(
      BuildContext context, String url, dynamic colorScheme) async {
    if (url.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Preparing QR…',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: colorScheme.primary,
        duration: const Duration(seconds: 1),
      ),
    );
    try {
      final dir = await getTemporaryDirectory();
      final name = Uri.parse(url).pathSegments.isNotEmpty
          ? Uri.parse(url).pathSegments.last
          : 'qr.jpg';
      final ext = name.contains('.') ? name.split('.').last : 'jpg';
      final filePath = '${dir.path}/zenfoo_payment_qr.$ext';
      await Dio().download(url, filePath);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text:
              'Zenfoo Payment QR — scan this in your UPI app to pay, then upload the payment screenshot.',
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not share the QR. Please try again.',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  void _showBankDepositDetailsBottomSheet(
      BuildContext context, dynamic colorScheme) {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bank Deposit', style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                        GestureDetector(
                          onTap: () { HapticFeedback.lightImpact(); Navigator.pop(sheetContext); },
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
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: colorScheme.primary.withAlpha(0x20), borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.account_balance, size: 20, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(paymentDetails?.bankDetails.bankName ?? '-', style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text('Account Available', style: GoogleFonts.inter(color: colorScheme.textSecondary, fontSize: 12)),
                              ],
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Use below account number for depositing cash into the CDM',
                          style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5)),
                      const SizedBox(height: 12),
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
                            Text(paymentDetails?.bankDetails.accountNumber ?? '-',
                                style: GoogleFonts.inter(color: colorScheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Clipboard.setData(ClipboardData(text: paymentDetails?.bankDetails.accountNumber ?? ''));
                                ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(
                                  content: Text('Account number copied', style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                                  backgroundColor: colorScheme.primary,
                                  duration: const Duration(seconds: 2),
                                ));
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
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(sheetContext);
                          _showUploadProofBottomSheet(context, colorScheme);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text("I've Paid - Upload Proof", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
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

  Widget _buildDetailRow(String label, String value, dynamic colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(dynamic colorScheme, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(0x20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.inter(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 13,
            ),
          ),
        ],
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
                  child: Center(child: Text('Done', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepositBottomSheet(
      BuildContext context, DepositCashProvider provider) {
    provider.prepareForDeposit();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: Consumer<DepositCashProvider>(
            builder: (innerCtx, provider, _) {
              final colorScheme = innerCtx.watch<ThemeProvider>().colorScheme;

              return Container(
                height: MediaQuery.of(innerCtx).size.height * 0.85,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(innerCtx, colorScheme),
                    const Divider(height: 1),

                    // Select All Checkbox
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Checkbox(
                            value: provider.isAllNotSettledSelected(),
                            onChanged: (val) =>
                                provider.toggleAllNotSettled(val ?? false),
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

                    Expanded(
                      child: provider.isDepositLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: provider.depositTransactions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final tx = provider.depositTransactions[index];
                                final isSelected = provider
                                    .selectedTransactionIds
                                    .contains(tx.id);

                                return GestureDetector(
                                  onTap: () => provider
                                      .toggleTransactionSelection(tx.id!),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.primary
                                              .withValues(alpha: 0.05)
                                          : colorScheme.background,
                                      borderRadius: BorderRadius.circular(12),
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
                                          onChanged: (_) => provider
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
                                                'Order #${tx.orderId}',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                _formatDate(tx),
                                                style: GoogleFonts.inter(
                                                  color:
                                                      colorScheme.textSecondary,
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


                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: CustomButton(
                        text:
                            'Pay ₹${provider.selectedAmount.toStringAsFixed(0)}',
                        isLoading: provider.isPaymentProcessing,
                        onPressed: provider.selectedTransactionIds.isEmpty ||
                                provider.isPaymentProcessing
                            ? null
                            : () => _handlePayment(innerCtx, provider),
                        boxShadow: const [BoxShadow()],
                        elevation: 0,
                        borderRadius: 12,
                        child: Center(
                          child: Text(
                            provider.isPaymentProcessing
                                ? 'Processing...'
                                : 'Pay ₹${provider.selectedAmount.toStringAsFixed(0)}',
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(bottomCtx);
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
                              "I've Paid - Upload Proof",
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

  Future<void> _handlePayment(
      BuildContext context, DepositCashProvider provider) async {
    provider.clearPaymentState();

    await provider.processPayment();

    if (!context.mounted) return;

    final colorScheme = context.read<ThemeProvider>().colorScheme;

    if (provider.paymentSuccess) {
      Navigator.pop(context); // Close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment successful! Transactions settled.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: colorScheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
}
