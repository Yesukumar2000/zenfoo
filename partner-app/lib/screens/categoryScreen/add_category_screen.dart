import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/models/category_model.dart';
import 'package:project/helper/utils/custom_text_form_field.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/helper/widgets/image_picker_bottom_sheet.dart';
import 'package:project/helper/widgets/keyboard_dismissible_wrapper.dart';
import 'package:project/provider/category_add_provider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class AddCategoryScreen extends StatefulWidget {
  final CategoryModel? category;

  const AddCategoryScreen({Key? key, this.category}) : super(key: key);

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen>
    with WidgetsBindingObserver {
  late CategoryAddProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = CategoryAddProvider(category: widget.category);
    _provider.recoverLostData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return ChangeNotifierProvider<CategoryAddProvider>.value(
      value: _provider,
      child: Consumer<CategoryAddProvider>(
        builder: (context, provider, _) {
          return KeyboardDismissibleWrapper(
            child: PopScope(
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) {
                  _showExitConfirmation(context);
                }
              },
              canPop: false,
              child: Scaffold(
                backgroundColor: colorScheme.background,
                body: Column(
                  children: [
                    // AppHeader
                    AppHeader(
                      label: provider.category == null ? 'Category' : 'Edit',
                      title: provider.category == null
                          ? "Add Category"
                          : "Update Category",
                      showBackButton: true,
                      onBackPressed: () {
                        HapticFeedback.lightImpact();
                        _showExitConfirmation(context);
                      },
                    ),
                    // Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 12),
                            // Image Upload
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  ImagePickerBottomSheet.show(
                                    context,
                                    allowMultiple: false,
                                    title: 'Select Category Image',
                                    onImagesPicked: (images) {
                                      if (images.isNotEmpty) {
                                        provider.setImageFile(images.first);
                                      }
                                    },
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  margin: EdgeInsets.symmetric(vertical: 9),
                                  padding: EdgeInsets.symmetric(vertical: 25),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(14),
                                    border:
                                        Border.all(color: colorScheme.border),
                                  ),
                                  child: provider.imageFile == null &&
                                          provider.imageUrl == null
                                      ? Column(
                                          children: [
                                            Icon(Icons.camera_alt_outlined,
                                                color:
                                                    colorScheme.iconSecondary,
                                                size: 33),
                                            SizedBox(height: 7),
                                            Text(
                                              "Upload Category Image*",
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    colorScheme.textSecondary,
                                              ),
                                            ),
                                            SizedBox(height: 3),
                                            Text("PNG/JPG",
                                                style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: colorScheme
                                                        .textSecondary)),
                                          ],
                                        )
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: provider.imageFile != null
                                              ? Image.file(
                                                  provider.imageFile!,
                                                  width: 95,
                                                  height: 95,
                                                  fit: BoxFit.contain,
                                                )
                                              : Image.network(
                                                  provider.imageUrl!,
                                                  width: 95,
                                                  height: 95,
                                                  fit: BoxFit.contain,
                                                ),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),

                            // Category Name
                            CustomTextFormField(
                              title: "Category Name",
                              hintText: "Enter Category Name (e.g., Aashirvad)",
                              controller: provider.name,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(
                                    RegExp(r'[^a-zA-Z0-9 ]')),
                              ],
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.words,
                            ),
                            SizedBox(height: 13),

                            // Subtitle/Description
                            CustomTextFormField(
                              title: "Description",
                              hintText: "Enter category description",
                              controller: provider.subtitle,
                              maxLines: 3,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(
                                    RegExp(r'[^a-zA-Z0-9 ]')),
                                FilteringTextInputFormatter.deny(
                                    RegExp(r'\s{2,}')),
                              ],
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                            SizedBox(height: 24),

                            // Category Types Section
                            Text(
                              "Category Types (Optional)",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Add different types or variants for this category (e.g., organic, inorganic)",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: colorScheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 12),

                            // Type Input Field
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: provider.typeController,
                                    style: TextStyle(
                                        color: colorScheme.textPrimary),
                                    decoration: InputDecoration(
                                      hintText:
                                          "Enter type name (e.g., organic)",
                                      hintStyle: GoogleFonts.inter(
                                        color: colorScheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                      filled: true,
                                      fillColor: colorScheme.surfaceVariant,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: colorScheme.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: colorScheme.border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Color(0xFF9AC444), width: 2),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    onSubmitted: (value) {
                                      if (value.trim().isNotEmpty) {
                                        provider.addType(value);
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(width: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF9AC444),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      if (provider.typeController.text
                                          .trim()
                                          .isNotEmpty) {
                                        provider.addType(
                                            provider.typeController.text);
                                      }
                                    },
                                    icon: Icon(Icons.add, color: Colors.white),
                                    iconSize: 24,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            // Display existing types from category
                            if (provider.category != null &&
                                provider.category!.types.isNotEmpty) ...[
                              Text(
                                "Existing Types",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: provider.category!.types.map((type) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFDCEFBB),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Color(0xFF9AC444)
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          type.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF4A5568),
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () async {
                                            if (provider.isLoading) return;
                                            final success =
                                                await provider.removeTypeById(
                                                    context, type.id);
                                            if (success && context.mounted) {
                                              Navigator.of(context).pop(true);
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF9AC444),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 12),
                            ],

                            // Display newly added types (not yet saved)
                            if (provider.types.isNotEmpty) ...[
                              Text(
                                provider.category != null
                                    ? "New Types to Add"
                                    : "Types",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(provider.types.length,
                                    (index) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Color(0xFF0EA5E9)
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          provider.types[index],
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF0C4A6E),
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () =>
                                              provider.removeType(index),
                                          child: Container(
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF0EA5E9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: 16),
                            ],

                            SizedBox(height: 8),

                            // Delete button (only for update mode)
                            if (provider.category != null)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showDeleteConfirmation(context, provider),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.error,
                                  side: BorderSide(
                                      color: colorScheme.error, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  minimumSize: Size(double.infinity, 50),
                                  backgroundColor: Colors.transparent,
                                ),
                                icon: Icon(Icons.delete_outline, size: 20),
                                label: Text(
                                  "Delete Category",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: provider.isLoading
                          ? null
                          : () async {
                              final success =
                                  await provider.saveCategory(context);
                              if (success) {
                                Navigator.of(context).pop(true);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF9AC444),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        disabledBackgroundColor:
                            Color(0xFF9AC444).withValues(alpha: 0.6),
                      ),
                      child: provider.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              provider.category == null
                                  ? "Add Category"
                                  : "Update Category",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Discard Changes?",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Are you sure you want to exit? All unsaved changes will be lost.",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.textSecondary,
                    height: 1.02,
                    letterSpacing: -0.25,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(bottomSheetContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: colorScheme.border,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.textSecondary,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(bottomSheetContext);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: colorScheme.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Exit",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, CategoryAddProvider provider) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Delete Category?",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Are you sure you want to delete this category? This action cannot be undone.",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.textSecondary,
                    height: 1.5,
                    letterSpacing: -0.25,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(bottomSheetContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: colorScheme.border,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.textSecondary,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(bottomSheetContext);
                          final success =
                              await provider.deleteCategory(context);
                          if (success && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: colorScheme.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Delete",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
