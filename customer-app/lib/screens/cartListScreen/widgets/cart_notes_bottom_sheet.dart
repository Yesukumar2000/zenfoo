import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:project/provider/cartProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/generalWidgets/custom_text_form_field.dart';

class CartNotesBottomSheet extends StatefulWidget {
  final String title;
  final String? initialNote;
  final int? sellerId;
  final int? comboId;

  const CartNotesBottomSheet({
    Key? key,
    required this.title,
    this.initialNote,
    this.sellerId,
    this.comboId,
  }) : super(key: key);

  @override
  State<CartNotesBottomSheet> createState() => _CartNotesBottomSheetState();
}

class _CartNotesBottomSheetState extends State<CartNotesBottomSheet> {
  late TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final note = _noteController.text.trim();

    if (note.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final success = await context.read<CartProvider>().saveCartMetadata(
          context: context,
          sellerId: widget.sellerId,
          sellerNote: widget.sellerId != null ? note : null,
          comboId: widget.comboId,
          comboNote: widget.comboId != null ? note : null,
        );

    setState(() {
      _isSaving = false;
    });

    if (success) {
      Navigator.pop(context, note);
    } else {
      final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save note. Please try again.'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Note',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                            height: 1.2,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textSecondary,
                            height: 1.2,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.iconSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Text Field using CustomTextFormField
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: CustomTextFormField(
                title: 'Note',
                hintText: 'e.g., Please pack vegetables separately...',
                controller: _noteController,
                maxLines: 4,
                maxLength: 500,
                prefixIcon: Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: colorScheme.border,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveNote,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(colorScheme.buttonPrimaryText),
                              ),
                            )
                          : Text(
                              'Save Note',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.buttonPrimaryText,
                                height: 1.2,
                                letterSpacing: -0.2,
                              ),
                            ),
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

// Helper function to show the bottom sheet
Future<String?> showCartNotesBottomSheet({
  required BuildContext context,
  required String title,
  String? initialNote,
  int? sellerId,
  int? comboId,
}) async {
  return await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CartNotesBottomSheet(
      title: title,
      initialNote: initialNote,
      sellerId: sellerId,
      comboId: comboId,
    ),
  );
}
