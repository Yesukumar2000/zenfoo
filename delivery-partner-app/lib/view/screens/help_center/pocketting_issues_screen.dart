import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/order_history_model.dart';
import 'package:zenfoo_partner/providers/floating_cash_issue_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/image_picker_bottom_sheet.dart';
import 'package:zenfoo_partner/view/custom_widgets/request_sent.dart';

import '../../custom_widgets/custom_button.dart';

class PockettingIssuesScreen extends StatefulWidget {
  final String issueType;
  final Order? order;

  const PockettingIssuesScreen({
    super.key,
    required this.issueType,
    this.order,
  });

  @override
  State<PockettingIssuesScreen> createState() => _PockettingIssuesScreenState();
}

class _PockettingIssuesScreenState extends State<PockettingIssuesScreen> {
  late TextEditingController _descriptionController;

  File? _image1;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
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
      title: languageProvider
          .getTranslatedText('upload_multi_order_issue_evidence'),
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final languageProvider = context.read<LanguageProvider>();
    final provider = context.read<FloatingCashIssueProvider>();

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.getTranslatedText('please_fill_all_fields'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (widget.order?.orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order ID not found')),
      );
      return;
    }

    final attachments = <File>[];
    if (_image1 != null) attachments.add(_image1!);
    HapticFeedback.heavyImpact();

    await provider.floatingCashIssue(
      description: _descriptionController.text,
      issueType: 'pocketing_issue',
      issueIds: [widget.order!.orderId!],
      attachments: attachments.isNotEmpty ? attachments : null,
    );

    if (mounted) {
      if (provider.floatingCashIssueState.status == ApiStatus.success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RequestSent()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                provider.floatingCashIssueState.message ?? 'Submission failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _pickImage(int slot) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    ImagePickerBottomSheet.show(
      context: context,
      colorScheme: colorScheme,
      onImageSelected: (file) {
        setState(() {
          _image1 = file;
        });
      },
      onPermissionDenied: () {
        debugPrint('Permission denied');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final languageProvider = context.read<LanguageProvider>();
    final provider = context.watch<FloatingCashIssueProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            AppHeader(
              label: languageProvider.getTranslatedText('help_center'),
              title: languageProvider.getTranslatedText('pocketting_issues'),
              showBackButton: true,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Card (from Screenshot)
                  if (widget.order != null) _buildOrderCard(colorScheme),

                  const SizedBox(height: 24),

                  // Describe Issue Section
                  Text(
                    'Describe Issue',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDescriptionField(colorScheme, languageProvider),

                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.getTranslatedText('attachments'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.71,
                          letterSpacing: -0.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedImage != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: 156,
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
                                        color:
                                            Colors.black.withValues(alpha: 0.2),
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
                      else
                        GestureDetector(
                          onTap: _showImagePicker,
                          child: Container(
                            width: double.infinity,
                            height: 156,
                            decoration: ShapeDecoration(
                              color: colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: colorScheme.border,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 5,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 24,
                                  color: colorScheme.textSecondary,
                                ),
                                Text(
                                  languageProvider
                                      .getTranslatedText('upload_image'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.12,
                                  ),
                                ),
                                Text(
                                  languageProvider.getTranslatedText('png_jpg'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 52),

                  // Submit Button
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Consumer<FloatingCashIssueProvider>(
                      builder: (context, provider, child) {
                        final isLoading =
                            provider.floatingCashIssueState.status ==
                                ApiStatus.loading;
                        return CustomButton(
                          text: languageProvider
                              .getTranslatedText('send_enquiry'),
                          onPressed: isLoading ? null : _handleSubmit,
                          isLoading: isLoading,
                        );
                      },
                    ),
                  ),
                  // const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.order!.deliveryTime ?? '-- : --',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textSecondary,
                ),
              ),
              Text(
                'Items: ${widget.order!.itemCount}', // Logic placeholder or from order status
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order ID: ${widget.order!.orderId}', // Placeholder as not in Order model
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '₹${widget.order!.totalAmountPaid ?? "0.0"}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(colorScheme, languageProvider) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.border.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _descriptionController,
        minLines: 4,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Type message',
          hintStyle: GoogleFonts.inter(
            color: colorScheme.textSecondary.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: GoogleFonts.inter(
          color: colorScheme.textPrimary,
          fontSize: 14,
        ),
      ),
    );
  }
}
