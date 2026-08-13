import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/resgistration/food/food_registration_provider.dart';
import 'dart:ui';
import 'package:project/helper/utils/custom_text_form_field.dart';
import 'package:project/helper/widgets/app_header.dart';

class EditPersonalProfileScreen extends StatefulWidget {
  const EditPersonalProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditPersonalProfileScreen> createState() =>
      _EditPersonalProfileScreenState();
}

class _EditPersonalProfileScreenState extends State<EditPersonalProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<FoodRegistrationProvider>(context, listen: false);
      // Assuming we have a way to get the current seller data.
      // For now, let's assume the provider might already have it or we fetch it.
      // If the provider is scoped to this screen, we might need to fetch data here.
      // However, since we are reusing FoodRegistrationProvider, we should check if it needs initialization.
      // Ideally, we should fetch the current profile data and populate the form.
      // provider.getSellerData(); // We might need to implement this or use existing logic.

      // For now, I'll assume the provider has a method to fetch data or we pass it.
      // Let's trigger a fetch if needed.

      provider.fetchSellerData(
          storeId: Constant.session.getData(SessionManager.keyStoreId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    return Consumer<FoodRegistrationProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: colorScheme.background,
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: colorScheme.background,
              boxShadow: colorScheme.cardShadow,
            ),
            child: SafeArea(
              child: Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return gradientBtnWidget(
                    context,
                    10,
                    title: provider.isSubmitting ? "" : getTranslatedValue(context, updateProfileLabel),
                    callback: () {
                      if (provider.validateStep1() == null) {
                        // Call update API
                        provider.updatePersonalProfile(context,
                            Constant.session.getData(SessionManager.keyStoreId));
                      } else {
                        showMessage(context, provider.validateStep1()!,
                            MessageType.warning);
                      }
                    },
                    otherWidgets: provider.isSubmitting
                        ? Center(
                            child: CircularProgressIndicator(
                                color: colorScheme.primary))
                        : null,
                  );
                },
              ),
            ),
          ),
          body: Column(
            children: [
              Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return AppHeader(
                    label: getTranslatedValue(context, editProfileLabel),
                    title: getTranslatedValue(context, personalInformationLabel),
                    showBackButton: true,
                  );
                },
              ),
              Expanded(
                child: provider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Consumer<LanguageProvider>(
                          builder: (context, languageProvider, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomTextFormField(
                                  title: getTranslatedValue(context, nameLabel),
                                  hintText: getTranslatedValue(context, enterYourNameLabel),
                                  controller: provider.userNameController,
                                  prefixIcon: Icon(Icons.person_outline,
                                      size: 22, color: colorScheme.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  title: getTranslatedValue(context, emailAddressLabel),
                                  hintText: getTranslatedValue(context, enterEmailAddressLabel),
                                  controller: provider.emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icon(Icons.email_outlined,
                                      size: 22, color: colorScheme.textSecondary),
                                ),
                                // SizedBox(height: 16),
                                // CustomTextFormField(
                                //   title: "Mobile Number",
                                //   hintText: "Enter Mobile Number",
                                //   controller: provider.mobileController,
                                //   keyboardType: TextInputType.phone,
                                //   prefixIcon: Icon(Icons.phone_outlined,
                                //       size: 22, color: colorScheme.textSecondary),
                                //   readOnly:
                                //       true, // Usually mobile number is not editable or requires OTP
                                // ),
                                const SizedBox(height: 16),
                                // Password fields might not be needed for simple profile edit unless requested.
                                // Skipping password for now as it usually requires a separate flow.

                                // SizedBox(height: 24),
                                _UploadTile(
                                  title: getTranslatedValue(context, aadharCardLabel),
                                  uploadLabel:
                                      getTranslatedValue(context, uploadAadharLabel),
                                  file: provider.aadharFile,
                                  imageUrl: provider.aadharImageUrl,
                                  onTap: () async {
                                    final picked = await pickPDFOrImage(context);
                                    if (picked != null)
                                      provider.setAadharFile(picked);
                                  },
                                ),
                                const SizedBox(height: 12),
                                CustomTextFormField(
                                  title: getTranslatedValue(context, aadharNumberLabel),
                                  hintText:
                                      "e.g. ${AppValidators.aadhaarExample.replaceAll(' ', '')}",
                                  helperText:
                                      "12 digits, exactly as printed on the card",
                                  controller: provider.aadharNumberController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 12,
                                  validator: AppValidators.aadhaar,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(12),
                                  ],
                                  prefixIcon:  Icon(Icons.credit_card,
                                      size: 22, color: colorScheme.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                _UploadTile(
                                  title: getTranslatedValue(context, panCardLabel),
                                  uploadLabel:
                                      getTranslatedValue(context, uploadPanLabel),
                                  file: provider.panFile,
                                  imageUrl: provider.panImageUrl,
                                  onTap: () async {
                                    final picked = await pickPDFOrImage(context);
                                    if (picked != null) provider.setPanFile(picked);
                                  },
                                ),
                                const SizedBox(height: 12),
                                CustomTextFormField(
                                  title: getTranslatedValue(context, panNumberLabel),
                                  hintText: "e.g. ${AppValidators.panExample}",
                                  helperText:
                                      "10 characters — 5 letters, 4 digits, then 1 letter",
                                  controller: provider.panNumberController,
                                  keyboardType: TextInputType.text,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  maxLength: 10,
                                  validator: AppValidators.pan,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r'[^a-zA-Z0-9]')),
                                    LengthLimitingTextInputFormatter(10),
                                    UpperCaseTextFormatter(),
                                  ],
                                  prefixIcon: Icon(Icons.credit_card,
                                      size: 22, color: colorScheme.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                _UploadTile(
                                  title: getTranslatedValue(context, fssaiLabel),
                                  uploadLabel:
                                      getTranslatedValue(context, uploadFssaiLabel),
                                  file: provider.fassiFile,
                                  imageUrl: provider.fssaiImageUrl,
                                  onTap: () async {
                                    final picked = await pickPDFOrImage(context);
                                    if (picked != null)
                                      provider.setFassiFile(picked);
                                  },
                                ),
                                const SizedBox(height: 12),
                                CustomTextFormField(
                                  title: getTranslatedValue(context, fssaiNumberLabel),
                                  hintText: "e.g. ${AppValidators.fssaiExample}",
                                  helperText:
                                      "14 digits from your FSSAI licence / registration certificate",
                                  controller: provider.fssaiNumberController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 14,
                                  validator: (value) =>
                                      AppValidators.fssai(value),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(14),
                                  ],
                                  prefixIcon: Icon(Icons.credit_card,
                                      size: 22, color: colorScheme.textSecondary),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<File?> pickPDFOrImage(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }
}

class _UploadTile extends StatefulWidget {
  final String title, uploadLabel;
  final File? file;
  final String? imageUrl;
  final VoidCallback onTap;
  const _UploadTile({
    required this.title,
    required this.uploadLabel,
    required this.onTap,
    this.file,
    this.imageUrl,
    Key? key,
  }) : super(key: key);

  @override
  State<_UploadTile> createState() => _UploadTileState();
}

class _UploadTileState extends State<_UploadTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPreview() {
    final themeProvider = context.read<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    if (widget.file == null && widget.imageUrl == null) {
      // Empty state with modern upload icon
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorsRes.appColor.withValues(alpha: 0.1),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 36,
              color: ColorsRes.appColor,
            ),
          ),
          SizedBox(height: 12),
          Text(
            widget.uploadLabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap to browse',
            style: GoogleFonts.inter(
              color: ColorsRes.appColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: -0.15,
            ),
          ),
        ],
      );
    } else if (widget.file != null &&
        widget.file!.path.toLowerCase().endsWith('.pdf')) {
      // PDF preview with modern card
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                size: 32,
                color: colorScheme.error,
              ),
            ),
            SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PDF Document',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to change',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textSecondary,
                      letterSpacing: -0.15,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: colorScheme.success,
              ),
            ),
          ],
        ),
      );
    } else {
      // Image preview with modern styling
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: widget.file != null
                ? Image.file(
                    widget.file!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                  )
                : setNetworkImg(
                    image: widget.imageUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    boxFit: BoxFit.contain,
                    // errorBuilder: (context, error, stackTrace) => Center(
                    //   child: Icon(Icons.broken_image, color: Colors.grey),
                    // ),
                  ),
          ),
          // Overlay with success indicator
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.success,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          // Change overlay on hover/tap
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Tap to change",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colorScheme.textPrimary,
            letterSpacing: -0.1,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onTap();
          },
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.file != null || widget.imageUrl != null
                    ? colorScheme.background
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: widget.file != null || widget.imageUrl != null
                    ? Border.all(color: colorScheme.border, width: 1)
                    : null, // No border when empty, using dashed painter instead
              ),
              child: widget.file != null || widget.imageUrl != null
                  ? _buildPreview()
                  : CustomPaint(
                      painter: DashedBorderPainter(
                        color: colorScheme.border,
                        strokeWidth: 1.5,
                        dashWidth: 6,
                        dashSpace: 4,
                        borderRadius: 16,
                      ),
                      child: _buildPreview(),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.dashWidth = 5,
    this.dashSpace = 3,
    this.borderRadius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final Path dashedPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final Path path = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        path.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashWidth != oldDelegate.dashWidth ||
      dashSpace != oldDelegate.dashSpace ||
      borderRadius != oldDelegate.borderRadius;
}
