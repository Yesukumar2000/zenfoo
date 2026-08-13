import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:provider/provider.dart';

/// Image picker bottom sheet with camera and gallery options
class ImagePickerBottomSheet extends StatefulWidget {
  final bool allowMultiple;
  final Function(List<File>) onImagesPicked;
  final String? title;

  const ImagePickerBottomSheet({
    Key? key,
    this.allowMultiple = false,
    required this.onImagesPicked,
    this.title,
  }) : super(key: key);

  static Future<dynamic> show(
    BuildContext context, {
    bool allowMultiple = false,
    required Function(List<File>) onImagesPicked,
    String? title,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => ImagePickerBottomSheet(
        allowMultiple: allowMultiple,
        onImagesPicked: onImagesPicked,
        title: title,
      ),
    );
  }

  @override
  State<ImagePickerBottomSheet> createState() => _ImagePickerBottomSheetState();
}

class _ImagePickerBottomSheetState extends State<ImagePickerBottomSheet> {
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();


  Future<void> _pickFromCamera() async {
    try {
      if (Platform.isIOS) {
        // On iOS, image_picker handles permissions internally
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          requestFullMetadata: true,
        );

        if (image != null && mounted) {
          widget.onImagesPicked([File(image.path)]);
          Navigator.pop(context);
        }
        return;
      }

      PermissionStatus status = await Permission.camera.request();

      if (status.isGranted) {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          requestFullMetadata: true,
        );

        if (image != null) {
          if (mounted) {
            widget.onImagesPicked([File(image.path)]);
            Navigator.pop(context);
          }
        }
      } else if (status.isDenied) {
        _showPermissionError('Camera permission is required to take photos');
      } else if (status.isPermanentlyDenied) {
        _showPermissionDialog('Camera');
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      _showError('Error accessing camera: ${e.toString()}');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      // Pop the bottom sheet BEFORE opening the gallery.
      // On Android, the OS dismisses the sheet when the gallery activity
      // launches, causing showModalBottomSheet's future to complete with null
      // before the user selects an image. By popping with `true` first, the
      // caller can distinguish an intentional gallery open (result == true)
      // from a user-dismissed sheet (result == null).
      if (mounted) Navigator.pop(context, true);

      // NOTE: Do NOT manually request photo permissions here.
      // The image_picker plugin uses system intents / Android photo picker
      // which handle permissions internally. Manually requesting
      // Permission.photos on Android 14+ opens the system's "Select photos"
      // media picker, causing the gallery to appear twice.

      if (widget.allowMultiple) {
        final List<XFile> images = await _imagePicker.pickMultiImage(
          imageQuality: 85,
          requestFullMetadata: true,
        );

        if (images.isNotEmpty) {
          final files = images.map((img) => File(img.path)).toList();
          widget.onImagesPicked(files);
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          requestFullMetadata: true,
        );

        if (image != null) {
          widget.onImagesPicked([File(image.path)]);
        }
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
      _showError('Error accessing gallery: ${e.toString()}');
    }
  }

  void _showPermissionError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPermissionDialog(String permission) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$permission Permission Required',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.textPrimary,
          ),
        ),
        content: Text(
          'This app needs $permission access to select images. Please enable it in app settings.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: Text(
              'Open Settings',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final isMobile = MediaQuery.of(context).size.height < 800;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title ?? 'Select Image',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          color: colorScheme.textSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                color: colorScheme.border,
                height: 24,
                thickness: 1,
              ),
            ),

            // Image options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Camera option
                  _buildImageOption(
                    context: context,
                    icon: Icons.camera_alt_rounded,
                    label: 'Take Photo',
                    subtitle: 'Capture a new photo',
                    onTap: _pickFromCamera,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),

                  // Gallery option
                  _buildImageOption(
                    context: context,
                    icon: Icons.photo_library_rounded,
                    label:
                        widget.allowMultiple ? 'Select Photos' : 'Select Photo',
                    subtitle: widget.allowMultiple
                        ? 'Choose multiple photos'
                        : 'Choose from library',
                    onTap: _pickFromGallery,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),

            // Bottom padding for safe area
            SizedBox(height: isMobile ? 16 : 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required dynamic colorScheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.background.withValues(alpha: 0.5),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.2),
                      colorScheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.textSecondary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colorScheme.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
