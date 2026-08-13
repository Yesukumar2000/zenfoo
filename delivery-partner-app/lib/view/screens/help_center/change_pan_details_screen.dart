import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/customTextField.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/providers/update_personal_info_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/models/get_pan_response_model.dart';
import 'package:zenfoo_partner/view/custom_widgets/image_picker_bottom_sheet.dart';

class ChangePanDetailsScreen extends StatefulWidget {
  const ChangePanDetailsScreen({super.key});

  @override
  State<ChangePanDetailsScreen> createState() => _ChangePanDetailsScreenState();
}

class _ChangePanDetailsScreenState extends State<ChangePanDetailsScreen> {
  final TextEditingController _panNumberController = TextEditingController();
  File? _frontImage;
  File? _backImage;
  bool _removeRemoteFront = false;
  bool _removeRemoteBack = false;
  String _initialPanNumber = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPanDetails();
    });
  }

  Future<void> _fetchPanDetails() async {
    final provider = context.read<UpdatePersonalInfoProvider>();
    await provider.getPan();
    if (mounted && provider.getPanState.status == ApiStatus.success) {
      final panData = provider.getPanState.data as PanDataModel?;
      if (panData?.pan != null) {
        setState(() {
          _initialPanNumber = panData?.pan?.number ?? '';
          _panNumberController.text = _initialPanNumber;
        });
      }
    }
  }

  @override
  void dispose() {
    _panNumberController.dispose();
    super.dispose();
  }

  void _showImagePicker(String title) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final languageProvider = context.read<LanguageProvider>();
    ImagePickerBottomSheet.show(
      context: context,
      colorScheme: themeProvider.colorScheme,
      onImageSelected: (file) {
        if (mounted) {
          setState(() {
            if (title.toLowerCase().contains('front')) {
              _frontImage = file;
              _removeRemoteFront = false;
            } else {
              _backImage = file;
              _removeRemoteBack = false;
            }
          });
        }
      },
      onPermissionDenied: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider
                .getTranslatedText('permission_denied_camera_gallery')),
            duration: const Duration(seconds: 3),
          ),
        );
      },
      title: languageProvider.getTranslatedText('capture_pan_card'),
    );
  }

  void _removeImage(bool isFront) {
    setState(() {
      if (isFront) {
        _frontImage = null;
        _removeRemoteFront = true;
      } else {
        _backImage = null;
        _removeRemoteBack = true;
      }
    });
  }

  void _submit() {
    final languageProvider = context.read<LanguageProvider>();

    // Validation
    if (_panNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              languageProvider.getTranslatedText('please_fill_all_fields')),
        ),
      );
      return;
    }

    final provider = context.read<UpdatePersonalInfoProvider>();
    final panData = (provider.getPanState.data as PanDataModel?);

    final hasNumberChanged =
        _panNumberController.text.trim() != _initialPanNumber;
    final hasFrontChanged = _frontImage != null || _removeRemoteFront;
    final hasBackChanged = _backImage != null || _removeRemoteBack;

    if (!hasNumberChanged && !hasFrontChanged && !hasBackChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Change any field to update'),
        ),
      );
      return;
    }

    // Use provider to update
    provider
        .updatePan(
      panNumber: _panNumberController.text.trim(),
      frontImage: _frontImage,
      backImage: _backImage,
      frontUrl: _removeRemoteFront ? null : panData?.pan?.frontImageUrl,
      backUrl: _removeRemoteBack ? null : panData?.pan?.backImageUrl,
    )
        .then((_) {
      if (mounted) {
        if (provider.updatePanState.status == ApiStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Waiting for the approval'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.updatePanState.message ??
                  languageProvider.getTranslatedText('something_went_wrong')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final languageProvider = context.read<LanguageProvider>();
    final panProvider = context.watch<UpdatePersonalInfoProvider>();
    final isPageLoading = panProvider.getPanState.status == ApiStatus.loading;
    final isUpdating = panProvider.updatePanState.status == ApiStatus.loading;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: languageProvider.getTranslatedText('profile_management'),
            title: languageProvider.getTranslatedText('change_pan_details'),
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
          ),
          if (isPageLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// PAN NUMBER
                    CustomTextFormField(
                      title: languageProvider.getTranslatedText('pan_number'),
                      controller: _panNumberController,
                      hintText: languageProvider
                          .getTranslatedText('enter_pan_number'),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 10,
                    ),

                    const SizedBox(height: 16),

                    _buildUploadBox(
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      languageProvider: languageProvider,
                      title: languageProvider
                          .getTranslatedText('upload_pan_front_image'),
                      image: _frontImage,
                      isFront: true,
                      remoteUrl: _removeRemoteFront
                          ? null
                          : (panProvider.getPanState.data as PanDataModel?)
                              ?.pan
                              ?.frontImageUrl,
                    ),

                    const SizedBox(height: 24),

                    _buildUploadBox(
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      languageProvider: languageProvider,
                      title: languageProvider
                          .getTranslatedText('upload_pan_back_image'),
                      image: _backImage,
                      isFront: false,
                      remoteUrl: _removeRemoteBack
                          ? null
                          : (panProvider.getPanState.data as PanDataModel?)
                              ?.pan
                              ?.backImageUrl,
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
                                languageProvider
                                    .getTranslatedText('important_information'),
                                style: GoogleFonts.inter(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              if ((panProvider.getPanState.data
                                          as PanDataModel?)
                                      ?.pan
                                      ?.status !=
                                  null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Status: ${(panProvider.getPanState.data as PanDataModel?)?.pan?.status ?? ''}',
                                    style: GoogleFonts.inter(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTip(
                            textTheme,
                            colorScheme,
                            languageProvider.getTranslatedText(
                                'pan_number_must_be_10_chars'),
                          ),
                          _buildTip(
                            textTheme,
                            colorScheme,
                            languageProvider
                                .getTranslatedText('name_must_match_pan'),
                          ),
                          _buildTip(
                            textTheme,
                            colorScheme,
                            languageProvider
                                .getTranslatedText('upload_clear_image'),
                          ),
                          _buildTip(
                            textTheme,
                            colorScheme,
                            languageProvider
                                .getTranslatedText('pan_must_be_readable'),
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
              text: 'Update',
              onPressed: isUpdating || isPageLoading ? null : _submit,
              isLoading: isUpdating,
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
    required String title,
    required File? image,
    required bool isFront,
    String? remoteUrl,
  }) {
    final hasImage = image != null;
    final hasRemoteImage = remoteUrl != null && remoteUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.getTranslatedText('pan_card_image'),
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showImagePicker(title),
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
            child: hasImage || hasRemoteImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: hasImage
                            ? Image.file(
                                image,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                remoteUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                  child: Icon(Icons.broken_image,
                                      color: colorScheme.error),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeImage(isFront),
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
                        title,
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
                          color:
                              colorScheme.textSecondary.withValues(alpha: 0.7),
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
}
