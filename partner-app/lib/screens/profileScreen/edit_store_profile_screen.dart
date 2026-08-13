import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/custom_text_form_field.dart';
import 'package:flutter/services.dart';
import 'package:project/screens/resgistration/food/food_registration_provider.dart';
import 'package:project/models/places_model.dart';
import 'package:project/provider/place_proveder.dart';
import "package:project/screens/resgistration/food/location_picker.dart";
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class EditStoreProfileScreen extends StatefulWidget {
  const EditStoreProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditStoreProfileScreen> createState() => _EditStoreProfileScreenState();
}

class _EditStoreProfileScreenState extends State<EditStoreProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<FoodRegistrationProvider>(context, listen: false);

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
          body: Column(
            children: [
              Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return AppHeader(
                    label: getTranslatedValue(context, editProfileLabel),
                    title: getTranslatedValue(context, storeInformationLabel),
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
                                _UploadTile(
                                  title: getTranslatedValue(context, storeLogoLabel),
                                  uploadLabel: getTranslatedValue(context, uploadStoreLogoLabel),
                                  file: provider.storeLogo,
                                  imageUrl: provider.logoImageUrl,
                                  onTap: () async {
                                    final picked = await _pickImage(context);
                                    if (picked != null)
                                      provider.setStoreLogo(picked);
                                  },
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(height: 16),
                                _StoreImagesUploadTile(
                                    files: provider.storeImages,
                                    imageUrls: provider.storeImageUrls,
                                    onTap: () async {
                                      HapticFeedback.lightImpact();
                                      final files =
                                          await _pickMultipleImages(context);
                                      if (files.isNotEmpty)
                                        provider.addStoreImages(files);
                                    },
                                    onRemove: (i) => provider.removeStoreImage(i),
                                    onRemoveUrl: (i) =>
                                        provider.removeStoreImageUrl(i),
                                    colorScheme: colorScheme),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  title: getTranslatedValue(context, storeNameLabel),
                                  hintText: "e.g. Sri Sai Bakery & Sweets",
                                  helperText:
                                      "The name customers will see in the Zenfoo app",
                                  controller: provider.storeNameController,
                                  validator: AppValidators.storeName,
                                  textCapitalization: TextCapitalization.words,
                                ),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  title: getTranslatedValue(context, descriptionLabel),
                                  hintText:
                                      "e.g. Fresh sweets, snacks and hot samosas prepared daily",
                                  helperText:
                                      "20 to 500 characters — tell customers what you sell",
                                  controller: provider.descriptionController,
                                  maxLines: 3,
                                  validator: AppValidators.storeDescription,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  prefixIcon: Icon(Icons.edit_outlined,
                                      size: 22, color: colorScheme.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  title: getTranslatedValue(context, storeLocationLabel),
                                  hintText: provider.location ?? getTranslatedValue(context, selectLocationLabel),
                                  controller: TextEditingController(
                                      text: provider.location ?? ""),
                                  prefixIcon: Icon(Icons.location_on_rounded,
                                      size: 22, color: colorScheme.textSecondary),
                                  readOnly: true,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MultiProvider(
                                          providers: [
                                            ChangeNotifierProvider(
                                                create: (_) =>
                                                    PlaceSuggestionsProvider()),
                                            ChangeNotifierProvider(
                                                create: (_) =>
                                                    PlaceDetailsProvider()),
                                          ],
                                          child: LocationPickerScreen(
                                              // colorScheme: colorScheme,
                                              ),
                                        ),
                                      ),
                                    );

                                    if (result != null &&
                                        result is PlaceDetailsModel) {
                                      // Extract city from formatted address
                                      String? cityName;
                                      if (result.formattedAddress != null) {
                                        final addressParts =
                                            result.formattedAddress!.split(',');
                                        // Try to extract city (usually second or third part)
                                        if (addressParts.length > 1) {
                                          cityName =
                                              addressParts[addressParts.length - 3]
                                                  .trim();
                                          provider.selectCity(cityName);
                                        }
                                      }

                                      provider.setLocationData(
                                        address: result.formattedAddress ?? '',
                                        lat: result.latitude ?? 0.0,
                                        lng: result.longitude ?? 0.0,
                                        cityName: cityName,
                                      );
                                    }
                                  },
                                ),
                                if (provider.categories.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  CustomTextFormField(
                                    title: getTranslatedValue(context, selectCategoriesLabel),
                                    hintText: provider.categories
                                        .map((c) => c.name)
                                        .join(", "),
                                    controller: TextEditingController(
                                        text: provider.categories
                                            .map((c) => c.name)
                                            .join(", ")),
                                    prefixIcon: Icon(Icons.list,
                                        size: 22, color: colorScheme.textSecondary),
                                    readOnly: true,
                                    // Categories are now read-only and auto-populated from store type
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  title: getTranslatedValue(context, storeUrlLabel),
                                  hintText: getTranslatedValue(context, pastUrlLabel),
                                  controller: provider.urlController,
                                  prefixIcon: Icon(Icons.link_rounded,
                                      size: 22, color: colorScheme.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  title: getTranslatedValue(context, taxNameLabel),
                                  hintText: "e.g. Sri Sai Foods",
                                  helperText:
                                      "Legal / trade name exactly as on the GST certificate",
                                  controller: provider.taxNameController,
                                  validator: AppValidators.gstBusinessName,
                                  textCapitalization: TextCapitalization.words,
                                ),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  title: getTranslatedValue(context, taxNumberLabel),
                                  hintText: "e.g. ${AppValidators.gstinExample}",
                                  helperText:
                                      "15 characters: state code + PAN + entity code + Z + 1",
                                  controller: provider.taxNumberController,
                                  maxLength: 15,
                                  validator: AppValidators.gstin,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r'[^a-zA-Z0-9]')),
                                    LengthLimitingTextInputFormatter(15),
                                    UpperCaseTextFormatter(),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          bottomNavigationBar: Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: gradientBtnWidget(
                    context,
                    10,
                    title: provider.isUploadingStep2 ? "" : getTranslatedValue(context, updateStoreLabel),
                    callback: () {
                      if (provider.validateStep2() == null) {
                        // Call update API
                        provider.uploadStep2Data(
                            context,
                            int.tryParse(Constant.session
                                .getData(SessionManager.keyStoreId)));
                      } else {
                        showMessage(context, provider.validateStep2()!,
                            MessageType.warning);
                      }
                    },
                    otherWidgets: provider.isUploadingStep2
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white))
                        : null,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<File?> _pickImage(BuildContext context) async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null && res.files.single.path != null) {
      return File(res.files.single.path!);
    }
    return null;
  }

  Future<List<File>> _pickMultipleImages(BuildContext context) async {
    final res = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: true);
    if (res != null && res.files.isNotEmpty) {
      return res.files
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();
    }
    return [];
  }
}

