import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/selfie_camera_screen.dart';

class SelectSelfieStep extends StatefulWidget {
  final Function(Future<bool> Function())? onSaveCallback;

  const SelectSelfieStep({super.key, this.onSaveCallback});

  @override
  State<SelectSelfieStep> createState() => _SelectSelfieStepState();
}

class _SelectSelfieStepState extends State<SelectSelfieStep> {
  String? selfiePath;
  String? existingImageUrl;
  bool hasRemovedExisting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load existing profile image if available
      final authProvider = context.read<AuthProvider>();
      final deliveryBoy = authProvider.currentDeliveryBoy;

      if (deliveryBoy?.profileImageUrl != null) {
        setState(() {
          existingImageUrl = deliveryBoy!.profileImageUrl;
        });
      }

      // Register save callback with parent form
      if (widget.onSaveCallback != null) {
        widget.onSaveCallback!(_saveProfileImage);
      }
    });
  }

  Future<bool> _saveProfileImage() async {
    // Only call API if user added a new image (not just using existing)
    if (selfiePath != null) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.updateProfileImage(imagePath: selfiePath!);
      return isStatusSuccess(authProvider.updateProfileImageState.status);
    }

    // If no existing image and no new selfie, require photo
    if (existingImageUrl == null && selfiePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a selfie')),
      );
      return false;
    }

    // If user removed existing and didn't add new one, require new photo
    if (hasRemovedExisting && selfiePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a selfie')),
      );
      return false;
    }

    // If existing image is present and not removed, skip API call
    return true;
  }

  Future<void> _takeSelfie() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const SelfieCameraScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        selfiePath = result;
        hasRemovedExisting = true;
      });
    }
  }

  void _removeSelfie() {
    setState(() {
      if (selfiePath != null) {
        // Remove newly captured photo
        selfiePath = null;
      } else if (existingImageUrl != null) {
        // Mark existing as removed
        hasRemovedExisting = true;
        existingImageUrl = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasImage = selfiePath != null || existingImageUrl != null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// 🔹 SELFIE DOTTED CIRCLE
            Stack(
              alignment: Alignment.center,
              children: [
                DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                    radius: const Radius.circular(365),
                    dashPattern: const [6, 6],
                    strokeWidth: 1.5,
                    color: hasImage ? Colors.transparent : colorScheme.border,
                    borderPadding: const EdgeInsets.all(2),
                  ),
                  child: GestureDetector(
                    onTap: _takeSelfie,
                    child: Container(
                      height: AppDimensions.getWidth(65),
                      width: AppDimensions.getWidth(65),
                      padding: EdgeInsets.all(hasImage ? 0 : 5),
                      decoration: BoxDecoration(
                        border: hasImage
                            ? Border.all(width: 5, color: colorScheme.primary)
                            : null,
                        shape: BoxShape.circle,
                        color: colorScheme.surface,
                      ),
                      child: hasImage
                          ? ClipOval(
                              child: selfiePath != null
                                  ? Image.file(
                                      File(selfiePath!),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Image.network(
                                      existingImageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              size: 28,
                                              color: colorScheme.error,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Failed to load',
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: colorScheme.error,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 28,
                                  color: colorScheme.textSecondary,
                                ),
                                const SizedBox(
                                    height: AppDimensions.paddingSmall),
                                Text(
                                  "Take selfie",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                /// Remove button
                if (hasImage)
                  Positioned(
                    top: 0,
                    right: 20,
                    child: GestureDetector(
                      onTap: _removeSelfie,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.border,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppDimensions.paddingLarge),

            /// 🔹 INFO TEXT
            Text(
              "See the difference between the correct photo and the wrong photo, so you know how to take it properly.",
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.textSecondary,
              ),
            ),

            const SizedBox(height: AppDimensions.paddingLarge),

            /// 🔹 SAMPLE IMAGES
            Image.asset(
              AppImages.selfieImage,
              width: AppDimensions.getWidth(90),
            )
          ],
        ),
      ),
    );
  }

  Widget _sampleImage(
    BuildContext context, {
    required String imagePath,
    required bool isCorrect,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: AppDimensions.getSize(30),
          backgroundImage: AssetImage(imagePath),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Icon(
          isCorrect ? Icons.check_circle : Icons.cancel,
          color: isCorrect ? Colors.green : Colors.red,
          size: 18,
        ),
      ],
    );
  }
}
