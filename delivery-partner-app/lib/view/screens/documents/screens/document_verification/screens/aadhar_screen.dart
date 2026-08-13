import 'dart:io';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/document_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/repository/auth_repository.dart';
import 'package:zenfoo_partner/repository/document_repository.dart';
import 'package:zenfoo_partner/services/local_storage.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/customTextField.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/image_picker_bottom_sheet.dart';

class AadhaarDetailsScreen extends StatefulWidget {
  const AadhaarDetailsScreen({super.key});

  @override
  State<AadhaarDetailsScreen> createState() => _AadhaarDetailsScreenState();
}

class _AadhaarDetailsScreenState extends State<AadhaarDetailsScreen> {

  final TextEditingController _aadharNumberController = TextEditingController();
  final DocumentRepository _documentRepo = DocumentRepository();
  final AuthRepository _authRepo = AuthRepository();
  bool _isUpdating = false;
  bool _hasExistingData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final docProvider = context.read<DocumentProvider>();
      _aadharNumberController.text = docProvider.aadharNumber ?? '';

      // Check if there's existing data from server
      _hasExistingData = docProvider.aadharFrontUrl != null ||
          docProvider.aadharBackUrl != null ||
          (docProvider.aadharNumber != null &&
              docProvider.aadharNumber!.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _aadharNumberController.dispose();
    super.dispose();
  }

  /// Show image picker for Aadhar (front or back)
  void _showImagePicker(bool isFront) {
    final title = isFront ? 'Capture Aadhar Front' : 'Capture Aadhar Back';
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    ImagePickerBottomSheet.show(
      context: context,
      colorScheme: themeProvider.colorScheme,
      onImageSelected: (file) {
        if (mounted) {
          final docProvider = context.read<DocumentProvider>();
          if (isFront) {
            docProvider.setAadharFront(file);
          } else {
            docProvider.setAadharBack(file);
          }
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
      title: title,
    );
  }

  void _removeImage(bool isFront) {
    final docProvider = context.read<DocumentProvider>();
    if (isFront) {
      docProvider.setAadharFront(null);
    } else {
      docProvider.setAadharBack(null);
    }
  }

  Future<void> _submit() async {
    final docProvider = context.read<DocumentProvider>();

    // Validation: Check if at least one field is updated
    final hasNewFrontImage = docProvider.aadharFront != null;
    final hasNewBackImage = docProvider.aadharBack != null;
    final hasNewNumber = _aadharNumberController.text.trim().isNotEmpty;

    // If nothing is changed, just go back
    if (!hasNewFrontImage && !hasNewBackImage && !hasNewNumber) {
      Navigator.pop(context);
      return;
    }

    // If no existing data, require all fields
    if (!_hasExistingData) {
      if (!hasNewFrontImage || !hasNewBackImage || !hasNewNumber) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload both images and enter Aadhar number'),
          ),
        );
        return;
      }
    }

    setState(() => _isUpdating = true);

    try {
      // Update the Aadhar number in provider
      if (hasNewNumber) {
        docProvider.setAadharNumber(_aadharNumberController.text.trim());
      }

      // Call updateDocuments API
      final response = await _documentRepo.updateDocuments(
        aadharNumber: hasNewNumber ? _aadharNumberController.text.trim() : null,
        aadharFront: docProvider.aadharFront,
        aadharBack: docProvider.aadharBack,
      );

      if (mounted) {
        setState(() => _isUpdating = false);

        if (isStatusSuccess(response.status)) {
          // Refresh personal details to get updated document data
          final personalDetailsResponse = await _authRepo.getPersonalDetails();

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
                content: Text('Aadhar details uploaded successfully'),
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
            title: "Aadhar Details",
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
                      /// AADHAR NUMBER FIELD
                      CustomTextFormField(
                        title: "Aadhar Number",
                        controller: _aadharNumberController,
                        hintText: "Enter Aadhar number",
                        keyboardType: TextInputType.number,
                        maxLength: 12,
                        onChanged: (value) {
                          // Update in real-time
                          docProvider.setAadharNumber(value);
                        },
                      ),

                      const SizedBox(height: AppDimensions.paddingLarge),

                      /// FRONT SIDE
                      _buildUploadBox(
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        title: "Front Side",
                        subtitle: "Upload front side of Aadhar card",
                        image: docProvider.aadharFront,
                        imageUrl: docProvider.aadharFrontUrl,
                        onTap: () => _showImagePicker(true),
                        onRemove: () => _removeImage(true),
                      ),

                      const SizedBox(height: AppDimensions.paddingMedium),

                      /// BACK SIDE
                      _buildUploadBox(
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        title: "Back Side",
                        subtitle: "Upload back side of Aadhar card",
                        image: docProvider.aadharBack,
                        imageUrl: docProvider.aadharBackUrl,
                        onTap: () => _showImagePicker(false),
                        onRemove: () => _removeImage(false),
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
                                  "Tips for better photos",
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTip(
                                textTheme, colorScheme, "Ensure good lighting"),
                            _buildTip(textTheme, colorScheme,
                                "Avoid glare and shadows"),
                            _buildTip(textTheme, colorScheme,
                                "All text must be readable"),
                            _buildTip(textTheme, colorScheme,
                                "Image should be clear and focused"),
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
          Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.textSecondary,
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
}
