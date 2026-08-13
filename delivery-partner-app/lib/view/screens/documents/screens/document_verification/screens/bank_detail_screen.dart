import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/document_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/repository/auth_repository.dart';
import 'package:zenfoo_partner/repository/document_repository.dart';
import 'package:zenfoo_partner/services/local_storage.dart';
import 'package:zenfoo_partner/services/razorpay_bank_service.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/customTextField.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/image_picker_bottom_sheet.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _holderNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final DocumentRepository _documentRepo = DocumentRepository();
  final AuthRepository _authRepo = AuthRepository();
  bool _isUpdating = false;
  bool _isFetchingBank = false;
  bool _hasExistingData = false;
  String? _fetchError;
  String? _fetchedBankName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final docProvider = context.read<DocumentProvider>();
      _bankNameController.text = docProvider.bankName ?? '';
      _holderNameController.text = docProvider.accountHolderName ?? '';
      _accountNumberController.text = docProvider.accountNumber ?? '';
      _ifscController.text = docProvider.ifscCode ?? '';

      // Check if there's existing data from server
      _hasExistingData = docProvider.bankPassbookImageUrl != null ||
          (docProvider.bankName != null && docProvider.bankName!.isNotEmpty) ||
          (docProvider.accountNumber != null &&
              docProvider.accountNumber!.isNotEmpty);
    });
  }

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
    ImagePickerBottomSheet.show(
      context: context,
      colorScheme: themeProvider.colorScheme,
      onImageSelected: (file) {
        if (mounted) {
          final docProvider = context.read<DocumentProvider>();
          docProvider.setBankPassbookImage(file);
        }
      },
      onPermissionDenied: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Please enable camera or gallery access.'),
            duration: Duration(seconds: 3),
          ),
        );
      },
      title: 'Capture Bank Passbook / Cheque',
    );
  }

  void _removeImage() {
    final docProvider = context.read<DocumentProvider>();
    docProvider.setBankPassbookImage(null);
  }

  Future<void> _fetchBankByIfsc() async {
    final ifsc = _ifscController.text.trim().toUpperCase();

    // Validation
    if (ifsc.isEmpty) {
      setState(() {
        _fetchError = 'Please enter IFSC code';
        _isFetchingBank = false;
      });
      return;
    }

    if (!RazorpayBankService.isValidIfscFormat(ifsc)) {
      setState(() {
        _fetchError = 'Invalid IFSC code format';
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

        // Update provider
        final docProvider = context.read<DocumentProvider>();
        docProvider.setBankName(bankDetails.bankName ?? '');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank details fetched successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_fetchError ?? 'Error fetching bank details'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    final docProvider = context.read<DocumentProvider>();

    // Validation: Check if at least one field is updated
    final hasNewImage = docProvider.bankPassbookImage != null;
    final hasNewBankName = _bankNameController.text.trim().isNotEmpty;
    final hasNewHolderName = _holderNameController.text.trim().isNotEmpty;
    final hasNewAccountNumber = _accountNumberController.text.trim().isNotEmpty;
    final hasNewIfsc = _ifscController.text.trim().isNotEmpty;

    // If nothing is changed, just go back
    if (!hasNewImage &&
        !hasNewBankName &&
        !hasNewHolderName &&
        !hasNewAccountNumber &&
        !hasNewIfsc) {
      Navigator.pop(context);
      return;
    }

    // If no existing data, require all fields
    if (!_hasExistingData) {
      if (!hasNewImage ||
          !hasNewBankName ||
          !hasNewHolderName ||
          !hasNewAccountNumber ||
          !hasNewIfsc) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all fields for initial submission'),
          ),
        );
        return;
      }
    }

    setState(() => _isUpdating = true);

    try {
      // Update all fields in provider
      if (hasNewBankName)
        docProvider.setBankName(_bankNameController.text.trim());
      if (hasNewHolderName)
        docProvider.setAccountHolderName(_holderNameController.text.trim());
      if (hasNewAccountNumber)
        docProvider.setAccountNumber(_accountNumberController.text.trim());
      if (hasNewIfsc) docProvider.setIfscCode(_ifscController.text.trim());

      // Call updateDocuments API
      final response = await _documentRepo.updateDocuments(
        bankName: hasNewBankName ? _bankNameController.text.trim() : null,
        accountHolderName:
            hasNewHolderName ? _holderNameController.text.trim() : null,
        accountNumber:
            hasNewAccountNumber ? _accountNumberController.text.trim() : null,
        ifscCode: hasNewIfsc ? _ifscController.text.trim() : null,
        bankPassbookImage: docProvider.bankPassbookImage,
      );

      if (mounted) {
        setState(() => _isUpdating = false);

        if (isStatusSuccess(response.status)) {
          // Refresh personal details to get updated document data
          final personalDetailsResponse =
              await _authRepo.getPersonalDetails();

          if (isStatusSuccess(personalDetailsResponse.status) && mounted) {
            final data = personalDetailsResponse.data;

            // Save updated data to local storage
            await LocalStorage.saveDeliveryBoyData(data);

            // Reload documents into provider
            if (data['documents'] != null) {
              docProvider.loadDocumentsFromApi(data['documents']);
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bank details uploaded successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // Pop after snackbar duration to show the message
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) Navigator.pop(context);
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Upload failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: "DOCUMENTS",
            title: "Bank Details",
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
          ),

          SizedBox(height: AppDimensions.getHeight(2)),

          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Consumer<DocumentProvider>(
                builder: (context, docProvider, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// IFSC CODE WITH SEARCH (AT TOP)
                      _buildIfscSearchSection(
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),

                      const SizedBox(height: AppDimensions.paddingLarge),

                      /// BANK NAME
                      CustomTextFormField(
                        title: "Bank Name",
                        controller: _bankNameController,
                        hintText: "Enter bank name",
                        textCapitalization: TextCapitalization.words,
                        enabled: !_isFetchingBank,
                        onChanged: (value) {
                          docProvider.setBankName(value);
                        },
                      ),

                      const SizedBox(height: AppDimensions.paddingMedium),

                      /// ACCOUNT HOLDER NAME
                      CustomTextFormField(
                        title: "Account Holder Name",
                        controller: _holderNameController,
                        hintText: "Enter account holder name",
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) {
                          docProvider.setAccountHolderName(value);
                        },
                      ),

                      const SizedBox(height: AppDimensions.paddingMedium),

                      /// ACCOUNT NUMBER
                      CustomTextFormField(
                        title: "Account Number",
                        controller: _accountNumberController,
                        hintText: "Enter account number",
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          docProvider.setAccountNumber(value);
                        },
                      ),

                      const SizedBox(height: AppDimensions.paddingLarge),

                      /// PASSBOOK/CHEQUE IMAGE
                      _buildUploadBox(
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        title: "Passbook / Cancelled Cheque",
                        subtitle:
                            "Upload image of bank passbook or cancelled cheque",
                        image: docProvider.bankPassbookImage,
                        imageUrl: docProvider.bankPassbookImageUrl,
                        onTap: _showImagePicker,
                        onRemove: _removeImage,
                      ),

                      const SizedBox(height: AppDimensions.paddingLarge),

                      /// TIPS
                      Container(
                        padding:
                            const EdgeInsets.all(AppDimensions.paddingMedium),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.05),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.borderRadius),
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
                                  "Important Information",
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTip(textTheme, colorScheme,
                                "Account holder name must match your registered name"),
                            _buildTip(textTheme, colorScheme,
                                "Double-check account number before submitting"),
                            _buildTip(textTheme, colorScheme,
                                "IFSC code must be correct for successful payments"),
                            _buildTip(textTheme, colorScheme,
                                "Upload a clear image of passbook or cancelled cheque"),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          /// SUBMIT BUTTON
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: CustomButton(
              text: _hasExistingData ? 'Update' : 'Submit',
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
      padding: const EdgeInsets.only(bottom: 4),
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
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.textSecondary,
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
    required String title,
    required String subtitle,
    required File? image,
    String? imageUrl,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final hasImage = image != null || (imageUrl != null && imageUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: AppDimensions.getHeight(25),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              border: Border.all(
                color: hasImage ? colorScheme.primary : colorScheme.border,
                width: hasImage ? 2 : 1,
              ),
            ),
            child: hasImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadius - 1),
                        child: image != null
                            ? Image.file(
                                image,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                imageUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 40,
                                        color: colorScheme.error,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Failed to load image',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                      // Badge to show if this is from server or local
                      if (image == null && imageUrl != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.cloud_done,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Uploaded',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onRemove,
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
                      const SizedBox(height: AppDimensions.paddingSmall),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "PNG, JPG (Max 5MB)",
                        style: textTheme.bodySmall?.copyWith(
                          color:
                              colorScheme.textSecondary.withValues(alpha: 0.7),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "IFSC Code",
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
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
                    hintText: "Enter IFSC code (e.g., SBIN0000001)",
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.inputPlaceholder,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.textPrimary,
                  ),
                  onChanged: (value) {
                    context.read<DocumentProvider>().setIfscCode(value);
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
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
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
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
