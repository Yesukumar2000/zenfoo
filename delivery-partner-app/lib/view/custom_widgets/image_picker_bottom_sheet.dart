import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zenfoo_partner/services/image_picker_service.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';

class ImagePickerBottomSheet {
  static void show({
    required BuildContext context,
    required AppColorScheme colorScheme,
    Function(File)? onImageSelected,
    Function(List<File>)? onImagesSelected,
    bool allowMultiple = false,
    bool cameraOnly = false,
    required Function()? onPermissionDenied,
    String title = 'Select Image',
  }) {
    assert(onImageSelected != null || onImagesSelected != null,
        'Either onImageSelected or onImagesSelected must be provided');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImagePickerSheet(
        colorScheme: colorScheme,
        onImageSelected: onImageSelected,
        onImagesSelected: onImagesSelected,
        allowMultiple: allowMultiple,
        cameraOnly: cameraOnly,
        onPermissionDenied: onPermissionDenied,
        title: title,
      ),
    );
  }
}

class _ImagePickerSheet extends StatefulWidget {
  final AppColorScheme colorScheme;
  final Function(File)? onImageSelected;
  final Function(List<File>)? onImagesSelected;
  final bool allowMultiple;
  final bool cameraOnly;
  final Function()? onPermissionDenied;
  final String title;

  const _ImagePickerSheet({
    required this.colorScheme,
    this.onImageSelected,
    this.onImagesSelected,
    this.allowMultiple = false,
    this.cameraOnly = false,
    this.onPermissionDenied,
    required this.title,
  });

  @override
  State<_ImagePickerSheet> createState() => _ImagePickerSheetState();
}

class _ImagePickerSheetState extends State<_ImagePickerSheet> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  bool _isGalleryLoading = false;
  bool _isCameraLoading = false;

  Future<bool> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    debugPrint('📷 Camera permission result: $status');

    if (status.isPermanentlyDenied) {
      debugPrint('📷 Camera permanently denied, opening settings...');
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  Future<bool> _checkPhotoPermission() async {
    final status = await Permission.mediaLibrary.request();
    debugPrint('📸 Photo permission result: $status');

    if (status.isPermanentlyDenied) {
      debugPrint('📸 Photo permanently denied, opening settings...');
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isGalleryLoading = true);

    try {
      debugPrint('🎬 Starting gallery picker...');

      if (widget.allowMultiple) {
        final files = await _imagePickerService.pickMultiImageFromGallery();

        debugPrint(
            '🎬 Gallery result: ${files.isNotEmpty ? "Success" : "Cancelled"}');

        if (files.isNotEmpty && mounted) {
          Navigator.pop(context);
          if (widget.onImagesSelected != null) {
            widget.onImagesSelected!(files);
          } else if (widget.onImageSelected != null) {
            widget.onImageSelected!(files.first);
          }
        } else if (mounted) {
          // Optional: Show error only if strictly needed, usually cancellation isn't an error
          // _showError('Failed to select images. Please try again.');
        }
      } else {
        final file = await _imagePickerService.pickImageFromGallery();

        debugPrint(
            '🎬 Gallery result: ${file != null ? "Success" : "Cancelled"}');

        if (file != null && mounted) {
          Navigator.pop(context);
          if (widget.onImageSelected != null) {
            widget.onImageSelected!(file);
          } else if (widget.onImagesSelected != null) {
            widget.onImagesSelected!([file]);
          }
        } else if (mounted) {
          // _showError('Failed to select image. Please try again.');
        }
      }
    } catch (e) {
      debugPrint('❌ Gallery error: $e');
      if (mounted) {
        _showError('Error accessing photo library: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGalleryLoading = false);
      }
    }
  }

  Future<void> _pickFromCamera() async {
    setState(() => _isCameraLoading = true);

    try {
      debugPrint('📷 Starting camera...');

      // Check if permission is permanently denied
      final hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        setState(() => _isCameraLoading = false);
        return;
      }

      final file = await _imagePickerService.pickImageFromCamera();

      debugPrint('📷 Camera result: ${file != null ? "Success" : "Cancelled"}');

      if (file != null && mounted) {
        Navigator.pop(context);
        if (widget.onImageSelected != null) {
          widget.onImageSelected!(file);
        } else if (widget.onImagesSelected != null) {
          widget.onImagesSelected!([file]);
        }
      } else if (mounted) {
        _showError('Failed to capture image. Please try again.');
      }
    } catch (e) {
      debugPrint('❌ Camera error: $e');
      if (mounted) {
        _showError('Error accessing camera: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCameraLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: widget.colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 16),
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color:
                        widget.colorScheme.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // Title
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: widget.colorScheme.textPrimary,
                  ),
                ),
              ),

              // Gallery Option (hidden when camera-only, e.g. during an active order)
              if (!widget.cameraOnly)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildOption(
                    icon: Icons.image_rounded,
                    label: widget.allowMultiple
                        ? 'Select Photos'
                        : 'Choose from Gallery',
                    description: widget.allowMultiple
                        ? 'Choose multiple photos'
                        : 'Select from your photos',
                    onTap: (_isGalleryLoading || _isCameraLoading)
                        ? null
                        : _pickFromGallery,
                    isLoading: _isGalleryLoading,
                  ),
                ),

              // Camera Option
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Take Photo',
                  description: 'Capture using camera',
                  onTap: (_isGalleryLoading || _isCameraLoading)
                      ? null
                      : _pickFromCamera,
                  isLoading: _isCameraLoading,
                ),
              ),

              // Cancel Button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: widget.colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.colorScheme.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: widget.colorScheme.textPrimary,
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
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.colorScheme.cardBorder,
            width: 1,
          ),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.colorScheme.primary,
                    ),
                  ),
                ),
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: widget.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.colorScheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: widget.colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
