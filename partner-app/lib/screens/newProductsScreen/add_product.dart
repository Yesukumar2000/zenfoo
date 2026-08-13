import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/styles/typography.dart';
import 'package:project/models/productList.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/helper/utils/custom_text_form_field.dart';
import 'package:project/provider/category_list_provider.dart';
import 'package:project/screens/newProductsScreen/category_selection_bottom_sheet.dart';
import 'package:project/repositories/categorySelectionApi.dart';
import 'package:quill_html_editor/quill_html_editor.dart';
import 'package:project/repositories/addProductApi.dart';
import 'package:project/helper/utils/generalImports.dart'
    hide CategoryListProvider, log, CategoryListScreen;
import 'package:project/screens/categoryScreen/three_stage_stepper_screen.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/helper/widgets/image_picker_bottom_sheet.dart';

import '../categoryScreen/category_list_screen.dart';

class VariantInputModel {
  final FocusNode statusFocus = FocusNode();
  final FocusNode unitFocus = FocusNode();

  final TextEditingController type = TextEditingController();
  final TextEditingController status = TextEditingController();
  final TextEditingController measurement = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController discountedPrice = TextEditingController();
  final TextEditingController stock = TextEditingController();
  final TextEditingController stockUnitName = TextEditingController();

  // Unit selection fields
  int? selectedUnitId;
  String? selectedUnitName;

  // Variant ID (for existing variants)
  String? variantId;

  // Variant images (multiple images per variant)
  List<File> variantImages = [];

  // Existing variant image URLs (from server)
  List<String> existingImageUrls = [];

  // Existing variant image IDs (from server, parallel to existingImageUrls)
  List<int> existingImageIds = [];

  // IDs of images that were removed by the user (to be sent to backend for deletion)
  List<int> deletedImageIds = [];

  final TextEditingController isUnlimitedStock = TextEditingController();
  final TextEditingController cartCount = TextEditingController();
  final TextEditingController taxableAmount = TextEditingController();

  Map<String, dynamic> toJson() => {
        "type": type.text,
        "status": status.text,
        "measurement": measurement.text,
        "price": price.text,
        "discounted_price": discountedPrice.text,
        "stock": stock.text,
        "stock_unit_name": stockUnitName.text,
        "is_unlimited_stock": isUnlimitedStock.text,
        "cart_count": cartCount.text,
        "taxable_amount": taxableAmount.text,
      };

  void setUnit(int id, String name, String shortCode) {
    selectedUnitId = id;
    selectedUnitName = name;
    stockUnitName.text = shortCode;
  }

  Variants toVariant() => Variants(
        type: type.text,
        status: status.text,
        measurement: measurement.text,
        price: price.text,
        discountedPrice: discountedPrice.text,
        stock: stock.text,
        stockUnitName: stockUnitName.text,
        isUnlimitedStock: isUnlimitedStock.text,
        cartCount: cartCount.text,
        taxableAmount: taxableAmount.text,
      );

  void dispose() {
    statusFocus.dispose();
    unitFocus.dispose();
    type.dispose();
    status.dispose();
    measurement.dispose();
    price.dispose();
    discountedPrice.dispose();
    stock.dispose();
    stockUnitName.dispose();
    isUnlimitedStock.dispose();
    cartCount.dispose();
    taxableAmount.dispose();
  }
}

class ProductStepperProvider extends ChangeNotifier {
  final ProductListItem? product;

  // Loading state for save operation
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  ProductStepperProvider({this.product}) {
    if (product != null) {
      _initFromProduct();
    } else {
      // Auto-populate FSSAI number from session for new products
      _initFromSession();
    }
  }

  void _initFromSession() {
    // Initialize stock type to 0 (Limited) and set isUnlimitedStock accordingly
    stockType = 0;
    isUnlimitedStock.text = '0';

    // Initialize pack type to 0 (Packet)
    packType = 0;
  }

  void _initFromProduct() {
    name.text = product!.name ?? '';
    slug.text = product!.slug ?? '';
    indicator.text = product!.indicator ?? '1';
    manufacturer.text = product!.manufacturer ?? '';
    madeIn.text = product!.madeIn ?? '';
    tags.text = product!.tags ?? '';
    otherInfo.text = product!.otherInfo ?? '';
    taxPercentage.text = product!.taxPercentage ?? '';
    fssaiLicNo.text = product!.fssaiLicNo ?? '';
    totalAllowedQuantity.text = product!.totalAllowedQuantity ?? '';
    taxIncludedInPrice.text = product!.taxIncludedInPrice ?? '0';

    debugPrint('=== EDIT PRODUCT DEBUG ===');
    debugPrint('FSSAI: "${product!.fssaiLicNo}"');
    debugPrint('Variants count: ${product!.variants?.length}');
    if (product!.variants != null) {
      for (int i = 0; i < product!.variants!.length; i++) {
        final v = product!.variants![i];
        debugPrint('Variant[$i] images: ${v.images?.length}, imageUrls: ${v.images?.map((img) => img.imageUrl).toList()}');
      }
    }
    debugPrint('=========================');

    // Set return/cancellable fields
    isReturnable = int.tryParse(product!.returnStatus ?? '1') ?? 1;
    returnDays.text = product!.returnDays ?? '';
    isCancellable = int.tryParse(product!.cancelableStatus ?? '1') ?? 1;
    cancelDays.text = product!.tillStatus ?? '';

    // Set stock type: 0 = limited, 1 = unlimited
    final isUnlimited = (product!.isUnlimitedStock ?? '0') == '1';
    stockType = isUnlimited ? 1 : 0;
    isUnlimitedStock.text = product!.isUnlimitedStock ?? '0';

    // Set pack type: packet or loose
    packType = (product!.type ?? 'packet').toLowerCase() == 'packet' ? 0 : 1;

    // Store description
    htmlDescription = product!.description ?? '';
    description.text = product!.description ?? '';
    imageUrl = product!.imageUrl;

    // Initialize dropdowns
    selectedCategoryGroupId = int.tryParse(product!.categoryGroupId ?? '');
    selectedCategoryGroupName = product!.categoryGroupName;

    selectedCategoryId = int.tryParse(product!.subCategoryGroupId ?? '');
    selectedCategoryName = product!.subCategoryGroupName;

    selectedSubcategoryId = int.tryParse(product!.categoryId ?? '');
    selectedSubcategoryName = product!.categoryName;
    categoryId.text = product!.categoryId ?? '';

    selectedBrandId = int.tryParse(product!.brandId ?? '');
    selectedBrandName = product!.brandName;
    brandId.text = product!.brandId ?? '';

    // Initialize item type
    selectedTypeId = int.tryParse(product!.itemTypeId ?? '');
    selectedTypeName = product!.itemTypeName;
    type.text = product!.type ?? '';

    if (product!.variants != null && product!.variants!.isNotEmpty) {
      variants = product!.variants!.map((v) {
        final model = VariantInputModel();
        model.type.text = v.type ?? '';
        // Convert status: 1 = Available, 0 = Unavailable
        model.status.text = (v.status == '1') ? 'Available' : 'Unavailable';
        model.measurement.text = v.measurement ?? '';
        model.price.text = v.price ?? '';
        model.discountedPrice.text = v.discountedPrice ?? '';
        model.stock.text = v.stock ?? '';
        model.stockUnitName.text = v.stockUnitName ?? '';
        model.cartCount.text = v.cartCount ?? '';

        // Set variant ID for existing variants
        model.variantId = v.id;

        // Set stock unit ID if available
        if (v.stockUnitId != null && v.stockUnitId != 'null') {
          model.selectedUnitId = int.tryParse(v.stockUnitId!);
        }

        // Load existing variant image URLs and IDs
        if (v.images != null && v.images!.isNotEmpty) {
          final validImages = v.images!.where((img) => img.imageUrl != null).toList();
          model.existingImageUrls = validImages.map((img) => img.imageUrl!).toList();
          model.existingImageIds = validImages
              .map((img) => int.tryParse(img.id?.toString() ?? '') ?? 0)
              .toList();
        }

        return model;
      }).toList();
    }
  }

  // Focus nodes for dropdown fields
  final FocusNode categoryGroupFocus = FocusNode();
  final FocusNode categoryFocus = FocusNode();
  final FocusNode subcategoryFocus = FocusNode();
  final FocusNode typeFocus = FocusNode();
  final FocusNode brandFocus = FocusNode();
  int stepIndex = 0;

