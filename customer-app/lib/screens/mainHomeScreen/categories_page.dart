// ignore_for_file: deprecated_member_use

import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/helper/generalWidgets/catalogue_image.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_groups.dart';
import 'package:project/provider/comboDetailProvider.dart';
import 'package:project/screens/categoryProducts/category_products_page.dart';
import 'package:project/screens/combos/comboDetailScreen.dart';
import 'package:project/screens/mainHomeScreen/categoryPage/category_page_provider.dart';
import 'package:project/screens/categoryProducts/widgets/banners_home.dart';
import 'package:project/screens/mainHomeScreen/widgets/animated_arrows_indicator.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:project/models/combo.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:velocity_x/velocity_x.dart';

class CategoriesPage extends StatelessWidget {
  final Combo? combo; // ✅ Optional combo parameter
  final ScrollController? scrollController;

  const CategoriesPage({
    super.key,
    this.combo,
    this.scrollController,
  });

  // Check if we're in "Add Extra Items" mode
  bool get isAddExtraMode => combo != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return ChangeNotifierProvider(
      create: (_) => CategoriesPageProvider(
        context,
        scrollController: scrollController,
      )..loadStores(context),
      child: Consumer<CategoriesPageProvider>(
        builder: (ctx, provider, _) {
          return Scaffold(
            backgroundColor: colorScheme.background,
            appBar: PreferredSize(
              preferredSize: Size(double.infinity, double.maxFinite),
              child: AppHeader(
                title: isAddExtraMode
                    ? getTranslatedValue(context, 'add_to_combo')
                        .replaceAll('{comboName}', combo?.name ?? '')
                    : getTranslatedValue(context, 'categories_header'),
                label: getTranslatedValue(context, 'select_category'),
              ),
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    // _categoriesHeader(context),
                    Expanded(
                      child: Row(
                        children: [
                          // LEFT SIDEBAR - Store Selector
                          _buildLeftSidebar(provider, context),

                          // RIGHT PANEL - Selected group's subcategories
                          _buildGroupContent(provider, context),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============ LEFT SIDEBAR ============
  Widget _buildLeftSidebar(
      CategoriesPageProvider provider, BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: colorScheme.background,
        border: Border(
          right: BorderSide(
            color: colorScheme.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: (provider.loadingStores ||
              (provider.allGroups.isEmpty && provider.loadingCategories))
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView.builder(
              controller: provider.leftSidebarController,
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: provider.allGroups.length,
              itemBuilder: (ctx, i) {
                final store = provider.allGroups[i];
                final isSelected = provider.selectedGroupIdx == i;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    provider.selectGroup(i);
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
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  // color: colorScheme.primary
                                  //     .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: AnimatedSlide(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      curve: Curves.easeOut,
                                      offset: isSelected
                                          ? Offset.zero
                                          : const Offset(0, 0.30),
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: store.id == 0
                                            ? Image.asset(
                                                'assets/animations/home_tab.png',
                                                width: 32,
                                                height: 32,
                                                fit: BoxFit.contain,
                                              )
                                            : (store.imageUrl?.isNotEmpty ??
                                                    false)
                                                ? CachedNetworkImage(
                                                    imageUrl: store.imageUrl!,
                                                    fit: BoxFit.contain,
                                                    placeholder: (context, url) => Shimmer.fromColors(
                                                      baseColor: const Color(0xFFE0E0E0),
                                                      highlightColor: const Color(0xFFF5F5F5),
                                                      child: Container(color: Colors.white),
                                                    ),
                                                    errorWidget: (context, url, error) => Icon(
                                                      Icons.store_rounded,
                                                      size: 24,
                                                      color: isSelected ? colorScheme.iconSecondary : colorScheme.primary,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.store_rounded,
                                                    size: 24,
                                                    color: isSelected
                                                        ? colorScheme
                                                            .iconSecondary
                                                        : colorScheme.primary,
                                                  ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: GoogleFonts.inter(
                                  color: isSelected
                                      ? colorScheme.textPrimary
                                      : colorScheme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  height: 1.2,
                                  letterSpacing: -0.1,
                                ),
                                child: Text(
                                  store.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 4,
                              decoration: BoxDecoration(
                                gradient: colorScheme.primaryGradient,
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

  // ============ RIGHT PANEL ============
  Widget _buildRightPanel(
      CategoriesPageProvider provider, BuildContext context) {
    final isAllMode = provider.selectedStoreIdx == 0;
    final isEmpty = provider.selectedStoreDetail.isEmpty && !isAllMode;

    return Expanded(
      child: provider.loadingCategories
          ? _buildCategoriesShimmer()
          : isEmpty
              ? _buildEmptyState(context)
              : RefreshConfiguration(
                  enableBallisticLoad: false,
                  dragSpeedRatio: 0.5,
                  footerTriggerDistance: 85,
                  headerTriggerDistance: 85,
                  child: SmartRefresher(
                    key: ValueKey(isAddExtraMode),
                    controller: provider.refreshController,
                    enablePullDown: provider.hasPreviousStore,
                    enablePullUp: provider.hasNextStore,
                    onRefresh: provider.onRefresh,
                    onLoading: provider.onLoadMore,
                    physics: ClampingScrollPhysics(),
                    header: CustomHeader(
                      height: 110,
                      builder: (headerContext, mode) {
                        return _buildRefreshHeader(
                            headerContext, mode, provider.previousStoreName);
                      },
                    ),
                    footer: CustomFooter(
                      height: 120,
                      builder: (footerContext, mode) {
                        return _buildLoadFooter(
                            footerContext, mode, provider.nextStoreName);
                      },
                    ),
                    child: CustomScrollView(
                      controller: provider.scrollController,
                      physics: ClampingScrollPhysics(),
                      slivers: [
                        // Sliders/Banners - Sliding carousel (from store sliders)
                        if (provider.selectedStoreDetail.isNotEmpty &&
                            provider.selectedStoreDetail[0].sliders.isNotEmpty)
                          SliverToBoxAdapter(
                            child: BannerCarousel(
                              mediaUrls: provider.selectedStoreDetail[0].sliders
                                  .map((e) => e.imageUrl ?? '')
                                  .where((e) => e.isNotEmpty)
                                  .toList(),
                              interval: const Duration(seconds: 4),
                            ),
                          )
                        else if (provider.banners.isNotEmpty)
                          // Fallback to banners if no store sliders
                          SliverToBoxAdapter(
                            child: BannerCarousel(
                              mediaUrls: provider.banners
                                  .map((e) => e.imageUrl)
                                  .toList(),
                              interval: const Duration(seconds: 4),
                            ),
                          ),

                        // Section Header
                        // SliverToBoxAdapter(
                        //   child: _buildSectionHeader(provider, context),
                        // ),

                        // Category indicators at top
                        if (provider.showScrollUpIndicator &&
                            provider.previousCategoryName != null)
                          SliverToBoxAdapter(
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  provider.scrollToPreviousCategory();
                                },
                                child: _buildCategoryIndicator(
                                  provider.previousCategoryName!,
                                  isDown: false,
                                ),
                              ),
                            ),
                          ),
                        // Show combos first when in "All" mode
                        if (!isAddExtraMode && provider.combos.isNotEmpty)
                          _buildCombosSection(provider, context),

                        // Show categories grid (always, including in "All" mode)
                        if (provider.selectedStoreDetail.isNotEmpty)
                          _buildCategoriesGrid(provider, context),

                        // Category indicators at bottom
                        if (provider.showScrollDownIndicator &&
                            provider.nextCategoryName != null)
                          SliverToBoxAdapter(
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  provider.scrollToNextCategory();
                                },
                                child: _buildCategoryIndicator(
                                  provider.nextCategoryName!,
                                  isDown: true,
                                ),
                              ),
                            ),
                          ),

                        // Bottom padding
                        SliverToBoxAdapter(
                          child: SizedBox(height: 100),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ============ GROUP CONTENT (selected group's subcategories) ============
  Widget _buildGroupContent(
      CategoriesPageProvider provider, BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final groups = provider.allGroups;

    if (groups.isEmpty) {
      return Expanded(
        child: provider.loadingCategories
            ? _buildCategoriesShimmer()
            : _buildEmptyState(context),
      );
    }

    final idx = provider.selectedGroupIdx.clamp(0, groups.length - 1);
    final cg = groups[idx];
    final subs = cg.subCategoryGroups;

    return Expanded(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Search bar (tap to open full product search)
          if (!isAddExtraMode)
            SliverToBoxAdapter(
              child: getTapToSearchBar(
                context: context,
                compact: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChangeNotifierProvider<ProductSearchProvider>(
                      create: (_) => ProductSearchProvider(),
                      child: ProductSearchScreen(),
                    ),
                  ),
                ),
              ),
            ),

          // Banner carousel
          if (provider.banners.isNotEmpty)
            SliverToBoxAdapter(
              child: BannerCarousel(
                mediaUrls:
                    provider.banners.map((e) => e.imageUrl).toList(),
                interval: const Duration(seconds: 4),
              ),
            ),

          // Selected group title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Text(
                cg.name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.3,
                  color: colorScheme.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
          ),

          // Subcategory cards grid
          if (subs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'No categories found',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final sub = subs[i];
                    return _GroupSubCard(
                      sub: sub,
                      onTap: () {
                        if (isAddExtraMode) {
                          _showProductsBottomSheet(context, sub.id, sub.name);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductScreen(
                                subCategoryGroupId: sub.id,
                                title: sub.name,
                                siblingSubGroups: subs,
                                siblingGroups: groups,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                  childCount: subs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============ SECTION HEADER ============
  Widget _buildSectionHeader(
      CategoriesPageProvider provider, BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final currentStore = provider.stores.isNotEmpty &&
            provider.selectedStoreIdx < provider.stores.length
        ? provider.stores[provider.selectedStoreIdx]
        : null;

    int totalCategories = 0;
    for (var store in provider.selectedStoreDetail!) {
      totalCategories += store.categoryGroups.length;
    }
  
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Store Icon
          if (currentStore?.imageUrl?.isNotEmpty == true)
            Container(
              width: 42,
              height: 42,
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.border,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: currentStore!.imageUrl!,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: const Color(0xFFE0E0E0),
                    highlightColor: const Color(0xFFF5F5F5),
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            ),
          SizedBox(width: currentStore?.imageUrl?.isNotEmpty == true ? 14 : 0),

          // Store Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAddExtraMode
                      ? getTranslatedValue(context, 'add_extra_items_header')
                      : (currentStore?.name ??
                          getTranslatedValue(context, 'categories_header')),
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                // const SizedBox(height: 4),
                // Text(
                //   isAddExtraMode
                //       ? getTranslatedValue(context, 'customize_combo').replaceAll('{comboName}', combo?.name ?? "your combo")
                //       : getTranslatedValue(context, 'categories_available').replaceAll('{count}', totalCategories.toString()),
                //   style: GoogleFonts.inter(
                //     color: colorScheme.textSecondary,
                //     fontSize: 13,
                //     fontWeight: FontWeight.w500,
                //     height: 1.15,
                //     letterSpacing: -0.2,
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ CATEGORIES GRID ============
  Widget _buildCategoriesGrid(
      CategoriesPageProvider provider, BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final allCategories = <MapEntry<String, dynamic>>[];
          for (var store in provider.selectedStoreDetail) {
            for (var cg in store.categoryGroups) {
              allCategories.add(MapEntry(cg.id.toString(), cg));
            }
          }

          if (index >= allCategories.length) return null;

          final entry = allCategories[index];
          final CategoryGroup cg = entry.value;

          return Container(
            key: provider.getCategoryKey(entry.key),
            color: colorScheme.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Header
                Container(
                  padding: EdgeInsets.fromLTRB(8, 16, 8, 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          cg.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.3,
                            color: colorScheme.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                      // Text(
                      //   getTranslatedValue(context, 'items_available').replaceAll('{count}', cg.subCategoryGroups.length.toString()),
                      //   style: GoogleFonts.inter(
                      //     fontSize: 13,
                      //     fontWeight: FontWeight.w500,
                      //     color: colorScheme.textSecondary,
                      //     letterSpacing: -0.2,
                      //     height: 1.15,
                      //   ),
                      // ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                // Subcategories Grid
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: cg.subCategoryGroups.length,
                    // Fixed row height rather than a ratio: the card is a
                    // fixed stack (100 image + gap + two lines of name), so a
                    // ratio only bought dead space that grew with the screen.
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      mainAxisExtent: _subCategoryCardExtent,
                    ),
                    itemBuilder: (ctx, idx) {
                      final sub = cg.subCategoryGroups[idx];
                      return _SubCategoryCard(
                        sub: sub,
                        cg: cg,
                        onTap: () {
                          if (isAddExtraMode) {
                            // Open as bottom sheet in add extra mode
                            _showProductsBottomSheet(
                              context,
                              sub.id,
                              sub.name,
                            );
                          } else {
                            // Navigate normally
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryProductScreen(
                                  subCategoryGroupId: sub.id,
                                  title: sub.name,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          );
        },
        childCount: () {
          int count = 0;
          for (var store in provider.selectedStoreDetail) {
            count += store.categoryGroups.length;
          }
          return count;
        }(),
      ),
    );
  }

  // ============ COMBOS SECTION ============
  Widget _buildCombosSection(
      CategoriesPageProvider provider, BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            // Combos header
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslatedValue(context, 'combos'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: -0.3,
                      color: colorScheme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            );
          }

          if (index == 1) {
            // Combos Grid
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: provider.combos.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 2,
                  childAspectRatio: 0.5,
                ),
                itemBuilder: (ctx, idx) {
                  final combo = provider.combos[idx];
                  return ComboProductCard(
                    combo: combo,
                    onView: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider(
                            create: (_) => ComboDetailProvider(),
                            child: ComboDetailScreen(
                              comboId: combo.id ?? 0,
                            ),
                          ),
                        ),
                      );
                    },
                    onBookmark: () async {
                      // Toggle bookmark
                      combo.isBookmarked = !(combo.isBookmarked ?? false);

                      // Call API
                      final result = await toggleComboBookmarkApi(
                        context: context,
                        comboId: combo.id!,
                      );

                      if (result != null && result['status'] == 1) {
                        showMessage(
                          context,
                          result['message'] ?? 'Bookmark updated',
                          MessageType.success,
                        );
                        // Refresh the combos list to update all cards
                        context.read<HomeScreenProvider>().fetchHomeCombos(context);
                      } else {
                        // Revert the toggle if API call failed
                        combo.isBookmarked = !(combo.isBookmarked ?? false);
                        showMessage(
                          context,
                          result?['message'] ?? 'Failed to update bookmark',
                          MessageType.error,
                        );
                      }
                    },
                  );
                },
              ),
            );
          }

          return null;
        },
        childCount: 2,
      ),
    );
  }

  // ============ PRODUCTS BOTTOM SHEET ============
  void _showProductsBottomSheet(
    BuildContext context,
    int subCategoryGroupId,
    String title,
  ) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.primary,
      useSafeArea: true,
      builder: (context) {
        return Container(
          // height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            // color: colorScheme.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Expanded(
                child: CategoryProductsBottomSheet(
                  subCategoryGroupId: subCategoryGroupId,
                  title: title,
                  combo: combo,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============ CATEGORIES SHIMMER ============
  Widget _buildCategoriesShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header shimmer
          const _ShimmerContainer(
            height: 24,
            width: 150,
            borderRadius: 8,
          ),
          const SizedBox(height: 20),

          // Category grid shimmer
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 2,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (ctx, idx) {
                return const _ShimmerCategoryCard();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============ EMPTY STATE ============
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    return Center(
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
              isAddExtraMode
                  ? Icons.add_shopping_cart
                  : Icons.category_outlined,
              size: 56,
              color: colorScheme.iconSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isAddExtraMode
                ? getTranslatedValue(context, 'no_items_available')
                : getTranslatedValue(context, 'no_categories_available'),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorScheme.textPrimary,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            getTranslatedValue(context, 'try_selecting_different_store'),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.textSecondary,
              letterSpacing: -0.2,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ============ HEADER ============
  Widget _categoriesHeader(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isAddExtraMode ? colorScheme.primary : colorScheme.primary,
            colorScheme.surface,
          ],
          stops: [0.0, 0.7],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            // Premium Title with Icon
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  if (isAddExtraMode)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.surface.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black.withValues(alpha: 0.9),
                          size: 22,
                        ),
                      ),
                    ),
                  if (isAddExtraMode) SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAddExtraMode
                              ? getTranslatedValue(
                                  context, 'add_extra_items_header')
                              : getTranslatedValue(
                                  context, 'categories_header'),
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: colorScheme.textPrimary,
                            letterSpacing: -0.7,
                          ),
                        ),
                        if (isAddExtraMode) ...[
                          SizedBox(height: 3),
                          Text(
                            combo?.name ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                              color: colorScheme.textSecondary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============ HELPER WIDGETS ============

  Widget _buildRefreshHeader(
      BuildContext context, RefreshStatus? mode, String? storeName) {
    if (mode == RefreshStatus.canRefresh) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedArrowsIndicator(
            isUp: false,
            color: Color(0xFF3B82F6),
            size: 28,
          ),
          SizedBox(height: 2),
          Text(
            getTranslatedValue(context, 'release_to_browse'),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 4),
          Text(
            storeName ?? getTranslatedValue(context, 'previous_store'),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3B82F6),
            ),
          ),
        ],
      );
    } else if (mode == RefreshStatus.refreshing) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Color(0xFF3B82F6),
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            getTranslatedValue(context, 'loading_store')
                .replaceAll('{storeName}', storeName ?? ""),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: const Color(0xFF111827),
              letterSpacing: -0.3,
              height: 1.15,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Color(0xFF3B82F6).withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedArrowsIndicator(
            isUp: false,
            color: Color(0xFF9E9E9E),
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            getTranslatedValue(context, 'pull_for_store').replaceAll(
                '{storeName}',
                storeName ?? getTranslatedValue(context, 'previous_store')),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadFooter(
      BuildContext context, LoadStatus? mode, String? storeName) {
    if (mode == LoadStatus.canLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            storeName ?? getTranslatedValue(context, 'next_store'),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9AC444),
            ),
          ),
          SizedBox(height: 4),
          Text(
            getTranslatedValue(context, 'release_to_browse'),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 10),
          AnimatedArrowsIndicator(
            isUp: true,
            color: Color(0xFF9AC444),
            size: 28,
          ),
        ],
      );
    } else if (mode == LoadStatus.loading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Color(0xFF9AC444),
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            getTranslatedValue(context, 'loading_store')
                .replaceAll('{storeName}', storeName ?? ""),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: const Color(0xFF111827),
              letterSpacing: -0.3,
              height: 1.15,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.white,
            Color(0xFF9AC444).withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedArrowsIndicator(
            isUp: true,
            color: Color(0xFF9E9E9E),
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            getTranslatedValue(context, 'pull_for_store').replaceAll(
                '{storeName}',
                storeName ?? getTranslatedValue(context, 'next_store')),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIndicator(String categoryName, {required bool isDown}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1200),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (isDown ? 5 : -5) * sin(value * 3.14159 * 2)),
          child: Opacity(
            opacity: 0.95,
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDown
                ? [Color(0xFF9AC444), Color(0xFF87B23D)]
                : [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: (isDown ? Color(0xFF9AC444) : Color(0xFF3B82F6))
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDown) ...[
              Icon(Icons.keyboard_arrow_up_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                categoryName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isDown) ...[
              SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ============ SUBCATEGORY CARD ============

/// The card is a fixed stack, so its grid gets a fixed row height:
/// 100 image + 6 gap + two lines of 12px name at 1.15 line height (27.6, up).
const double _subCategoryCardImage = 100;
const double _subCategoryCardGap = 6;
const double _subCategoryCardNameBlock = 28;
const double _subCategoryCardExtent = _subCategoryCardImage +
    _subCategoryCardGap +
    _subCategoryCardNameBlock;

class _SubCategoryCard extends StatelessWidget {
  final dynamic sub;
  final VoidCallback onTap;
  final CategoryGroup cg;

  const _SubCategoryCard({
    required this.sub,
    required this.onTap,
    required this.cg,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Image Container
          Container(
            clipBehavior: cg.id == 9 ? Clip.none : Clip.antiAlias,
            width: double.infinity,
            height: _subCategoryCardImage,
            decoration: cg.id == 9
                ? null
                : ShapeDecoration(
                    color: const Color(0xFFF8FFEB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x23000000),
                        blurRadius: 4,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                      )
                    ],
                  ),
            padding: EdgeInsets.all(12),
            child: CatalogueImage(
              url: sub.imageUrl,
              fallbackIcon: Icons.category_outlined,
            ),
          ),

          const SizedBox(height: _subCategoryCardGap),
          // Name — fixed two-line block so labels share a baseline across
          // the row instead of floating at their own heights.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: _subCategoryCardNameBlock,
              child: Text(
                sub.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textPrimary,
                  height: 1.15,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large white subcategory card used in the categories page right panel
/// (image on top, bold centered label below).
class _GroupSubCard extends StatelessWidget {
  final dynamic sub;
  final VoidCallback onTap;

  const _GroupSubCard({
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final hasImage = sub.imageUrl?.isNotEmpty == true;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: colorScheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CatalogueImage(
                  url: hasImage ? sub.imageUrl : null,
                  borderRadius: 10,
                  fallbackIcon: Icons.category_outlined,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Text(
                sub.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryProductsBottomSheet extends StatelessWidget {
  final int subCategoryGroupId;
  final String title;
  final Combo? combo;

  const CategoryProductsBottomSheet({
    Key? key,
    required this.subCategoryGroupId,
    required this.title,
    this.combo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CategoryProductScreen(
      key: ValueKey('bottomSheet_$subCategoryGroupId'), // new key
      subCategoryGroupId: subCategoryGroupId,
      title: title,
      isBottomSheet: true,
      combo: combo,
    );
  }
}

// ============ SHIMMER WIDGETS ============
class _ShimmerContainer extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const _ShimmerContainer({
    required this.height,
    this.width,
    required this.borderRadius,
  });

  @override
  State<_ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<_ShimmerContainer>
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
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.shimmerBase,
                colorScheme.shimmerHighlight,
                colorScheme.shimmerBase,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerCategoryCard extends StatefulWidget {
  const _ShimmerCategoryCard();

  @override
  State<_ShimmerCategoryCard> createState() => _ShimmerCategoryCardState();
}

class _ShimmerCategoryCardState extends State<_ShimmerCategoryCard>
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
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.border,
              width: 1,
            ),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            children: [
              // Image shimmer
              Container(
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      colorScheme.shimmerBase,
                      colorScheme.shimmerHighlight,
                      colorScheme.shimmerBase,
                    ],
                    stops: [
                      _animation.value - 0.3,
                      _animation.value,
                      _animation.value + 0.3,
                    ].map((e) => e.clamp(0.0, 1.0)).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Title shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        colorScheme.shimmerBase,
                        colorScheme.shimmerHighlight,
                        colorScheme.shimmerBase,
                      ],
                      stops: [
                        _animation.value - 0.3,
                        _animation.value,
                        _animation.value + 0.3,
                      ].map((e) => e.clamp(0.0, 1.0)).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        colorScheme.shimmerBase,
                        colorScheme.shimmerHighlight,
                        colorScheme.shimmerBase,
                      ],
                      stops: [
                        _animation.value - 0.3,
                        _animation.value,
                        _animation.value + 0.3,
                      ].map((e) => e.clamp(0.0, 1.0)).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
