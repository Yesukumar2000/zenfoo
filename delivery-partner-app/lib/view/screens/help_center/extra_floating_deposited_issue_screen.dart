import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/help_center/driver_issues_screen.dart';
import 'package:zenfoo_partner/view/custom_widgets/image_picker_bottom_sheet.dart';

class ExtraFloatingDepositedIssueScreen extends StatefulWidget {
  final String issueType;

  const ExtraFloatingDepositedIssueScreen({
    super.key,
    required this.issueType,
  });

  @override
  State<ExtraFloatingDepositedIssueScreen> createState() =>
      _ExtraFloatingDepositedIssueScreenState();
}

class _ExtraFloatingDepositedIssueScreenState
    extends State<ExtraFloatingDepositedIssueScreen> {
  final ApiService _apiService = ApiService();
  late TextEditingController _transactionIdController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String _selectedDepositType;
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _transactionIdController = TextEditingController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDepositType = 'icic_cash_deposit';
  }

  @override
  void dispose() {
    _transactionIdController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showImagePicker() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final languageProvider = context.read<LanguageProvider>();
    ImagePickerBottomSheet.show(
      context: context,
      colorScheme: themeProvider.colorScheme,
      onImageSelected: (file) {
        setState(() {
          _selectedImage = file;
        });
      },
      onPermissionDenied: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.getTranslatedText('permission_denied_camera_gallery')),
            duration: const Duration(seconds: 3),
          ),
        );
      },
      title: languageProvider.getTranslatedText('upload_transaction_proof'),
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  String get _payType {
    return _selectedDepositType == 'upi_cash_transfer' ? 'upi' : 'bank';
  }

  Future<void> _handleSubmit() async {
    final languageProvider = context.read<LanguageProvider>();

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.getTranslatedText('please_fill_all_fields'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isSubmitting) return;

    HapticFeedback.heavyImpact();
    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        'issue_type': 'extra_floating_deposited',
        'amount': _amountController.text.trim(),
        'pay_type': _payType,
      };

      if (_transactionIdController.text.trim().isNotEmpty) {
        final transactionId =
            int.tryParse(_transactionIdController.text.trim());
        if (transactionId != null) {
          data['issue_ids[0]'] = transactionId;
        }
      }

      if (_descriptionController.text.trim().isNotEmpty) {
        data['description'] = _descriptionController.text.trim();
      }

      Map<String, File>? files;
      if (_selectedImage != null) {
        files = {'attachments[0]': _selectedImage!};
      }

      final response = await _apiService.post(
        AppUrl.extraFloatingDeposited,
        data: data,
        files: files,
        isToast: false,
      );

      if (!mounted) return;

      if (response.status == ApiStatus.success) {
        _showSuccessDialog(response.data?['message']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to submit issue'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog([String? message]) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _SuccessScreen(
          colorScheme: colorScheme,
          title: languageProvider.getTranslatedText('request_sent'),
          message: message ??
              languageProvider.getTranslatedText('we_will_get_back_to_you'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF9AC444),
                    colorScheme.background,
                  ],
                ),
              ),
              child: AppHeader(
                label: languageProvider.getTranslatedText('support'),
                title: widget.issueType,
                onBackPressed: () => Navigator.pop(context),
                showBackButton: true,
                trailing: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DriverIssuesScreen(
                            fixedIssueType: 'extra_floating_deposited'),
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.watch<ThemeProvider>().isDarkMode
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.watch<ThemeProvider>().isDarkMode
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.black,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.history,
                        color: context.watch<ThemeProvider>().isDarkMode
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 24,
                children: [
                  // Select deposit type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Text(
                        languageProvider.getTranslatedText(
                            'select_type_of_cash_deposit'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          letterSpacing: -0.55,
                        ),
                      ),
                      Column(
                        spacing: 12,
                        children: [
                          _buildDepositTypeOption(
                            'icic_cash_deposit',
                            languageProvider.getTranslatedText('icic_cash_deposit'),
                            colorScheme,
                          ),
                          _buildDepositTypeOption(
                            'upi_cash_transfer',
                            languageProvider.getTranslatedText('upi_cash_transfer'),
                            colorScheme,
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Transaction ID
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Text(
                        languageProvider.getTranslatedText(
                            'enter_your_transaction_id'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          letterSpacing: -0.55,
                        ),
                      ),
                      Container(
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: TextField(
                          controller: _transactionIdController,
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.43,
                          ),
                          decoration: InputDecoration(
                            hintText: languageProvider.getTranslatedText('enter_transaction_id'),
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF7C7575),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.43,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Extra amount received
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Text(
                        languageProvider.getTranslatedText('extra_amount_received'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          letterSpacing: -0.55,
                        ),
                      ),
                      Container(
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: TextField(
                          controller: _amountController,
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.43,
                          ),
                          decoration: InputDecoration(
                            hintText: languageProvider.getTranslatedText('enter_amount'),
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF7C7575),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.43,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Upload transaction proof
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Text(
                        languageProvider
                            .getTranslatedText('upload_transaction_proof'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          letterSpacing: -0.55,
                        ),
                      ),
                      if (_selectedImage != null)
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 140,
                              decoration: ShapeDecoration(
                                color: const Color(0xFFF2F2F2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: ShapeDecoration(
                                    color: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: _showImagePicker,
                          child: Container(
                            width: double.infinity,
                            height: 140,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFF2F2F2),
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  color: Color(0xFF6B7280),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 8,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF6B7280),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: const Center(
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedUpload02,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                Text(
                                  languageProvider.getTranslatedText('png_jpg'),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Text(
                        languageProvider.getTranslatedText('describe_problem'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          letterSpacing: -0.55,
                        ),
                      ),
                      Container(
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: TextField(
                          controller: _descriptionController,
                          minLines: 5,
                          maxLines: 5,
                          textAlignVertical: TextAlignVertical.top,
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.43,
                          ),
                          decoration: InputDecoration(
                            hintText: languageProvider.getTranslatedText('type_message'),
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF7C7575),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.43,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: ShapeDecoration(
                      color: _isSubmitting
                          ? const Color(0xFF9AC444).withValues(alpha: 0.6)
                          : const Color(0xFF9AC444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSubmitting ? null : _handleSubmit,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  languageProvider
                                      .getTranslatedText('send_enquiry'),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositTypeOption(String key, String displayLabel, AppColorScheme colorScheme) {
    final isSelected = _selectedDepositType == key;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDepositType = key;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: double.infinity,
        height: 47,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              displayLabel,
              style: GoogleFonts.inter(
                color: const Color(0xFF2A2B2D),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.43,
              ),
            ),
            // Custom Radio Button
            Container(
              width: 24,
              height: 24,
              decoration: ShapeDecoration(
                color: isSelected ? const Color(0xFFA9F4A7) : const Color(0xFFE5E7EB),
                shape: const OvalBorder(),
              ),
              child: isSelected
                  ? const Center(
                      child: SizedBox(
                        width: 13,
                        height: 13,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: Color(0xFF029100),
                            shape: OvalBorder(),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessScreen extends StatefulWidget {
  final AppColorScheme colorScheme;
  final String title;
  final String message;

  const _SuccessScreen({
    required this.colorScheme,
    required this.title,
    required this.message,
  });

  @override
  State<_SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<_SuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF029100),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
