import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/models/category_by_admin.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/categoryScreen/admin_category_products_screen.dart';

class AdminManagedCategoriesScreen extends StatefulWidget {
  const AdminManagedCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<AdminManagedCategoriesScreen> createState() =>
      _AdminManagedCategoriesScreenState();
}

class _AdminManagedCategoriesScreenState
    extends State<AdminManagedCategoriesScreen> {
  CategoryByAdmin? _categoryData;
  bool _isLoading = true;
  String _errorMessage = '';

  // Track selected category group
  int? _selectedGroupId;

  // Scroll controller for right panel
  final ScrollController _rightScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _rightScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await getStoreCategoriesApi(context: context);

      if (response != null && response.status == 1) {
        setState(() {
          _categoryData = response;
          _isLoading = false;
          // Auto-select first category if available
          if (_selectedGroupId == null &&
              _categoryData?.data?.categoryGroups != null &&
              _categoryData!.data!.categoryGroups!.isNotEmpty) {
            _selectedGroupId = _categoryData!.data!.categoryGroups![0].id;
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response?.message ?? 'Failed to load categories';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: "Categories",
            title: "Your Product Categories",
            showBackButton: true,
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_categoryData == null ||
        _categoryData!.data == null ||
        _categoryData!.data!.categoryGroups == null ||
        _categoryData!.data!.categoryGroups!.isEmpty) {
      return _buildEmptyState();
    }

    // Two-column layout
    return Row(
      children: [
        // Left sidebar (110px width)
        _buildLeftSidebar(),
        // Divider
        Container(
          width: 1,
          color: colorScheme.border,
        ),
        // Right content area
        Expanded(
          child: _buildRightContent(),
        ),
      ],
    );
  }

  Widget _buildLeftSidebar() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.textPrimary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: _categoryData!.data!.categoryGroups!.length,
        itemBuilder: (context, index) {
          final categoryGroup = _categoryData!.data!.categoryGroups![index];
          final isSelected = _selectedGroupId == categoryGroup.id;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedGroupId = categoryGroup.id;
              });
              // Scroll to top of right panel
              _rightScrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category image with circular container
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: AnimatedSlide(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                offset: isSelected
                                    ? Offset.zero
                                    : const Offset(0, 0.30),
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: (categoryGroup.imageUrl?.isNotEmpty ??
                                          false)
                                      ? setNetworkImg(
                                          image: categoryGroup.imageUrl!,
                                          width: 48,
                                          height: 48,
                                          boxFit: BoxFit.cover,
                                        )
                                      : Icon(
                                          Icons.category_rounded,
                                          size: 24,
                                          color: isSelected
                                              ? colorScheme.textSecondary
                                              : colorScheme.primary,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Category name with animated style
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? colorScheme.textPrimary
                                : colorScheme.textSecondary,
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            height: 1.2,
                            letterSpacing: -0.1,
                          ),
                          child: Text(
                            categoryGroup.name ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gradient indicator bar on the right
                  if (isSelected)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
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

  Widget _buildRightContent() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final selectedGroup = _categoryData!.data!.categoryGroups!
        .firstWhere((g) => g.id == _selectedGroupId);

    return RefreshIndicator(
      onRefresh: _fetchCategories,
      color: colorScheme.primary,
      child: CustomScrollView(
        controller: _rightScrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Section Header
          SliverToBoxAdapter(
            child: _buildSectionHeader(selectedGroup),
          ),

          // Subcategories Grid
          if (selectedGroup.subCategoryGroups != null &&
              selectedGroup.subCategoryGroups!.isNotEmpty)
            _buildSubCategoriesGrid(selectedGroup)
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: colorScheme.textSecondary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No subcategories',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(CategoryGroups selectedGroup) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedGroup.name ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${selectedGroup.subCategoryGroups?.length ?? 0} subcategories',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: selectedGroup.status == 1
                  ? colorScheme.success.withValues(alpha: 0.1)
                  : colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selectedGroup.status == 1
                        ? colorScheme.success
                        : colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  selectedGroup.status == 1 ? "Active" : "Inactive",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selectedGroup.status == 1
                        ? colorScheme.success
                        : colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoriesGrid(CategoryGroups selectedGroup) {
    return SliverPadding(
      padding: const EdgeInsets.all(4),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 0.55,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final subCategory = selectedGroup.subCategoryGroups![index];
            return _buildSubCategoryGridCard(subCategory);
          },
          childCount: selectedGroup.subCategoryGroups!.length,
        ),
      ),
    );
  }

  Widget _buildSubCategoryGridCard(SubCategoryGroups subCategory) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final categoryCount = subCategory.categories?.length ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminCategoryProductsScreen(
              subCategoryGroup: subCategory,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.border),
          boxShadow: [
            BoxShadow(
              color: colorScheme.textPrimary.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image/Icon at top
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: subCategory.imageUrl != null &&
                          subCategory.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: setNetworkImg(
                            image: subCategory.imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            boxFit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.folder_outlined,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                ),
              ),
            ),
            // Content at bottom
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subCategory.name ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$categoryCount ${categoryCount == 1 ? 'item' : 'items'}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.textSecondary,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return RefreshIndicator(
      onRefresh: _fetchCategories,
      color: colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: colorScheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _fetchCategories,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Retry",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildEmptyState() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return RefreshIndicator(
      onRefresh: _fetchCategories,
      color: colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 80,
                  color: colorScheme.textSecondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  "No categories available",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Categories are managed by admin",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorScheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== SHIMMER LOADING STATES ==========

  Widget _buildLoadingShimmer() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Row(
      children: [
        // Left sidebar shimmer
        _buildLeftSidebarShimmer(),
        // Divider
        Container(
          width: 1,
          color: colorScheme.border,
        ),
        // Right content shimmer
        Expanded(
          child: Column(
            children: [
              // Section header shimmer
              _buildSectionHeaderShimmer(),
              // Grid shimmer
              Expanded(
                child: _buildSubcategoryGridShimmer(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeftSidebarShimmer() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.textPrimary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: 6, // Show 6 shimmer items
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category image shimmer
                CustomShimmer(
                  width: 48,
                  height: 48,
                  borderRadius: 24, // Circular
                ),
                const SizedBox(height: 6),
                // Category name shimmer
                CustomShimmer(
                  width: 48,
                  height: 20,
                  borderRadius: 4,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeaderShimmer() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomShimmer(
                  width: 200,
                  height: 28,
                  borderRadius: 4,
                ),
                const SizedBox(height: 6),
                CustomShimmer(
                  width: 120,
                  height: 16,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          // Status badge shimmer
          CustomShimmer(
            width: 80,
            height: 28,
            borderRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryGridShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.55,
      ),
      itemCount: 9, // Show 9 shimmer cards
      itemBuilder: (context, index) {
        return _buildSubcategoryCardShimmer();
      },
    );
  }

  Widget _buildSubcategoryCardShimmer() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.border),
        boxShadow: [
          BoxShadow(
            color: colorScheme.textPrimary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image shimmer at top
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: CustomShimmer(
                  width: 60,
                  height: 60,
                  borderRadius: 8,
                ),
              ),
            ),
          ),
          // Content shimmer at bottom
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomShimmer(
                    width: double.infinity,
                    height: 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 4),
                  CustomShimmer(
                    width: 80,
                    height: 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 6),
                  CustomShimmer(
                    width: 60,
                    height: 12,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
