import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

import '../../../providers/language_provider.dart';
import '../../../utils/appHeader.dart';
import '../../custom_widgets/image_picker_bottom_sheet.dart';
import 'rain_mode_success_screen.dart';

class RainModeActivationScreen extends StatefulWidget {
  const RainModeActivationScreen({super.key});

  @override
  State<RainModeActivationScreen> createState() =>
      _RainModeActivationScreenState();
}

class _RainModeActivationScreenState extends State<RainModeActivationScreen> {
  File? _selectedImage;

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

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
            content: Text(languageProvider
                .getTranslatedText('permission_denied_camera_gallery')),
            duration: const Duration(seconds: 3),
          ),
        );
      },
      title: languageProvider.getTranslatedText('capture_bank_passbook'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final languageProvider = context.read<LanguageProvider>();
    // final provider = context.watch<FloatingCashIssueProvider>();
    return SafeArea(
      bottom: true,
      top: false,
      child: CustomScaffold(
        backgroundColor: colorScheme.background,
        body: Column(
          children: [
            AppHeader(
              label: languageProvider.getTranslatedText('help_center'),
              title: 'Rain Mode Activation',
              showBackButton: true,
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildUploadBox(
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      languageProvider: languageProvider,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RainModeSuccessScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Active Rain Mode',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
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
          'Proof of rain mode activation',
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
                        'Upload image proof of rain mode activation',
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