  // Step 1 controllers
  final name = TextEditingController();
  final taxId = TextEditingController();
  final brandId = TextEditingController();
  final slug = TextEditingController();
  final categoryId = TextEditingController();
  final indicator = TextEditingController();
  final isApproved = TextEditingController();
  final manufacturer = TextEditingController();
  final madeIn = TextEditingController();
  final type = TextEditingController();
  final isUnlimitedStock = TextEditingController(text: "0");
  final totalAllowedQuantity = TextEditingController();
  final taxIncludedInPrice = TextEditingController(text: '0'); // Default to No

  final fssaiLicNo = TextEditingController();
  final taxPercentage = TextEditingController();

  // Description
  String htmlDescription = '';
  final QuillEditorController descriptionController = QuillEditorController();
  final description = TextEditingController();

  final tags = TextEditingController();
  final otherInfo = TextEditingController();

  // Type selection fields
  int? selectedTypeId;
  String? selectedTypeName;
  String? selectedFoodTypeName;

  // Brand selection fields
  int? selectedBrandId;
  String? selectedBrandName;

  // Category selection fields
  int? selectedCategoryGroupId;
  String? selectedCategoryGroupName;
  int? selectedCategoryId;
  String? selectedCategoryName;
  int? selectedSubcategoryId;
  String? selectedSubcategoryName;

  File? imageFile; // for upload
  String? imageUrl;

  // STEP 2: VARIANTS
  List<VariantInputModel> variants = [VariantInputModel()];
  int packType = 0; // Packet/Loose
  int stockType = 0; // Limited/Unlimited

  // New for Step 3
  int isReturnable = 1;
  int isCancellable = 1;
  final returnDays = TextEditingController();
  final cancelDays = TextEditingController();
  
  // Cancelable statuses data
  List<Map<String, dynamic>> cancelableStatuses = [];
  bool isLoadingCancelableStatuses = false;

  void setReturnable(int val) {
    isReturnable = val;
    notifyListeners();
  }

  void setCancellable(int val) {
    isCancellable = val;
    notifyListeners();
    // Fetch cancelable statuses when cancellable is set to yes
    if (val == 1) {
      // We need to get context from somewhere, let's add a context parameter
      // For now, we'll handle this in the widget
    }
  }

  void setCancelDays(String value) {
    cancelDays.text = value;
    notifyListeners();
  }

  // Method to check if current value exists in dropdown items
  String? getValidCancelDaysValue() {
    if (cancelDays.text.isEmpty) return null;
    
    final hasMatchingItem = cancelableStatuses.any((status) => 
        status['id'].toString() == cancelDays.text);
    
    return hasMatchingItem ? cancelDays.text : null;
  }

  Future<void> fetchCancelableStatuses(BuildContext context) async {
    if (cancelableStatuses.isNotEmpty) return;
    
    isLoadingCancelableStatuses = true;
    notifyListeners();

    try {
      final response = await isCancelableApi(context: context);
      
      if (response != null && response['status'] == 1) {
        List<Map<String, dynamic>> apiData = List<Map<String, dynamic>>.from(response['data']);
        
        // Remove duplicates by ID
        Set<String> seenIds = {};
        cancelableStatuses = apiData.where((status) {
          final id = status['id'].toString();
          if (seenIds.contains(id)) {
            return false;
          }
          seenIds.add(id);
          return true;
        }).toList();
        
        // Validate current cancelDays value against new data
        if (cancelDays.text.isNotEmpty) {
          final isValidValue = cancelableStatuses.any((status) => 
              status['id'].toString() == cancelDays.text);
          if (!isValidValue) {
            // Clear the value if it's not valid anymore
            cancelDays.clear();
          }
        }
        
      } else {
        // Fallback to default options if API fails
        cancelableStatuses = [
          {"id": 2, "status": "Received"},
          {"id": 3, "status": "Processed"},
          {"id": 4, "status": "Shipped"}
        ];
      }
    } catch (e) {
      print('Error fetching cancelable statuses: $e');
      // Fallback to default options if API fails
      cancelableStatuses = [
        {"id": 2, "status": "Received"},
        {"id": 3, "status": "Processed"},
        {"id": 4, "status": "Shipped"}
      ];
    } finally {
      isLoadingCancelableStatuses = false;
      notifyListeners();
    }
  }

  // Method to clear and reset the list if needed
  void resetCancelableStatuses() {
    cancelableStatuses.clear();
    notifyListeners();
  }

  void setCategoryGroup(int id, String name) {
    selectedCategoryGroupId = id;
    selectedCategoryGroupName = name;
    // Reset subsequent selections
    selectedCategoryId = null;
    selectedCategoryName = null;
    selectedSubcategoryId = null;
    selectedSubcategoryName = null;
    categoryId.clear();
    notifyListeners();
  }

  void setCategory(int id, String name) {
    selectedCategoryId = id;
    selectedCategoryName = name;
    // Reset subsequent selections
    selectedSubcategoryId = null;
    selectedSubcategoryName = null;
    categoryId.clear();
    notifyListeners();
  }

  void setSubcategory(int id, String name) {
    selectedSubcategoryId = id;
    selectedSubcategoryName = name;
    categoryId.text = id.toString();
    notifyListeners();
  }

  void setProductType(int id, String name) {
    selectedTypeId = id;
    selectedTypeName = name;
    type.text =
        name; // Keep type controller for backward compatibility if needed, or just use selectedTypeId
    notifyListeners();
  }

  void setTaxIncluded(String val) {
    taxIncludedInPrice.text = val;
    notifyListeners();
  }

  void setBrand(int id, String name) {
    selectedBrandId = id;
    selectedBrandName = name;
    brandId.text = id.toString();
    notifyListeners();
  }

  void setHtmlDescription(String description) {
    htmlDescription = description;
    descriptionController.setText(htmlDescription);
    notifyListeners();
  }

  void setFoodType(String typeId) {
    indicator.text = typeId;
    selectedFoodTypeName = typeId == '1' ? 'Veg' : 'Non-Veg';
    notifyListeners();
  }

  void nextStep(BuildContext context) {
    if (stepIndex == 0) {
      if (imageFile == null && imageUrl == null) {
        showMessage(
            context,
            getTranslatedValue(context, selectProductImageLabel),
            MessageType.error);
        return;
      }
      if (name.text.trim().isEmpty) {
        showMessage(
            context,
            getTranslatedValue(context, productNameValidationMessageLabel),
            MessageType.error);
        return;
      }

      if (selectedSubcategoryId == null) {
        showMessage(
            context,
            getTranslatedValue(context, pleaseSelectCategoryLabel),
            MessageType.error);
        return;
      }
      if (selectedTypeId == null) {
        showMessage(context, getTranslatedValue(context, pleaseSelectTypeLabel),
            MessageType.error);
        return;
      }
      if (description.text.trim().isEmpty) {
        showMessage(
            context,
            getTranslatedValue(context, productDescriptionValidationMessageLabel),
            MessageType.error);
        return;
      }
    }

    if (stepIndex < 2) {
      stepIndex++;
      notifyListeners();
    }
  }

