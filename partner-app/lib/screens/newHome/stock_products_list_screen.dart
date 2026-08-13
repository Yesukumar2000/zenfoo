import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/models/stock_product.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

enum StockListType { soldOut, lowStock }

class StockProductsListScreen extends StatefulWidget {
  final StockListType type;

  const StockProductsListScreen({Key? key, required this.type})
      : super(key: key);

  @override
  State<StockProductsListScreen> createState() =>
      _StockProductsListScreenState();
}

class _StockProductsListScreenState extends State<StockProductsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<StockProduct> _products = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalCount = 0;

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
    super.dispose();
  }

  String get _apiName => widget.type == StockListType.soldOut
      ? ApiAndParams.apiSoldOutProducts
      : ApiAndParams.apiLowStockProducts;

  String get _title => widget.type == StockListType.soldOut
      ? getTranslatedValue(context, soldOutProductsLabel)
      : getTranslatedValue(context, lowStockProductsLabel);

  String get _headerLabel => widget.type == StockListType.soldOut
      ? getTranslatedValue(context, soldOutProductsLabel)
      : getTranslatedValue(context, lowStockProductsLabel);

  Color get _accentColor => widget.type == StockListType.soldOut
      ? const Color(0xFFEF4444)
      : const Color(0xFFF97316);

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (_currentPage < _lastPage && !_isLoadingMore) {
        _loadMore();
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
      final params = <String, dynamic>{
        'page': _currentPage.toString(),
        'per_page': '10',
      };
      if (_searchController.text.trim().isNotEmpty) {
        params['search'] = _searchController.text.trim();
      }

      final response = await sendApiRequest(
        apiName: _apiName,
        params: params,
        isPost: false,
      );

      final Map<String, dynamic> data = json.decode(response);
      final parsed = StockProductResponse.fromJson(data);

      if (parsed.status == 1 && parsed.data != null) {
        _currentPage = parsed.data!.currentPage ?? 1;
        _lastPage = parsed.data!.lastPage ?? 1;
        _totalCount = parsed.totalCount ?? 0;

        final newProducts = parsed.data!.data ?? [];

        setState(() {
          if (isRefresh) {
            _products = newProducts;
          } else {
            _products.addAll(newProducts);
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stock products: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: colorScheme.background,
          body: RefreshIndicator(
            onRefresh: () => _fetchProducts(isRefresh: true),
            color: _accentColor,
            backgroundColor: colorScheme.cardBackground,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: AppHeader(
                    label: _headerLabel,
                    title: '$_title ($_totalCount)',
                    showBackButton: true,
                    onBackPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                ),

                // Search bar
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

                // Content
                if (_isLoading)
                  SliverToBoxAdapter(child: _buildLoadingState(colorScheme))
                else if (_products.isEmpty)
                  SliverFillRemaining(
                      child: _buildEmptyState(colorScheme))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _products.length) {
                            return _buildLoadMoreIndicator(colorScheme);
                          }
                          return _buildProductCard(
                              _products[index], colorScheme);
                        },
                        childCount:
                            _products.length + (_isLoadingMore ? 1 : 0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(StockProduct product, dynamic colorScheme) {
    final imageUrl = product.imageUrl;
    final isSoldOut = product.stock == 0;
    final variant = product.variants?.isNotEmpty == true
        ? product.variants!.first
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Product image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.border, width: 1.5),
                color: colorScheme.surface,
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2_rounded,
                        size: 28,
                        color: colorScheme.iconSecondary,
                      ),
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
                      // Stock badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isSoldOut
                              ? getTranslatedValue(
                                  context, soldOutProductsLabel)
                              : 'Stock: ${product.stock} ${product.stockUnitName}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Category badge
                      if (product.category?.name != null)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDEEAFF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.category!.name!,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1E40AF),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Variant info
                  if (variant != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: variant.status == 1
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                variant.status == 1
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 10,
                                color: variant.status == 1
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                variant.status == 1 ? 'Available' : 'Out',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: variant.status == 1
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (product.variants != null &&
                            product.variants!.length > 1) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${product.variants!.length} variants',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(dynamic colorScheme) {
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
              height: 90,
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

  Widget _buildEmptyState(dynamic colorScheme) {
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
                widget.type == StockListType.soldOut
                    ? Icons.remove_shopping_cart_outlined
                    : Icons.inventory_2_outlined,
                size: 48,
                color: colorScheme.iconSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.type == StockListType.soldOut
                  ? 'No sold out products'
                  : 'No low stock products',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.type == StockListType.soldOut
                  ? 'All products are in stock'
                  : 'All products have sufficient stock',
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

  Widget _buildLoadMoreIndicator(dynamic colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: _accentColor,
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
