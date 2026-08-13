import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/models/wrongItemReportModel.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/screens/reportsScreen/my_reports_screen.dart';

class SelectWrongItemsScreen extends StatefulWidget {
  final String orderId;
  final Set<String> selectedOptions;
  final String issueType;

  const SelectWrongItemsScreen({
    super.key,
    required this.orderId,
    required this.selectedOptions,
    required this.issueType,
  });

  @override
  State<SelectWrongItemsScreen> createState() =>
      _SelectWrongItemsScreenState();
}

class _SelectWrongItemsScreenState extends State<SelectWrongItemsScreen> {
  bool isLoading = true;
  WrongItemReportModel? reportData;
  Map<String, List<XFile>> selectedImages = {};
  Map<String, TextEditingController> descriptionControllers = {};
  final ImagePicker _imagePicker = ImagePicker();
  bool requestRefund = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchStoreList();
  }

  @override
  void dispose() {
    for (var controller in descriptionControllers.values) {
      controller.dispose();
    }
    super.dispose();
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

  Future<void> _fetchStoreList() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Build request params based on previous selections
      Map<String, dynamic> params = {
        'order_id': widget.orderId,
      };

      // Add combo and zenfoo based on selections
      bool hasCombo = widget.selectedOptions.contains('combos');
      bool hasZenfoo = widget.selectedOptions.contains('zenfoo');

      if (hasCombo) params['combo'] = 'true';
      if (hasZenfoo) params['zenfoo'] = 'true';

      // Check for vendor selections
      List<int> vendorIds = [];
      for (var option in widget.selectedOptions) {
        if (option.startsWith('vendor_')) {
          int? vendorId = int.tryParse(option.replaceFirst('vendor_', ''));
          if (vendorId != null) {
            vendorIds.add(vendorId);
          }
        }
      }

      // Add vendor_id parameter if we have vendors
      if (vendorIds.isNotEmpty) {
        params['vendor_id'] = vendorIds.join(',');
      }

      // If we have vendors but no combos/zenfoo, set both to false
      if (vendorIds.isNotEmpty && !hasCombo && !hasZenfoo) {
        params['combo'] = 'false';
        params['zenfoo'] = 'false';
      }

      log('Fetching wrong item store list with params: ${json.encode(params)}');

      final response = await sendApiRequest(
        apiName: 'wrong_item_report/store_list',
        params: params,
        isPost: false,
        context: context,
      );

      final data = json.decode(response);

      log('Wrong item store list API Response: ${json.encode(data)}');

      if (data['status'] == 1) {
        setState(() {
          reportData = WrongItemReportModel.fromJson(data['data']);
          isLoading = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to load store list');
      }
    } catch (e) {
      log('Error fetching store list: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        showMessage(
          context,
          'Failed to load store list: $e',
          MessageType.error,
        );
      }
    }
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
    if (isSubmitting) return;

    // Validate that at least one store or combo has images or description
    bool hasData = false;

    if (reportData != null) {
      for (var store in reportData!.storeList) {
        final storeKey = 'store_${store.storeId}';
        if (selectedImages.containsKey(storeKey) ||
            (descriptionControllers[storeKey]?.text.isNotEmpty ?? false)) {
          hasData = true;
          break;
        }
      }

      if (!hasData) {
        for (var combo in reportData!.comboList) {
          final comboKey = 'combo_${combo.comboId}';
          if (selectedImages.containsKey(comboKey) ||
              (descriptionControllers[comboKey]?.text.isNotEmpty ?? false)) {
            hasData = true;
            break;
          }
        }
      }
    }

    if (!hasData) {
      showMessage(
        context,
        'Please add images or description for at least one item',
        MessageType.warning,
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Build the multipart request params
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

      // Add normal store items
      if (reportData != null && reportData!.storeList.isNotEmpty) {
        for (var store in reportData!.storeList) {
          final storeKey = 'store_${store.storeId}';
          final description = descriptionControllers[storeKey]?.text ?? '';
          final images = _getImages(storeKey);

          if (images.isNotEmpty || description.isNotEmpty) {
            // Add store_id and description
            params['normal_items[$normalItemIndex][store_id]'] = store.storeId.toString();
            params['normal_items[$normalItemIndex][description]'] = description;
            
            // Add empty product_ids array as required by API
            // Note: Wrong items screen reports entire store issues, not specific products
            // So we send an empty array to satisfy API structure
            params['normal_items[$normalItemIndex][product_ids][]'] = '';

            // Add images for this store
            for (int i = 0; i < images.length; i++) {
              fileParamsNames.add('normal_items[$normalItemIndex][images][]');
              fileParamsFilesPath.add(images[i].path);
            }

            normalItemIndex++;
          }
        }
      }

      // Add combo items
      if (reportData != null && reportData!.comboList.isNotEmpty) {
        for (var combo in reportData!.comboList) {
          final comboKey = 'combo_${combo.comboId}';
          final description = descriptionControllers[comboKey]?.text ?? '';
          final images = _getImages(comboKey);

          if (images.isNotEmpty || description.isNotEmpty) {
            // Add combo_id and description
            params['combo_items[$comboItemIndex][combo_id]'] = combo.comboId.toString();
            params['combo_items[$comboItemIndex][description]'] = description;
            
            // Add empty product_ids array as required by API
            // Note: Wrong items screen reports entire combo issues, not specific products
            // So we send an empty array to satisfy API structure
            params['combo_items[$comboItemIndex][product_ids][]'] = '';

            // Add images for this combo
            for (int i = 0; i < images.length; i++) {
              fileParamsNames.add('combo_items[$comboItemIndex][images][]');
              fileParamsFilesPath.add(images[i].path);
            }

            comboItemIndex++;
          }
        }
      }

      log('Submitting wrong item report with params: ${json.encode(params)}');
      log('File params count: ${fileParamsNames.length}');

      final response = await sendApiMultiPartRequest(
        apiName: 'wrong_item_report/store',
        params: params,
        fileParamsNames: fileParamsNames,
        fileParamsFilesPath: fileParamsFilesPath,
        context: context,
      );

      final data = json.decode(response);

      if (data['status'] == 1) {
        showMessage(
          context,
          'Wrong item report submitted successfully!',
          MessageType.success,
        );

        // Navigate to MyReportsScreen after removing last 4 pages
        if (mounted) {
          int popCount = 0;
          Navigator.of(context).popUntil((route) {
            if (popCount >= 4) {
              return true;
            }
            popCount++;
            return false;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyReportsScreen(),
            ),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to submit report');
      }
    } catch (e) {
      log('Error submitting wrong item report: $e');
      
      String errorMessage = 'Failed to submit report';
      
      // Check if it's a 404 error (endpoint doesn't exist)
      if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        errorMessage = 'Issue reporting feature is currently unavailable. Please contact customer support directly.';
      } else if (e.toString().contains('FormatException') && e.toString().contains('<!DOCTYPE html>')) {
        errorMessage = 'Server error: Issue reporting endpoint not found. Please contact support.';
      } else {
        errorMessage = 'Failed to submit report: $e';
      }
      
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
        showMessage(
          context,
          errorMessage,
          MessageType.error,
        );
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
                title: 'Report Wrong Items',
                showBackButton: true,
              ),
              Expanded(
                child: isLoading
                    ? _buildLoadingState(colorScheme)
                    : reportData == null
                        ? _buildErrorState(colorScheme)
                        : _buildReportForm(colorScheme),
              ),
            ],
          ),
          bottomNavigationBar: isLoading || reportData == null
              ? null
              : _buildBottomSubmitButton(colorScheme),
        );
      },
    );
  }

  Widget _buildLoadingState(AppColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions shimmer
          _buildShimmerCard(
            colorScheme: colorScheme,
            height: 60,
            borderRadius: 12,
          ),
          const SizedBox(height: 20),

          // Store/Combo section shimmers (3 cards)
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildShimmerStoreCard(colorScheme),
          )),
        ],
      ),
    );
  }

  Widget _buildShimmerCard({
    required AppColorScheme colorScheme,
    required double height,
    double? width,
    double borderRadius = 16,
  }) {
    return Shimmer.fromColors(
      baseColor: colorScheme.shimmerBase,
      highlightColor: colorScheme.shimmerHighlight,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget _buildShimmerStoreCard(AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store name shimmer
          _buildShimmerCard(
            colorScheme: colorScheme,
            height: 20,
            width: 150,
            borderRadius: 8,
          ),
          const SizedBox(height: 20),

          // Images label shimmer
          _buildShimmerCard(
            colorScheme: colorScheme,
            height: 16,
            width: 80,
            borderRadius: 6,
          ),
          const SizedBox(height: 12),

          // Image container shimmer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.border),
            ),
            child: Row(
              children: [
                // Add button shimmer
                _buildShimmerCard(
                  colorScheme: colorScheme,
                  height: 90,
                  width: 90,
                  borderRadius: 12,
                ),
                const SizedBox(width: 12),
                // Second placeholder shimmer
                _buildShimmerCard(
                  colorScheme: colorScheme,
                  height: 90,
                  width: 90,
                  borderRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Description label shimmer
          _buildShimmerCard(
            colorScheme: colorScheme,
            height: 16,
            width: 100,
            borderRadius: 6,
          ),
          const SizedBox(height: 10),

          // Description field shimmer
          _buildShimmerCard(
            colorScheme: colorScheme,
            height: 120,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppColorScheme colorScheme) {
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
            'Failed to load store list',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
              letterSpacing: -0.55,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchStoreList,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportForm(AppColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          _buildInstructions(colorScheme),
          const SizedBox(height: 20),

          // Store sections
          if (reportData != null && reportData!.storeList.isNotEmpty) ...[
            ...reportData!.storeList.map(
              (store) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildStoreSection(store, colorScheme),
              ),
            ),
          ],

          // Combo sections
          if (reportData != null && reportData!.comboList.isNotEmpty) ...[
            ...reportData!.comboList.map(
              (combo) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildComboSection(combo, colorScheme),
              ),
            ),
          ],

          // Request Refund checkbox
          _buildRefundCheckbox(colorScheme),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInstructions(AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 22,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Upload images and describe what was wrong for each item',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.textPrimary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreSection(WrongItemStore store, AppColorScheme colorScheme) {
    final storeKey = 'store_${store.storeId}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
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
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colorScheme.textPrimary,
              letterSpacing: -0.55,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 20),

          // Images section
          _buildImageSection(storeKey, colorScheme),

          const SizedBox(height: 20),

          // Description field
          _buildDescriptionField(
            storeKey,
            'Describe what was wrong with items from ${store.storeName}',
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildComboSection(WrongItemCombo combo, AppColorScheme colorScheme) {
    final comboKey = 'combo_${combo.comboId}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Combo name with badge
          Row(
            children: [
              Expanded(
                child: Text(
                  combo.comboName,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.55,
                    height: 1.02,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Combo',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                    letterSpacing: -0.55,
                    height: 1.02,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Images section
          _buildImageSection(comboKey, colorScheme),

          const SizedBox(height: 20),

          // Description field
          _buildDescriptionField(
            comboKey,
            'Describe what was wrong with ${combo.comboName}',
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(String key, AppColorScheme colorScheme) {
    final images = _getImages(key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Images',
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
              _buildAddImageButton(key, colorScheme),

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
                color: colorScheme.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton(String key, AppColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => _pickImages(key),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 6),
            Text(
              'Add',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(
    String key,
    String hintText,
    AppColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.textSecondary,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _getDescriptionController(key),
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: colorScheme.inputPlaceholder,
              letterSpacing: -0.55,
              height: 1.02,
            ),
            filled: true,
            fillColor: colorScheme.inputBackground,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.inputBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.inputBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: colorScheme.textPrimary,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
      ],
    );
  }

  Widget _buildRefundCheckbox(AppColorScheme colorScheme) {
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
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
              'Request Refund',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.textPrimary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSubmitButton(AppColorScheme colorScheme) {
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
          onPressed: isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.6),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Submitting...',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Submit Report',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.55,
                    height: 1.02,
                  ),
                ),
        ),
      ),
    );
  }
}
