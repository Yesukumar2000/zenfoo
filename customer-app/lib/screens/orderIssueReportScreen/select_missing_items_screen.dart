import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/models/orderIssueItemsModel.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/screens/reportsScreen/my_reports_screen.dart';

class SelectMissingItemsScreen extends StatefulWidget {
  final String orderId;
  final Set<String> selectedOptions;
  final String issueType;

  const SelectMissingItemsScreen({
    super.key,
    required this.orderId,
    required this.selectedOptions,
    required this.issueType,
  });

  @override
  State<SelectMissingItemsScreen> createState() =>
      _SelectMissingItemsScreenState();
}

class _SelectMissingItemsScreenState extends State<SelectMissingItemsScreen> {
  bool isLoading = true;
  bool isSubmitting = false;
  OrderIssueItemsModel? orderData;
  Set<int> selectedItems = {};
  bool requestRefund = false;
  Map<String, TextEditingController> descriptionControllers = {};
  Map<String, List<XFile>> selectedImages = {};
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchOrderItems();
  }

  @override
  void dispose() {
    for (var controller in descriptionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getTitleByIssueType(BuildContext context) {
    switch (widget.issueType) {
      case 'item_missing':
        return getTranslatedValue(context, selectMissingItemsLabel);
      case 'wrong_order':
        return getTranslatedValue(context, selectWrongItemsLabel);
      default:
        return getTranslatedValue(context, selectMissingItemsLabel);
    }
  }

  TextEditingController _getDescriptionController(String key) {
    if (!descriptionControllers.containsKey(key)) {
      descriptionControllers[key] = TextEditingController();
    }
    return descriptionControllers[key]!;
  }

  List<XFile> _getImages(String key) {
    return selectedImages[key] ?? [];
  }

  Future<void> _pickImages(String key) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          if (!selectedImages.containsKey(key)) {
            selectedImages[key] = [];
          }
          selectedImages[key]!.addAll(images);
        });
      }
    } catch (e) {
      log('Error picking images: $e');
      if (mounted) {
        showMessage(
          context,
          'Failed to pick images: $e',
          MessageType.error,
        );
      }
    }
  }

  void _removeImage(String key, int index) {
    setState(() {
      if (selectedImages.containsKey(key) &&
          index >= 0 &&
          index < selectedImages[key]!.length) {
        selectedImages[key]!.removeAt(index);
        if (selectedImages[key]!.isEmpty) {
          selectedImages.remove(key);
        }
      }
    });
  }

  Future<void> _fetchOrderItems() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Build request params based on previous selections
      Map<String, dynamic> params = {
        'order_id': widget.orderId,
      };

      // Add combo, zenfoo, or vendor_ids based on selections
      bool hasCombo = widget.selectedOptions.contains('combos');
      bool hasZenfoo = widget.selectedOptions.contains('zenfoo');
      List<int> vendorIds = [];

      for (var option in widget.selectedOptions) {
        if (option.startsWith('vendor_')) {
          int? vendorId = int.tryParse(option.replaceFirst('vendor_', ''));
          if (vendorId != null) {
            vendorIds.add(vendorId);
          }
        }
      }

      if (hasCombo) params['combo'] = true;
      if (hasZenfoo) params['zenfoo'] = true;
      if (vendorIds.isNotEmpty) params['vendor_ids'] = vendorIds.join(',');

      log('Fetching order items with params: ${json.encode(params)}');

      final response = await sendApiRequest(
        apiName: 'issue_report/order_item_details',
        params: params,
        isPost: true,
        context: context,
      );

      final data = json.decode(response);

      log('Order items API Response: ${json.encode(data)}');

      if (data['status'] == 1) {
        setState(() {
          orderData = OrderIssueItemsModel.fromJson(data['message']);
          isLoading = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to load order items');
      }
    } catch (e) {
      log('Error fetching order items: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        showMessage(
          context,
          'Failed to load order items: $e',
          MessageType.error,
        );
      }
    }
  }

  /// Returns true if the item can be selected (for return type, checks return availability)
  bool _isItemSelectable(OrderProduct item) {
    if (widget.issueType == 'return') {
      return item.isStillReturnAvailable;
    }
    return true;
  }

  void _handleItemSelect(int itemId) {
    setState(() {
      if (selectedItems.contains(itemId)) {
        selectedItems.remove(itemId);
      } else {
        selectedItems.add(itemId);
      }
    });

    log('Selected items: ${selectedItems.join(", ")}');
  }

  void _handleSelectAll() {
    setState(() {
      if (selectedItems.length == _getTotalItemsCount()) {
        // All selected, deselect all
        selectedItems.clear();
      } else {
        // Select all
        selectedItems = _getAllItemIds().toSet();
      }
    });
  }

  List<int> _getAllItemIds() {
    List<int> allIds = [];

    if (orderData == null) return allIds;

    // Add store items (only selectable ones)
    for (var store in orderData!.storeWiseItems) {
      for (var item in store.items) {
        if (_isItemSelectable(item)) {
          allIds.add(item.productId);
        }
      }
    }

    // Add combo products (not the combo itself, but individual products within combos)
    for (var combo in orderData!.comboItems) {
      for (var product in combo.products) {
        if (_isItemSelectable(product)) {
          allIds.add(product.productId);
        }
      }
    }

    return allIds;
  }

  int _getTotalItemsCount() {
    return _getAllItemIds().length;
  }

  String _mapIssueTypeToApiValue(String issueType) {
    switch (issueType) {
      case 'item_missing':
        return 'missing';
      case 'wrong_order':
        return 'wrong';
      default:
        return issueType;
    }
  }

  Future<void> _handleSubmit() async {
    if (selectedItems.isEmpty) {
      showMessage(
        context,
        'Please select at least one item',
        MessageType.warning,
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Build request params for multipart upload
      Map<String, String> params = {
        'order_id': widget.orderId,
        'type': _mapIssueTypeToApiValue(widget.issueType),
        'description': widget.issueType,
        'is_refund_requested': requestRefund.toString(),
      };

      // Prepare files for multipart upload
      List<String> fileParamsNames = [];
      List<String> fileParamsFilesPath = [];

      int normalItemIndex = 0;
      int comboItemIndex = 0;

      // Add normal store items with images
      if (orderData != null && orderData!.storeWiseItems.isNotEmpty) {
        for (var store in orderData!.storeWiseItems) {
          // Get selected product IDs for this store
          List<int> storeProductIds = store.items
              .where((item) => selectedItems.contains(item.productId))
              .map((item) => item.productId)
              .toList();

          if (storeProductIds.isNotEmpty) {
            final storeKey = 'store_${store.storeId}';
            final description = descriptionControllers[storeKey]?.text ?? '';
            final images = _getImages(storeKey);

            // Add store info and product IDs
            params['normal_items[$normalItemIndex][store_id]'] =
                store.storeId.toString();
            
            // Add product IDs as individual array elements
            for (int i = 0; i < storeProductIds.length; i++) {
              params['normal_items[$normalItemIndex][product_ids][$i]'] =
                  storeProductIds[i].toString();
            }
            
            params['normal_items[$normalItemIndex][description]'] = description;

            // Add images for this store. Backend keys store images by
            // store_id: normal_items_images[store_id][]
            for (int i = 0; i < images.length; i++) {
              fileParamsNames.add('normal_items_images[${store.storeId}][]');
              fileParamsFilesPath.add(images[i].path);
            }

            normalItemIndex++;
          }
        }
      }

      // Add combo items with images
      if (orderData != null && orderData!.comboItems.isNotEmpty) {
        for (var combo in orderData!.comboItems) {
          // Get selected product IDs for this combo
          List<int> comboProductIds = combo.products
              .where((product) => selectedItems.contains(product.productId))
              .map((product) => product.productId)
              .toList();

          if (comboProductIds.isNotEmpty) {
            final comboKey = 'combo_${combo.id}';
            final description = descriptionControllers[comboKey]?.text ?? '';
            final images = _getImages(comboKey);

            // Add combo info and product IDs
            params['combo_items[$comboItemIndex][combo_id]'] =
                combo.id.toString();
            
            // Add product IDs as individual array elements
            for (int i = 0; i < comboProductIds.length; i++) {
              params['combo_items[$comboItemIndex][product_ids][$i]'] =
                  comboProductIds[i].toString();
            }
            
            params['combo_items[$comboItemIndex][description]'] = description;

            // Add images for this combo. Backend keys combo images by
            // combo_id: combo_items_images[combo_id][]
            for (int i = 0; i < images.length; i++) {
              fileParamsNames.add('combo_items_images[${combo.id}][]');
              fileParamsFilesPath.add(images[i].path);
            }

            comboItemIndex++;
          }
        }
      }

      log('Submitting issue report with params: ${json.encode(params)}');
      log('File params count: ${fileParamsNames.length}');

      final response = await sendApiMultiPartRequest(
        apiName: 'issue_report/store',
        params: params,
        fileParamsNames: fileParamsNames,
        fileParamsFilesPath: fileParamsFilesPath,
        context: context,
      );

      final data = json.decode(response);

      if (data['status'] == 1) {
        showMessage(
          context,
          'Issue reported successfully!',
          MessageType.success,
        );

        // Navigate to MyReportsScreen after removing last 4 pages
        if (mounted) {
          // Remove 4 pages: OrderIssueReportScreen, SelectIssueTypeScreen, SelectMissingItemsScreen, and previous screen
          int popCount = 0;
          Navigator.of(context).popUntil((route) {
            if (popCount >= 4) {
              return true;
            }
            popCount++;
            return false;
          });

          // Navigate to MyReportsScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyReportsScreen(),
            ),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to submit issue report');
      }
    } catch (e) {
      log('Error submitting issue report: $e');
      
      String errorMessage = 'Failed to submit issue report';
      
      // Check if it's a 404 error (endpoint doesn't exist)
      if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        errorMessage = 'Issue reporting feature is currently unavailable. Please contact customer support directly.';
      } else if (e.toString().contains('FormatException') && e.toString().contains('<!DOCTYPE html>')) {
        errorMessage = 'Server error: Issue reporting endpoint not found. Please contact support.';
      } else {
        errorMessage = 'Failed to submit issue report: $e';
      }
      
      if (mounted) {
        showMessage(
          context,
          errorMessage,
          MessageType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return Scaffold(
          backgroundColor: colorScheme.background,
          body: Column(
            children: [
              AppHeader(
                label: 'Order #${widget.orderId}',
                title: _getTitleByIssueType(context),
                showBackButton: true,
              ),
              Expanded(
                child: isLoading
                    ? _buildLoadingState(colorScheme)
                    : orderData == null
                        ? _buildErrorState(context, colorScheme)
                        : _buildItemsList(context, colorScheme),
              ),
            ],
          ),
          bottomNavigationBar: isLoading || orderData == null
              ? null
              : _buildBottomSubmitButton(context, colorScheme),
        );
      },
    );
  }

  Widget _buildLoadingState(AppColorScheme colorScheme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _ShimmerItemCard(colorScheme: colorScheme),
    );
  }

  Widget _buildErrorState(BuildContext context, AppColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            getTranslatedValue(context, failedLoadItemsLabel),
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
              letterSpacing: -0.55,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchOrderItems,
            child: Text(getTranslatedValue(context, retryLabel)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, AppColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Select All
          _buildHeader(context, colorScheme),
          const SizedBox(height: 20),

          // Store-wise items
          if (orderData != null && orderData!.storeWiseItems.isNotEmpty) ...[
            ...orderData!.storeWiseItems.map(
              (store) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildStoreSection(context, store, colorScheme),
              ),
            ),
          ],

          // Combo items
          if (orderData != null && orderData!.comboItems.isNotEmpty) ...[
            ...orderData!.comboItems.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildComboSection(
                        context, entry.value, entry.key, colorScheme),
                  ),
                ),
          ],

          const SizedBox(height: 20),

          // Request Refund checkbox
          _buildRefundCheckbox(context, colorScheme),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getTitleByIssueType(context),
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colorScheme.textPrimary,
              letterSpacing: -0.55,
              height: 1.4,
            ),
          ),
          TextButton(
            onPressed: _handleSelectAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              selectedItems.length == _getTotalItemsCount()
                  ? getTranslatedValue(context, deselectAllLabel)
                  : getTranslatedValue(context, selectAllLabel),
              style: GoogleFonts.inter(
                color: colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.55,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreSection(
      BuildContext context, StoreWiseItems store, AppColorScheme colorScheme) {
    final storeKey = 'store_${store.storeId}';
    final hasSelectedItems =
        store.items.any((item) => selectedItems.contains(item.productId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store name
          Text(
            store.storeName,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.textSecondary,
              letterSpacing: -0.55,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Items list
          ...store.items.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key < store.items.length - 1 ? 12 : 0,
                  ),
                  child: _buildItemRow(
                    entry.value,
                    colorScheme,
                  ),
                ),
              ),

          // Description field for this store (only show if items are selected)
          if (hasSelectedItems) ...[
            const SizedBox(height: 16),
            _buildDescriptionField(
              context,
              storeKey,
              'Describe issue for ${store.storeName}',
              colorScheme,
            ),
            const SizedBox(height: 16),
            // Image section for this store
            _buildImageSection(context, storeKey, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildComboSection(BuildContext context, ComboItem combo, int index,
      AppColorScheme colorScheme) {
    final comboKey = 'combo_${combo.id}';
    final hasSelectedItems = combo.products
        .any((product) => selectedItems.contains(product.productId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Combo header
          _buildComboItemRow(combo, colorScheme),

          // Description field for this combo (only show if items are selected)
          if (hasSelectedItems) ...[
            const SizedBox(height: 16),
            _buildDescriptionField(
              context,
              comboKey,
              'Describe issue for ${combo.comboName}',
              colorScheme,
            ),
            const SizedBox(height: 16),
            // Image section for this combo
            _buildImageSection(context, comboKey, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderProduct item, AppColorScheme colorScheme) {
    final isSelected = selectedItems.contains(item.productId);
    final canSelect = _isItemSelectable(item);

    return GestureDetector(
      onTap: canSelect ? () => _handleItemSelect(item.productId) : null,
      child: Opacity(
        opacity: canSelect ? 1.0 : 0.5,
        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.textPrimary,
                      letterSpacing: -0.55,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.variantMeasurement,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colorScheme.textSecondary,
                      letterSpacing: -0.55,
                      height: 1.4,
                    ),
                  ),
                  if (!canSelect) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Not Returnable',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '₹${item.subTotal}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? colorScheme.primary : colorScheme.textPrimary,
                letterSpacing: -0.55,
                height: 1.4,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.borderStrong,
                  width: 2,
                ),
                color: isSelected ? colorScheme.primary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildComboItemRow(ComboItem combo, AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Combo header (non-selectable)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      combo.comboName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.55,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${combo.comboQuantity} combo • ${combo.products.length} items',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colorScheme.textSecondary,
                        letterSpacing: -0.55,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${combo.subTotal.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textPrimary,
                  letterSpacing: -0.55,
                  height: 1.4,
                ),
              ),
            ],
          ),

          // Products list (selectable)
          if (combo.products.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...combo.products.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key < combo.products.length - 1 ? 8 : 0,
                    ),
                    child: _buildComboProductRow(
                      entry.value,
                      colorScheme,
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildComboProductRow(
      OrderProduct product, AppColorScheme colorScheme) {
    final isSelected = selectedItems.contains(product.productId);

    return GestureDetector(
      onTap: () => _handleItemSelect(product.productId),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.textPrimary,
                      letterSpacing: -0.55,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.variantMeasurement,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.textSecondary,
                      letterSpacing: -0.55,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '₹${product.subTotal.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? colorScheme.primary : colorScheme.textPrimary,
                letterSpacing: -0.55,
                height: 1.4,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.borderStrong,
                  width: 2,
                ),
                color: isSelected ? colorScheme.primary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(
    BuildContext context,
    String key,
    String hintText,
    AppColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, descriptionOptionalLabel),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.textSecondary,
            letterSpacing: -0.55,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _getDescriptionController(key),
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: colorScheme.inputPlaceholder,
              letterSpacing: -0.55,
              height: 1.4,
            ),
            filled: true,
            fillColor: colorScheme.inputBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: colorScheme.textPrimary,
            letterSpacing: -0.55,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildRefundCheckbox(
      BuildContext context, AppColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          requestRefund = !requestRefund;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: requestRefund
                      ? colorScheme.primary
                      : colorScheme.borderStrong,
                  width: 2,
                ),
                color: requestRefund ? colorScheme.primary : Colors.transparent,
              ),
              child: requestRefund
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              getTranslatedValue(context, requestRefundLabel),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.textPrimary,
                letterSpacing: -0.55,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSubmitButton(
      BuildContext context, AppColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              (selectedItems.isEmpty || isSubmitting) ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: colorScheme.buttonDisabledBackground,
            disabledForegroundColor: colorScheme.buttonDisabledText,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: isSubmitting
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.buttonPrimaryText,
                    ),
                  ),
                )
              : Text(
                  selectedItems.isEmpty
                      ? getTranslatedValue(context, selectItemsToSubmitLabel)
                      : '${getTranslatedValue(context, submitLabel)} (${selectedItems.length} item${selectedItems.length > 1 ? 's' : ''})',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.55,
                    height: 1.4,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildImageSection(
      BuildContext context, String key, AppColorScheme colorScheme) {
    final images = _getImages(key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              getTranslatedValue(context, 'images'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.textSecondary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${images.length})',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.textTertiary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Optional)',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: colorScheme.textTertiary,
                letterSpacing: -0.55,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Image grid and add button in full width container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.border),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Add image button as first item
              _buildAddImageButton(context, key, colorScheme),

              // Existing images
              ...images.asMap().entries.map((entry) {
                return _buildImageThumbnail(
                  key,
                  entry.value,
                  entry.key,
                  colorScheme,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton(
      BuildContext context, String key, AppColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => _pickImages(key),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
          color: colorScheme.primary.withValues(alpha: 0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(
    String key,
    XFile image,
    int index,
    AppColorScheme colorScheme,
  ) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            image: DecorationImage(
              image: FileImage(File(image.path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(key, index),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade500,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade500.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Shimmer loading widget for item cards
class _ShimmerItemCard extends StatefulWidget {
  final AppColorScheme colorScheme;

  const _ShimmerItemCard({Key? key, required this.colorScheme})
      : super(key: key);

  @override
  State<_ShimmerItemCard> createState() => _ShimmerItemCardState();
}

class _ShimmerItemCardState extends State<_ShimmerItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double? borderRadius,
  }) {
    final shimmerBaseColor = widget.colorScheme.isDark
        ? const Color(0xFF2D3339)
        : const Color(0xFFE0E0E0);
    final shimmerHighlightColor = widget.colorScheme.isDark
        ? const Color(0xFF3C4248)
        : const Color(0xFFF5F5F5);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            shimmerBaseColor,
            shimmerHighlightColor,
            shimmerBaseColor,
          ],
          stops: [
            _animation.value - 0.3,
            _animation.value,
            _animation.value + 0.3,
          ].map((e) => e.clamp(0.0, 1.0)).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.colorScheme.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Left side - text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name shimmer
                    _buildShimmerBox(
                      width: double.infinity,
                      height: 16,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 8),
                    // Variant measurement shimmer
                    _buildShimmerBox(
                      width: 100,
                      height: 14,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Price shimmer
              _buildShimmerBox(
                width: 60,
                height: 16,
                borderRadius: 4,
              ),
              const SizedBox(width: 12),
              // Checkbox shimmer
              _buildShimmerBox(
                width: 22,
                height: 22,
                borderRadius: 6,
              ),
            ],
          ),
        );
      },
    );
  }
}
