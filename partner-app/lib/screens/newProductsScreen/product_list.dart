import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/models/productList.dart';
import 'package:project/screens/newProductsScreen/add_product.dart';
import 'package:project/repositories/addProductApi.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class ProductListScreen extends StatefulWidget {
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final Map<String, int> _selectedVariantIdx = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch products on init
    Future.delayed(Duration.zero, () {
      context.read<ProductListProvider>().fetchSellerProducts(
            context: context,
            isRefresh: true,
          );
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final provider = context.read<ProductListProvider>();
      if (provider.hasMorePages &&
          provider.productState != ProductState.loadingMore) {
        provider.loadMoreSellerProducts(context);
      }
    }
  }

  Future<void> _onRefresh() async {
    await context.read<ProductListProvider>().fetchSellerProducts(
          context: context,
          isRefresh: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return AppHeader(
                label: getTranslatedValue(context, inventoryLabel),
                title: getTranslatedValue(context, productsLabel),
                showBackButton: false,
              );
            },
          ),
          Expanded(
            child: Consumer<ProductListProvider>(
              builder: (context, provider, _) {
                // Loading state
                if (provider.productState == ProductState.loading) {
                  return ProductListShimmer(itemCount: 6);
                }

                // Error state
                if (provider.productState == ProductState.error) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: colorScheme.primary,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: constraints.maxHeight,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: colorScheme.error
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: colorScheme.error,
                                      ),
                                    ),
                                    SizedBox(height: 24),
                                    Consumer<LanguageProvider>(
                                      builder: (context, languageProvider, _) {
                                        return Text(
                                          getTranslatedValue(
                                              context, oopsErrorLabel),
                                          style: GoogleFonts.inter(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.textPrimary,
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      provider.message,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: colorScheme.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 24),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _onRefresh,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            color: Color(0xFF16A34A),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0xFF16A34A)
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 12,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 16,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.refresh_rounded,
                                                  color: colorScheme.primary,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  getTranslatedValue(
                                                      context, tryAgainLabel),
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: colorScheme.primary,
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
                        );
                      },
                    ),
                  );
                }

                // Empty state
                if (provider.productState == ProductState.empty) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: colorScheme.primary,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: constraints.maxHeight,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(24),
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
                                    SizedBox(height: 24),
                                    Text(
                                      getTranslatedValue(
                                          context, noProductsYetLabel),
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      getTranslatedValue(
                                          context, startBuildingInventoryLabel),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: colorScheme.textSecondary,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                // Products list
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: colorScheme.primary,
                  backgroundColor: colorScheme.surface,
                  strokeWidth: 3.0,
                  displacement: 40,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                        left: 16, right: 16, top: 16, bottom: 88),
                    itemCount: provider.sellerProducts.length +
                        (provider.productState == ProductState.loadingMore
                            ? 1
                            : 0),
                    itemBuilder: (context, idx) {
                      // Loading more indicator
                      if (idx >= provider.sellerProducts.length) {
                        return LoadMoreIndicator();
                      }

                      final item = provider.sellerProducts[idx];
                      final vIdx = _selectedVariantIdx[item.id] ?? 0;
                      final selectedVariant =
                          (item.variants != null && item.variants!.isNotEmpty)
                              ? item.variants![vIdx]
                              : Variants();

                      final isManagedByAdmin =
                          Constant.session.getManagedByAdmin();

                      final editLoadingKey = 'edit_${item.id}';
                      final deleteLoadingKey = 'delete_${item.id}';
                      final menuLoadingKey = 'more_${item.id}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ProductListCard(
                          item: item,
                          selectedVariant: selectedVariant,
                          isManagedByAdmin: isManagedByAdmin,
                          isEditLoading:
                              provider.isActionLoading(editLoadingKey),
                          isDeleteLoading:
                              provider.isActionLoading(deleteLoadingKey),
                          isMenuLoading:
                              provider.isActionLoading(menuLoadingKey),
                          onEdit: isManagedByAdmin
                              ? null
                              : () async {
                                  if (provider.isActionLoading(editLoadingKey))
                                    return;

                                  provider.setActionLoading(
                                      editLoadingKey, true);
                                  try {
                                    // Fetch single product details
                                    final response =
                                        await getSingleSellerProductApi(
                                      context: context,
                                      productId: item.id!,
                                    );

                                    provider.setActionLoading(
                                        editLoadingKey, false);

                                    if (response['status'] == 1) {
                                      final productData = response['data'];
                                      debugPrint('=== SINGLE PRODUCT API RAW ===');
                                      debugPrint('fssai_number: ${productData['fssai_number']}');
                                      debugPrint('variants count: ${(productData['variants'] as List?)?.length}');
                                      if (productData['variants'] != null) {
                                        for (var v in productData['variants']) {
                                          debugPrint('variant images: ${v['images']}');
                                        }
                                      }
                                      debugPrint('==============================');
                                      final detailedProduct =
                                          ProductListItem.fromJson(productData);

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddProductScreen(
                                            product: detailedProduct,
                                          ),
                                        ),
                                      ).then((_) => _onRefresh());
                                    } else {
                                      showMessage(
                                        context,
                                        response['message'] ??
                                            'Failed to fetch product details',
                                        MessageType.error,
                                      );
                                    }
                                  } catch (e) {
                                    provider.setActionLoading(
                                        editLoadingKey, false);
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
                                  if (provider.isActionLoading(
                                      deleteLoadingKey)) return;
                                  _showDeleteConfirmation(item);
                                },
                          onMenu: () {},
                          onVariantTap: () =>
                              _showVariantsSheet(context, item, vIdx),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Constant.session.getManagedByAdmin()
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Color(0xFF059669),
              elevation: 4,
              highlightElevation: 8,
              icon: Icon(Icons.add, color: Colors.white, size: 24),
              label: Text(
                "Add Product",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddProductScreen(),
                  ),
                ).then((_) => _onRefresh());
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showDeleteConfirmation(ProductListItem item) {
    final themeProvider = context.read<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

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
                  child: Text(
                    getTranslatedValue(context, deleteProductLabel),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
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
                          builder: (context, languageProvider, _) {
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
                          builder: (context, languageProvider, _) {
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
              builder: (context, languageProvider, _) {
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
                      builder: (context, languageProvider, _) {
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
                        await _onRefresh();
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
                      builder: (context, languageProvider, _) {
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

  void _showVariantsSheet(
      BuildContext ctx, ProductListItem item, int selectedIndex) {
    final themeProvider = context.read<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final isManagedByAdmin = Constant.session.getManagedByAdmin();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: colorScheme.surface,
      builder: (context) {
        return ProductVariantsSheet(
          product: item,
          selectedIdx: selectedIndex,
          isManagedByAdmin: isManagedByAdmin,
          onVariantSelect: (idx) {
            setState(() => _selectedVariantIdx[item.id!] = idx);
            Navigator.pop(context);
          },
          onDelete: (idx) => _showDeleteVariantConfirmation(context, item, idx),
        );
      },
    );
  }

  void _showDeleteVariantConfirmation(
      BuildContext context, ProductListItem item, int variantIdx) {
    if (item.variants == null || variantIdx >= item.variants!.length) return;

    final themeProvider = context.read<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final variant = item.variants![variantIdx];
    final variantName =
        '${variant.measurement ?? ""} ${variant.stockUnitShortCode ?? variant.stockUnitName ?? ""}';

    // Don't allow deletion if it's the only variant
    if (item.variants!.length == 1) {
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
      backgroundColor: colorScheme.surface,
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
                    onTap: () => Navigator.pop(bottomSheetContext),
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
                          builder: (context, languageProvider, _) {
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
                          builder: (context, languageProvider, _) {
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
            // Variant info
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, _) {
                return Text(
                  getTranslatedValue(context, areYouSureDeleteVariantLabel),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.category_rounded,
                        color: colorScheme.iconSecondary,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Variant',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    variantName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: colorScheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'from ${item.name}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colorScheme.textSecondary,
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
                      side: BorderSide(color: colorScheme.border, width: 1.5),
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
                      Navigator.pop(bottomSheetContext); // Close bottom sheet
                      await _deleteVariant(context, item, variantIdx);
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

  Future<void> _deleteVariant(
      BuildContext context, ProductListItem item, int variantIdx) async {
    if (item.variants == null || variantIdx >= item.variants!.length) return;

    final themeProvider = context.read<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final variant = item.variants![variantIdx];
    if (variant.id == null) {
      showMessage(context, 'Invalid variant ID', MessageType.error);
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
                SizedBox(height: 16),
                Consumer<LanguageProvider>(
                  builder: (context, languageProvider, _) {
                    return Text(
                      getTranslatedValue(context, deletingVariantLabel),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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

      final response = await deleteVariantApi(
        variantId: variant.id!,
        context: context,
      );

      Navigator.pop(context); // Dismiss loading dialog

      if (response['status'] == 1) {
        // Close the variants sheet if open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        showMessage(
          context,
          getTranslatedValue(context, variantDeletedSuccessLabel),
          MessageType.success,
        );

        // Refresh the product list
        await _onRefresh();
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to delete variant',
          MessageType.warning,
        );
      }
    } catch (e) {
      Navigator.pop(context); // Dismiss loading dialog if error
      print('Error deleting variant: $e');
      showMessage(
        context,
        'Error deleting variant',
        MessageType.error,
      );
    }
  }
}

class ProductListCard extends StatelessWidget {
  final ProductListItem item;
  final Variants selectedVariant;
  final bool isManagedByAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMenu;
  final VoidCallback? onVariantTap;
  final bool isEditLoading;
  final bool isDeleteLoading;
  final bool isMenuLoading;

  const ProductListCard({
    Key? key,
    required this.item,
    required this.selectedVariant,
    this.isManagedByAdmin = false,
    this.onEdit,
    this.onDelete,
    this.onMenu,
    this.onVariantTap,
    this.isEditLoading = false,
    this.isDeleteLoading = false,
    this.isMenuLoading = false,
  }) : super(key: key);

  Widget _buildProductImage(ProductListItem item, Variants selectedVariant) {
    // Try to get variant image first, then fallback to product image
    String? imageUrl;

    // Check if selected variant has images
    if (selectedVariant.images != null && selectedVariant.images!.isNotEmpty) {
      imageUrl = selectedVariant.images!.first.imageUrl;
    }

    // Fallback to product image if no variant image
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == 'null') {
      imageUrl = item.imageUrl;
    }

    // Display image or placeholder
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null') {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.image, size: 48, color: Color(0xFFD1D5DB));
        },
      );
    } else {
      return Icon(Icons.image, size: 48, color: Color(0xFFD1D5DB));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final approved = (item.isApproved ?? "0") == "1";

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Image & Approved tag
          Stack(
            children: [
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
                      color: Colors.black.withValues(alpha: 0.03),
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildProductImage(item, selectedVariant),
              ),
              if (approved)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Color(0xFF16A34A),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 4,
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                          size: 10,
                          color: Colors.white,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Approved',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            height: 1.02,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 14),
          // Main Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name ?? "-",
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
                if (item.avgRating != null && item.avgRating! > 0) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFF59E0B)),
                      SizedBox(width: 4),
                      Text(
                        '${item.avgRating}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                      if (item.ratingCount != null &&
                          item.ratingCount! > 0) ...[
                        SizedBox(width: 4),
                        Text(
                          '(${item.ratingCount})',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isManagedByAdmin
                        ? Color(0xFFEFF6FF)
                        : Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isManagedByAdmin) ...[
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedUserSettings01,
                          size: 11,
                          color: Color(0xFF3B82F6),
                        ),
                        SizedBox(width: 4),
                      ],
                      Text(
                        isManagedByAdmin
                            ? 'Admin Managed'
                            : 'Stock: ${selectedVariant.stock ?? "--"}',
                        style: GoogleFonts.inter(
                          color: isManagedByAdmin
                              ? Color(0xFF3B82F6)
                              : Color(0xFF6B7280),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.55,
                          height: 1.02,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 7),
                Row(
                  children: [
                    Text(
                      '₹${selectedVariant.discountedPrice ?? selectedVariant.price ?? "-"}',
                      style: GoogleFonts.inter(
                        color: ColorsRes.appColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                    SizedBox(width: 6),
                    if (selectedVariant.discountedPrice != null &&
                        selectedVariant.discountedPrice != '' &&
                        selectedVariant.discountedPrice !=
                            selectedVariant.price)
                      Text(
                        '₹${selectedVariant.price ?? ""}',
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
                ),
                SizedBox(height: 7),
                // Variant DropDown
                InkWell(
                  onTap: onVariantTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      border: Border.all(
                        color: colorScheme.border,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${selectedVariant.measurement ?? ""} ${selectedVariant.stockUnitShortCode ?? selectedVariant.stockUnitName ?? ""}',
                          style: GoogleFonts.inter(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.55,
                            height: 1.02,
                          ),
                        ),
                        SizedBox(width: 5),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowDown01,
                          size: 13,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Visibility(
            visible: onEdit != null && onDelete != null && onMenu != null,
            child: Container(
              margin: EdgeInsets.only(left: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isEditLoading
                      ? _LoadingIndicator(
                          color: colorScheme.primary,
                          backgroundColor: colorScheme.surfaceVariant,
                        )
                      : _ActionIcon(
                          icon: HugeIcons.strokeRoundedPencilEdit01,
                          onTap: onEdit,
                          color: colorScheme.primary,
                          backgroundColor: colorScheme.surfaceVariant,
                        ),
                  SizedBox(height: 10),
                  isDeleteLoading
                      ? _LoadingIndicator(
                          color: colorScheme.error,
                          backgroundColor: colorScheme.surfaceVariant,
                        )
                      : _ActionIcon(
                          icon: HugeIcons.strokeRoundedDelete01,
                          onTap: onDelete,
                          color: colorScheme.error,
                          backgroundColor: colorScheme.surfaceVariant,
                        ),
                  SizedBox(height: 10),
                  isMenuLoading
                      ? _LoadingIndicator(
                          color: colorScheme.textSecondary,
                          backgroundColor: colorScheme.surfaceVariant,
                        )
                      : _ActionIcon(
                          icon: HugeIcons.strokeRoundedMoreHorizontal,
                          onTap: onMenu,
                          color: colorScheme.textSecondary,
                          backgroundColor: colorScheme.surfaceVariant,
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

class _ActionIcon extends StatelessWidget {
  final List<List<dynamic>> icon;
  final VoidCallback? onTap;
  final Color color;
  final Color? backgroundColor;

  const _ActionIcon({
    required this.icon,
    this.onTap,
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: backgroundColor ?? colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9.0),
          child: HugeIcon(
            icon: icon,
            size: 18,
            color: color,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final Color color;
  final Color? backgroundColor;

  const _LoadingIndicator({
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

class ProductVariantsSheet extends StatelessWidget {
  final ProductListItem product;
  final int selectedIdx;
  final bool isManagedByAdmin;
  final Function(int idx) onVariantSelect;
  final Function(int idx) onDelete;

  const ProductVariantsSheet({
    Key? key,
    required this.product,
    required this.selectedIdx,
    required this.isManagedByAdmin,
    required this.onVariantSelect,
    required this.onDelete,
  }) : super(key: key);

  Widget _buildVariantImage(Variants variant, ProductListItem product) {
    // Try to get variant image first, then fallback to product image
    String? imageUrl;

    // Check if variant has images
    if (variant.images != null && variant.images!.isNotEmpty) {
      imageUrl = variant.images!.first.imageUrl;
    }

    // Fallback to product image if no variant image
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == 'null') {
      imageUrl = product.imageUrl;
    }

    // Display image or placeholder
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null') {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.image, size: 24, color: Color(0xFFD1D5DB));
        },
      );
    } else {
      return Icon(Icons.image, size: 24, color: Color(0xFFD1D5DB));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final variants = product.variants ?? [];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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
            padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    product.name ?? "",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Material(
                  color: colorScheme.surfaceVariant,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                ...variants.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final v = entry.value;
                  final isSelected = idx == selectedIdx;
                  return Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onVariantSelect(idx),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.surfaceVariant
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 62,
                                  height: 62,
                                  margin: EdgeInsets.only(right: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: colorScheme.border, width: 1),
                                    color: colorScheme.surfaceVariant,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _buildVariantImage(v, product),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${v.measurement ?? ""} ${v.stockUnitShortCode ?? v.stockUnitName ?? ""}',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: colorScheme.textPrimary,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                              "₹${v.discountedPrice ?? v.price ?? "0"}",
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                color: colorScheme.textPrimary,
                                                letterSpacing: -0.3,
                                              )),
                                          SizedBox(width: 8),
                                          if (v.discountedPrice != null &&
                                              v.discountedPrice != "" &&
                                              v.discountedPrice != v.price)
                                            Text(
                                              "₹${v.price}",
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color:
                                                    colorScheme.textSecondary,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isManagedByAdmin
                                            ? colorScheme.surfaceVariant
                                            : colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isManagedByAdmin) ...[
                                            HugeIcon(
                                              icon: HugeIcons
                                                  .strokeRoundedUserSettings01,
                                              size: 11,
                                              color: colorScheme.primary,
                                            ),
                                            SizedBox(width: 4),
                                          ],
                                          Text(
                                            isManagedByAdmin
                                                ? 'Admin Managed'
                                                : 'Stock: ${v.stock ?? "--"}',
                                            style: GoogleFonts.inter(
                                              color: isManagedByAdmin
                                                  ? colorScheme.primary
                                                  : colorScheme.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isManagedByAdmin) ...[
                                      SizedBox(height: 8),
                                      Material(
                                        color: colorScheme.background,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: InkWell(
                                          onTap: () => onDelete(idx),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: HugeIcon(
                                              icon: HugeIcons
                                                  .strokeRoundedDelete01,
                                              size: 18,
                                              color: colorScheme.error,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (idx < variants.length - 1)
                        Divider(
                          color: colorScheme.divider,
                          thickness: 1,
                          height: 24,
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Shimmer loading widget for product list
class ProductListShimmer extends StatelessWidget {
  final int itemCount;

  const ProductListShimmer({Key? key, this.itemCount = 5}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 88),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ProductCardShimmer(),
        );
      },
    );
  }
}

class _ProductCardShimmer extends StatefulWidget {
  @override
  _ProductCardShimmerState createState() => _ProductCardShimmerState();
}

class _ProductCardShimmerState extends State<_ProductCardShimmer>
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.border, width: 1),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image placeholder
              _buildShimmerBox(90, 90, 12),
              SizedBox(width: 14),
              // Content placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(double.infinity, 16, 4),
                    SizedBox(height: 8),
                    _buildShimmerBox(80, 12, 4),
                    SizedBox(height: 8),
                    _buildShimmerBox(100, 18, 4),
                    SizedBox(height: 8),
                    _buildShimmerBox(60, 24, 8),
                  ],
                ),
              ),
              SizedBox(width: 8),
              // Actions placeholder
              Column(
                children: [
                  _buildShimmerBox(36, 36, 10),
                  SizedBox(height: 10),
                  _buildShimmerBox(36, 36, 10),
                  SizedBox(height: 10),
                  _buildShimmerBox(36, 36, 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox(double width, double height, double borderRadius) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final isDark = colorScheme == app_theme.AppColorScheme.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [
                  Color(0xFF374151),
                  Color(0xFF4B5563),
                  Color(0xFF374151),
                ]
              : [
                  Color(0xFFE0E0E0),
                  Color(0xFFF5F5F5),
                  Color(0xFFE0E0E0),
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
}

// Load more indicator widget
class LoadMoreIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircularProgressIndicator(
            color: Color(0xFF9AC444),
            strokeWidth: 3,
          ),
          SizedBox(height: 12),
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return Text(
                getTranslatedValue(context, loadingMoreProductsLabel),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
