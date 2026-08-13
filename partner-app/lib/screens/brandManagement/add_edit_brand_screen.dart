import 'package:flutter/material.dart';
import 'package:project/helper/utils/custom_text_form_field.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/image_picker_bottom_sheet.dart';
import 'package:project/helper/widgets/universal_scaffold.dart';
import 'package:project/models/brand.dart';
import 'package:project/models/category_selection_models.dart';
import 'package:project/repositories/brandApi.dart';

class AddEditBrandScreen extends StatefulWidget {
  final BrandData? brand;

  const AddEditBrandScreen({Key? key, this.brand}) : super(key: key);

  @override
  State<AddEditBrandScreen> createState() => _AddEditBrandScreenState();
}

class _AddEditBrandScreenState extends State<AddEditBrandScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  File? _imageFile;
  String? _existingImageUrl;
  int _status = 1; // 1 = Active, 0 = Inactive
  List<CategoryItem> _selectedCategories = [];
  bool _isLoading = false;

  // Category search and pagination
  List<CategoryItem> _allCategories = [];
  List<CategoryItem> _filteredCategories = [];
  bool _isLoadingCategories = false;
  bool _hasMoreCategories = true;
  int _currentPage = 1;
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.brand != null) {
      _nameController.text = widget.brand!.name ?? '';
      _existingImageUrl = widget.brand!.imageUrl;
      _status = int.tryParse(widget.brand!.status ?? '1') ?? 1;

      // Convert BrandCategory to CategoryItem
      if (widget.brand!.categories != null) {
        _selectedCategories = widget.brand!.categories!
            .map((cat) => CategoryItem(
                  id: cat.id ?? 0,
                  name: cat.name ?? '',
                ))
            .toList();
      }
    }
    _loadCategories();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreCategories();
    }
  }

  Future<void> _loadCategories({bool refresh = false}) async {
    if (_isLoadingCategories) return;

    if (refresh) {
      _currentPage = 1;
      _allCategories.clear();
      _hasMoreCategories = true;
    }

    setState(() {
      _isLoadingCategories = true;
    });

    // try {
    // Build params map
    final Map<String, String> params = {};

    // Add page parameter
    params['page'] = _currentPage.toString();

    // Add search parameter if provided
    if (_searchQuery.isNotEmpty) {
      params['search'] = _searchQuery;
    }
    final response = await getSellerCategoriesApi(
      params: params,
    );

    if (response['status'] == 1 && response['data'] != null) {
      final List<dynamic> data = response['data']['data'] ?? [];

      setState(() {
        if (refresh || _currentPage == 1) {
          _allCategories =
              data.map((json) => CategoryItem.fromJson(json)).toList();
        } else {
          _allCategories
              .addAll(data.map((json) => CategoryItem.fromJson(json)).toList());
        }

        final currentPage = int.parse(response['data']['current_page'] ?? "1");
        final lastPage = response['data']['last_page'];
        _hasMoreCategories = currentPage < lastPage;

        if (_hasMoreCategories) {
          _currentPage++;
        }

        _filterCategories();
        _isLoadingCategories = false;
      });
    } else {
      setState(() {
        _isLoadingCategories = false;
      });
    }
    // } catch (e) {
    //   setState(() {
    //     _isLoadingCategories = false;
    //   });
    //   if (mounted) {
    //     showMessage(context, 'Error loading categories: $e', MessageType.error);
    //   }
    // }
  }

  void _loadMoreCategories() {
    if (_hasMoreCategories && !_isLoadingCategories) {
      _loadCategories();
    }
  }

  void _filterCategories() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredCategories = _allCategories;
      } else {
        _filteredCategories = _allCategories
            .where((cat) =>
                cat.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _loadCategories(refresh: true);
    });
  }

  Future<void> _pickImage() async {
    ImagePickerBottomSheet.show(
      context,
      allowMultiple: false,
      title: 'Select Brand Image',
      onImagesPicked: (images) {
        if (images.isNotEmpty) {
          setState(() {
            _imageFile = images.first;
            _existingImageUrl = null;
          });
        }
      },
    );
  }

  void _toggleCategorySelection(CategoryItem category) {
    setState(() {
      final index =
          _selectedCategories.indexWhere((cat) => cat.id == category.id);
      if (index >= 0) {
        _selectedCategories.removeAt(index);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  bool _isCategorySelected(CategoryItem category) {
    return _selectedCategories.any((cat) => cat.id == category.id);
  }

  void _showCategorySelectionBottomSheet() {
    // Reset search
    _searchController.clear();
    _searchQuery = '';
    _filterCategories(); // Re-filter with empty search

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Select Categories",
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                              letterSpacing: -0.55,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(bottomSheetContext),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: CustomTextFormField(
                      title: "",
                      hintText: "Search categories...",
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),

                  // Selected count
                  if (_selectedCategories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${_selectedCategories.length} ${_selectedCategories.length == 1 ? 'category' : 'categories'} selected",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Category List
                  Expanded(
                    child: _isLoadingCategories && _allCategories.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF9AC444),
                            ),
                          )
                        : _filteredCategories.isEmpty
                            ? Center(
                                child: Text(
                                  "No categories found",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _filteredCategories.length +
                                    (_hasMoreCategories ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _filteredCategories.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF9AC444),
                                        ),
                                      ),
                                    );
                                  }

                                  final category = _filteredCategories[index];
                                  final isSelected =
                                      _isCategorySelected(category);

                                  return InkWell(
                                    onTap: () {
                                      _toggleCategorySelection(category);
                                      setModalState(() {});
                                      setState(() {});
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFDCFCE7)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF9AC444)
                                              : const Color(0xFFE5E7EB),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Category Image
                                          if (category.image != null &&
                                              category.image!.isNotEmpty)
                                            Container(
                                              width: 48,
                                              height: 48,
                                              margin: const EdgeInsets.only(
                                                  right: 12),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                color: const Color(0xFFF3F4F6),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  category.image!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 24,
                                                        color:
                                                            Color(0xFFD1D5DB),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              category.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? const Color(0xFF16A34A)
                                                    : const Color(0xFF111827),
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF9AC444),
                                              size: 24,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),

                  // Done Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(bottomSheetContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9AC444),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Done",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveBrand() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      showMessage(context, 'Please enter brand name', MessageType.error);
      return;
    }

    if (_selectedCategories.isEmpty) {
      showMessage(
          context, 'Please select at least one category', MessageType.error);
      return;
    }

    if (_imageFile == null &&
        (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      showMessage(context, 'Please select a brand image', MessageType.error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryIds = _selectedCategories.map((cat) => cat.id).toList();

      final response = await saveBrandApi(
        context: context,
        name: _nameController.text.trim(),
        status: _status.toString(),
        categoryIds: categoryIds,
        imageFile: _imageFile,
        brandId: widget.brand?.id,
      );

      setState(() {
        _isLoading = false;
      });

      if (response['status'].toString() == '1' || response['success'] == true) {
        if (mounted) {
          showMessage(
            context,
            response['message'] ??
                (widget.brand == null
                    ? 'Brand created successfully'
                    : 'Brand updated successfully'),
            MessageType.success,
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          showMessage(
            context,
            response['message'] ?? 'Failed to save brand',
            MessageType.error,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showMessage(context, 'Error: $e', MessageType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return UniversalScaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB9E990), Color(0xFFFFFFFF)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 22,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.brand == null ? "Add Brand" : "Edit Brand",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 21,
                            color: Colors.black,
                            letterSpacing: -0.55,
                            height: 1.02,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Upload
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 9),
                        padding: const EdgeInsets.symmetric(vertical: 25),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6F7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: _imageFile == null &&
                                (_existingImageUrl == null ||
                                    _existingImageUrl!.isEmpty)
                            ? Column(
                                children: [
                                  const Icon(Icons.branding_watermark_outlined,
                                      color: Color(0xFFB9B9B9), size: 33),
                                  const SizedBox(height: 7),
                                  Text(
                                    "Upload Brand Image*",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFB9B9B9),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text("PNG/JPG",
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFFB9B9B9))),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _imageFile != null
                                    ? Image.file(
                                        _imageFile!,
                                        width: 95,
                                        height: 95,
                                        fit: BoxFit.contain,
                                      )
                                    : Image.network(
                                        _existingImageUrl!,
                                        width: 95,
                                        height: 95,
                                        fit: BoxFit.contain,
                                      ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Brand Name
                  CustomTextFormField(
                    title: "Brand Name",
                    hintText: "Enter Brand Name",
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  // Status Selection
                  Text(
                    "Status",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _status = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _status == 1
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _status == 1
                                    ? const Color(0xFF9AC444)
                                    : const Color(0xFFE5E7EB),
                                width: _status == 1 ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_status == 1)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF9AC444),
                                    size: 20,
                                  ),
                                if (_status == 1) const SizedBox(width: 8),
                                Text(
                                  "Active",
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: _status == 1
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: _status == 1
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _status = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _status == 0
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _status == 0
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFE5E7EB),
                                width: _status == 0 ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_status == 0)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFEF4444),
                                    size: 20,
                                  ),
                                if (_status == 0) const SizedBox(width: 8),
                                Text(
                                  "Inactive",
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: _status == 0
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: _status == 0
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Categories Selection
                  Text(
                    "Categories",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showCategorySelectionBottomSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedCategories.isEmpty
                                  ? "Select Categories"
                                  : "${_selectedCategories.length} ${_selectedCategories.length == 1 ? 'category' : 'categories'} selected",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: _selectedCategories.isEmpty
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF111827),
                                fontWeight: _selectedCategories.isEmpty
                                    ? FontWeight.w400
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Selected Categories Display
                  if (_selectedCategories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedCategories.map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF9AC444)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                category.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategories.remove(category);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF9AC444),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
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
                  ],
                ],
              ),
            ),
          ),

          // Save Button
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBrand,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9AC444),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  disabledBackgroundColor:
                      const Color(0xFF9AC444).withValues(alpha: 0.6),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.brand == null ? "Create Brand" : "Update Brand",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
