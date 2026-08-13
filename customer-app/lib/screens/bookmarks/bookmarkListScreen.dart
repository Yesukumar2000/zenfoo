import 'package:project/helper/styles/product_card_metrics.dart';
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/models/bookmarkTab.dart';
import 'package:project/models/combo.dart';
import 'package:project/provider/bookmarkListProvider.dart';
import 'package:project/provider/comboDetailProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/categoryProducts/widgets/product_card.dart';
import 'package:project/screens/combos/comboDetailScreen.dart';
import 'package:project/screens/supermartDetail/supermart_detail_screen.dart';
import 'package:project/screens/sweetHouseDetail/sweet_house_detail_screen.dart';

class BookmarkListScreen extends StatefulWidget {
  const BookmarkListScreen({Key? key}) : super(key: key);

  @override
  State<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends State<BookmarkListScreen> {
  int selectedTabIndex = 0;
  final Map<int, int> selectedItemIndex = {}; // Track selected item per tab
  final Map<String, BookmarkTabDataResponse> cachedTabData =
      {}; // Cache tab data
  bool _initialFetchDone =
      false; // Flag to ensure initial fetch happens only once

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      context.read<BookmarkListProvider>().fetchBookmarksList(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: getTranslatedValue(context, 'saved_items'),
          title: getTranslatedValue(context, 'bookmarks_label'),
          showBackButton: true,
        ),
      ),
      body: Consumer<BookmarkListProvider>(
        builder: (context, bookmarkProvider, child) {
          if (bookmarkProvider.state == BookmarkListState.loading) {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            );
          }

          if (bookmarkProvider.state == BookmarkListState.error) {
            return Center(
              child: Text(
                bookmarkProvider.errorMessage,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textSecondary,
                ),
              ),
            );
          }

