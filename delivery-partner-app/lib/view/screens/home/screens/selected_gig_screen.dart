import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/home/screens/take_selfie_screen.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';

class SelectedGigScreen extends StatefulWidget {
  const SelectedGigScreen({super.key});

  @override
  State<SelectedGigScreen> createState() => _SelectedGigScreenState();
}

class _SelectedGigScreenState extends State<SelectedGigScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Initialize shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Simulate loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
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
            label: 'SELECTED GIG',
            title: 'Selected Gigs',
            showBackButton: true,
          ),

          const SizedBox(height: 24),

          /// ================= BODY =================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium),
              child: _isLoading
                  ? _buildLoadingSkeleton(colorScheme)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// DATE LABEL
                        Text(
                          'Sun, 04 NOV',
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.55,
                            height: 1.02,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// TIME SLOTS
                        _timeSlot("06:00 AM - 12:00 PM", true, colorScheme),
                        _timeSlot("12:00 PM - 04:30 PM", false, colorScheme),
                        _timeSlot("04:30 PM - 09:00 PM", false, colorScheme),

                        const Spacer(),

                        /// BOOK BUTTON
                        CustomButton(
                          text: "Book",
                          onPressed: () {
                            _showSelfieBottomSheet(context, colorScheme);
                          },
                          height: 52,
                        ),

                        const SizedBox(height: AppDimensions.paddingMedium),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// DATE LABEL SKELETON
        _buildShimmerBox(140, 20, 4, colorScheme),

        const SizedBox(height: 20),

        /// TIME SLOTS SKELETON
        _timeSlotSkeleton(colorScheme),
        _timeSlotSkeleton(colorScheme),
        _timeSlotSkeleton(colorScheme),

        const Spacer(),

        /// BOOK BUTTON SKELETON
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(120),
          ),
          child: Center(
            child: _buildShimmerBox(60, 16, 4, colorScheme),
          ),
        ),

        const SizedBox(height: AppDimensions.paddingMedium),
      ],
    );
  }

  Widget _timeSlotSkeleton(colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildShimmerBox(180, 14, 4, colorScheme),
          ),
          const SizedBox(width: 12),
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(
      double width, double height, double radius, colorScheme) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.surfaceVariant,
                colorScheme.surface,
                colorScheme.surfaceVariant,
              ],
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSelfieBottomSheet(BuildContext context, colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ILLUSTRATION
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                AppImages.deliveryBoy,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            /// TITLE
            Text(
              'Take a selfie',
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),

            const SizedBox(height: 12),

            /// DESCRIPTION
            Text(
              'Keep your face fully visible in good lighting and\nlook straight at the camera.',
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.55,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            /// CAMERA BUTTON
            CustomButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TakeSelfieScreen(),
                  ),
                );
              },
              text: 'Open Camera',
              height: 52,
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  /// ================= TIME SLOT ITEM =================
  Widget _timeSlot(String time, bool selected, colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              time,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
          ),
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary,
                width: selected ? 0 : 1.5,
              ),
            ),
            child: selected
                ? Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: colorScheme.surface,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
