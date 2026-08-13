import 'dart:io' as io;

import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/models/bulk_upload_instructions_model.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class ProductBulkUploadScreen extends StatefulWidget {
  final String from;

  ProductBulkUploadScreen({Key? key, required this.from}) : super(key: key);

  @override
  State<ProductBulkUploadScreen> createState() =>
      _ProductBulkUploadScreenState();
}

class _ProductBulkUploadScreenState extends State<ProductBulkUploadScreen> {
  String selectedPath = "";

  @override
  void initState() {
    super.initState();
    // Fetch instructions on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductBulkOperationsProvider>().fetchBulkUploadInstructions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: getTranslatedValue(
            context,
            widget.from == "upload"
                ? titleProductsBulkUploadLabel
                : titleProductsBulkUpdateLabel,
          ),
          title: getTranslatedValue(context, bulkUploadTitleLabel),
          showBackButton: true,
        ),
      ),
      body: Consumer<ProductBulkOperationsProvider>(
        builder: (context, provider, _) {
          if (provider.instructionsState == BulkUploadInstructionsState.loading) {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            );
          }

          if (provider.instructionsState == BulkUploadInstructionsState.error ||
              provider.instructionsData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: colorScheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load instructions',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.fetchBulkUploadInstructions();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final instructions = provider.instructionsData!;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUploadIconSection(context, colorScheme, instructions),
                  const SizedBox(height: 28),
                  _buildStepsSection(context, colorScheme, instructions),
                  const SizedBox(height: 28),
                  _buildTipsSection(context, colorScheme, instructions),
                  const SizedBox(height: 28),
                  _buildFileSelectionSection(context, colorScheme),
                  const SizedBox(height: 28),
                  _buildColumnsSection(context, colorScheme, instructions),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.background,
            border: Border(
              top: BorderSide(
                color: colorScheme.border,
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSubmitButton(context, colorScheme),
              const SizedBox(height: 12),
              _buildDownloadLink(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  /// BUILD UPLOAD ICON SECTION
  Widget _buildUploadIconSection(
    BuildContext context,
    app_theme.AppColorScheme colorScheme,
    BulkUploadInstructionsData instructions,
  ) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              instructions.title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                instructions.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// BUILD STEPS SECTION
  Widget _buildStepsSection(
    BuildContext context,
    app_theme.AppColorScheme colorScheme,
    BulkUploadInstructionsData instructions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Steps to Upload',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        ...instructions.steps.map((step) => _buildStepCard(
              context,
              colorScheme,
              step,
            )),
      ],
    );
  }

  /// BUILD STEP CARD
  Widget _buildStepCard(
    BuildContext context,
    app_theme.AppColorScheme colorScheme,
    InstructionStep step,
  ) {
    IconData iconData;
    Color iconColor;

    switch (step.icon) {
      case 'download':
        iconData = Icons.download_outlined;
        iconColor = Colors.blue;
        break;
      case 'info':
        iconData = Icons.info_outline;
        iconColor = Colors.orange;
        break;
      case 'edit':
        iconData = Icons.edit_outlined;
        iconColor = Colors.purple;
        break;
      case 'upload':
        iconData = Icons.upload_outlined;
        iconColor = Colors.green;
        break;
      case 'error':
        iconData = Icons.error_outline;
        iconColor = Colors.red;
        break;
      case 'check_circle':
        iconData = Icons.check_circle_outline;
        iconColor = Colors.teal;
        break;
      default:
        iconData = Icons.circle_outlined;
        iconColor = colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                iconData,
                size: 20,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${step.step}: ${step.title}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// BUILD TIPS SECTION
  Widget _buildTipsSection(
    BuildContext context,
    app_theme.AppColorScheme colorScheme,
    BulkUploadInstructionsData instructions,
  ) {
    if (instructions.tips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Important Tips',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: instructions.tips
                .map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tip,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  /// BUILD FILE SELECTION SECTION
  Widget _buildFileSelectionSection(
    BuildContext context,
    app_theme.AppColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select File',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['xlsx', 'xls'],
            );

            if (result != null && result.files.single.path != null) {
              File pickedFile = File(result.files.single.path!);

              if (!await pickedFile.exists()) {
                showMessage(
                  context,
                  getTranslatedValue(context, fileNotFoundLabel),
                  MessageType.error,
                );
                return;
              }

              File? savedFile = await saveFileToLocalStorage(pickedFile);

              setState(() {
                selectedPath = savedFile!.path.toString();
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary,
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 40,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to select .xlsx file',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (selectedPath.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 18,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedPath.split("/").last,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPath = "";
                    });
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// BUILD COLUMNS SECTION
  Widget _buildColumnsSection(
    BuildContext context,
    app_theme.AppColorScheme colorScheme,
    BulkUploadInstructionsData instructions,
  ) {
    if (instructions.columns.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Column Reference',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        ...instructions.columns.map((col) => _buildColumnTile(
              context,
              colorScheme,
              col,
            )),
      ],
    );
  }

  /// BUILD COLUMN TILE
  Widget _buildColumnTile(
    BuildContext context,
    app_theme.AppColorScheme colorScheme,
    ColumnInfo column,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                column.column,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        column.header,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                    ),
                    if (column.required)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Required',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  column.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show error dialog with list of errors
  void _showErrorDialog(
    BuildContext context,
    app_theme.AppColorScheme colorScheme,
    String message,
    List<BulkUploadError> errors,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Upload Failed',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                  ),
                ),
                if (errors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: errors.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final error = errors[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Row ${error.row}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      error.product,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                error.message,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: colorScheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// BUILD SUBMIT BUTTON
  Widget _buildSubmitButton(
    BuildContext context,
    app_theme.AppColorScheme colorScheme,
  ) {
    return Consumer<ProductBulkOperationsProvider>(
      builder: (context, provider, _) {
        final isUploading = provider.productBulkOperationsState ==
            ProductBulkOperationsState.loading;

        return GestureDetector(
          onTap: selectedPath.isEmpty || isUploading
              ? null
              : () async {
                  final result = await provider.productBulkOperation(
                    context: context,
                    fileParamsFilesPath: selectedPath,
                    isUpload: widget.from == "upload",
                  );

                  if (result.success) {
                    setState(() {
                      selectedPath = "";
                    });
                    showMessage(
                      context,
                      result.message.isNotEmpty
                          ? result.message
                          : getTranslatedValue(
                              context,
                              bulkUploadSuccessMessageLabel,
                            ),
                      MessageType.success,
                    );
                  } else {
                    _showErrorDialog(
                      context,
                      colorScheme,
                      result.message,
                      result.errors,
                    );
                  }
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: selectedPath.isEmpty
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isUploading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      getTranslatedValue(
                        context,
                        widget.from == "upload" ? uploadLabel : updateLabel,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  /// BUILD DOWNLOAD LINK
  Widget _buildDownloadLink(
    BuildContext context,
    app_theme.AppColorScheme colorScheme,
  ) {
    return Consumer<ProductBulkOperationsProvider>(
      builder: (context, provider, _) {
        final isLoading =
            provider.productSampleFileState == ProductSampleFileState.loading;

        return GestureDetector(
          onTap: isLoading
              ? null
              : () async {
                  provider
                      .getProductDownloadExcel(
                    context: context,
                    from: widget.from,
                  )
                      .then(
                    (htmlContent) async {
                      if (htmlContent != null) {
                        try {
                          final appDocDirPath = io.Platform.isAndroid
                              ? (await ExternalPath
                                  .getExternalStoragePublicDirectory(
                                      ExternalPath.DIRECTORY_DOWNLOAD))
                              : (await getApplicationDocumentsDirectory())
                                  .path;

                          final targetFileName =
                              "bulk_product_upload_template_${DateTime.now().millisecondsSinceEpoch}.xlsx";

                          io.File file =
                              io.File("$appDocDirPath/$targetFileName");

                          await file.writeAsBytes(htmlContent, flush: true);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        getTranslatedValue(
                                            context, fileSavedSuccessfullyLabel),
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.green.shade600,
                                duration: const Duration(seconds: 4),
                                action: SnackBarAction(
                                  label:
                                      getTranslatedValue(context, showFileLabel),
                                  textColor: Colors.white,
                                  onPressed: () {
                                    OpenFile.open(file.path);
                                  },
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            showMessage(
                              context,
                              getTranslatedValue(context, errorSavingFileLabel),
                              MessageType.error,
                            );
                          }
                        }
                      }
                    },
                  );
                },
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        colorScheme.primary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Download Template',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
