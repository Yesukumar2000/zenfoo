import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/productList.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class ProductStockManagementScreen extends StatefulWidget {
  const ProductStockManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProductStockManagementScreen> createState() =>
      _ProductStockManagementScreenState();
}

class _ProductStockManagementScreenState
    extends State<ProductStockManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<ProductListItem> _products = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;

  // Track stock updates in progress
  final Map<String, bool> _updatingStock = {};
  final Map<String, TextEditingController> _stockControllers = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchProducts(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    // Dispose all stock controllers
    for (var controller in _stockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (_currentPage < _lastPage && !_isLoadingMore) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _fetchProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _products.clear();
        _isLoading = true;
      });
    }

    try {
      final response = await getSellerProductsApi(
        context: context,
        params: {
          'page': _currentPage.toString(),
          if (_searchController.text.isNotEmpty)
            'search': _searchController.text,
        },
      );

      if (response['status'] == 1) {
        final data = response['data'];
        _currentPage = data['current_page'] ?? 1;
        _lastPage = data['last_page'] ?? 1;

        if (data['data'] != null) {
          final List<dynamic> productList = data['data'];
          final newProducts = productList
              .map((json) => ProductListItem.fromJson(json))
              .toList();

          setState(() {
            if (isRefresh) {
              _products = newProducts;
            } else {
              _products.addAll(newProducts);
            }
            _isLoading = false;
            _isLoadingMore = false;
          });

          // Initialize stock controllers for new products
          _initializeControllers();
        }
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      showMessage(context, 'Error loading products', MessageType.error);
    }
  }

  void _initializeControllers() {
    for (var product in _products) {
      if (product.variants != null) {
        for (var variant in product.variants!) {
          if (variant.id != null &&
              !_stockControllers.containsKey(variant.id)) {
            _stockControllers[variant.id!] =
                TextEditingController(text: variant.stock);
          }
        }
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _fetchProducts();
  }

  Future<void> _updateVariantStock(String variantId, String newStock) async {
    setState(() {
      _updatingStock[variantId] = true;
    });

    try {
      final response = await getUpdateProductStockApi(
        context: context,
        params: {
          'id': variantId,
          'stock': newStock,
        },
      );

      if (response['status'].toString() == '1') {
        showMessage(
          context,
          'Stock updated successfully',
          MessageType.success,
        );
        // Update local data
        for (var product in _products) {
          if (product.variants != null) {
            for (var variant in product.variants!) {
              if (variant.id == variantId) {
                variant.stock = newStock;
                break;
              }
            }
          }
        }
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to update stock',
          MessageType.error,
        );
      }
    } catch (e) {
      showMessage(context, 'Error updating stock', MessageType.error);
    } finally {
      setState(() {
        _updatingStock.remove(variantId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: RefreshIndicator(
        onRefresh: () => _fetchProducts(isRefresh: true),
        color: const Color(0xFF9AC444),
        backgroundColor: colorScheme.cardBackground,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Header
            SliverToBoxAdapter(
              child: AppHeader(
                label: 'Inventory',
                title: 'Stock Management',
                showBackButton: true,
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.border,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.textSecondary,
                        letterSpacing: -0.3,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.iconSecondary,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                color: colorScheme.iconSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _fetchProducts(isRefresh: true);
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _fetchProducts(isRefresh: true),
                  ),
                ),
              ),
            ),

            // Products List
            if (_isLoading)
              SliverToBoxAdapter(child: _buildLoadingState())
            else if (_products.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _products.length) {
                        return _buildLoadMoreIndicator();
                      }
                      return _buildModernProductCard(_products[index]);
                    },
                    childCount: _products.length + (_isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProductCard(ProductListItem product) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final hasVariants =
        product.variants != null && product.variants!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Compact Product Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                // Compact Product image
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.border,
                      width: 1.5,
                    ),
                    color: colorScheme.surface,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: product.imageUrl != null &&
                          product.imageUrl!.isNotEmpty &&
                          product.imageUrl != 'null'
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.inventory_2_rounded,
                              size: 28,
                              color: colorScheme.iconSecondary,
                            );
                          },
                        )
                      : Icon(
                          Icons.inventory_2_rounded,
                          size: 28,
                          color: colorScheme.iconSecondary,
                        ),
                ),
                const SizedBox(width: 12),
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name ?? '-',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: colorScheme.textPrimary,
                          height: 1.3,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9AC444)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedPackage,
                                  size: 10,
                                  color: Color(0xFF9AC444),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${hasVariants ? product.variants!.length : 0}',
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (product.type != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDEEAFF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.type!,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF1E40AF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Variants Section with Header
          if (hasVariants)
            Column(
              children: [
                // Variants Divider
                Container(
                  height: 1,
                  color: colorScheme.border,
                ),
                // Variants List
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: product.variants!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final variant = entry.value;
                      final isLast = index == product.variants!.length - 1;
                      return _buildModernVariantItem(product, variant, isLast);
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildModernVariantItem(
    ProductListItem product,
    Variants variant,
    bool isLast,
  ) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final controller = _stockControllers[variant.id] ??
        TextEditingController(text: variant.stock);
    final isUpdating = _updatingStock[variant.id] ?? false;

    // Get variant image or fallback to product image
    String? variantImageUrl;
    if (variant.images != null && variant.images!.isNotEmpty) {
      variantImageUrl = variant.images!.first.imageUrl;
    }
    if (variantImageUrl == null ||
        variantImageUrl.isEmpty ||
        variantImageUrl == 'null') {
      variantImageUrl = product.imageUrl;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.border,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Variant Info
            Row(
              children: [
                // Variant image
                if (variantImageUrl != null &&
                    variantImageUrl.isNotEmpty &&
                    variantImageUrl != 'null')
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.border),
                      color: colorScheme.surface,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      variantImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image,
                          size: 20,
                          color: colorScheme.iconSecondary,
                        );
                      },
                    ),
                  ),
                // Variant details (compact)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Measurement & Status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9AC444)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedPackage,
                                  size: 12,
                                  color: Color(0xFF9AC444),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${variant.measurement ?? ''} ${variant.stockUnitShortCode ?? variant.stockUnitName ?? ''}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: colorScheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: variant.status == '1'
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  variant.status == '1'
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 10,
                                  color: variant.status == '1'
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  variant.status == '1' ? 'Available' : 'Out',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: variant.status == '1'
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Price
                      Row(
                        children: [
                          Text(
                            '₹${variant.discountedPrice ?? variant.price ?? '0'}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF059669),
                            ),
                          ),
                          if (variant.discountedPrice != null &&
                              variant.discountedPrice != '' &&
                              variant.discountedPrice != variant.price) ...[
                            const SizedBox(width: 4),
                            Text(
                              '₹${variant.price}',
                              style: GoogleFonts.inter(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 11,
                                color: colorScheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Stock input (compact inline)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF9AC444),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9AC444)
                                          .withValues(alpha: 0.1),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        bottomLeft: Radius.circular(6),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Stock',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter
                                            .digitsOnly,
                                      ],
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.textPrimary,
                                      ),
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Update button (compact)
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: isUpdating
                                  ? null
                                  : () {
                                      if (controller.text.isEmpty) {
                                        showMessage(
                                          context,
                                          'Please enter stock',
                                          MessageType.warning,
                                        );
                                        return;
                                      }
                                      if (controller.text.length > 9) {
                                        showMessage(
                                          context,
                                          'Max 9 digits',
                                          MessageType.error,
                                        );
                                        return;
                                      }
                                      _updateVariantStock(
                                        variant.id!,
                                        controller.text,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9AC444),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                                minimumSize: Size.zero,
                              ),
                              child: isUpdating
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const HugeIcon(
                                          icon: HugeIcons
                                              .strokeRoundedCheckmarkCircle01,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Update',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: List.generate(
          4,
          (index) => Shimmer.fromColors(
            baseColor: colorScheme.border,
            highlightColor: colorScheme.surfaceVariant,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: colorScheme.iconSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No products found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add products to manage stock',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colorScheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF9AC444),
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading more...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colorScheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Improved compact L-shaped connector
class _CompactHierarchyLinePainter extends CustomPainter {
  final bool isLast;

  _CompactHierarchyLinePainter({required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9AC444)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const double radius = 10.0;
    final double centerX = size.width / 2;
    final double startY = 0;
    final double midY = size.height * 0.5;

    // Vertical line from top
    path.moveTo(centerX, startY);
    path.lineTo(centerX, midY - radius);

    // Smooth L-curve
    path.quadraticBezierTo(
      centerX,
      midY,
      centerX + radius,
      midY,
    );

    // Horizontal line extending right
    path.lineTo(size.width, midY);

    // Continue vertical line if not last
    if (!isLast) {
      path.moveTo(centerX, midY);
      path.lineTo(centerX, size.height);
    }

    canvas.drawPath(path, paint);

    // Add a small circle at the junction for better visual
    final circlePaint = Paint()
      ..color = const Color(0xFF9AC444)
      ..style = PaintingStyle.fill;
    if (!isLast)
      canvas.drawCircle(
        Offset(centerX, midY),
        3.5,
        circlePaint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