// --- Upload Tile and Image Previews ---
class _UploadTile extends StatefulWidget {
  final String title, uploadLabel;
  final File? file;
  final String? imageUrl;
  final VoidCallback onTap;
  final dynamic colorScheme;
  const _UploadTile({
    required this.title,
    required this.uploadLabel,
    required this.onTap,
    required this.colorScheme,
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
              color: widget.colorScheme.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            getTranslatedValue(context, tapToBrowseLabel),
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
                color: widget.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                size: 32,
                color: widget.colorScheme.error,
              ),
            ),
            SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    getTranslatedValue(context, pdfDocumentLabel),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.colorScheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    getTranslatedValue(context, tapToChangeLabel),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: widget.colorScheme.textSecondary,
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
                color: widget.colorScheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: widget.colorScheme.success,
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
                color: widget.colorScheme.success,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: widget.colorScheme.textPrimary,
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
                    ? widget.colorScheme.surface
                    : widget.colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: widget.file != null || widget.imageUrl != null
                    ? Border.all(color: widget.colorScheme.border, width: 1)
                    : null, // No border when empty, using dashed painter instead
              ),
              child: widget.file != null || widget.imageUrl != null
                  ? _buildPreview()
                  : CustomPaint(
                      painter: DashedBorderPainter(
                        color: widget.colorScheme.border,
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

class _StoreImagesUploadTile extends StatefulWidget {
  final List<File> files;
  final List<String> imageUrls;
  final VoidCallback onTap;
  final Function(int) onRemove;
  final Function(int) onRemoveUrl;
  final dynamic colorScheme;

  const _StoreImagesUploadTile({
    Key? key,
    required this.files,
    required this.imageUrls,
    required this.onTap,
    required this.onRemove,
    required this.onRemoveUrl,
    required this.colorScheme,
  }) : super(key: key);

  @override
  State<_StoreImagesUploadTile> createState() => _StoreImagesUploadTileState();
}

class _StoreImagesUploadTileState extends State<_StoreImagesUploadTile> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full-width "Add Photos" button styled like _UploadTile
            _UploadTile(
              title: getTranslatedValue(context, storeImagesLabel),
              uploadLabel: getTranslatedValue(context, addStoreImagesLabel),
              onTap: widget.onTap,
              colorScheme: widget.colorScheme,
              // We don't pass file/imageUrl here because this is just the "Add" button
              // The images are shown below
            ),

            if (widget.imageUrls.isNotEmpty || widget.files.isNotEmpty) ...[
              SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    // Existing Images from Server
                    ...widget.imageUrls.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _ImageThumbnail(
                          imageUrl: entry.value,
                          onRemove: () => widget.onRemoveUrl(entry.key),
                          isServerImage: true,
                          colorScheme: widget.colorScheme,
                        ),
                      );
                    }).toList(),

                    // Newly Added Images
                    ...widget.files.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _ImageThumbnail(
                          file: entry.value,
                          onRemove: () => widget.onRemove(entry.key),
                          isServerImage: false,
                          colorScheme: widget.colorScheme,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ImageThumbnail extends StatefulWidget {
  final File? file;
  final String? imageUrl;
  final VoidCallback onRemove;
  final bool isServerImage;
  final dynamic colorScheme;

  const _ImageThumbnail({
    Key? key,
    this.file,
    this.imageUrl,
    required this.onRemove,
    this.isServerImage = false,
    required this.colorScheme,
  }) : super(key: key);

  @override
  State<_ImageThumbnail> createState() => _ImageThumbnailState();
}

class _ImageThumbnailState extends State<_ImageThumbnail> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: widget.file != null
                ? Image.file(widget.file!, fit: BoxFit.cover)
                : setNetworkImg(
                    image: widget.imageUrl!,
                    boxFit: BoxFit.cover,
                    // errorBuilder: (context, error, stackTrace) =>
                    //     Center(child: Icon(Icons.error, color: Colors.red,),),
                  ),
          ),
        ),
        // Remove button for both server and local images
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onRemove();
            },
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child:
                  Icon(Icons.close, size: 14, color: widget.colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }
}
