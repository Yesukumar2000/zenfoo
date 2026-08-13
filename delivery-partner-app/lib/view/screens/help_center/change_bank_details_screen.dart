import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/razorpay_bank_service.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/customTextField.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/image_picker_bottom_sheet.dart';

class ChangeBankDetailsScreen extends StatefulWidget {
  const ChangeBankDetailsScreen({super.key});

  @override
  State<ChangeBankDetailsScreen> createState() =>
      _ChangeBankDetailsScreenState();
}

class _ChangeBankDetailsScreenState extends State<ChangeBankDetailsScreen> {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _holderNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscController = TextEditingController();

  bool _isUpdating = false;
  bool _isFetchingBank = false;
  String? _fetchError;
  String? _fetchedBankName;
  File? _selectedImage;

  @override
  void dispose() {
    _bankNameController.dispose();
    _holderNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  /// Show image picker for bank passbook
  void _showImagePicker() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final languageProvider = context.read<LanguageProvider>();
    ImagePickerBottomSheet.show(
      context: context,
      colorScheme: themeProvider.colorScheme,
      onImageSelected: (file) {
        if (mounted) {
          setState(() {
            _selectedImage = file;
          });
        }
      },
      onPermissionDenied: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.getTranslatedText('permission_denied_camera_gallery')),
            duration: const Duration(seconds: 3),
          ),
        );
      },
      title: languageProvider.getTranslatedText('capture_bank_passbook'),
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _fetchBankByIfsc() async {
    final ifsc = _ifscController.text.trim().toUpperCase();
    final languageProvider = context.read<LanguageProvider>();

    // Validation
    if (ifsc.isEmpty) {
      setState(() {
        _fetchError = languageProvider.getTranslatedText('please_enter_ifsc');
        _isFetchingBank = false;
      });
      return;
    }

    if (!RazorpayBankService.isValidIfscFormat(ifsc)) {
      setState(() {
        _fetchError = languageProvider.getTranslatedText('invalid_ifsc_format');
        _isFetchingBank = false;
      });
      return;
    }

    setState(() {
      _isFetchingBank = true;
      _fetchError = null;
      _fetchedBankName = null;
    });

    try {
      final bankDetails = await RazorpayBankService.getBankDetailsByIfsc(ifsc);

      if (mounted) {
        setState(() {
          _fetchedBankName = bankDetails.bankName;
          _bankNameController.text = bankDetails.bankName ?? '';
          _isFetchingBank = false;
          _fetchError = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.getTranslatedText('bank_details_fetched')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchError = e.toString().replaceAll('Exception: ', '');
          _isFetchingBank = false;
          _fetchedBankName = null;
        });

        final errorMessage = _fetchError ?? languageProvider.getTranslatedText('error_fetching_bank_details');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _submit() {
    final languageProvider = context.read<LanguageProvider>();

    // Validation
    if (_bankNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.getTranslatedText('please_fill_all_fields')),
        ),
      );
      return;
    }

    if (_holderNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.getTranslatedText('please_fill_all_fields')),
        ),
      );
      return;
    }

    if (_accountNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.getTranslatedText('please_fill_all_fields')),
        ),
      );
      return;
    }

    if (_ifscController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.getTranslatedText('please_enter_ifsc')),
        ),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.getTranslatedText('please_upload_passbook_image')),
        ),
      );
      return;
    }

    // Show success message (UI only - as requested)
    setState(() => _isUpdating = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isUpdating = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.getTranslatedText('bank_details_updated')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final languageProvider = context.read<LanguageProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: languageProvider.getTranslatedText('profile_management'),
            title: languageProvider.getTranslatedText('change_bank_details'),
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),

          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// IFSC CODE WITH SEARCH (AT TOP)
                  _buildIfscSearchSection(
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    languageProvider: languageProvider,
                  ),

                  const SizedBox(height: 24),

                  /// BANK NAME
                  CustomTextFormField(
                    title: languageProvider.getTranslatedText('bank_name'),
                    controller: _bankNameController,
                    hintText: languageProvider.getTranslatedText('enter_bank_name'),
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isFetchingBank,
                  ),

                  const SizedBox(height: 16),

                  /// ACCOUNT HOLDER NAME
                  CustomTextFormField(
                    title: languageProvider.getTranslatedText('account_holder_name'),
                    controller: _holderNameController,
                    hintText: languageProvider.getTranslatedText('enter_account_holder_name'),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  /// ACCOUNT NUMBER
                  CustomTextFormField(
                    title: languageProvider.getTranslatedText('account_number'),
                    controller: _accountNumberController,
                    hintText: languageProvider.getTranslatedText('enter_account_number'),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 24),

                  /// PASSBOOK/CHEQUE IMAGE
                  _buildUploadBox(
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    languageProvider: languageProvider,
                  ),

                  const SizedBox(height: 24),

                  /// TIPS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              languageProvider.getTranslatedText('important_information'),
                              style: GoogleFonts.inter(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTip(
                          textTheme,
                          colorScheme,
                          languageProvider.getTranslatedText('account_holder_name_must_match'),
                        ),
                        _buildTip(
                          textTheme,
                          colorScheme,
                          languageProvider.getTranslatedText('double_check_account_number'),
                        ),
                        _buildTip(
                          textTheme,
                          colorScheme,
                          languageProvider.getTranslatedText('ifsc_code_must_be_correct'),
                        ),
                        _buildTip(
                          textTheme,
                          colorScheme,
                          languageProvider.getTranslatedText('upload_clear_image'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// SUBMIT BUTTON
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomButton(
              text: languageProvider.getTranslatedText('update'),
              onPressed: _isUpdating ? null : _submit,
              isLoading: _isUpdating,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(TextTheme textTheme, colorScheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox({
    required colorScheme,
    required TextTheme textTheme,
    required LanguageProvider languageProvider,
  }) {
    final hasImage = _selectedImage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.getTranslatedText('passbook_cheque'),
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImagePicker,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasImage ? colorScheme.primary : colorScheme.border,
                width: hasImage ? 2 : 1,
              ),
            ),
            child: hasImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close,
                              color: colorScheme.error,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: colorScheme.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        languageProvider.getTranslatedText('upload_passbook_cheque'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        languageProvider.getTranslatedText('png_jpg_max_5mb'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildIfscSearchSection({
    required colorScheme,
    required TextTheme textTheme,
    required LanguageProvider languageProvider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.getTranslatedText('ifsc_code'),
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ifscController,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_isFetchingBank,
                  decoration: InputDecoration(
                    hintText: languageProvider.getTranslatedText('enter_ifsc_code'),
                    hintStyle: GoogleFonts.inter(
                      color: colorScheme.inputPlaceholder,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                  ),
                  onChanged: (value) {
                    setState(() => _fetchError = null);
                  },
                  maxLength: 11,
                  buildCounter: (context,
                      {required currentLength,
                      required isFocused,
                      required maxLength}) {
                    return null;
                  },
                ),
              ),
              if (_isFetchingBank)
                Padding(
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
              else
                GestureDetector(
                  onTap: _ifscController.text.length == 11
                      ? _fetchBankByIfsc
                      : null,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _ifscController.text.length == 11
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_fetchError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
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
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (_fetchedBankName != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: colorScheme.success,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Bank: $_fetchedBankName',
                style: GoogleFonts.inter(
                  color: colorScheme.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
