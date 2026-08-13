import 'package:project/helper/styles/product_card_metrics.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_groups.dart';
import 'package:project/models/store_with_category_group.dart';
import 'package:project/screens/categoryProducts/category_products_page.dart';
import 'package:project/screens/categoryProducts/widgets/banners_home.dart';
import 'package:project/screens/categoryProducts/widgets/product_card.dart';
import 'package:project/screens/mainHomeScreen/categoryPage/category_product_provider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class MeatCategoryScreen extends StatefulWidget {
  final CategoryGroup group;
  final StoreSeller? supermart;

  const MeatCategoryScreen({
    required this.group,
    this.supermart,
    super.key,
  });

  @override
  State<MeatCategoryScreen> createState() => _MeatCategoryScreenState();
}

class _MeatCategoryScreenState extends State<MeatCategoryScreen> {
  int _selectedIdx = 0;
  late final CategoryProductProvider _provider;

  List<SubCategoryGroup> get _subGroups => widget.group.subCategoryGroups;

  @override
  void initState() {
    super.initState();
    _provider = CategoryProductProvider(
      _subGroups.isNotEmpty ? _subGroups[0].id : 0,
    );
    if (_subGroups.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _provider.loadInitial(context);
      });
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  void _selectSubGroup(int i) {
    if (_selectedIdx == i) return;
    setState(() => _selectedIdx = i);
    _provider.switchSubGroup(context, _subGroups[i].id);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: '',
          title: widget.group.name,
          showBackButton: true,
        ),
      ),
      body: SafeArea(
        top: false,
        child: ChangeNotifierProvider.value(
          value: _provider,
          child: Consumer<CategoryProductProvider>(
            builder: (context, provider, _) {
              // Left rail (sub-category groups) stays full height; the search
              // bar + banner live inside the right content column so they sit
              // beside the rail (not spanning the full width above it).
              return Row(
                children: [
                  _buildSidebar(colorScheme),
                  Expanded(
                    child: _buildRightContent(context, provider, colorScheme),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // LEFT SIDEBAR — SubCategoryGroups
  Widget _buildSidebar(AppColorScheme colorScheme) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: colorScheme.border, width: 1),
        ),
        boxShadow: colorScheme.cardShadow,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        itemCount: _subGroups.length,
        itemBuilder: (ctx, i) {
          final sub = _subGroups[i];
          final isSelected = _selectedIdx == i;
          return GestureDetector(
            onTap: () => _selectSubGroup(i),
            child: Stack(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.15)
                              : colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child:
                              (sub.imageUrl != null && sub.imageUrl!.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: sub.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          Shimmer.fromColors(
                                        baseColor: const Color(0xFFE0E0E0),
                                        highlightColor: const Color(0xFFF5F5F5),
                                        child: Container(color: Colors.white),
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    )
                                  : const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    top: 8,
                    bottom: 8,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(3)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // RIGHT PANEL — search bar + banner + category chips + product grid.
  // Everything scrolls together; the chips stay pinned below the banner.
  Widget _buildRightContent(BuildContext context,
      CategoryProductProvider provider, AppColorScheme colorScheme) {
    final showChips = !provider.loading && provider.categories.length > 1;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200 &&
            provider.hasMore &&
            !provider.loadingMore) {
          provider.loadProducts(context);
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Search bar (tap to open full product search) + banner.
          SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                getTapToSearchBar(
                  context: context,
                  compact: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChangeNotifierProvider<ProductSearchProvider>(
                        create: (_) => ProductSearchProvider(),
                        child: ProductSearchScreen(
                          sellerId: widget.supermart?.id,
                        ),
                      ),
                    ),
                  ),
                ),
                if (provider.banners.isNotEmpty)
                  BannerCarousel(
                    mediaUrls:
                        provider.banners.map((e) => e.imageUrl).toList(),
                    interval: const Duration(seconds: 4),
                  ),
              ],
            ),
          ),

          // Category chips (e.g. Oils / Ghee / Massala) — pinned below banner.
          if (showChips)
            SliverPersistentHeader(
              pinned: true,
              delegate: _ChipHeaderDelegate(
                height: 52,
                child: Container(
                  color: colorScheme.background,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: CategoryChipRow(
                    categories:
                        provider.categories.map((e) => e.name).toList(),
                    selectedIndex: provider.selectedCategoryIdx,
                    onSelected: (i) => provider.selectCategory(context, i),
                  ),
                ),
              ),
            ),

          // Products / shimmer / empty state.
          if (provider.loading)
            _buildProductShimmerSliver(colorScheme)
          else if (provider.products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No products found',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.textSecondary,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  productGridPagePadding, 6, productGridPagePadding, 120),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: productGridGutter,
                  crossAxisSpacing: productGridGutter,
                  mainAxisExtent: productCardExtent,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, idx) {
                    if (idx >= provider.products.length) {
                      return _buildShimmerCard(colorScheme);
                    }
                    return MiniProductCardContainer(
                      product: provider.products[idx],
                    );
                  },
                  childCount: provider.products.length +
                      (provider.loadingMore ? 2 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductShimmerSliver(AppColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          productGridPagePadding, 6, productGridPagePadding, 120),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: productGridGutter,
          crossAxisSpacing: productGridGutter,
          mainAxisExtent: productCardExtent,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, __) => _buildShimmerCard(colorScheme),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildShimmerCard(AppColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

// Pinned header that keeps the category chip row visible while scrolling.
class _ChipHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _ChipHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: height, child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _ChipHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}
