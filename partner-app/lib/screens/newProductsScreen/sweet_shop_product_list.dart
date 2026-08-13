import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/models/productList.dart';
import 'package:project/models/sweetShopProducts.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/repositories/sweetShopProductsApi.dart';
import 'package:project/screens/newProductsScreen/add_product.dart';
import 'package:project/screens/newProductsScreen/product_list.dart';

class SweetShopProductListScreen extends StatefulWidget {
  @override
  State<SweetShopProductListScreen> createState() =>
      _SweetShopProductListScreenState();
}

class _SweetShopProductListScreenState
    extends State<SweetShopProductListScreen> {
  // State
  bool _isLoading = true;
  String _errorMessage = '';
  SweetShopProductsData? _productsData;

  // For tracking selected variants
  final Map<String, int> _selectedVariantIdx = {};

  // For scroll functionality
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _categoryKeys = {};

  // For tracking expanded categories in menu
  final Set<int> _expandedCategories = {};

  // For search and filter
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _sortBy = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await getSweetShopProductsByCategoryApi(
        context: context,
        search: _searchController.text,
        sortBy: _sortBy,
      );

      if (response['status'] == 1 && response['data'] != null) {
        setState(() {
          _productsData = SweetShopProductsData.fromJson(response['data']);
          _isLoading = false;

          // Initialize keys for each category
          for (var category in _productsData!.productsByCategory) {
            _categoryKeys[category.categoryId] = GlobalKey();
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'] ?? 'Failed to load products';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _scrollToCategory(int categoryId) {
    final key = _categoryKeys[categoryId];
    if (key != null && key.currentContext != null) {
      Navigator.pop(context); // Close the menu sheet
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  void _showMenuBottomSheet() {
    if (_productsData == null) return;

    final themeProvider = context.read<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Consumer<LanguageProvider>(
                        builder: (context, languageProvider, child) {
                          return Text(
                            getTranslatedValue(context, menuLabel),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              color: colorScheme.textPrimary,
                              letterSpacing: -0.5,
                              height: 1.02,
                            ),
                          );
                        },
                      ),
                    ),
                    Material(
                      color: colorScheme.surfaceVariant,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.close,
                            size: 24,
                            color: colorScheme.iconSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: colorScheme.divider),
              // Categories list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _productsData!.productsByCategory.length,
                  itemBuilder: (context, index) {
                    final categoryGroup =
                        _productsData!.productsByCategory[index];
                    return _buildMenuCategoryItem(
                        categoryGroup, setModalState, colorScheme);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCategoryItem(ProductsByCategory categoryGroup,
      StateSetter setModalState, app_theme.AppColorScheme colorScheme) {
    final isExpanded = _expandedCategories.contains(categoryGroup.categoryId);

    return SafeArea(
      child: Column(
        children: [
          // Category header
          InkWell(
            onTap: () {
              setModalState(() {
                if (isExpanded) {
                  _expandedCategories.remove(categoryGroup.categoryId);
                } else {
                  _expandedCategories.add(categoryGroup.categoryId);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      categoryGroup.categoryName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 24,
                      color: colorScheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Products list (shown when expanded)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: categoryGroup.products.map((product) {
                  return InkWell(
                    onTap: () => _scrollToCategory(categoryGroup.categoryId),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: colorScheme.textSecondary,
                                fontWeight: FontWeight.w500,
                                height: 1.02,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // Divider
          Divider(
              height: 1,
              thickness: 1,
              indent: 20,
              endIndent: 20,
              color: colorScheme.divider),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isManagedByAdmin = Constant.session.getManagedByAdmin();
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // Header with AppHeader
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return AppHeader(
                label: getTranslatedValue(context, productsLabel),
                title: getTranslatedValue(context, manageFoodItemsLabel),
                showBackButton: false,
                trailing: isManagedByAdmin
                    ? null
                    : InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddProductScreen(),
                            ),
                          ).then((_) => _fetchProducts());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add,
                                color: colorScheme.textPrimary,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Consumer<LanguageProvider>(
                                builder: (context, languageProvider, child) {
                                  return Text(
                                    getTranslatedValue(context, addLabel),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: colorScheme.textPrimary,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
              );
            },
          ),
          // Search and Filter
          _buildSearchAndFilter(),
          // Body
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchAndFilter() {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  _fetchProducts();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: GoogleFonts.inter(color: colorScheme.textSecondary),
                prefixIcon:
                    Icon(Icons.search, color: colorScheme.iconSecondary),
                fillColor: colorScheme.surfaceVariant,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.border,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.border,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              style: GoogleFonts.inter(color: colorScheme.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _showSortOptions,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.filter_list,
                color: _sortBy.isNotEmpty
                    ? colorScheme.primary
                    : colorScheme.iconSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    final themeProvider = context.read<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: colorScheme.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort By',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSortOption('Default', '', colorScheme),
                  _buildSortOption(
                      'Price: Low to High', 'price_asc', colorScheme),
                  _buildSortOption(
                      'Price: High to Low', 'price_desc', colorScheme),
                  _buildSortOption(
                      'Rating: Low to High', 'rating_asc', colorScheme),
                  _buildSortOption(
                      'Rating: High to Low', 'rating_desc', colorScheme),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption(
      String title, String value, app_theme.AppColorScheme colorScheme) {
    bool isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
        _fetchProducts();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    if (_isLoading) {
      return ProductListShimmer(itemCount: 6);
    }

    if (_errorMessage.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchProducts,
        color: colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        return Text(
                          getTranslatedValue(context, oopsErrorLabel),
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colorScheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _fetchProducts,
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: colorScheme.success,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colorScheme.success.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Try Again',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_productsData == null || _productsData!.productsByCategory.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchProducts,
        color: colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 56,
                        color: colorScheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        return Text(
                          getTranslatedValue(context, noFoodItemsYetLabel),
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        return Text(
                          getTranslatedValue(context, startBuildingMenuLabel),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colorScheme.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Products list grouped by categories
    return RefreshIndicator(
      onRefresh: _fetchProducts,
      color: colorScheme.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
        itemCount: _productsData!.productsByCategory.length,
        itemBuilder: (context, index) {
          final categoryGroup = _productsData!.productsByCategory[index];
          return _buildCategorySection(categoryGroup, colorScheme);
        },
      ),
    );
  }

  Widget _buildCategorySection(
      ProductsByCategory categoryGroup, app_theme.AppColorScheme colorScheme) {
    return Container(
      key: _categoryKeys[categoryGroup.categoryId],
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(6),
            // decoration: BoxDecoration(
            //   gradient: LinearGradient(
            //     begin: Alignment.topLeft,
            //     end: Alignment.bottomRight,
            //     colors: [
            //       const Color(0xFF9AC444).withValues(alpha: 0.1),
            //       const Color(0xFF9AC444).withValues(alpha: 0.05),
            //     ],
            //   ),
            //   borderRadius: BorderRadius.circular(16),
            //   border: Border.all(
            //     color: const Color(0xFF9AC444).withValues(alpha: 0.3),
            //   ),
            // ),
            child: Row(
              children: [
                // if (categoryGroup.categoryImageUrl != null)
                //   Container(
                //     width: 56,
                //     height: 56,
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(12),
                //       border: Border.all(color: const Color(0xFFE5E7EB)),
                //       color: const Color(0xFFF9FAFB),
                //     ),
                //     clipBehavior: Clip.antiAlias,
                //     child: Image.network(
                //       categoryGroup.categoryImageUrl!,
                //       fit: BoxFit.cover,
                //       errorBuilder: (context, error, stackTrace) {
                //         return const Icon(
                //           Icons.restaurant_menu,
                //           color: Color(0xFF9CA3AF),
                //           size: 28,
                //         );
                //       },
                //     ),
                //   )
                // else
                //   Container(
                //     width: 56,
                //     height: 56,
                //     decoration: BoxDecoration(
                //       color: const Color(0xFF9AC444).withValues(alpha: 0.2),
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     child: const Icon(
                //       Icons.restaurant_menu,
                //       color: Color(0xFF9AC444),
                //       size: 28,
                //     ),
                //   ),
                // const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryGroup.categoryName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      // const SizedBox(height: 4),
                      // Text(
                      //   '${categoryGroup.productCount} ${categoryGroup.productCount == 1 ? "item" : "items"}',
                      //   style: GoogleFonts.inter(
                      //     fontSize: 14,
                      //     fontWeight: FontWeight.w500,
                      //     color: const Color(0xFF6B7280),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // const SizedBox(height: 12),
          // Products in this category
          ...categoryGroup.products.map((product) {
            final vIdx = _selectedVariantIdx[product.id] ?? 0;
            final selectedVariant =
                (product.variants != null && product.variants!.isNotEmpty)
                    ? product.variants![vIdx]
                    : Variants();

            final isManagedByAdmin = Constant.session.getManagedByAdmin();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProductListCard(
                item: product,
                selectedVariant: selectedVariant,
                isEditLoading: false,
                isDeleteLoading: false,
                isMenuLoading: false,
                onEdit: isManagedByAdmin
                    ? null
                    : () async {
                        try {
                          final response = await getSingleSellerProductApi(
                            context: context,
                            productId: product.id!,
                          );

                          if (response['status'] == 1) {
                            final productData = response['data'];
                            final detailedProduct =
                                ProductListItem.fromJson(productData);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddProductScreen(
                                  product: detailedProduct,
                                ),
                              ),
                            ).then((_) => _fetchProducts());
                          } else {
                            showMessage(
                              context,
                              response['message'] ??
                                  'Failed to fetch product details',
                              MessageType.error,
                            );
                          }
                        } catch (e) {
                          showMessage(
                            context,
                            'Error: $e',
                            MessageType.error,
                          );
                        }
                      },
                onDelete: isManagedByAdmin
                    ? null
                    : () {
                        _showDeleteConfirmation(product);
                      },
                onMenu: () {},
                onVariantTap: () =>
                    _showVariantsSheet(context, product, vIdx, colorScheme),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    // Show menu button for all users to navigate between categories
    return FloatingActionButton(
      backgroundColor: colorScheme.primary,
      elevation: 4,
      highlightElevation: 8,
      onPressed: _showMenuBottomSheet,
      child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
    );
  }

  void _showDeleteConfirmation(ProductListItem item) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: colorScheme.surface,
      builder: (context) => Container(
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
                    builder: (context, languageProvider, child) {
                      return Text(
                        getTranslatedValue(context, deleteProductLabel),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      );
                    },
                  ),
                ),
                Material(
                  color: colorScheme.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: colorScheme.iconSecondary,
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
                        Consumer<LanguageProvider>(
                          builder: (context, languageProvider, child) {
                            return Text(
                              getTranslatedValue(context, permanentActionLabel),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF991B1B),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 4),
                        Consumer<LanguageProvider>(
                          builder: (context, languageProvider, child) {
                            return Text(
                              getTranslatedValue(
                                  context, actionCannotBeUndoneLabel),
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
            // Product info
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return Text(
                  getTranslatedValue(context, areYouSureDeleteProductLabel),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: colorScheme.textSecondary,
                    height: 1.5,
                  ),
                );
              },
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    color: colorScheme.iconSecondary,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name ?? 'Product',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colorScheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.border, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        return Text(
                          getTranslatedValue(context, cancelLabel),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: colorScheme.textSecondary,
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
                      Navigator.pop(context);
                      final success = await context
                          .read<ProductListProvider>()
                          .deleteProduct(
                            context: context,
                            productId: item.id!,
                          );
                      if (success) {
                        _selectedVariantIdx.remove(item.id);
                        await _fetchProducts();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        return Text(
                          getTranslatedValue(context, deleteProductLabel),
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

  void _showVariantsSheet(BuildContext ctx, ProductListItem item,
      int selectedIndex, app_theme.AppColorScheme colorScheme) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: colorScheme.background,
      builder: (context) {
        return ProductVariantsSheet(
          product: item,
          isManagedByAdmin: false,
          selectedIdx: selectedIndex,
          onVariantSelect: (idx) {
            setState(() => _selectedVariantIdx[item.id!] = idx);
            Navigator.pop(context);
          },
          onDelete: (idx) {}, // Implement if needed
        );
      },
    );
  }
}
