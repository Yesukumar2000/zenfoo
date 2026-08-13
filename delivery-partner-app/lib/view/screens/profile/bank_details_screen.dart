import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/document_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/local_storage.dart';
import 'package:zenfoo_partner/services/razorpay_bank_service.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final TextEditingController _ifscController = TextEditingController();
  bool _isFetchingBankDetails = false;
  String? _bankName;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBankDetails();
    });
    _ifscController.addListener(_onIfscChanged);
  }

  @override
  void dispose() {
    _ifscController.removeListener(_onIfscChanged);
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _loadBankDetails() async {
    final documentProvider = context.read<DocumentProvider>();

    // Load delivery boy data from local storage
    final deliveryBoyData = await LocalStorage.getDeliveryBoyData();

    if (deliveryBoyData != null && deliveryBoyData['documents'] != null) {
      // Load documents from stored delivery boy data
      log(deliveryBoyData['documents'].toString());
      documentProvider.loadDocumentsFromApi(deliveryBoyData['documents']);

      // Pre-fill IFSC code if available
      if (mounted && documentProvider.ifscCode != null) {
        _ifscController.text = documentProvider.ifscCode!;
      }
    }
  }

  void _onIfscChanged() {
    String ifsc = _ifscController.text.trim().toUpperCase();

    // Clear previous error when user starts typing
    if (_fetchError != null) {
      setState(() => _fetchError = null);
    }

    // Only fetch if IFSC code is complete (11 characters)
    if (ifsc.length == 11 && RazorpayBankService.isValidIfscFormat(ifsc)) {
      _fetchBankDetails(ifsc);
    }
  }

  Future<void> _fetchBankDetails(String ifscCode) async {
    if (_isFetchingBankDetails) return;

    setState(() {
      _isFetchingBankDetails = true;
      _fetchError = null;
      _bankName = null;
    });

    try {
      final bankDetails =
          await RazorpayBankService.getBankDetailsByIfsc(ifscCode);

      if (mounted) {
        setState(() {
          _bankName = bankDetails.bankName;
          _isFetchingBankDetails = false;
        });

        // Show success message
        _showSuccessSnackBar('Bank details fetched successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchError = e.toString().replaceAll('Exception: ', '');
          _isFetchingBankDetails = false;
          _bankName = null;
        });

        // Show error message
        _showErrorSnackBar(_fetchError!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final documentProvider = context.watch<DocumentProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          const AppHeader(
            label: 'PAYMENT INFO',
            title: 'Bank Details',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IFSC Input Section
                  _buildIfscInputSection(colorScheme),
                  const SizedBox(height: 24),

                  // Bank Details Display Section
                  if (documentProvider.accountHolderName?.isNotEmpty ?? false)
                    _buildBankDetailsDisplay(colorScheme, documentProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIfscInputSection(AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IFSC Code',
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _fetchError != null
                  ? colorScheme.error
                  : colorScheme.border.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _ifscController,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: InputDecoration(
              hintText: 'Enter IFSC code (e.g., SBIN0000001)',
              hintStyle: GoogleFonts.inter(
                color: colorScheme.inputPlaceholder,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.55,
                height: 1.02,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: _isFetchingBankDetails
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  : _ifscController.text.length == 11 &&
                          RazorpayBankService.isValidIfscFormat(
                              _ifscController.text)
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: colorScheme.success,
                            size: 20,
                          ),
                        )
                      : null,
            ),
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.55,
              height: 1.02,
            ),
          ),
        ),
        if (_fetchError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colorScheme.error,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _fetchError!,
                  style: GoogleFonts.inter(
                    color: colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.55,
                    height: 1.02,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (_bankName != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: colorScheme.success,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Bank: $_bankName',
                style: GoogleFonts.inter(
                  color: colorScheme.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.55,
                  height: 1.02,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBankDetailsDisplay(
      AppColorScheme colorScheme, DocumentProvider documentProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Badge
        _buildStatusBadge(colorScheme, documentProvider.bankDetailsStatus),

        const SizedBox(height: 20),

        // Passbook Image Card
        if (documentProvider.bankPassbookImageUrl != null)
          _buildPassbookImageCard(
              colorScheme, documentProvider.bankPassbookImageUrl!),

        const SizedBox(height: 20),

        // Bank Details Card
        _buildBankDetailsCard(colorScheme, documentProvider),
      ],
    );
  }

  Widget _buildStatusBadge(AppColorScheme colorScheme, String? status) {
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    switch (status?.toLowerCase()) {
      case 'approved':
      case 'verified':
        badgeColor = colorScheme.success;
        statusText = 'Verified';
        statusIcon = Icons.verified_rounded;
        break;
      case 'pending_verification':
        badgeColor = const Color(0xFFFB923C);
        statusText = 'Pending Verification';
        statusIcon = Icons.pending_rounded;
        break;
      case 'rejected':
        badgeColor = colorScheme.error;
        statusText = 'Rejected';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        badgeColor = colorScheme.textSecondary;
        statusText = 'Not Submitted';
        statusIcon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: badgeColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Status',
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: GoogleFonts.inter(
                    color: badgeColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassbookImageCard(AppColorScheme colorScheme, String imageUrl) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.3),
        ),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedImageUpload,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Passbook Image',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showImagePreview(imageUrl),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: colorScheme.primary,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: colorScheme.surfaceVariant,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: colorScheme.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load image',
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailsCard(
      AppColorScheme colorScheme, DocumentProvider documentProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.3),
        ),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedBank,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Account Information',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bank Name
          _buildDetailItem(
            colorScheme,
            'Bank Name',
            documentProvider.bankName ?? 'Not provided',
            HugeIcons.strokeRoundedBank,
          ),

          const SizedBox(height: 16),

          // Account Holder Name
          _buildDetailItem(
            colorScheme,
            'Account Holder Name',
            documentProvider.accountHolderName ?? 'Not provided',
            HugeIcons.strokeRoundedUser,
          ),

          const SizedBox(height: 16),

          // Account Number
          _buildDetailItem(
            colorScheme,
            'Account Number',
            documentProvider.accountNumber ?? 'Not provided',
            HugeIcons.strokeRoundedCreditCard,
            isCopyable: true,
          ),

          const SizedBox(height: 16),

          // IFSC Code
          _buildDetailItem(
            colorScheme,
            'IFSC Code',
            documentProvider.ifscCode ?? 'Not provided',
            HugeIcons.strokeRoundedCode,
            isCopyable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    AppColorScheme colorScheme,
    String label,
    String value,
    dynamic icon, {
    bool isCopyable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.border.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: icon,
                color: colorScheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isCopyable && value != 'Not provided') ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _copyToClipboard(value),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCopy01,
                      color: colorScheme.primary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showSuccessSnackBar(String message) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.55,
                  height: 1.02,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.55,
                  height: 1.02,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied to clipboard',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
