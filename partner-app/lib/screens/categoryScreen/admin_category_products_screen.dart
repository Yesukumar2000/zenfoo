import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/models/category_by_admin.dart';
import 'package:project/models/category_products_by_admin.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class AdminCategoryProductsScreen extends StatefulWidget {
  final SubCategoryGroups subCategoryGroup;

  const AdminCategoryProductsScreen({
    Key? key,
    required this.subCategoryGroup,
  }) : super(key: key);

  @override
  State<AdminCategoryProductsScreen> createState() =>
      _AdminCategoryProductsScreenState();
}

class _AdminCategoryProductsScreenState
    extends State<AdminCategoryProductsScreen> {
  // Track selected category
  int? _selectedCategoryId;

  // Scroll controller for right panel
  final ScrollController _rightScrollController = ScrollController();

  // Products data will be loaded here
  List<Products> _products = [];
  bool _isLoadingProducts = false;

  // Track selected variant for each product
  final Map<int, int> _selectedVariantIdx = {};

  @override
  void initState() {
    super.initState();
    // Auto-select first category if available
    if (widget.subCategoryGroup.categories != null &&
        widget.subCategoryGroup.categories!.isNotEmpty) {
      _selectedCategoryId = widget.subCategoryGroup.categories![0].id;
      _fetchProducts(_selectedCategoryId!);
    }
  }

  @override
  void dispose() {
    _rightScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts(int categoryId) async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final response = await getProductsByCategoryApi(
        context: context,
        categoryId: categoryId,
      );

      setState(() {
        _products = response?.data?.products ?? [];
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
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
            label: "Products",
            title: widget.subCategoryGroup.name ?? "Category Products",
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

    if (widget.subCategoryGroup.categories == null ||
        widget.subCategoryGroup.categories!.isEmpty) {
      return _buildEmptyState();
    }

    // Two-column layout
    return Row(
      children: [
        // Left sidebar - Categories list
        _buildLeftSidebar(),
        // Divider
        Container(
          width: 1,
          color: colorScheme.border,
        ),
        // Right content area - Products
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
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: widget.subCategoryGroup.categories == null ||
             widget.subCategoryGroup.categories!.isEmpty
          ? _buildLeftSidebarShimmer()
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: widget.subCategoryGroup.categories!.length,
              itemBuilder: (context, index) {
                final category = widget.subCategoryGroup.categories![index];
                final isSelected = _selectedCategoryId == category.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                    });
                    if (category.id != null) {
                      _fetchProducts(category.id!);
                    }
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
                              // Category image/icon with circular container
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
                                        child:
                                            (category.imageUrl?.isNotEmpty ?? false)
                                                ? setNetworkImg(
                                                    image: category.imageUrl!,
                                                    width: 48,
                                                    height: 48,
                                                    boxFit: BoxFit.cover,
                                                  )
                                                : Icon(
                                                    Icons.restaurant,
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
                                  category.name ?? '',
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
                                borderRadius: const BorderRadius.only(
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

  Widget _buildLeftSidebarShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: 5, // Show 5 shimmer items
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
    );
  }

  Widget _buildRightContent() {
    final selectedCategory = widget.subCategoryGroup.categories!
        .firstWhere((c) => c.id == _selectedCategoryId);

    return CustomScrollView(
      controller: _rightScrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Section Header
        SliverToBoxAdapter(
          child: _isLoadingProducts
              ? _buildSectionHeaderShimmer()
              : _buildSectionHeader(selectedCategory),
        ),

        // Products List
        if (_isLoadingProducts)
          _buildProductsShimmer()
        else if (_products.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Builder(
              builder: (context) {
                final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: colorScheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products available',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else
          _buildProductsList(),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(Categories selectedCategory) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedCategory.name ?? '',
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
            '${_products.length} products',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.textSecondary,
              letterSpacing: -0.1,
            ),
          ),
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomShimmer(
            width: 200,
            height: 28,
            borderRadius: 4,
          ),
          const SizedBox(height: 8),
          CustomShimmer(
            width: 120,
            height: 16,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _products[index];
            final vIdx = _selectedVariantIdx[product.id] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildProductCard(product, vIdx),
            );
          },
          childCount: _products.length,
        ),
      ),
    );
  }

  Widget _buildProductsShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildProductCardShimmer(),
            );
          },
          childCount: 6, // Show 6 shimmer cards
        ),
      ),
    );
  }

  Widget _buildProductCardShimmer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Image Shimmer
          CustomShimmer(
            width: 90,
            height: 90,
            borderRadius: 12,
          ),
          const SizedBox(width: 14),
          // Main Details Shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Product name shimmer
                CustomShimmer(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                CustomShimmer(
                  width: 120,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 12),
                // Price shimmer
                CustomShimmer(
                  width: 80,
                  height: 20,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                // Variant badge shimmer
                CustomShimmer(
                  width: 100,
                  height: 28,
                  borderRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Products product, int selectedVariantIndex) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    // Get selected variant for price and stock
    final variant = (product.variants?.isNotEmpty == true &&
            selectedVariantIndex < product.variants!.length)
        ? product.variants![selectedVariantIndex]
        : (product.variants?.isNotEmpty == true ? product.variants![0] : null);

    final price = variant?.price ?? 0;
    final discountedPrice = variant?.discountedPrice ?? 0;
    final hasDiscount = discountedPrice > 0 && discountedPrice < price;
    final displayPrice = hasDiscount ? discountedPrice : price;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            spreadRadius: 0,
            color: colorScheme.textPrimary.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Image
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.border, width: 1),
              color: colorScheme.surfaceVariant,
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: colorScheme.textPrimary.withValues(alpha: 0.03),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? setNetworkImg(
                    image: product.imageUrl!,
                    width: 90,
                    height: 90,
                    boxFit: BoxFit.cover,
                  )
                : Icon(
                    Icons.fastfood,
                    size: 48,
                    color: colorScheme.textTertiary,
                  ),
          ),
          const SizedBox(width: 14),
          // Main Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Product name
                Text(
                  product.name ?? '-',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.55,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Stock status badge
                // if (variant != null)
                //   Container(
                //     padding:
                //         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //     decoration: BoxDecoration(
                //       color: _getStockBadgeColor(variant.stock ?? 0)
                //           .withValues(alpha: 0.1),
                //       borderRadius: BorderRadius.circular(6),
                //     ),
                //     child: Row(
                //       mainAxisSize: MainAxisSize.min,
                //       children: [
                //         Container(
                //           width: 6,
                //           height: 6,
                //           decoration: BoxDecoration(
                //             color: _getStockBadgeColor(variant.stock ?? 0),
                //             shape: BoxShape.circle,
                //           ),
                //         ),
                //         const SizedBox(width: 4),
                //         Text(
                //           _getStockStatusText(variant.stock ?? 0),
                //           style: GoogleFonts.inter(
                //             color: _getStockBadgeColor(variant.stock ?? 0),
                //             fontSize: 11,
                //             fontWeight: FontWeight.w600,
                //             letterSpacing: -0.55,
                //             height: 1.02,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // const SizedBox(height: 7),
                // Price
                Row(
                  children: [
                    Text(
                      '₹$displayPrice',
                      style: GoogleFonts.inter(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text(
                        '₹$price',
                        style: GoogleFonts.inter(
                          decoration: TextDecoration.lineThrough,
                          decorationThickness: 1.5,
                          color: colorScheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          letterSpacing: -0.55,
                          height: 1.02,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 7),
                // Variant info - tappable to show variants sheet
                if (variant != null && product.variants!.length > 1)
                  InkWell(
                    onTap: () => _showVariantsSheet(product, selectedVariantIndex),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${variant.measurement ?? ""} ${variant.stockUnitName ?? ""}',
                            style: GoogleFonts.inter(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.55,
                              height: 1.02,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (variant != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${variant.measurement ?? ""} ${variant.stockUnitName ?? ""}',
                      style: GoogleFonts.inter(
                        color: colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStockBadgeColor(int stock) {
    if (stock <= 0) return const Color(0xFFEF4444);
    if (stock <= 10) return const Color(0xFFFFA726);
    return const Color(0xFF66BB6A);
  }

  String _getStockStatusText(int stock) {
    if (stock <= 0) return 'Out of Stock';
    if (stock <= 10) return 'Low Stock ($stock)';
    return 'Stock: $stock';
  }

  void _showVariantsSheet(Products product, int selectedIndex) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: colorScheme.surface,
      builder: (context) {
        return _ProductVariantsSheet(
          product: product,
          selectedIdx: selectedIndex,
          onVariantSelect: (idx) {
            setState(() => _selectedVariantIdx[product.id!] = idx);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: colorScheme.textTertiary,
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
          ],
        ),
      ),
    );
  }
}

class _ProductVariantsSheet extends StatelessWidget {
  final Products product;
  final int selectedIdx;
  final Function(int idx) onVariantSelect;

  const _ProductVariantsSheet({
    Key? key,
    required this.product,
    required this.selectedIdx,
    required this.onVariantSelect,
  }) : super(key: key);

  Widget _buildVariantImage(Variants variant, Products product, BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    // For now, use product image as variants don't have images in this model
    String? imageUrl = product.imageUrl;

    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null') {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.image, size: 24, color: colorScheme.textTertiary);
        },
      );
    } else {
      return Icon(Icons.image, size: 24, color: colorScheme.textTertiary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final variants = product.variants ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [BoxShadow(
          color: colorScheme.textPrimary.withValues(alpha: 0.25),
          blurRadius: 22,
        )],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name ?? "",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 21,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.55,
                    height: 1.02,
                  ),
                ),
              ),
              Material(
                color: colorScheme.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(7.49),
                    child: Icon(Icons.close, size: 19, color: colorScheme.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...variants.asMap().entries.map((entry) {
            final idx = entry.key;
            final v = entry.value;
            final isSelected = idx == selectedIdx;
            return Column(
              children: [
                InkWell(
                  onTap: () => onVariantSelect(idx),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          margin: const EdgeInsets.only(right: 13),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: colorScheme.surfaceVariant,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildVariantImage(v, product, context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${v.measurement ?? ""} ${v.stockUnitName ?? ""}',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: colorScheme.textPrimary,
                                  letterSpacing: -0.55,
                                  height: 1.02,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    "₹${v.discountedPrice ?? v.price ?? "0"}",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: colorScheme.textPrimary,
                                      letterSpacing: -0.55,
                                      height: 1.02,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  if (v.discountedPrice != null &&
                                      v.discountedPrice != 0 &&
                                      v.discountedPrice != v.price)
                                    Text(
                                      "₹${v.price}",
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: colorScheme.textTertiary,
                                        decoration: TextDecoration.lineThrough,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.55,
                                        height: 1.02,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Column(
                        //   children: [
                        //     Container(
                        //       padding: const EdgeInsets.symmetric(
                        //           horizontal: 8, vertical: 4),
                        //       decoration: BoxDecoration(
                        //         color: _getStockBadgeColor(v.stock ?? 0)
                        //             .withValues(alpha: 0.1),
                        //         borderRadius: BorderRadius.circular(6),
                        //       ),
                        //       child: Row(
                        //         mainAxisSize: MainAxisSize.min,
                        //         children: [
                        //           Container(
                        //             width: 6,
                        //             height: 6,
                        //             decoration: BoxDecoration(
                        //               color: _getStockBadgeColor(v.stock ?? 0),
                        //               shape: BoxShape.circle,
                        //             ),
                        //           ),
                        //           const SizedBox(width: 4),
                        //           Text(
                        //             _getStockStatusText(v.stock ?? 0),
                        //             style: GoogleFonts.inter(
                        //               color: _getStockBadgeColor(v.stock ?? 0),
                        //               fontSize: 11,
                        //               fontWeight: FontWeight.w600,
                        //               letterSpacing: -0.55,
                        //               height: 1.02,
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ),
                if (idx < variants.length - 1)
                  Divider(
                    color: colorScheme.border,
                    thickness: 1,
                    height: 22,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Color _getStockBadgeColor(int stock) {
    if (stock <= 0) return const Color(0xFFEF4444);
    if (stock <= 10) return const Color(0xFFFFA726);
    return const Color(0xFF66BB6A);
  }

  String _getStockStatusText(int stock) {
    if (stock <= 0) return 'Out of Stock';
    if (stock <= 10) return 'Low Stock ($stock)';
    return 'Stock: $stock';
  }
}
