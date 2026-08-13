import 'package:project/helper/styles/product_card_metrics.dart';
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_groups.dart';
import 'package:project/models/seller_category_tree.dart';
import 'package:project/models/seller_product_list.dart';
import 'package:project/models/store_with_category_group.dart';
import 'package:project/screens/categoryProducts/widgets/product_card.dart';
import 'package:project/screens/mainHomeScreen/homeScreen/widget/categories_grid.dart';

class SupermartDetailScreen extends StatefulWidget {
  final int? sellerId;

  const SupermartDetailScreen({
    Key? key,
    required this.sellerId,
  }) : super(key: key);

  @override
  State<SupermartDetailScreen> createState() => _SupermartDetailScreenState();
}

class _SupermartDetailScreenState extends State<SupermartDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  int _currentTabIndex = 0;
  bool _isTabBarStuck = false;

  StoreSeller? seller;
  bool isLoadingSeller = true;

  SellerCategoryTree? categoryTree;
  bool isLoadingCategories = true;

  List<SellerProductList> productLists = [];
  bool isLoadingProductLists = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSeller();
      _loadCategoryGroups();
      _loadProductLists();
    });
  }

  Future<void> _loadSeller() async {
    if (widget.sellerId == null) {
      setState(() {
        isLoadingSeller = false;
      });
      return;
    }

    setState(() {
      isLoadingSeller = true;
    });

    try {
      // Fetch seller data by ID
      final response = await fetchSupermartSellers(
        context,
        perPage: 100,
        page: 1,
        sellerId: widget.sellerId,
      );

      if (response?.data != null && response!.data.isNotEmpty) {
        // Find the seller with matching ID
        StoreSeller? foundSeller;
        try {
          foundSeller = response.data.firstWhere(
            (s) => s.id == widget.sellerId,
          );
        } catch (e) {
          foundSeller = null;
        }

        if (mounted) {
          setState(() {
            seller = foundSeller;
            isLoadingSeller = false;
          });
          // categories loaded separately via widget.sellerId
        }
      } else {
        if (mounted) {
          setState(() {
            seller = null;
            isLoadingSeller = false;
            isLoadingCategories = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading seller: $e');
      if (mounted) {
        setState(() {
          seller = null;
          isLoadingSeller = false;
          isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _loadCategoryGroups() async {
    if (widget.sellerId == null) {
      setState(() => isLoadingCategories = false);
      return;
    }

    setState(() {
      isLoadingCategories = true;
    });

    final tree = await fetchSellerCategoryTree(
      context,
      sellerId: widget.sellerId!,
    );

    if (mounted) {
      setState(() {
        categoryTree = tree;
        isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadProductLists() async {
    setState(() {
      isLoadingProductLists = true;
    });

    final response = await fetchSellerProductLists(
      context,
      sellerId: widget.sellerId ?? 0,
    );
    setState(() {
      productLists = response?.productLists ?? [];
      isLoadingProductLists = false;
    });
  }

  // Tapping the store search bar opens the category browse experience
  // (the same screen reachable from the Categories tab), landing on the
  // first available sub-category group. Falls back to global product search
  // when this store has no categories loaded yet.
  // Tapping the store search bar opens a text search scoped to THIS store
  // (only this super-mart seller's products are returned).
  void _openStoreSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ProductSearchProvider>(
          create: (_) => ProductSearchProvider(),
          child: ProductSearchScreen(sellerId: seller?.id),
        ),
      ),
    );
  }

  double? get minimumPrice {
    double? minPrice;

    for (final list in productLists) {
      for (final product in list.products) {
        if (product.variants != null && product.variants!.isNotEmpty) {
          for (final variant in product.variants!) {
            final price = double.tryParse(
                variant.discountedPrice ?? variant.price ?? '0');
            if (price != null && price > 0) {
              if (minPrice == null || price < minPrice) {
                minPrice = price;
              }
            }
          }
        }
      }
    }

    return minPrice;
  }

  void _scrollListener() {
    final isStuck = _scrollController.offset >= 180;
    if (isStuck != _isTabBarStuck) {
      setState(() {
        _isTabBarStuck = isStuck;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _loadSeller(),
                _loadCategoryGroups(),
                _loadProductLists(),
              ]);
            },
            color: colorScheme.primary,
            child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _StoreImageHeaderDelegate(
                  onBackTap: () => Navigator.of(context).pop(),
                  onShareTap: () {
                    SharePlus.instance.share(ShareParams(text: 'https://play.google.com/store/apps/details?id=com.zenfoo.customer'));
                  },
                  onBookmarkTap: () async {
                    if (seller == null) return;

                    // Toggle bookmark
                    seller!.isBookmarked = !(seller!.isBookmarked ?? false);
                    setState(() {});

                    // Call API
                    final result = await toggleSellerBookmarkApi(
                      context: context,
                      sellerId: seller!.id!,
                    );

                    if (result != null && result['status'] == 1) {
                      showMessage(
                        context,
                        result['message'] ?? 'Bookmark updated',
                        MessageType.success,
                      );
                    } else {
                      // Revert the toggle if API call failed
                      seller!.isBookmarked = !(seller!.isBookmarked ?? false);
                      setState(() {});
                      showMessage(
                        context,
                        result?['message'] ?? 'Failed to update bookmark',
                        MessageType.error,
                      );
                    }
                  },
                  isBookmarked: seller?.isBookmarked ?? false,
                  seller: seller,
                  minimumPrice: minimumPrice,
                ),
              ),
              // Full-width search bar below the store title.
              SliverToBoxAdapter(
                child: Container(
                  color: colorScheme.background,
                  child: getTapToSearchBar(
                    context: context,
                    onTap: _openStoreSearch,
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  tabController: _tabController,
                  isStuck: _isTabBarStuck,
                  topPadding: MediaQuery.of(context).padding.top,
                ),
              ),
              if (_currentTabIndex == 0)
                ..._buildExploreSlivers(colorScheme)
              else
                ..._buildCategoriesSlivers(colorScheme),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
          ),
          if (context.watch<CartProvider>().totalItemsCount > 0)
            PositionedDirectional(
              bottom: 20,
              start: 0,
              end: 0,
              child: CartOverlay(),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildExploreSlivers(AppColorScheme colorScheme) {
    if (isLoadingProductLists) {
      return [
        SliverToBoxAdapter(
          child: _ProductListsShimmer(colorScheme: colorScheme),
        ),
      ];
    }

    // Collect all unique products from all lists
    final seen = <String>{};
    final allProducts = <ProductListItem>[];
    for (final list in productLists) {
      for (final p in list.products) {
        final key = p.id ?? '';
        if (key.isNotEmpty && seen.add(key)) {
          allProducts.add(p);
        }
      }
    }

    if (allProducts.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _EmptyProductsState(colorScheme: colorScheme),
        ),
      ];
    }

    // Sort by rating desc for Top Rated section
    final topRated = List<ProductListItem>.from(allProducts)
      ..sort((a, b) {
        final ra = double.tryParse(a.averageRating ?? '0') ?? 0;
        final rb = double.tryParse(b.averageRating ?? '0') ?? 0;
        return rb.compareTo(ra);
      });

    // Split all products into two equal halves
    final half = (allProducts.length / 2).ceil();
    final firstHalf = allProducts.sublist(0, half);
    final secondHalf = allProducts.sublist(half);

    Widget buildSection(String title, List<ProductListItem> products) {
      if (products.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.55,
                    height: 1.02,
                  ),
                ),
                GestureDetector(
                  onTap: () => _tabController.animateTo(1),
                  child: Icon(Icons.arrow_forward, size: 20, color: colorScheme.textPrimary),
                ),
              ],
            ),
          ),
          SizedBox(
            height: productCardExtent,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: productRailCardWidth,
                child: MiniProductCardContainer(product: products[index], disableHero: true),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    return [
      SliverToBoxAdapter(child: buildSection('Top Rated Products', topRated)),
      if (firstHalf.isNotEmpty)
        SliverToBoxAdapter(child: buildSection('Top Selling Picks', firstHalf)),
      if (secondHalf.isNotEmpty)
        SliverToBoxAdapter(child: buildSection('Hot & Trending', secondHalf)),
    ];
  }

  List<Widget> _buildCategoriesSlivers(AppColorScheme colorScheme) {
    if (isLoadingCategories) {
      return [
        SliverToBoxAdapter(
          child: _CategoriesShimmer(colorScheme: colorScheme),
        ),
      ];
    }

    final hasGroups = categoryTree?.categoryGroups.isNotEmpty == true;

    if (!hasGroups) {
      return [
        SliverToBoxAdapter(
          child: _EmptyCategoriesState(colorScheme: colorScheme),
        ),
      ];
    }

    // Convert SellerCategoryGroup → CategoryGroup for use with CategoryGroupsList
    final List<CategoryGroup> groups = categoryTree!.categoryGroups
        .map((g) => CategoryGroup(
              id: g.id,
              name: g.name,
              imageUrl: g.imageUrl,
              subCategoryGroups: g.subCategoryGroups
                  .map((s) => SubCategoryGroup(
                        id: s.id,
                        name: s.name,
                        imageUrl: s.imageUrl,
                        categoryGroupId: s.categoryGroupId,
                        subcategoryIds: s.subcategoryIds,
                        isGroup: s.isGroup,
                      ))
                  .toList(),
            ))
        .toList();

    return [
      SliverToBoxAdapter(
        child: CategoryGroupsList(groups: groups, supermart: seller),
      ),
    ];
  }
}

class _StoreImageHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onBackTap;
  final VoidCallback onShareTap;
  final VoidCallback onBookmarkTap;
  final bool isBookmarked;
  final StoreSeller? seller;
  final double? minimumPrice;

  _StoreImageHeaderDelegate({
    required this.onBackTap,
    required this.onShareTap,
    required this.onBookmarkTap,
    required this.isBookmarked,
    this.seller,
    required this.minimumPrice,
  });

  @override
  double get minExtent => 180;

  @override
  double get maxExtent => 350;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final progress = shrinkOffset / maxExtent;
    final String storeImageUrl = seller?.logoUrl ?? '';

    return Container(
      height: maxExtent - shrinkOffset,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        image: storeImageUrl.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(storeImageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ActionButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconSize: 18,
                      onTap: onBackTap,
                      colorScheme: colorScheme,
                    ),
                    Row(
                      children: [
                        _ActionButton(
                          icon: isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border_rounded,
                          iconSize: 22,
                          onTap: onBookmarkTap,
                          isActive: isBookmarked,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 10),
                        _ActionButton(
                          icon: Icons.share_outlined,
                          iconSize: 20,
                          onTap: onShareTap,
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (progress < 0.3 && seller != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: StoreInfoCard(
                storeName: seller!.storeName ?? seller!.name ?? '',
                storeDescription: seller!.storeDescription,
                storeLocation: seller!.storeLocation,
                distanceKm: seller!.distanceKm,
                travelTimeMin: seller!.travelTimeMin,
                minimumPrice: minimumPrice,
                rating: seller!.rating,
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StoreImageHeaderDelegate oldDelegate) {
    return isBookmarked != oldDelegate.isBookmarked ||
        seller != oldDelegate.seller ||
        minimumPrice != oldDelegate.minimumPrice;
  }

  @override
  OverScrollHeaderStretchConfiguration get stretchConfiguration =>
      OverScrollHeaderStretchConfiguration();
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final bool isStuck;
  final double topPadding;

  _TabBarDelegate({
    required this.tabController,
    required this.isStuck,
    required this.topPadding,
  });

  @override
  double get minExtent => isStuck ? 56 + topPadding : 56;

  @override
  double get maxExtent => isStuck ? 56 + topPadding : 56;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Container(
      padding: EdgeInsets.only(top: isStuck ? topPadding : 0),
      color: colorScheme.surface,
      child: Column(
        children: [
          TabBar(
            controller: tabController,
            indicatorColor: colorScheme.primary,
            indicatorWeight: 5,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
            dividerColor: Colors.transparent,
            labelColor: colorScheme.textPrimary,
            unselectedLabelColor: colorScheme.textSecondary,
            labelStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.02,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              height: 1.02,
            ),
            tabs: [
              Tab(text: getTranslatedValue(context, 'explore_tab')),
              Tab(text: getTranslatedValue(context, 'categories_tab')),
            ],
          ),
          Container(
            height: 1,
            color: colorScheme.border,
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return isStuck != oldDelegate.isStuck ||
        topPadding != oldDelegate.topPadding;
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;
  final bool isActive;
  final AppColorScheme colorScheme;

  const _ActionButton({
    required this.icon,
    required this.iconSize,
    required this.onTap,
    required this.colorScheme,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: isActive ? colorScheme.primaryGradient : null,
          color: isActive ? null : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : colorScheme.border.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : colorScheme.cardShadowColor,
              blurRadius: isActive ? 12 : 8,
              offset: Offset(0, isActive ? 4 : 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: isActive ? Colors.white : colorScheme.iconPrimary,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

class StoreInfoCard extends StatelessWidget {
  final String storeName;
  final String? storeDescription;
  final String? storeLocation;
  final String? distanceKm;
  final String? travelTimeMin;
  final double? minimumPrice;
  final double? rating;

  const StoreInfoCard({
    super.key,
    required this.storeName,
    this.storeDescription,
    this.storeLocation,
    this.distanceKm,
    this.travelTimeMin,
    this.minimumPrice,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  storeName,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (rating != null && rating! > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${rating!.toStringAsFixed(1)} ${rating! >= 4.0 ? 'Excellent' : rating! >= 3.5 ? 'Very Good' : 'Good'}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.02,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (storeDescription != null && storeDescription!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              storeDescription!,
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Column(
            children: [
              if (travelTimeMin != null || distanceKm != null)
                _InfoRow(
                  icon: Icons.directions_bike_outlined,
                  text: [
                    if (travelTimeMin != null) 'Fast Delivery: $travelTimeMin',
                    if (distanceKm != null) distanceKm!,
                  ].join(' | '),
                  iconColor: colorScheme.primary,
                  colorScheme: colorScheme,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  final AppColorScheme colorScheme;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.02,
              letterSpacing: -0.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductListsShimmer extends StatefulWidget {
  final AppColorScheme colorScheme;

  const _ProductListsShimmer({Key? key, required this.colorScheme})
      : super(key: key);

  @override
  State<_ProductListsShimmer> createState() => _ProductListsShimmerState();
}

class _ProductListsShimmerState extends State<_ProductListsShimmer>
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < 3; i++) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      colors: [
                        widget.colorScheme.shimmerBase,
                        widget.colorScheme.shimmerHighlight,
                        widget.colorScheme.shimmerBase,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment(_animation.value - 1, 0),
                      end: Alignment(_animation.value, 0),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: productCardExtent,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: productRailCardWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.colorScheme.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.colorScheme.border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 130,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    widget.colorScheme.shimmerBase,
                                    widget.colorScheme.shimmerHighlight,
                                    widget.colorScheme.shimmerBase,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                  begin: Alignment(_animation.value - 1, 0),
                                  end: Alignment(_animation.value, 0),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: LinearGradient(
                                        colors: [
                                          widget.colorScheme.shimmerBase,
                                          widget.colorScheme.shimmerHighlight,
                                          widget.colorScheme.shimmerBase,
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                        begin:
                                            Alignment(_animation.value - 1, 0),
                                        end: Alignment(_animation.value, 0),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 80,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: LinearGradient(
                                        colors: [
                                          widget.colorScheme.shimmerBase,
                                          widget.colorScheme.shimmerHighlight,
                                          widget.colorScheme.shimmerBase,
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                        begin:
                                            Alignment(_animation.value - 1, 0),
                                        end: Alignment(_animation.value, 0),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                        colors: [
                                          widget.colorScheme.shimmerBase,
                                          widget.colorScheme.shimmerHighlight,
                                          widget.colorScheme.shimmerBase,
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                        begin:
                                            Alignment(_animation.value - 1, 0),
                                        end: Alignment(_animation.value, 0),
                                      ),
                                    ),
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
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  final AppColorScheme colorScheme;

  const _EmptyProductsState({Key? key, required this.colorScheme})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 60,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              getTranslatedValue(context, 'no_products_available'),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              getTranslatedValue(context, 'no_products_available_message'),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: colorScheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesShimmer extends StatefulWidget {
  final AppColorScheme colorScheme;

  const _CategoriesShimmer({Key? key, required this.colorScheme})
      : super(key: key);

  @override
  State<_CategoriesShimmer> createState() => _CategoriesShimmerState();
}

class _CategoriesShimmerState extends State<_CategoriesShimmer>
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int groupIndex = 0; groupIndex < 2; groupIndex++) ...[
                Container(
                  width: 120,
                  height: 20,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      colors: [
                        widget.colorScheme.shimmerBase,
                        widget.colorScheme.shimmerHighlight,
                        widget.colorScheme.shimmerBase,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment(_animation.value - 1, 0),
                      end: Alignment(_animation.value, 0),
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Container(
                          width: 72,
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                widget.colorScheme.shimmerBase,
                                widget.colorScheme.shimmerHighlight,
                                widget.colorScheme.shimmerBase,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              begin: Alignment(_animation.value - 1, 0),
                              end: Alignment(_animation.value, 0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: [
                                widget.colorScheme.shimmerBase,
                                widget.colorScheme.shimmerHighlight,
                                widget.colorScheme.shimmerBase,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              begin: Alignment(_animation.value - 1, 0),
                              end: Alignment(_animation.value, 0),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyCategoriesState extends StatelessWidget {
  final AppColorScheme colorScheme;

  const _EmptyCategoriesState({Key? key, required this.colorScheme})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 60,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              getTranslatedValue(context, 'no_categories_available'),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              getTranslatedValue(context, 'no_categories_available_message'),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: colorScheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