          final bookmarkTabs = bookmarkProvider.bookmarkTabs;
          if (bookmarkTabs == null || bookmarkTabs.data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 64,
                    color: colorScheme.iconDisabled,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    getTranslatedValue(context, 'no_bookmarks_available'),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Trigger initial API call for first item of first tab
          if (!_initialFetchDone && bookmarkTabs.data.isNotEmpty) {
            _initialFetchDone = true;
            final firstTab = bookmarkTabs.data[0];
            if (firstTab.items.isNotEmpty) {
              Future.microtask(() => _fetchTabDataIfNeeded(firstTab, 0));
            }
          }

          return Column(
            children: [
              // Tab Navigation
              _buildTabNavigation(bookmarkTabs.data, colorScheme),
              // Item Navigation (horizontal scrollable items)
              if (bookmarkTabs.data[selectedTabIndex].items.isNotEmpty)
                _buildItemNavigation(
                  bookmarkTabs.data[selectedTabIndex],
                  colorScheme,
                ),
              // Tab Content - Show selected item details
              Expanded(
                child: _buildItemDetailContent(
                  bookmarkTabs.data[selectedTabIndex],
                  colorScheme,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabNavigation(
      List<BookmarkTab> tabs, AppColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isSelected = selectedTabIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedTabIndex = index;
                  selectedItemIndex[index] = 0; // Reset item selection
                });
                // Fetch data for first item in this tab if not cached
                // For combos, fetch even if items list is empty
                if (tab.tabType == 'combos' || tab.items.isNotEmpty) {
                  _fetchTabDataIfNeeded(tab, 0);
                }
              },
              child: Container(
                margin:
                    EdgeInsets.only(right: index != tabs.length - 1 ? 12 : 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? colorScheme.primary : colorScheme.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : colorScheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.3)
                            : colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tab.count.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : colorScheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildItemNavigation(BookmarkTab tab, AppColorScheme colorScheme) {
    final itemIndex = selectedItemIndex[selectedTabIndex] ?? 0;

    return Container(
      color: colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: List.generate(tab.items.length, (index) {
            final item = tab.items[index];
            final isSelected = itemIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedItemIndex[selectedTabIndex] = index;
                });
                _fetchTabDataIfNeeded(tab, index);
              },
              child: Container(
                margin: EdgeInsets.only(
                    right: index != tab.items.length - 1 ? 12 : 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? colorScheme.primary : colorScheme.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Item image thumbnail
                    if (item.image.isNotEmpty)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: colorScheme.surfaceVariant,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: item.image,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: isSelected
                                    ? Colors.white
                                    : colorScheme.primary,
                                strokeWidth: 1.5,
                              ),
                            ),
                            errorWidget: (context, url, error) => imgErrorWidget(iconSize: 16),
                          ),
                        ),
                      ),
                    if (item.image.isNotEmpty) const SizedBox(width: 8),
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : colorScheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildItemDetailContent(BookmarkTab tab, AppColorScheme colorScheme) {
    // For combos, skip the empty items check since data comes from API
    if (tab.items.isEmpty && tab.tabType != 'combos') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 64,
              color: colorScheme.iconDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              getTranslatedValue(context, 'no_bookmarks_in_category')
                  .replaceAll('{category}', tab.name),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Build cache key based on selected item ID
    final selectedIndex = selectedItemIndex[selectedTabIndex] ?? 0;
    final selectedItemId = selectedIndex < tab.items.length
        ? tab.items[selectedIndex].id
        : 0;
    final cacheKey = '${tab.tabType}_$selectedItemId';
    final tabData = cachedTabData[cacheKey];

    // Show loading state while fetching data
    if (tabData == null) {
      return Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      );
    }

    // Show empty state if API returned no data
    if (tabData.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 64,
              color: colorScheme.iconDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'No details available',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // For stores tab type, show products in a 2x2 grid
    if (tab.tabType == 'stores' && tabData.data.isNotEmpty) {
      return _buildStoresProductGrid(tabData.data, colorScheme);
    }

    // For combos tab type, show combos in a 2x2 grid
    if (tab.tabType == 'combos' && tabData.data.isNotEmpty) {
      return _buildCombosGrid(tabData.data, colorScheme);
    }

    // For sellers tab type, show all sellers as a list
    if (tab.tabType == 'sellers' && tabData.data.isNotEmpty) {
      final selectedTabItem = selectedIndex < tab.items.length
          ? tab.items[selectedIndex]
          : null;
      // isSuperMart comes from backend (once deployed).
      // Fallback: check store name until backend is deployed to Hostinger.
      final storeIsSuperMart = selectedTabItem?.isSuperMart == true ||
          (selectedTabItem?.name.toLowerCase().contains('super mart') ?? false);
      return _buildSellersList(tabData.data, colorScheme, storeIsSuperMart: storeIsSuperMart);
    }

    // For other tab types, show single detail card
    final detailedItem = tabData.data.isNotEmpty ? tabData.data[0] : null;

    // Guard against null detailedItem
    if (detailedItem == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 64,
              color: colorScheme.iconDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'No details available',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large item card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.border, width: 1),
              boxShadow: colorScheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: detailedItem.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: detailedItem.image,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => imgErrorWidget(iconSize: 40),
                          )
                        : imgErrorWidget(iconSize: 40),
                  ),
                ),
                // Name and info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detailedItem.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${detailedItem.id}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.textTertiary,
                        ),
                      ),
                      // Show price info if available (combos, products)
                      if (detailedItem.price > 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '₹${detailedItem.price.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.textPrimary,
                              ),
                            ),
                            if (detailedItem.discountPercentage != null &&
                                detailedItem.discountPercentage! > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${detailedItem.discountPercentage!.toStringAsFixed(1)}% OFF',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      // Show rating if available
                      if (detailedItem.rating != null &&
                          detailedItem.rating! > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: const Color(0xFFFFB800),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${detailedItem.rating!.toStringAsFixed(1)} (${detailedItem.ratingCount ?? 0})',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          _navigateToDetailScreen(
                            context,
                            BookmarkItem(
                              id: detailedItem.id,
                              name: detailedItem.name,
                              image: detailedItem.image,
                            ),
                            tab.tabType,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              getTranslatedValue(
                                  context, 'view_details_button'),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoresProductGrid(
    List<BookmarkTabDataItem> items,
    AppColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: productGridGutter,
          crossAxisSpacing: productGridGutter,
          mainAxisExtent: productCardExtent,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          // Use actual variant from API if available, otherwise create one from item data
          final variant = Variants(
            id: item.variants?.isNotEmpty == true
                ? item.variants![0].id
                : item.id.toString(),
            price: item.variants?.isNotEmpty == true
                ? item.variants![0].price
                : item.price.toStringAsFixed(0),
            discountedPrice: item.variants?.isNotEmpty == true
                ? item.variants![0].discountedPrice
                : item.discountedPrice?.toStringAsFixed(0),
            measurement: item.variants?.isNotEmpty == true
                ? item.variants![0].measurement ?? ''
                : '',
            stockUnitName: item.variants?.isNotEmpty == true
                ? item.variants![0].stockUnitName ?? ''
                : '',
            stock: item.variants?.isNotEmpty == true
                ? item.variants![0].stock ?? '999'
                : '999',
            isUnlimitedStock: item.variants?.isNotEmpty == true
                ? item.variants![0].isUnlimitedStock ?? '1'
                : '1',
            cartCount: item.variants?.isNotEmpty == true
                ? item.variants![0].cartCount ?? '0'
                : '0',
          );

          // Convert BookmarkTabDataItem to ProductListItem for display
          final product = ProductListItem(
            id: item.id.toString(),
            name: item.name,
            imageUrl: item.image,
            price: item.price.toInt(),
            discountedPrice: item.discountedPrice?.toInt(),
            averageRating: item.rating?.toStringAsFixed(1),
            ratingCount: item.ratingCount,
            sellerId: item.sellerId?.toString() ?? '',
            isBookmarked: item.isBookmarked,
            variants: [variant],
          );

          return MiniProductCardContainer(
            product: product,
            disableHero: false,
          );
        },
      ),
    );
  }

  Widget _buildCombosGrid(
    List<BookmarkTabDataItem> items,
    AppColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.55,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final combo = _convertBookmarkItemToCombo(item);

          return ComboProductCard(
            combo: combo,
            onView: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider<ComboDetailProvider>(
                        create: (_) => ComboDetailProvider(),
                      ),
                    ],
                    child: ComboDetailScreen(
                      comboId: item.id,
                    ),
                  ),
                ),
              );
            },
            onBookmark: () {
              setState(() {
                item.isBookmarked = !(item.isBookmarked ?? false);
              });
            },
          );
        },
      ),
    );
  }

  Combo _convertBookmarkItemToCombo(BookmarkTabDataItem item) {
    // Map BookmarkTabDataItem to Combo
    // This handles the full combo API response structure
    debugPrint("=== COMBO BOOKMARK DEBUG ===");
    debugPrint("name: ${item.name}");
    debugPrint("price: ${item.price}");
    debugPrint("totalProductPrice: ${item.totalProductPrice}");
    debugPrint("totalActualPrice: ${item.totalActualPrice}");
    debugPrint("discountPercentage: ${item.discountPercentage}");
    debugPrint("currency: ${item.currency}");
    return Combo(
      id: item.id,
      name: item.name,
      description: item.description,
      imageUrl: item.image,
      rating: item.rating,
      ratingCount: item.ratingCount,
      productCount: item.productCount,
      type: item.type,
      categoryType: item.categoryType,
      status: item.status,
      totalProductsPrice: item.totalProductPrice,
      totalActualPrice: item.totalActualPrice,
      discountPercentage: item.discountPercentage,
      currency: item.currency ?? '₹',
      isBookmarked: item.isBookmarked,
      isAlreadyAdded: item.isAlreadyAdded == true ? 1 : 0,
      cartQuantity: item.cartQuantity,
      products: item.products,
      stores: null, // Stores data not available in bookmark response
    );
  }

  Future<void> _fetchTabDataIfNeeded(BookmarkTab tab, int itemIndex) async {
    // For all tab types, require items to exist and itemIndex to be valid
    if (itemIndex >= tab.items.length) return;

    final item = tab.items[itemIndex];
    final id = item.id;

    // Create cache key based on tab type and item ID
    final cacheKey = '${tab.tabType}_${id}';

    // Return if already cached
    // if (cachedTabData.containsKey(cacheKey)) {
    //   return;
    // }

    // Fetch data for this specific item
    final response = await fetchBookmarkTabDataApi(
      context: context,
      tabType: tab.tabType,
      id: id,
    );

    if (response != null && mounted) {
      setState(() {
        cachedTabData[cacheKey] = response;
      });
    }
  }

  Widget _buildSellersList(
    List<BookmarkTabDataItem> items,
    AppColorScheme colorScheme, {
    bool storeIsSuperMart = false,
  }) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.border, width: 1),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo / image
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: (item.logoUrl?.isNotEmpty == true || item.image.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: item.logoUrl?.isNotEmpty == true ? item.logoUrl! : item.image,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              imgErrorWidget(iconSize: 40),
                        )
                      : imgErrorWidget(iconSize: 40),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (item.rating != null && item.rating! > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              size: 14, color: const Color(0xFFFFB800)),
                          const SizedBox(width: 4),
                          Text(
                            '${item.rating!.toStringAsFixed(1)} (${item.ratingCount ?? 0})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _navigateToDetailScreen(
                        context,
                        BookmarkItem(
                          id: item.id,
                          name: item.name,
                          image: item.logoUrl ?? item.image,
                        ),
                        'sellers',
                        isSuperMart: storeIsSuperMart || item.isSuperMart == true,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            getTranslatedValue(context, 'view_details_button'),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToDetailScreen(
    BuildContext context,
    BookmarkItem item,
    String tabType, {
    bool isSuperMart = false,
  }) {
    if (tabType == 'stores') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SupermartDetailScreen(
            sellerId: item.id,
          ),
        ),
      );
    } else if (tabType == 'sellers') {
      if (isSuperMart) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SupermartDetailScreen(
              sellerId: item.id,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SweetHouseDetailScreen(
              sellerId: item.id.toString(),
            ),
          ),
        );
      }
    } else if (tabType == 'combos') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComboDetailScreen(
            comboId: item.id,
          ),
        ),
      );
    }
  }
}
