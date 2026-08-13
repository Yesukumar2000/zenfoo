import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/selfie_camera_screen.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';

class TakeSelfieScreen extends StatefulWidget {
  const TakeSelfieScreen({super.key});

  @override
  State<TakeSelfieScreen> createState() => _TakeSelfieScreenState();
}

class _TakeSelfieScreenState extends State<TakeSelfieScreen> {
  String? selfiePath;

  Future<void> _takeSelfie() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelfieCameraScreen(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        selfiePath = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// ================= APP HEADER =================
          const AppHeader(
            label: 'GO ON DUTY',
            title: 'Take Selfie',
            showBackButton: true,
          ),

          const SizedBox(height: 24),

          /// ================= BODY =================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// SELFIE PREVIEW
                  GestureDetector(
                    onTap: _takeSelfie,
                    child: Container(
                      height: 280,
                      width: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.border.withValues(alpha: 0.2),
                        border: Border.all(
                          color: selfiePath != null
                              ? colorScheme.primary
                              : colorScheme.border.withValues(alpha: 0.5),
                          width: selfiePath != null ? 4 : 2,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                      child: selfiePath != null
                          ? ClipOval(
                              child: Image.file(
                                File(selfiePath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 64,
                                  color: colorScheme.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tap to take selfie',
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.55,
                                    height: 1.02,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// INFO TEXT
                  Text(
                    'See the difference between the correct photo and the wrong photo, so you know how to take it properly.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.55,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// SAMPLE IMAGES
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppImages.selfieImage,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          /// CONTINUE BUTTON
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: CustomButton(
              text: selfiePath != null ? 'Continue' : 'Take Selfie',
              onPressed: () {
                if (selfiePath != null) {
                  // Navigate to next screen with selfie path
                  Navigator.pop(context, selfiePath);
                } else {
                  _takeSelfie();
                }
              },
              height: 52,
            ),
          ),
        ],
      ),
    );
  }
}
