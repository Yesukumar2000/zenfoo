import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/utils/custom_text_form_field.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/helper/widgets/image_picker_bottom_sheet.dart';
import 'package:project/models/bank_model.dart';
import 'package:project/provider/bank_details_provider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class AddEditBankScreen extends StatefulWidget {
  final BankModel? bank;

  const AddEditBankScreen({Key? key, this.bank}) : super(key: key);

  @override
  State<AddEditBankScreen> createState() => _AddEditBankScreenState();
}

class _AddEditBankScreenState extends State<AddEditBankScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BankDetailsProvider>(context, listen: false);
      if (widget.bank != null) {
        provider.populateForm(widget.bank!);
      } else {
        provider.clearForm();
      }
      // Initialize IFSC auto-fetch listener
      provider.initializeIFSCListener(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Consumer<BankDetailsProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // AppHeader
              Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return AppHeader(
                    label: widget.bank == null
                        ? getTranslatedValue(context, addBankLabel)
                        : getTranslatedValue(context, editBankLabel),
                    title: getTranslatedValue(context, bankDetailsLabel),
                    showBackButton: true,
                    onBackPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 120),
                  child: Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return Column(
                        spacing: 16,
                        children: [
                          CustomTextFormField(
                            title: getTranslatedValue(context, ifscCodeLabel),
                            hintText:
                                getTranslatedValue(context, enterIFSCCodeLabel),
                            controller: provider.ifscCodeController,
                            textCapitalization: TextCapitalization.characters,
                            suffixIcon: GestureDetector(
                              onTap: provider.isLoading
                                  ? null
                                  : () => provider.fetchIFSCDetails(context),
                              child: Container(
                                width: 48,
                                height: 48,
                                // decoration: BoxDecoration(
                                //   color: provider.isLoading
                                //       ? colorScheme.surfaceVariant
                                //       : ColorsRes.appColor,
                                //   borderRadius: BorderRadius.circular(12),
                                // ),
                                child: Center(
                                  child: provider.isLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: ColorsRes.appColor,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          Icons.search,
                                          color: ColorsRes.appColor,
                                          size: 24,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          CustomTextFormField(
                            title: getTranslatedValue(context, bankNameLabel),
                            hintText:
                                getTranslatedValue(context, enterBankNameLabel),
                            controller: provider.bankNameController,
                            textCapitalization: TextCapitalization.words,
                          ),
                          CustomTextFormField(
                            title:
                                getTranslatedValue(context, accountNumberLabel),
                            hintText: getTranslatedValue(
                                context, enterAccountNumberLabel),
                            controller: provider.accountNumberController,
                            keyboardType: TextInputType.number,
                          ),
                          CustomTextFormField(
                            title: getTranslatedValue(
                                context, accountHolderNameLabel),
                            hintText: getTranslatedValue(
                                context, enterAccountHolderNameLabel),
                            controller: provider.accountHolderNameController,
                            textCapitalization: TextCapitalization.words,
                          ),

                          // Optional document upload
                          _UploadTile(
                            title:
                                getTranslatedValue(context, bankDocumentLabel),
                            uploadLabel:
                                getTranslatedValue(context, uploadChequeLabel),
                            file: provider.documentFile,
                            imageUrl: provider.documentUrl,
                            onTap: () {
                              final parentContext = context;
                              ImagePickerBottomSheet.show(
                                context,
                                allowMultiple: false,
                                onImagesPicked: (files) async {
                                  if (files.isNotEmpty) {
                                    final type =
                                        await _showDocumentTypeDialog(
                                            parentContext);
                                    if (type != null) {
                                      provider.setDocument(
                                          files.first, type);
                                    }
                                  }
                                },
                                title: getTranslatedValue(
                                    context, selectImagePDFLabel),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<BankDetailsProvider>(
        builder: (context, provider, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
                  child: _buildConfirmButton(context, provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConfirmButton(
      BuildContext context, BankDetailsProvider provider) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return GestureDetector(
          onTap:
              provider.isLoading ? null : () => _handleSave(context, provider),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 17),
            decoration: ShapeDecoration(
              color: ColorsRes.appColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(1000),
              ),
            ),
            child: provider.isLoading
                ? Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      getTranslatedValue(context, confirmLabel),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave(
      BuildContext context, BankDetailsProvider provider) async {
    bool success;
    if (widget.bank == null) {
      success = await provider.addBankAccount(
        context,
        Constant.session.getData(SessionManager.keyStoreId),
      );
    } else {
      success = await provider.updateBankAccount(
        context,
        Constant.session.getData(SessionManager.keyStoreId),
        widget.bank!.id!,
      );
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<File?> pickPDFOrImage(BuildContext context) async {
    List<File>? selectedFiles;

    await ImagePickerBottomSheet.show(
      context,
      allowMultiple: false,
      onImagesPicked: (files) {
        selectedFiles = files;
      },
      title: getTranslatedValue(context, selectImagePDFLabel),
    );

    return selectedFiles != null && selectedFiles!.isNotEmpty
        ? selectedFiles!.first
        : null;
  }

  Future<String?> _showDocumentTypeDialog(BuildContext context) async {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    return showDialog<String>(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return AlertDialog(
            backgroundColor: colorScheme.surface,
            title: Text(
              getTranslatedValue(context, selectDocumentTypeLabel),
              style: TextStyle(color: colorScheme.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    getTranslatedValue(context, cancelledChequeLabel),
                    style: TextStyle(color: colorScheme.textPrimary),
                  ),
                  onTap: () => Navigator.pop(context, 'cheque'),
                ),
                ListTile(
                  title: Text(
                    getTranslatedValue(context, bankStatementLabel),
                    style: TextStyle(color: colorScheme.textPrimary),
                  ),
                  onTap: () => Navigator.pop(context, 'statement'),
                ),
                ListTile(
                  title: Text(
                    getTranslatedValue(context, passbookLabel),
                    style: TextStyle(color: colorScheme.textPrimary),
                  ),
                  onTap: () => Navigator.pop(context, 'passbook'),
                ),
              ],
            ),
          );
        },
      ),
    );
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

class _UploadTileState extends State<_UploadTile> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    bool hasFile =
        widget.file != null || (widget.imageUrl?.isNotEmpty ?? false);
    String? displayUrl = widget.imageUrl;
    bool isPDF = false;

    if (widget.file != null) {
      isPDF = widget.file!.path.toLowerCase().endsWith('.pdf');
    } else if (displayUrl != null) {
      isPDF = displayUrl.toLowerCase().endsWith('.pdf');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          child: Container(
            width: double.infinity,
            height: hasFile ? 140 : 100,
            decoration: BoxDecoration(
              color: hasFile
                  ? colorScheme.cardBackground
                  : colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: hasFile
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        if (isPDF)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.picture_as_pdf,
                                    size: 48, color: Colors.red),
                                SizedBox(height: 8),
                                Text(
                                  getTranslatedValue(context, pdfDocumentLabel),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: colorScheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (widget.file != null)
                          Positioned.fill(
                            child: Image.file(widget.file!, fit: BoxFit.cover),
                          )
                        else if (displayUrl != null)
                          Positioned.fill(
                            child: Image.network(displayUrl, fit: BoxFit.cover),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child:
                                Icon(Icons.edit, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomPaint(
                    painter: DashedBorderPainter(
                      color: colorScheme.border,
                      strokeWidth: 1.5,
                      dashWidth: 6,
                      dashSpace: 4,
                      borderRadius: 12,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 32, color: colorScheme.iconSecondary),
                          SizedBox(height: 8),
                          Text(
                            widget.uploadLabel,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colorScheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
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