  void previousStep(BuildContext context) {
    if (stepIndex > 0) {
      stepIndex--;
      notifyListeners();
    } else {
      // Get theme colors
      final themeProvider =
          Provider.of<app_theme.ThemeProvider>(context, listen: false);
      final colorScheme = themeProvider.colorScheme;

      // Show exit confirmation bottom sheet
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        builder: (bottomSheetContext) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
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
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, _) {
                      return Column(
                        children: [
                          Text(
                            getTranslatedValue(context, discardChangesLabel),
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.textPrimary,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // Message
                          Text(
                            getTranslatedValue(
                                context, unsavedChangesWillBeLostLabel),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: colorScheme.textSecondary,
                              height: 1.02,
                              letterSpacing: -0.25,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 28),
                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.pop(bottomSheetContext),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    side: BorderSide(
                                      color: colorScheme.border,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    getTranslatedValue(context, cancelLabel),
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.textPrimary,
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    backgroundColor: colorScheme.error,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    getTranslatedValue(context, exitLabel),
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
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  void setImageFile(File? f) {
    imageFile = f;
    imageUrl = null;
    notifyListeners();
  }

  void addVariant() {
    variants.add(VariantInputModel());
    notifyListeners();
  }

  void removeVariant(int idx) {
    if (variants.length > 1) {
      final removed = variants[idx];
      variants.removeAt(idx);
      notifyListeners();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        removed.dispose();
      });
    }
  }

  void setPackType(int v) {
    packType = v;
    notifyListeners();
  }

  void setStockType(int v) {
    stockType = v;
    isUnlimitedStock.text = v == 1 ? '1' : '0';
    notifyListeners();
  }

  void addVariantImages(int idx, List<File> files) {
    if (idx >= 0 && idx < variants.length) {
      variants[idx].variantImages.addAll(files);
      notifyListeners();
    }
  }

  void removeVariantImage(int idx, {int? imageIndex, int? existingIndex}) {
    if (idx >= 0 && idx < variants.length) {
      if (imageIndex != null && imageIndex < variants[idx].variantImages.length) {
        variants[idx].variantImages.removeAt(imageIndex);
      }
      if (existingIndex != null && existingIndex < variants[idx].existingImageUrls.length) {
        // Track the deleted image ID for backend deletion
        if (existingIndex < variants[idx].existingImageIds.length) {
          final deletedId = variants[idx].existingImageIds[existingIndex];
          if (deletedId > 0) {
            variants[idx].deletedImageIds.add(deletedId);
          }
          variants[idx].existingImageIds.removeAt(existingIndex);
        }
        variants[idx].existingImageUrls.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  /// Delete the current product
  Future<bool> deleteProduct(BuildContext context) async {
    if (product == null || product!.id == null) {
      showMessage(context, 'No product to delete', MessageType.error);
      return false;
    }

    try {
      final result = await deleteProductApi(
        productId: product!.id!,
        context: context,
      );

      if (result != null && result['status'].toString() == '1') {
        showMessage(
            context,
            result['message'] ?? 'Product deleted successfully!',
            MessageType.success);
        return true;
      } else {
        showMessage(context, result['message'] ?? 'Failed to delete product',
            MessageType.error);
        return false;
      }
    } catch (e) {
      showMessage(context, 'Error deleting product: $e', MessageType.error);
      return false;
    }
  }

  /// Delete a specific variant
  Future<bool> deleteVariant(int idx, BuildContext context) async {
    if (idx < 0 || idx >= variants.length) {
      return false;
    }

    final variant = variants[idx];

    // If variant has an ID (existing variant), delete from server
    if (variant.variantId != null && variant.variantId!.isNotEmpty) {
      try {
        final result = await deleteVariantApi(
          variantId: variant.variantId!,
          context: context,
        );

        if (result != null && result['status'].toString() == '1') {
          showMessage(
              context,
              result['message'] ?? 'Variant deleted successfully!',
              MessageType.success);
          // Remove from local list
          variants.removeAt(idx);
          notifyListeners();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            variant.dispose();
          });
          return true;
        } else {
          showMessage(context, result['message'] ?? 'Failed to delete variant',
              MessageType.error);
          return false;
        }
      } catch (e) {
        showMessage(context, 'Error deleting variant: $e', MessageType.error);
        return false;
      }
    } else {
      // New variant (not saved yet), just remove from list
      if (variants.length > 1) {
        variant.dispose();
        variants.removeAt(idx);
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  Future<ProductListItem> getProductListItem() async {
    return ProductListItem(
      name: name.text,
      taxId: taxId.text,
      brandId: selectedBrandId?.toString() ?? brandId.text,
      slug: slug.text,
      categoryId: categoryId.text,
      indicator: indicator.text,
      isApproved: isApproved.text,
      manufacturer: manufacturer.text,
      madeIn: madeIn.text,
      type: selectedTypeId?.toString() ??
          type.text, // Use ID if selected, else text
      isUnlimitedStock: isUnlimitedStock.text,
      totalAllowedQuantity: totalAllowedQuantity.text,
      taxIncludedInPrice: taxIncludedInPrice.text,
      taxPercentage: taxPercentage
          .text, // Add this to model if needed, or handle separately
      fssaiLicNo: fssaiLicNo.text,
      description: description.text,
      tags: tags.text,
      otherInfo: otherInfo.text,
      imageUrl: imageUrl, // Set this after uploading if API returns URL
      variants: variants.map((e) => e.toVariant()).toList(),
    );
  }

  /// Save product to API using multipart request
  Future<bool> saveProduct(BuildContext context) async {
    // Set loading state
    _isSaving = true;
    notifyListeners();

    try {
      // Get store ID from session
      final storeId = Constant.session.getData(SessionManager.keyStoreId);

      // Prepare basic params
      Map<String, String> params = {
        'name': name.text.trim(),
        'store_id': storeId.toString(),
        'category_id': selectedSubcategoryId?.toString() ?? '',
        'category_group_id': selectedCategoryGroupId?.toString() ?? '',
        'sub_category_group_id': selectedCategoryId?.toString() ?? '',
        'item_type_id': selectedTypeId?.toString() ?? '',
        'description': description.text,
        'brand_id': selectedBrandId?.toString() ?? '',
        'is_unlimited_stock': isUnlimitedStock.text,
        'type': packType == 0 ? 'packet' : 'loose',
        'max_allowed_quantity': totalAllowedQuantity.text,
        'tags': tags.text,
        'made_in': madeIn.text,
        'other_info': otherInfo.text,
        'manufacturer': manufacturer.text,
        'tax': taxPercentage.text,
        'indicator': indicator.text,
        'total_allowed_quantity': totalAllowedQuantity.text,
        'fssai_number': fssaiLicNo.text,
        'tax_included_in_price': taxIncludedInPrice.text,
        'return_status': isReturnable.toString(),
        'return_days': returnDays.text.isEmpty ? '0' : returnDays.text,
        'cancelable_status': isCancellable.toString(),
        'till_status': cancelDays.text.isEmpty ? '0' : cancelDays.text,
      };

      // Debug: Print all params
      print('=== API Params ===');
      params.forEach((key, value) {
        print('$key: $value');
      });
      print('==================');

      // Add variant arrays based on type
      String type = packType == 0 ? 'packet' : 'loose';

      if (type == 'packet') {
        // Packet type: each variant has its own stock, unit, and status
        for (int i = 0; i < variants.length; i++) {
          final variant = variants[i];
          params['variant_id[$i]'] = variant.variantId.toString();
          params['packet_measurement[$i]'] = variant.measurement.text;
          params['packet_price[$i]'] = variant.price.text;
          params['discounted_price[$i]'] = variant.discountedPrice.text;
          params['packet_status[$i]'] =
              variant.status.text == 'Available' ? '1' : '0';
          params['packet_stock[$i]'] =
              stockType == 1 ? '0' : variant.stock.text;
          params['packet_stock_unit_id[$i]'] =
              variant.selectedUnitId?.toString() ?? '1';
        }
      } else {
        // Loose type: shared stock_unit_id and status across all variants
        // Use first variant's unit and status for all
        final firstVariant = variants.isNotEmpty ? variants[0] : null;
        params['loose_stock_unit_id'] =
            firstVariant?.selectedUnitId?.toString() ?? '1';
        params['status'] = firstVariant?.status.text == 'Available' ? '1' : '0';

        int looseIdx = 0;
        for (int i = 0; i < variants.length; i++) {
          final variant = variants[i];
          if (variant.measurement.text.isEmpty && variant.price.text.isEmpty && variant.variantId == null) {
            continue;
          }
          params['variant_id[$looseIdx]'] = variant.variantId.toString();
          params['loose_measurement[$looseIdx]'] = variant.measurement.text;
          params['loose_price[$looseIdx]'] = variant.price.text;
          params['loose_discounted_price[$looseIdx]'] = variant.discountedPrice.text;
          params['loose_stock[$looseIdx]'] = stockType == 1 ? '0' : variant.stock.text;
          looseIdx++;
        }
      }

      // Filter out empty variants for file uploads
      final nonEmptyVariants = <int>[];
      for (int i = 0; i < variants.length; i++) {
        final v = variants[i];
        if (type == 'loose' && v.measurement.text.isEmpty && v.price.text.isEmpty && v.variantId == null) {
          continue;
        }
        nonEmptyVariants.add(i);
      }

      // Prepare files map
      Map<String, File> filesMap = {};
      if (imageFile != null) {
        filesMap['image'] = imageFile!;
      }

      // Collect deleted image IDs from all variants (for update only)
      if (product != null) {
        List<int> allDeletedImageIds = [];
        for (int idx = 0; idx < variants.length; idx++) {
          allDeletedImageIds.addAll(variants[idx].deletedImageIds);
        }
        if (allDeletedImageIds.isNotEmpty) {
          params['deleteImageIds'] = json.encode(allDeletedImageIds);
          debugPrint('=== Deleted image IDs: $allDeletedImageIds ===');
        }
      }

      // Add variant images (key format: packet_variant_images_{index} or loose_variant_images_{index})
      List<MapEntry<String, File>> variantFilesList = [];
      for (int idx = 0; idx < nonEmptyVariants.length; idx++) {
        final images = variants[nonEmptyVariants[idx]].variantImages;
        debugPrint('=== Variant[$idx] images count: ${images.length} ===');
        if (images.isNotEmpty) {
          String key = type == 'packet'
              ? 'packet_variant_images_$idx[]'
              : 'loose_variant_images_$idx[]';
          for (final file in images) {
            debugPrint('Adding variant image: key=$key, path=${file.path}');
            variantFilesList.add(MapEntry(key, file));
          }
        }
      }
      debugPrint('=== Total variant files to upload: ${variantFilesList.length} ===');
      debugPrint('=== filesMap count: ${filesMap.length} ===');

      // Call API
      final result = await addOrUpdateProductApi(
        params: params,
        filesMap: filesMap,
        filesList: variantFilesList.isNotEmpty ? variantFilesList : null,
        context: context,
        isAdd: product == null,
        productId: product?.id,
      );

      if (result != null && result['status'].toString() == '1') {
        showMessage(context, result['message'] ?? 'Product saved successfully!',
            MessageType.success);
        return true;
      } else {
        showMessage(context, result?['message'] ?? 'Failed to save product',
            MessageType.error);
        return false;
      }
    } catch (e) {
      print('Error saving product: $e');
      showMessage(context, 'Error: $e', MessageType.error);
      return false;
    } finally {
      // Reset loading state
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Removed invalid statusFocus disposal (belongs to VariantInputModel)
    name.dispose();
    // Dispose focus nodes
    categoryGroupFocus.dispose();
    categoryFocus.dispose();
    subcategoryFocus.dispose();
    typeFocus.dispose();
    brandFocus.dispose();
    taxId.dispose();
    brandId.dispose();
    slug.dispose();
    categoryId.dispose();
    indicator.dispose();
    isApproved.dispose();
    manufacturer.dispose();
    madeIn.dispose();
    type.dispose();
    isUnlimitedStock.dispose();
    totalAllowedQuantity.dispose();
    taxIncludedInPrice.dispose();
    taxPercentage.dispose();
    fssaiLicNo.dispose();
    descriptionController.dispose();
    description.dispose();
    tags.dispose();
    otherInfo.dispose();
    returnDays.dispose();
    cancelDays.dispose();
    for (final v in variants) {
      v.dispose();
    }
    super.dispose();
  }
}

// -- WRAPPER & STEP 1 --
class AddProductScreen extends StatelessWidget {
  final ProductListItem? product;

  const AddProductScreen({Key? key, this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductStepperProvider>(
      create: (_) {
        final provider = ProductStepperProvider(product: product);
        // Initialize cancelable statuses after provider creation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.fetchCancelableStatuses(context);
        });
        return provider;
      },
      child: Consumer<ProductStepperProvider>(
        builder: (context, provider, _) {
          final themeProvider = context.watch<app_theme.ThemeProvider>();
          final colorScheme = themeProvider.colorScheme;

          return PopScope(
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                provider.previousStep(context);
              }
            },
            canPop: false,
            child: Scaffold(
              backgroundColor: colorScheme.background,
              body: Column(
                children: [
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, _) {
                      return AppHeader(
                        label: Constant.session.getIsSweetHouse()
                            ? getTranslatedValue(
                                context,
                                Constant.session.getIsSweetHouse()
                                    ? foodManagementLabel
                                    : manageFoodItemsLabel)
                            : getTranslatedValue(context, productManagementLabel),
                        title: Constant.session.getIsSweetHouse()
                            ? (provider.product == null
                                ? getTranslatedValue(context, addFoodItemsLabel)
                                : getTranslatedValue(
                                    context, updateFoodItemsLabel))
                            : (provider.product == null
                                ? getTranslatedValue(context, addProductLabel)
                                : getTranslatedValue(
                                    context, updateProductLabel)),
                        showBackButton: true,
                        onBackPressed: () => provider.previousStep(context),
                        trailing: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _stepper(provider.stepIndex, colorScheme),
                        ),
                      );
                    },
                  ),
                  Expanded(child: _StepBody()),
                ],
              ),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: provider.isSaving
                        ? null
                        : () async {
                            if (provider.stepIndex < 2) {
                              provider.nextStep(context);
                            } else {
                              // Validate cancellable till status
                              if (provider.isCancellable == 1 &&
                                  provider.cancelDays.text.trim().isEmpty) {
                                showMessage(
                                    context,
                                    getTranslatedValue(context,
                                        productCancelableStatusSelectionValidationMessageLabel),
                                    MessageType.error);
                                return;
                              }
                              // Call saveProduct API
                              final success =
                                  await provider.saveProduct(context);
                              if (success) {
                                // Navigate back on success
                                Navigator.of(context).pop();
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      elevation: 0,
                      disabledBackgroundColor:
                          colorScheme.primary.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Consumer<LanguageProvider>(
                      builder: (context, languageProvider, _) {
                        return provider.isSaving
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    provider.product == null
                                        ? getTranslatedValue(
                                            context, addingLabel)
                                        : getTranslatedValue(
                                            context, updatingLabel),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 19,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                provider.stepIndex == 2
                                    ? getTranslatedValue(context, finishLabel)
                                    : "Next",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 19,
                                ),
                              );
                      },
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

  Widget _stepper(int step, app_theme.AppColorScheme colorScheme) {
    Color line(int s) => step >= s ? colorScheme.primary : colorScheme.border;
    Widget node(String n, bool act, bool fill) => Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: fill
                ? colorScheme.primary.withValues(alpha: 0.6)
                : act
                    ? colorScheme.primary
                    : colorScheme.border,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: fill
                ? Icon(
                    Icons.check,
                    color: colorScheme.primary,
                    size: 21,
                  )
                : Text(
                    n,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                    ),
                  ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          node("1", step == 0, step > 0),
          Container(height: 5, width: 42, color: line(1)),
          node("2", step == 1, step > 1),
          Container(height: 5, width: 42, color: line(2)),
          node("3", step == 2, false),
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductStepperProvider>(context);

    if (provider.stepIndex == 0) return _Step1MainFields();
    if (provider.stepIndex == 1) return _Step2Variants();
    return _Step3ReturnCancel();
  }
}

// Step 1: Main Product Info
class _Step1MainFields extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<ProductStepperProvider>(context, listen: false);
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () {
                ImagePickerBottomSheet.show(
                  context,
                  allowMultiple: false,
                  title: getTranslatedValue(context, selectProductImageLabel),
                  onImagesPicked: (images) {
                    if (images.isNotEmpty) {
                      p.setImageFile(images.first);
                    }
                  },
                );
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 9),
                padding: const EdgeInsets.symmetric(vertical: 25),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.border),
                ),
                child: p.imageFile == null && p.imageUrl == null
                    ? Column(
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              color: colorScheme.textTertiary, size: 33),
                          const SizedBox(height: 7),
                          Text(
                            getTranslatedValue(
                                context, selectProductImageLabel),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(getTranslatedValue(context, pngJpgFormatLabel),
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: colorScheme.textTertiary)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: p.imageFile != null
                            ? Image.file(
                                p.imageFile!,
                                width: 95,
                                height: 95,
                                fit: BoxFit.contain,
                              )
                            : setNetworkImg(
                                image: p.imageUrl!,
                                width: 95,
                                height: 95,
                                boxFit: BoxFit.contain,
                              ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return CustomTextFormField(
                title: getTranslatedValue(context, productNameLabel),
                hintText: getTranslatedValue(context, productNameHintLabel),
                controller: p.name,
                textCapitalization: TextCapitalization.sentences,
              );
            },
          ),
          SizedBox(height: 13),
          // Category Selection Dropdowns
          _buildCategorySelectionSection(context, p),
          SizedBox(height: 13),

          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return Text(
                getTranslatedValue(context, typeSelectionLabel),
                style: AppTypography.bodyMedium(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textPrimary,
                ),
              );
            },
          ),
          SizedBox(height: 4),

          // Type Selection
          _buildDropdownButton(
            context: context,
            label: getTranslatedValue(context, selectTypeLabel),
            selectedValue: p.selectedTypeName,
            onTap: p.selectedSubcategoryId != null
                ? () => _showTypeBottomSheet(context, p)
                : null,
            isEnabled: p.selectedSubcategoryId != null,
            focusNode: p.typeFocus,
          ),

          SizedBox(height: 13),

          // Food Type: Veg / Non-Veg selector
          Consumer<app_theme.ThemeProvider>(
            builder: (context, themeProvider, _) {
              final colorScheme = themeProvider.colorScheme;
              final isVeg = p.indicator.text == '1';
              final isNonVeg = p.indicator.text == '2';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Food Type',
                    style: AppTypography.bodyMedium(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      // Veg option
                      Expanded(
                        child: GestureDetector(
                          onTap: () => p.setFoodType('1'),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isVeg
                                  ? Color(0xFF4CAF50).withValues(alpha: 0.12)
                                  : colorScheme.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isVeg
                                    ? Color(0xFF4CAF50)
                                    : colorScheme.border,
                                width: isVeg ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Color(0xFF4CAF50),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Veg',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isVeg
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isVeg
                                        ? Color(0xFF4CAF50)
                                        : colorScheme.textSecondary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Non-Veg option
                      Expanded(
                        child: GestureDetector(
                          onTap: () => p.setFoodType('2'),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isNonVeg
                                  ? Color(0xFFE53935).withValues(alpha: 0.12)
                                  : colorScheme.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isNonVeg
                                    ? Color(0xFFE53935)
                                    : colorScheme.border,
                                width: isNonVeg ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Color(0xFFE53935),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFE53935),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Non-Veg',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isNonVeg
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isNonVeg
                                        ? Color(0xFFE53935)
                                        : colorScheme.textSecondary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 13),

          // Hide brand, manufacturer, made in, and tax fields for sweet house
          if (!Constant.session.getIsSweetHouse()) ...[
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslatedValue(context, selectBrandLabel),
                      style: AppTypography.bodyMedium(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),

                    // Brand Selection
                    _buildDropdownButton(
                      context: context,
                      label: getTranslatedValue(context, selectBrandLabel),
                      selectedValue: p.selectedBrandName,
                      onTap: () => _showBrandBottomSheet(context, p),
                      focusNode: p.brandFocus,
                    ),

                    SizedBox(height: 13),

                    CustomTextFormField(
                      title: getTranslatedValue(context, manufacturerLabel),
                      hintText: getTranslatedValue(
                          context, productManufacturerHintLabel),
                      controller: p.manufacturer,
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 13),
                    CustomTextFormField(
                      title: getTranslatedValue(context, madeInLabel),
                      hintText:
                          getTranslatedValue(context, productMadeInHintLabel),
                      controller: p.madeIn,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 13),

            // // Tax Included Dropdown
            // Consumer<LanguageProvider>(
            //   builder: (context, languageProvider, _) {
            //     return Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text(
            //           getTranslatedValue(context, taxIncludedInPriceLabel),
            //           style: GoogleFonts.inter(
            //             fontSize: 14,
            //             fontWeight: FontWeight.w500,
            //             color: colorScheme.textPrimary,
            //           ),
            //         ),
            //         const SizedBox(height: 6),
            //         Container(
            //           padding: const EdgeInsets.symmetric(horizontal: 12),
            //           decoration: BoxDecoration(
            //             color: colorScheme.surfaceVariant,
            //             borderRadius: BorderRadius.circular(14),
            //             border: Border.all(color: colorScheme.border),
            //           ),
            //           child: DropdownButtonHideUnderline(
            //             child: DropdownButton<String>(
            //               value: p.taxIncludedInPrice.text,
            //               isExpanded: true,
            //               icon: Icon(Icons.keyboard_arrow_down,
            //                   color: colorScheme.textSecondary),
            //               items: [
            //                 DropdownMenuItem(
            //                     value: '1',
            //                     child: Consumer<LanguageProvider>(
            //                       builder: (context, provider, _) {
            //                         return Text(
            //                             getTranslatedValue(context, yesLabel),
            //                             style: GoogleFonts.inter(
            //                               color: colorScheme.textPrimary,
            //                             ));
            //                       },
            //                     )),
            //                 DropdownMenuItem(
            //                     value: '0',
            //                     child: Consumer<LanguageProvider>(
            //                       builder: (context, provider, _) {
            //                         return Text(
            //                             getTranslatedValue(context, noLabel),
            //                             style: GoogleFonts.inter(
            //                               color: colorScheme.textPrimary,
            //                             ));
            //                       },
            //                     )),
            //               ],
            //               onChanged: (val) {
            //                 if (val != null) p.setTaxIncluded(val);
            //               },
            //             ),
            //           ),
            //         ),
            //         SizedBox(height: 13),
            //
            //         // Tax Percentage
            //         CustomTextFormField(
            //           title: getTranslatedValue(context, taxPercentageLabel),
            //           hintText: getTranslatedValue(
            //               context, taxPercentageExampleLabel),
            //           controller: p.taxPercentage,
            //           keyboardType: TextInputType.number,
            //           inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            //         ),
            //       ],
            //     );
            //   },
            // ),
            // SizedBox(height: 13),
          ],

          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return CustomTextFormField(
                title: getTranslatedValue(context, fssaiLicenseLabel),
                hintText: getTranslatedValue(context, fssaiLicenseExampleLabel),
                controller: p.fssaiLicNo,
                maxLength: 14,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length != 14) {
                    return getTranslatedValue(
                        context, fssaiLicenseValidationLabel);
                  }
                  return null;
                },
              );
            },
          ),
          SizedBox(height: 13),

          // Description
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return CustomTextFormField(
                title: getTranslatedValue(context, descriptionLabel),
                hintText: getTranslatedValue(
                    context, enterProductDescriptionLabel),
                controller: p.description,
                maxLines: 3,
              );
            },
          ),
          SizedBox(height: 13),

          // Tags
          // Consumer<LanguageProvider>(
          //   builder: (context, languageProvider, _) {
          //     return CustomTextFormField(
          //       title: getTranslatedValue(context, tagsLabel),
          //       hintText: getTranslatedValue(context, tagsHintLabel),
          //       controller: p.tags,
          //       maxLines: 3,
          //     );
          //   },
          // ),
          SizedBox(height: 13),

          // Other Info
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return CustomTextFormField(
                title: getTranslatedValue(context, otherInfoLabel),
                hintText: getTranslatedValue(context, enterOtherInfoLabel),
                controller: p.otherInfo,
                maxLines: 3,
              );
            },
          ),
          SizedBox(height: 13),
        ],
      ),
    );
  }

  Widget _buildCategorySelectionSection(
      BuildContext context, ProductStepperProvider p) {
    return _buildCategorySelectionContent(context, p);
  }

  Widget _buildCategorySelectionContent(
      BuildContext context, ProductStepperProvider p) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    // Check if user is a sweet house (single category selection only)
    final isSweetHouse = Constant.session.getIsSweetHouse();
    // Check if user is not managed by admin
    final isNotManagedByAdmin = !Constant.session.getManagedByAdmin();

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              getTranslatedValue(context, categorySelectionLabel),
              style: AppTypography.bodyMedium(
                fontWeight: FontWeight.w600,
                color: colorScheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            if (isSweetHouse && isNotManagedByAdmin)
              // Sweet house: Show single category selection only
              _buildDropdownButton(
                context: context,
                label: getTranslatedValue(context, selectCategoryLabel),
                selectedValue: p.selectedSubcategoryName,
                onTap: () => _showSweetHouseCategoryBottomSheet(context, p),
                focusNode: p.categoryGroupFocus,
              )
            else
              // Show traditional three dropdown selection
              ...[
              // Category Group Dropdown
              _buildDropdownButton(
                context: context,
                label: getTranslatedValue(context, selectCategoryGroupLabel),
                selectedValue: p.selectedCategoryGroupName,
                onTap: () => _showCategoryGroupBottomSheet(context, p),
                focusNode: p.categoryGroupFocus,
              ),

              // Category Dropdown (enabled only if category group is selected)
              if (p.selectedCategoryGroupId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomPaint(
                        size: Size(24, 50),
                        painter: _HierarchyLinePainter(isLast: false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildDropdownButton(
                            context: context,
                            label: getTranslatedValue(
                                context, selectCategoryLabel),
                            selectedValue: p.selectedCategoryName,
                            onTap: () => _showCategoryBottomSheet(context, p),
                            isEnabled: true,
                            focusNode: p.categoryFocus,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Subcategory Dropdown (enabled only if category is selected)
              if (p.selectedCategoryId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Spacer for first level indentation
                      SizedBox(width: 24),
                      CustomPaint(
                        size: Size(24, 50),
                        painter: _HierarchyLinePainter(isLast: true),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildDropdownButton(
                            context: context,
                            label: getTranslatedValue(
                                context, selectSubcategoryLabel),
                            selectedValue: p.selectedSubcategoryName,
                            onTap: () =>
                                _showSubcategoryBottomSheet(context, p),
                            isEnabled: true,
                            focusNode: p.subcategoryFocus,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDropdownButton({
    required BuildContext context,
    required String label,
    String? selectedValue,
    VoidCallback? onTap,
    bool isEnabled = true,
    FocusNode? focusNode,
  }) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return InkWell(
      onTap: isEnabled
          ? () {
              if (focusNode != null)
                FocusScope.of(context).requestFocus(focusNode);
              onTap?.call();
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isEnabled ? colorScheme.surfaceVariant : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? colorScheme.border : colorScheme.divider,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedValue ?? label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: selectedValue != null
                      ? colorScheme.textPrimary
                      : isEnabled
                          ? colorScheme.textTertiary
                          : colorScheme.divider,
                  fontWeight:
                      selectedValue != null ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color:
                  isEnabled ? colorScheme.textSecondary : colorScheme.divider,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryGroupBottomSheet(
      BuildContext context, ProductStepperProvider p) {
    final storeId = Constant.session.getData(SessionManager.keyStoreId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: CategorySelectionBottomSheet(
          title: getTranslatedValue(ctx, selectCategoryGroupLabel),
          searchHint: getTranslatedValue(ctx, searchCategoryGroupsLabel),
          fetchData: (search, page) => getCategoryGroupsRepository(
            storeId: storeId,
            search: search,
            page: page,
          ),
          onItemSelected: (item) {
            if (item is Map<String, dynamic>) {
              p.setCategoryGroup(item['id'], item['name']);
            }
          },
          addNewLabel: 'Manage Categories',
          onAddNew: () {},
        ),
      ),
    ).then((result) {
      if (result == 'addNew') {
        Constant.navigatorKay.currentState
            ?.pushNamed(categoryManagementScreen);
      }
    });
  }

  void _showCategoryBottomSheet(
      BuildContext context, ProductStepperProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: CategorySelectionBottomSheet(
          title: getTranslatedValue(ctx, selectCategoryLabel),
          searchHint: getTranslatedValue(ctx, searchCategoriesLabel),
          fetchData: (search, page) => getCategoriesByGroupRepository(
            categoryGroupId: p.selectedCategoryGroupId!,
            search: search,
            page: page,
          ),
          onItemSelected: (item) {
            if (item is Map<String, dynamic>) {
              p.setCategory(item['id'], item['name']);
            }
          },
          addNewLabel: 'Manage Categories',
          onAddNew: () {},
        ),
      ),
    ).then((result) {
      if (result == 'addNew') {
        Constant.navigatorKay.currentState
            ?.pushNamed(categoryManagementScreen);
      }
    });
  }

  void _showSubcategoryBottomSheet(
      BuildContext context, ProductStepperProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: CategorySelectionBottomSheet(
          title: getTranslatedValue(context, selectSubcategoryLabel),
          searchHint: getTranslatedValue(context, searchSubcategoriesLabel),
          fetchData: (search, page) => getSubCategoriesByGroupRepository(
            subCategoryGroupId: p.selectedCategoryId!,
            search: search,
            page: page,
          ),
          onItemSelected: (item) {
            if (item is Map<String, dynamic>) {
              p.setSubcategory(item['id'], item['name']);
            }
          },
        ),
      ),
    );
  }

  void _showSweetHouseCategoryBottomSheet(
      BuildContext context, ProductStepperProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: CategorySelectionBottomSheet(
          title: getTranslatedValue(ctx, selectCategoryLabel),
          searchHint: getTranslatedValue(ctx, searchCategoriesLabel),
          fetchData: (search, page) async {
            // Use the same API as category list screen for sweet house
            final Map<String, String> params = {};
            params['page'] = page.toString();
            if (search != null && search.isNotEmpty) {
              params['search'] = search;
            }
            return await getSellerCategoriesApi(params: params);
          },
          onItemSelected: (item) {
            if (item is Map<String, dynamic>) {
              log(item.toString());
              // For sweet house, set only the subcategory (final level)
              p.setSubcategory(item['id'], item['name']);
            }
          },
          addNewLabel: 'Manage Categories',
          onAddNew: () {},
        ),
      ),
    ).then((result) {
      if (result == 'addNew') {
        Constant.navigatorKay.currentState
            ?.pushNamed(categoryManagementScreen);
      }
    });
  }

  void _showTypeBottomSheet(
      BuildContext context, ProductStepperProvider p) async {
    // First, check if types exist for this category
    try {
      final response = await getCategoryTypesRepository(
        categoryId: p.selectedSubcategoryId.toString(),
        search: null,
        page: 1,
      );

      // Check if response has data
      final hasTypes = response['data'] != null &&
          response['data']['data'] != null &&
          (response['data']['data'] as List).isNotEmpty;

      if (!hasTypes && context.mounted) {
        // Show dialog to add types
        _showAddTypesDialog(context, p);
        return;
      }
    } catch (e) {
      print('Error checking types: $e');
    }

    // Show normal bottom sheet if types exist
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: CategorySelectionBottomSheet(
            title: getTranslatedValue(context, selectTypeLabel),
            searchHint: getTranslatedValue(context, searchTypesLabel),
            fetchData: (search, page) => getCategoryTypesRepository(
              categoryId: p.selectedSubcategoryId.toString(),
              search: search,
              page: page,
            ),
            onItemSelected: (item) {
              if (item is Map<String, dynamic>) {
                p.setProductType(item['id'], item['name']);
              }
            },
          ),
        ),
      );
    }
  }

  void _showAddTypesDialog(BuildContext context, ProductStepperProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  getTranslatedValue(context, noTypesAvailableLabel),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Close the dialog
                      Navigator.pop(bottomSheetContext);

                      // Navigate to organize screen (Three-Stage Category Stepper)
                      if (!Constant.session.getManagedByAdmin() &&
                          !Constant.session.getIsSweetHouse()) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiProvider(
                              providers: [
                                ChangeNotifierProvider(
                                  create: (context) => CategoryListProvider(),
                                ),
                              ],
                              child: const ThreeStageCategoryStepperScreen(),
                            ),
                          ),
                        );
                        // Show success message
                        if (result == true && context.mounted) {
                          showMessage(
                            context,
                            'You can now select the type for your product.',
                            MessageType.success,
                          );
                        }
                      } else {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiProvider(
                              providers: [
                                ChangeNotifierProvider(
                                  create: (context) => CategoryListProvider(),
                                ),
                              ],
                              child: const CategoryListScreen(),
                            ),
                          ),
                        );
                        // Show success message
                        if (result == true && context.mounted) {
                          showMessage(
                            context,
                            'You can now select the type for your product.',
                            MessageType.success,
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9AC444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.layers_outlined, size: 20),
                    label: Consumer<LanguageProvider>(
                      builder: (context, languageProvider, _) {
                        return Text(
                          getTranslatedValue(
                              context, organizeCategoriesAddTypesLabel),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBrandBottomSheet(
      BuildContext context, ProductStepperProvider p) async {
    // First, check if brands exist for this category
    try {
      final response = await getAllBrandsRepository(
        search: null,
        page: 1,
        categoryId: p.selectedSubcategoryId,
      );

      // Check if response has data
      final hasBrands = response['data'] != null &&
          response['data']['data'] != null &&
          (response['data']['data'] as List).isNotEmpty;

      if (!hasBrands && context.mounted) {
        // Show dialog to add brands
        _showAddBrandsDialog(context, p);
        return;
      }
    } catch (e) {
      print('Error checking brands: $e');
    }

    // Show normal bottom sheet if brands exist
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: CategorySelectionBottomSheet(
            title: getTranslatedValue(context, selectBrandLabel),
            searchHint: getTranslatedValue(context, searchBrandsLabel),
            fetchData: (search, page) => getAllBrandsRepository(
              search: search,
              page: page,
              categoryId: p.selectedSubcategoryId,
            ),
            onItemSelected: (item) {
              if (item is Map<String, dynamic>) {
                p.setBrand(item['id'], item['name']);
              }
            },
          ),
        ),
      );
    }
  }

  void _showAddBrandsDialog(BuildContext context, ProductStepperProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.branding_watermark_outlined,
                    size: 48,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Consumer<LanguageProvider>(
                  builder: (context, languageProvider, _) {
                    return Text(
                      getTranslatedValue(context, noBrandsAvailableLabel),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Description
                Consumer<LanguageProvider>(
                  builder: (context, languageProvider, _) {
                    return Text(
                      getTranslatedValue(
                          context, noBrandsAvailableMessageLabel),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Close the dialog
                      Navigator.pop(bottomSheetContext);

                      // Navigate to brand management screen
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MultiProvider(
                            providers: [
                              ChangeNotifierProvider(
                                create: (context) => BrandManagementProvider(),
                              ),
                            ],
                            child: const BrandManagementScreen(),
                          ),
                        ),
                      );

                      // Show success message
                      if (result == true && context.mounted) {
                        showMessage(
                          context,
                          'You can now select the brand for your product.',
                          MessageType.success,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9AC444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_business_outlined, size: 20),
                    label: Consumer<LanguageProvider>(
                      builder: (context, languageProvider, _) {
                        return Text(
                          getTranslatedValue(context, addBrandLabel),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Alternative action
                TextButton(
                  onPressed: () {
                    Navigator.pop(bottomSheetContext);
                  },
                  child: Consumer<LanguageProvider>(
                    builder: (context, languageProvider, _) {
                      return Text(
                        getTranslatedValue(context, skipForNowLabel),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Show delete variant confirmation bottom sheet
void _showDeleteVariantConfirmation(
    BuildContext context, ProductStepperProvider provider, int variantIdx) {
  if (variantIdx < 0 || variantIdx >= provider.variants.length) return;

  final variant = provider.variants[variantIdx];
  final variantName = variant.measurement.text.isEmpty
      ? 'Variant ${variantIdx + 1}'
      : '${variant.measurement.text} ${variant.stockUnitName.text}';

  // Don't allow deletion if it's the only variant
  if (provider.variants.length == 1) {
    showMessage(
      context,
      'Cannot delete the only variant. A product must have at least one variant.',
      MessageType.warning,
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    backgroundColor: Colors.white,
    builder: (bottomSheetContext) => Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            children: [
              Expanded(
                child: Consumer<LanguageProvider>(
                  builder: (context, languageProvider, _) {
                    return Text(
                      getTranslatedValue(context, deleteVariantLabel),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    );
                  },
                ),
              ),
              Material(
                color: Color(0xFFF3F4F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => Navigator.pop(bottomSheetContext),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Warning icon and message
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variant.variantId != null &&
                                variant.variantId!.isNotEmpty
                            ? 'Permanent Action'
                            : 'Remove Variant',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Consumer<LanguageProvider>(
                        builder: (context, languageProvider, _) {
                          return Text(
                            variant.variantId != null &&
                                    variant.variantId!.isNotEmpty
                                ? getTranslatedValue(
                                    context, actionCannotBeUndoneLabel)
                                : getTranslatedValue(
                                    context, willRemoveUnsavedVariantLabel),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Color(0xFF991B1B),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Variant info
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return Text(
                getTranslatedValue(context, areYouSureDeleteVariantLabel),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Color(0xFF374151),
                  height: 1.5,
                ),
              );
            },
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.category_rounded,
                      color: Color(0xFF6B7280),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Consumer<LanguageProvider>(
                      builder: (context, languageProvider, _) {
                        return Text(
                          getTranslatedValue(context, variantLabel),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  variantName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
                if (provider.product != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'from ${provider.product!.name ?? "Product"}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(bottomSheetContext),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Consumer<LanguageProvider>(
                    builder: (context, languageProvider, _) {
                      return Text(
                        getTranslatedValue(context, cancelLabel),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF374151),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(bottomSheetContext);

                    // If variant has an ID (existing variant), call deleteVariant
                    if (variant.variantId != null &&
                        variant.variantId!.isNotEmpty) {
                      await provider.deleteVariant(variantIdx, context);
                    } else {
                      // New variant (not saved yet), just remove from list
                      provider.removeVariant(variantIdx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Consumer<LanguageProvider>(
                    builder: (context, languageProvider, _) {
                      return Text(
                        getTranslatedValue(context, deleteVariantLabel),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _HierarchyLinePainter extends CustomPainter {
  final bool isLast;

  _HierarchyLinePainter({required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double radius = 12.0;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Start from top
    path.moveTo(centerX, -12);

    // Draw vertical line to just before the curve
    path.lineTo(centerX, centerY - radius);

    // Draw the curve (bottom-left corner of the L)
    path.quadraticBezierTo(
      centerX, centerY, // Control point (corner)
      centerX + radius, centerY, // End point (start of horizontal)
    );

    // Draw horizontal line to the end
    path.lineTo(size.width, centerY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Step 2: Variants UI ---
class _Step2Variants extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductStepperProvider>(context);
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
      child: Column(
        children: [
          // Pack and Stock type selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.border),
              boxShadow: colorScheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<LanguageProvider>(
                  builder: (context, languageProvider, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(getTranslatedValue(context, packTypeLabel),
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.textPrimary)),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            _RadioCircle(
                              value: 0,
                              groupValue: provider.packType,
                              onChanged: provider.setPackType,
                              label: getTranslatedValue(context, packetLabel),
                            ),
                            const SizedBox(width: 22),
                            _RadioCircle(
                              value: 1,
                              groupValue: provider.packType,
                              onChanged: provider.setPackType,
                              label: getTranslatedValue(context, looseLabel),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(getTranslatedValue(context, stockTypeLabel),
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.textPrimary)),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            _RadioCircle(
                              value: 0,
                              groupValue: provider.stockType,
                              onChanged: provider.setStockType,
                              label: getTranslatedValue(context, limitedLabel),
                            ),
                            const SizedBox(width: 28),
                            _RadioCircle(
                              value: 1,
                              groupValue: provider.stockType,
                              onChanged: provider.setStockType,
                              label:
                                  getTranslatedValue(context, unlimitedLabel),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          ...provider.variants.asMap().entries.map((entry) {
            int idx = entry.key;
            VariantInputModel v = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 17),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 18),
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.border),
                boxShadow: colorScheme.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          title: getTranslatedValue(context, measurementLabel),
                          hintText: idx == 0
                              ? getTranslatedValue(
                                  context, measurementExample1Label)
                              : getTranslatedValue(
                                  context, measurementExampleLabel),
                          controller: v.measurement,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: CustomTextFormField(
                          title:
                              getTranslatedValue(context, measurementUnitLabel),
                          hintText:
                              getTranslatedValue(context, selectUnitLabel),
                          controller: v.stockUnitName,
                          focusNode: v.unitFocus,
                          readOnly: true,
                          onTap: () =>
                              _showUnitBottomSheet(context, v, v.unitFocus),
                          suffixIcon: HugeIcon(
                              icon: HugeIcons.strokeRoundedEdit02, size: 16),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          title:
                              getTranslatedValue(context, stockQuantityLabel),
                          hintText: idx == 0
                              ? getTranslatedValue(
                                  context, stockQuantityExampleLabel)
                              : "",
                          controller: v.stock,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: CustomTextFormField(
                          title: getTranslatedValue(context, stockStatusLabel),
                          hintText: getTranslatedValue(
                              context, stockStatusExampleLabel),
                          controller: v.status,
                          focusNode: v.statusFocus,
                          readOnly: true,
                          onTap: () => _showStockStatusBottomSheet(
                              context, v, v.statusFocus),
                          suffixIcon: HugeIcon(
                              icon: HugeIcons.strokeRoundedEdit02, size: 16),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          title: getTranslatedValue(context, priceLabel),
                          hintText:
                              getTranslatedValue(context, enterPriceLabel),
                          prefixIcon: Icon(Icons.currency_rupee),
                          controller: v.price,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$')),
                          ],
                        ),
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: CustomTextFormField(
                          title:
                              getTranslatedValue(context, discountedPriceLabel),
                          hintText: getTranslatedValue(
                              context, enterDiscountedPriceLabel),
                          prefixIcon: Icon(Icons.currency_rupee),
                          controller: v.discountedPrice,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 13),

                  // Variant Image Upload (multiple images)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show existing images + new images in a wrap
                        if (v.existingImageUrls.isNotEmpty ||
                            v.variantImages.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Existing server images
                              ...v.existingImageUrls
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _ShimmerNetworkImage(
                                        imageUrl: entry.value,
                                        height: 80,
                                        width: 80,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () =>
                                            provider.removeVariantImage(idx,
                                                existingIndex: entry.key),
                                        child: Container(
                                          padding: EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: colorScheme.error,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.close,
                                              color: colorScheme.iconPrimary,
                                              size: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              // New local images
                              ...v.variantImages
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        entry.value,
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () =>
                                            provider.removeVariantImage(idx,
                                                imageIndex: entry.key),
                                        child: Container(
                                          padding: EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: colorScheme.error,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.close,
                                              color: colorScheme.iconPrimary,
                                              size: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        if (v.existingImageUrls.isNotEmpty ||
                            v.variantImages.isNotEmpty)
                          SizedBox(height: 10),
                        // Add image button
                        GestureDetector(
                          onTap: () {
                            ImagePickerBottomSheet.show(
                              context,
                              allowMultiple: true,
                              title: getTranslatedValue(
                                  context, selectVariantImageLabel),
                              onImagesPicked: (images) {
                                if (images.isNotEmpty) {
                                  provider.addVariantImages(idx, images);
                                }
                              },
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedImage02,
                                color: colorScheme.textTertiary,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                v.existingImageUrls.isEmpty &&
                                        v.variantImages.isEmpty
                                    ? getTranslatedValue(
                                        context, uploadVariantImageLabel)
                                    : 'Add More Images',
                                style: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 13),
                  Row(
                    children: [
                      if (idx != 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(color: colorScheme.error),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(19)),
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => _showDeleteVariantConfirmation(
                                context, provider, idx),
                            icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedDelete01,
                                color: colorScheme.error,
                                size: 17),
                            label: Consumer<LanguageProvider>(
                              builder: (context, languageProvider, _) {
                                return Text(
                                    getTranslatedValue(context, removeLabel),
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600));
                              },
                            ),
                          ),
                        ),
                      if (idx != 0) SizedBox(width: 14),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.success,
                            side: BorderSide(color: colorScheme.success),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(19)),
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: provider.addVariant,
                          icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedAdd01,
                              color: colorScheme.success,
                              size: 17),
                          label: Consumer<LanguageProvider>(
                            builder: (context, languageProvider, _) {
                              return Text(
                                  getTranslatedValue(
                                      context, productVariantAddLabel),
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600));
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}

_showStockStatusBottomSheet(
    BuildContext context, VariantInputModel v, FocusNode? focusNode) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslatedValue(context, stockStatusLabel),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        title:
                            Text(getTranslatedValue(context, availableLabel)),
                        onTap: () {
                          v.status.text =
                              getTranslatedValue(context, availableLabel);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title:
                            Text(getTranslatedValue(context, outOfStockLabel)),
                        onTap: () {
                          v.status.text =
                              getTranslatedValue(context, outOfStockLabel);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  ).then((_) {
    // Request focus after bottom sheet closes
    if (focusNode != null) {
      Future.delayed(Duration(milliseconds: 100), () {
        focusNode.requestFocus();
      });
    }
  });
}

_showUnitBottomSheet(
    BuildContext context, VariantInputModel v, FocusNode? focusNode) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: CategorySelectionBottomSheet(
        title: getTranslatedValue(context, selectUnitLabel),
        searchHint: getTranslatedValue(context, searchUnitsLabel),
        fetchData: (search, page) => getAllUnitsRepository(
          search: search,
          page: page,
        ),
        onItemSelected: (item) {
          if (item is Map<String, dynamic>) {
            v.setUnit(
              item['id'],
              item['name'],
              item['short_code'] ?? item['name'],
            );
          }
        },
      ),
    ),
  ).then((_) {
    // Request focus after bottom sheet closes
    if (focusNode != null) {
      Future.delayed(Duration(milliseconds: 100), () {
        focusNode.requestFocus();
      });
    }
  });
}

// --- Custom Radio UI ---
class _RadioCircle extends StatelessWidget {
  final int value, groupValue;
  final void Function(int) onChanged;
  final String label;
  const _RadioCircle(
      {required this.value,
      required this.groupValue,
      required this.onChanged,
      required this.label});
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary, width: 2),
            ),
            child: value == groupValue
                ? Center(
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: colorScheme.primary),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
              color: colorScheme.textPrimary,
              decoration: value == groupValue ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step3ReturnCancel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<ProductStepperProvider>(context);
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          // Is returnable
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 19),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: colorScheme.cardBackground,
                  border: Border.all(color: colorScheme.border),
                  boxShadow: colorScheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslatedValue(context, isReturnableLabel),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: -0.5,
                        height: 1.02,
                        color: colorScheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _RadioCircle(
                          value: 1,
                          groupValue: p.isReturnable,
                          onChanged: (val) => p.setReturnable(val),
                          label: getTranslatedValue(context, yesLabel),
                        ),
                        const SizedBox(width: 16),
                        _RadioCircle(
                          value: 0,
                          groupValue: p.isReturnable,
                          onChanged: (val) => p.setReturnable(val),
                          label: getTranslatedValue(context, noLabel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Visibility(
                      visible: p.isReturnable == 1,
                      child: CustomTextFormField(
                        title: getTranslatedValue(context, returnDaysLabel),
                        hintText:
                            getTranslatedValue(context, returnDaysHintLabel),
                        controller: p.returnDays,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Is cancelled
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: colorScheme.cardBackground,
                  border: Border.all(color: colorScheme.border),
                  boxShadow: colorScheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslatedValue(context, isCancelableLabel),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: -0.5,
                        height: 1.02,
                        color: colorScheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _RadioCircle(
                          value: 1,
                          groupValue: p.isCancellable,
                          onChanged: (val) {
                            p.setCancellable(val);
                            if (val == 1) {
                              p.fetchCancelableStatuses(context);
                            }
                          },
                          label: getTranslatedValue(context, yesLabel),
                        ),
                        SizedBox(width: 16),
                        _RadioCircle(
                          value: 0,
                          groupValue: p.isCancellable,
                          onChanged: (val) => p.setCancellable(val),
                          label: getTranslatedValue(context, noLabel),
                        ),
                      ],
                    ),
                    SizedBox(height: 13),
                    Visibility(
                      visible: p.isCancellable == 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getTranslatedValue(context, tillWhichStatusLabel),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 50,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Builder(
                              builder: (context) {
                                return p.isLoadingCancelableStatuses
                                    ? Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ),
                                      )
                                    : DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          padding: EdgeInsets.symmetric(horizontal: 12),
                                          hint: Text(
                                            'Select',
                                            style: TextStyle(
                                              color: Colors.grey[300],
                                              fontSize: 14,
                                            ),
                                          ),
                                          value: p.getValidCancelDaysValue(),
                                          items: p.cancelableStatuses.map((status) {
                                            return DropdownMenuItem<String>(
                                              value: status['id'].toString(),
                                              child: Text(
                                                status['status'].toString(),
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            if (newValue != null) {
                                              p.setCancelDays(newValue);
                                            }
                                          },
                                        ),
                                      );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 6),
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return CustomTextFormField(
                title: getTranslatedValue(context, totalAllowedQuantityLabel),
                hintText:
                    getTranslatedValue(context, enterTotalAllowedQuantityLabel),
                controller: p.totalAllowedQuantity,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ShimmerNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double height;
  final double width;

  const _ShimmerNetworkImage({
    Key? key,
    required this.imageUrl,
    required this.height,
    required this.width,
  }) : super(key: key);

  @override
  State<_ShimmerNetworkImage> createState() => _ShimmerNetworkImageState();
}

class _ShimmerNetworkImageState extends State<_ShimmerNetworkImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _loaded = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Shimmer placeholder
          if (!_loaded)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.grey.shade300,
                        Colors.grey.shade100,
                        Colors.grey.shade300,
                      ],
                      stops: [
                        0.0,
                        (_animation.value + 2) / 4,
                        1.0,
                      ],
                    ),
                  ),
                );
              },
            ),
          // Actual image
          Image.network(
            widget.imageUrl,
            height: widget.height,
            width: widget.width,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                if (!_loaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _loaded = true);
                  });
                }
                return child;
              }
              return const SizedBox.shrink();
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.broken_image, color: Colors.grey, size: 24),
              );
            },
          ),
        ],
      ),
    );
  }
}
