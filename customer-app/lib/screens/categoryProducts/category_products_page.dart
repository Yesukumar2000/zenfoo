import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/helper/styles/appColorScheme.dart' as app_theme;
import 'package:project/helper/styles/product_card_metrics.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/combo.dart';
import 'package:project/models/category_groups.dart';
import 'package:project/models/store_with_category_group.dart';
import 'package:project/screens/categoryProducts/widgets/banners_home.dart';
import 'package:project/screens/categoryProducts/widgets/product_card.dart';
import 'package:project/screens/mainHomeScreen/categoryPage/category_product_provider.dart';
import 'package:project/models/sortby_filter_model.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

/// Fish-store cards carry the extra Before/After/Pieces box, so they keep the
/// taller cell they have always had — 420 is what their old 0.42 ratio produced
/// at the previous card width. Everything else on this page uses the app-wide
/// [productCardExtent].
const double _fishProductCellExtent = 420;

class CategoryProductScreen extends StatefulWidget {
  final int subCategoryGroupId;
  final String title;
  final int? initialSelectedCategoryId; // Pre-select a specific category by ID

  // NEW
  final Combo? combo; // pass combo when used for "add extra"
  final StoreSeller? supermart; // pass supermart when used for "add extra"
  final bool isBottomSheet; // true when shown inside a sheet
  // Sibling sub-category groups (e.g. Atta Rice & Dal, Oil & Ghee, Masala's)
  // shown as a top chip row so the user can switch sub-groups in place.
  final List<SubCategoryGroup>? siblingSubGroups;
  // Top-level category groups (e.g. Groceries & Kitchen, Snacks & Drinks)
  // shown as the topmost chip row — switching a group swaps the sub-group row.
  final List<CategoryGroup>? siblingGroups;

  const CategoryProductScreen({
    super.key,
    required this.subCategoryGroupId,
    required this.title,
    this.initialSelectedCategoryId,
    this.combo,
    this.supermart,
    this.isBottomSheet = false,
    this.siblingSubGroups,
    this.siblingGroups,
  });

  @override
  State<CategoryProductScreen> createState() => _CategoryProductScreenState();
}

class _CategoryProductScreenState extends State<CategoryProductScreen>
    with SingleTickerProviderStateMixin {
  bool _showSearchAndBanner = true;
  // Categories render in the left vertical sidebar (restored); the sticky
  // header's bottom chip row shows Type chips ("All", ...) instead.
  final bool _showSidebar = true;
  late AnimationController _shimmerController;
  bool showNextCategoryHint = false;
  bool showPrevCategoryHint = false;
  double _topOverscroll = 0.0;
  double _bottomOverscroll = 0.0;
  bool _isSwitchingActive = false; // Prevents jumping multiple categories
  int? _previousCategoryIdx;

  // Currently selected sub-group (for the top sibling chip row + heading).
  late String _subGroupTitle;
  late int _currentSubGroupId;
  // Currently selected top-level group (for the group chip row).
  int _currentGroupId = -1;

  // Sub-groups to show in the sub-group row: the selected group's children when
  // a group list is provided, otherwise the static siblingSubGroups.
  List<SubCategoryGroup> get _currentSubGroups {
    if (widget.siblingGroups != null) {
      for (final g in widget.siblingGroups!) {
        if (g.id == _currentGroupId) return g.subCategoryGroups;
      }
    }
    return widget.siblingSubGroups ?? const [];
  }

  @override
  void initState() {
    super.initState();
    _subGroupTitle = widget.title;
    _currentSubGroupId = widget.subCategoryGroupId;
    // Find which group the initial sub-group belongs to.
    if (widget.siblingGroups != null) {
      for (final g in widget.siblingGroups!) {
        if (g.subCategoryGroups.any((s) => s.id == widget.subCategoryGroupId)) {
          _currentGroupId = g.id;
          break;
        }
      }
    }
    // Initialize shimmer animation controller
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    // Scroll listener will be attached after provider is created
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(
      ScrollNotification notification, CategoryProductProvider provider) {
    // LOCK: Ignore all scroll events during a transition cooldown
    if (provider.isSwitchingCategory || _isSwitchingActive) {
      if (showNextCategoryHint || showPrevCategoryHint) {
        setState(() {
          showNextCategoryHint = false;
          showPrevCategoryHint = false;
          _bottomOverscroll = 0;
          _topOverscroll = 0;
        });
      }
      return false;
    }

    final metrics = notification.metrics;
    final pixels = metrics.pixels;

    // ----- Banner hide/show logic -----
    final shouldShow = pixels < 50;
    if (shouldShow != _showSearchAndBanner) {
      setState(() => _showSearchAndBanner = shouldShow);
    }

    // ----- Detect bottom of list for Pagination/Hint -----
    if (pixels > metrics.maxScrollExtent) {
      final overscroll = pixels - metrics.maxScrollExtent;
      if (provider.hasMore && !provider.loadingMore && overscroll > 20) {
        provider.loadProducts(context);
      } else if (!provider.hasMore && !provider.loadingMore) {
        final currentIndex = provider.selectedCategoryIdx;
        if (currentIndex < provider.categories.length - 1) {
          // Dead zone of 15px before showing the hint
          if (overscroll > 15) {
            if (!showNextCategoryHint) {
              setState(() => showNextCategoryHint = true);
            }
            // Update overscroll amount for dynamic feedback
            setState(() => _bottomOverscroll = overscroll.clamp(0, 100));
          } else {
            if (showNextCategoryHint) {
              setState(() {
                showNextCategoryHint = false;
                _bottomOverscroll = 0;
              });
            }
          }

          // Trigger NEXT: Pull up past threshold
          if (overscroll > 80) {
            _previousCategoryIdx = currentIndex;
            _isSwitchingActive = true;
            provider.selectCategory(context, currentIndex + 1);

            setState(() {
              showNextCategoryHint = false;
              _bottomOverscroll = 0;
            });

            // Unlock after transition duration + buffer
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) setState(() => _isSwitchingActive = false);
            });

            HapticFeedback.mediumImpact();
          }
        }
      }
    } else {
      if (showNextCategoryHint) {
        setState(() {
          showNextCategoryHint = false;
          _bottomOverscroll = 0;
        });
      }
    }

    // ----- Detect top of list for PREV Hint -----
    if (pixels < 0) {
      final overscroll = pixels.abs();
      final currentIndex = provider.selectedCategoryIdx;
      if (currentIndex > 0) {
        // Dead zone of 15px before showing the hint
        if (overscroll > 15) {
          if (!showPrevCategoryHint) {
            setState(() => showPrevCategoryHint = true);
          }
          // Update overscroll amount for dynamic feedback
          setState(() => _topOverscroll = overscroll.clamp(0, 100));
        } else {
          if (showPrevCategoryHint) {
            setState(() {
              showPrevCategoryHint = false;
              _topOverscroll = 0;
            });
          }
        }

        // Trigger PREV: Pull down past threshold
        if (overscroll > 80) {
          _previousCategoryIdx = currentIndex;
          _isSwitchingActive = true;
          provider.selectCategory(context, currentIndex - 1);

          setState(() {
            showPrevCategoryHint = false;
            _topOverscroll = 0;
          });

          // Unlock after transition duration + buffer
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => _isSwitchingActive = false);
          });

          HapticFeedback.mediumImpact();
        }
      }
    } else {
      if (showPrevCategoryHint) {
        setState(() {
          showPrevCategoryHint = false;
          _topOverscroll = 0;
        });
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return ChangeNotifierProvider(
      create: (_) => CategoryProductProvider(
        widget.subCategoryGroupId,
        initialSelectedCategoryId: widget.initialSelectedCategoryId,
      )..loadInitial(context),
      child: Consumer<CategoryProductProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: colorScheme.background,
            appBar: PreferredSize(
              preferredSize: Size(double.infinity, double.maxFinite),
              child: AppHeader(
                label: widget.supermart != null
                    ? getTranslatedValue(context, 'select_items_to_add')
                    : (widget.isBottomSheet && widget.combo != null
                        ? getTranslatedValue(context, 'select_items_to_add')
                        : getTranslatedValue(context, 'categories_header')),
                title: widget.supermart != null
                    ? getTranslatedValue(context, 'add_to_item')
                        .replaceAll('{name}', widget.supermart!.storeName ?? '')
                    : (widget.isBottomSheet && widget.combo != null
                        ? getTranslatedValue(context, 'add_to_item')
                            .replaceAll('{name}', widget.combo!.name ?? '')
                        : widget.title),
                showBackButton: true,
              ),
            ),
            body: SafeArea(
              top: false,
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Visibility(
                      //   visible: !(widget.isBottomSheet && widget.combo != null),
                      //   child: categoriesHeader(
                      //     context,
                      //     widget.isBottomSheet && widget.combo != null
                      //         ? 'Add Extra Items'
                      //         : widget.title,
                      //     colorScheme,
                      //   ),
                      // ),
                      Expanded(
                        child: Row(
                          children: [
                            // LEFT SIDEBAR - Categories (hidden; replaced by the
                            // horizontal CategoryChipRow in the sticky header)
                            if (_showSidebar)
                              Container(
                              width: 72,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                border: Border(
                                  right: BorderSide(
                                    color: colorScheme.border,
                                    width: 1,
                                  ),
                                ),
                                boxShadow: colorScheme.cardShadow,
                              ),
                              child: Column(
                                children: [
                                  // Categories List
                                  Expanded(
                                    child: provider.loading
                                        ? ListView.builder(
                                            itemCount: 6,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 6),
                                            itemBuilder: (_, i) =>
                                                _buildCategoryShimmer(
                                                    colorScheme),
                                          )
                                        : ListView.builder(
                                            controller:
                                                provider.leftSidebarController,
                                            padding: const EdgeInsets.only(
                                                top: 12, bottom: 100),
                                            itemCount:
                                                provider.categories.length,
                                            itemBuilder: (ctx, i) {
                                              final cat =
                                                  provider.categories[i];
                                              final isSelected = provider
                                                      .selectedCategoryIdx ==
                                                  i;

                                              return GestureDetector(
                                                onTap: () {
                                                  _previousCategoryIdx =
                                                      provider
                                                          .selectedCategoryIdx;
                                                  provider.selectCategory(
                                                      context, i);
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 200),
                                                  child: Stack(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 8,
                                                                horizontal: 6),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            // Image container
                                                            Container(
                                                              width: 48,
                                                              height: 48,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: colorScheme
                                                                    .primary
                                                                    .withValues(
                                                                        alpha:
                                                                            0.1),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              child: ClipOval(
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          6),
                                                                  child:
                                                                      AnimatedSlide(
                                                                    duration: const Duration(
                                                                        milliseconds:
                                                                            220),
                                                                    curve: Curves
                                                                        .easeOut,
                                                                    offset: isSelected
                                                                        ? Offset
                                                                            .zero
                                                                        : const Offset(
                                                                            0,
                                                                            0.30),
                                                                    child:
                                                                        FittedBox(
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      child: (cat.imageUrl?.isNotEmpty ??
                                                                              false)
                                                                          ? Image
                                                                              .network(
                                                                              cat.imageUrl!,
                                                                            )
                                                                          : Icon(
                                                                              Icons.category_rounded,
                                                                              size: 24,
                                                                              color: isSelected ? colorScheme.iconDisabled : colorScheme.primary,
                                                                            ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(
                                                                height: 6),
                                                            // Category Name
                                                            Text(
                                                              cat.name,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: GoogleFonts
                                                                  .inter(
                                                                color: isSelected
                                                                    ? colorScheme
                                                                        .textPrimary
                                                                    : colorScheme
                                                                        .textSecondary,
                                                                fontSize: 10,
                                                                fontWeight: isSelected
                                                                    ? FontWeight
                                                                        .w600
                                                                    : FontWeight
                                                                        .w500,
                                                                height: 1.2,
                                                                letterSpacing:
                                                                    -0.1,
                                                              ),
                                                              maxLines: 3,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      // Selection Indicator
                                                      if (isSelected)
                                                        Positioned(
                                                          right: 0,
                                                          top: 0,
                                                          bottom: 0,
                                                          child: Container(
                                                            width: 4,
                                                            decoration:
                                                                BoxDecoration(
                                                              gradient: colorScheme
                                                                  .primaryGradient,
                                                              borderRadius:
                                                                  const BorderRadius
                                                                      .only(
                                                                topLeft: Radius
                                                                    .circular(
                                                                        12),
                                                                bottomLeft: Radius
                                                                    .circular(
                                                                        12),
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
                                  ),
                                ],
                              ),
                            ),

                            // RIGHT PANEL - Products
                            Expanded(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) =>
                                    _handleScrollNotification(
                                        notification, provider),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  transitionBuilder: (child, animation) {
                                    final isEntering = child.key ==
                                        ValueKey(provider.selectedCategoryIdx);
                                    final isNext =
                                        provider.selectedCategoryIdx >
                                            (_previousCategoryIdx ?? 0);

                                    // Slide up if going next, slide down if going prev
                                    final double slideOffset =
                                        isNext ? 0.08 : -0.08;

                                    return isEntering
                                        ? FadeTransition(
                                            opacity: animation,
                                            child: SlideTransition(
                                              position: animation.drive(Tween(
                                                  begin: Offset(0, slideOffset),
                                                  end: Offset.zero)),
                                              child: child,
                                            ),
                                          )
                                        : FadeTransition(
                                            opacity: animation,
                                            child: SlideTransition(
                                              position: animation.drive(Tween(
                                                  begin:
                                                      Offset(0, -slideOffset),
                                                  end: Offset.zero)),
                                              child: child,
                                            ),
                                          );
                                  },
                                  child: CustomScrollView(
                                    key: ValueKey(provider.selectedCategoryIdx),
                                    physics: const BouncingScrollPhysics(
                                        parent:
                                            AlwaysScrollableScrollPhysics()),
                                    slivers: [
                                      // Search and Banner - Animated visibility
                                      SliverToBoxAdapter(
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                          height:
                                              _showSearchAndBanner ? null : 0,
                                          child: AnimatedOpacity(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            opacity: _showSearchAndBanner
                                                ? 1.0
                                                : 0.0,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Search bar (tap to open full product search)
                                                if (!widget.isBottomSheet)
                                                  getTapToSearchBar(
                                                    context: context,
                                                    compact: true,
                                                    // Scope search to this store
                                                    // when inside a super mart.
                                                    onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ChangeNotifierProvider<
                                                                ProductSearchProvider>(
                                                          create: (_) =>
                                                              ProductSearchProvider(),
                                                          child:
                                                              ProductSearchScreen(
                                                            sellerId: widget
                                                                .supermart?.id,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                if (provider.banners.isNotEmpty)
                                                  BannerCarousel(
                                                    mediaUrls: provider.banners
                                                        .map((e) => e.imageUrl)
                                                        .toList(),
                                                    interval: const Duration(
                                                        seconds: 4),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Top-level group chips
                                      // (Groceries & Kitchen, Snacks & Drinks, ...)
                                      // Commented out — hidden per request.
                                      /*
                                      if (!widget.isBottomSheet &&
                                          (widget.siblingGroups?.length ?? 0) > 1)
                                        SliverToBoxAdapter(
                                          child: Container(
                                            color: colorScheme.background,
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 12, 16, 0),
                                            child: CategoryChipRow(
                                              categories: widget.siblingGroups!
                                                  .map((e) => e.name)
                                                  .toList(),
                                              selectedIndex: widget.siblingGroups!
                                                  .indexWhere(
                                                      (e) => e.id == _currentGroupId),
                                              onSelected: (i) {
                                                final g =
                                                    widget.siblingGroups![i];
                                                if (g.id == _currentGroupId ||
                                                    g.subCategoryGroups.isEmpty) {
                                                  return;
                                                }
                                                final firstSub =
                                                    g.subCategoryGroups.first;
                                                setState(() {
                                                  _currentGroupId = g.id;
                                                  _currentSubGroupId = firstSub.id;
                                                  _subGroupTitle = firstSub.name;
                                                });
                                                provider.switchSubGroup(
                                                    context, firstSub.id);
                                              },
                                            ),
                                          ),
                                        ),
                                      */

                                      // Sibling sub-group chips
                                      // (Atta Rice & Dal, Oil & Ghee, Masala's, ...)
                                      // Commented out for now — not needed.
                                      /*
                                      if (!widget.isBottomSheet &&
                                          _currentSubGroups.length > 1)
                                        SliverToBoxAdapter(
                                          child: Container(
                                            color: colorScheme.background,
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 12, 16, 4),
                                            child: CategoryChipRow(
                                              categories: _currentSubGroups
                                                  .map((e) => e.name)
                                                  .toList(),
                                              selectedIndex: _currentSubGroups
                                                  .indexWhere((e) =>
                                                      e.id == _currentSubGroupId),
                                              onSelected: (i) {
                                                final sub = _currentSubGroups[i];
                                                if (sub.id == _currentSubGroupId) {
                                                  return;
                                                }
                                                setState(() {
                                                  _currentSubGroupId = sub.id;
                                                  _subGroupTitle = sub.name;
                                                });
                                                provider.switchSubGroup(
                                                    context, sub.id);
                                              },
                                            ),
                                          ),
                                        ),
                                      */

                                      // Sticky Header - Item Details and Filter Chips
                                      SliverPersistentHeader(
                                        pinned: true,
                                        delegate: _StickyHeaderDelegate(
                                          colorScheme: colorScheme,
                                          child: Container(
                                            color: colorScheme.background,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Products Section Header
                                                // (title + type chips) commented
                                                // out — removing the empty header
                                                // space above the filter bar.
                                                /*
                                                Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.surface,
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color:
                                                            colorScheme.border,
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Top row: Title + item count + filter button
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                // Sub-group heading
                                                                // commented out
                                                                // for now — not
                                                                // needed.
                                                                /*
                                                                Text(
                                                                  _subGroupTitle,
                                                                  style:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    color: colorScheme
                                                                        .textPrimary,
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    height: 1.2,
                                                                    letterSpacing:
                                                                        -0.3,
                                                                  ),
                                                                ),
                                                                */
                                                                // const SizedBox(
                                                                //     height: 2),
                                                                // Text(
                                                                //   getTranslatedValue(
                                                                //           context,
                                                                //           'items_available')
                                                                //       .replaceAll(
                                                                //           '{count}',
                                                                //           provider
                                                                //               .products
                                                                //               .length
                                                                //               .toString()),
                                                                //   style: GoogleFonts
                                                                //       .inter(
                                                                //     color: colorScheme
                                                                //         .textSecondary,
                                                                //     fontSize: 12,
                                                                //     fontWeight:
                                                                //         FontWeight
                                                                //             .w500,
                                                                //     height: 1.3,
                                                                //     letterSpacing:
                                                                //         -0.1,
                                                                //   ),
                                                                // ),
                                                              ],
                                                            ),
                                                          ),

                                                          // Filter Button
                                                          // GestureDetector(
                                                          //   onTap: () {
                                                          //     showUnifiedFilterSheet(
                                                          //         context);
                                                          //   },
                                                          //   child: Container(
                                                          //     padding:
                                                          //         const EdgeInsets
                                                          //             .symmetric(
                                                          //             horizontal: 12,
                                                          //             vertical: 8),
                                                          //     decoration:
                                                          //         BoxDecoration(
                                                          //       color: colorScheme
                                                          //           .primary
                                                          //           .withValues(
                                                          //               alpha: 0.1),
                                                          //       borderRadius:
                                                          //           BorderRadius
                                                          //               .circular(8),
                                                          //       border: Border.all(
                                                          //         color: colorScheme
                                                          //             .primary
                                                          //             .withValues(
                                                          //                 alpha: 0.3),
                                                          //         width: 1,
                                                          //       ),
                                                          //     ),
                                                          //     child: Row(
                                                          //       mainAxisSize:
                                                          //           MainAxisSize.min,
                                                          //       children: [
                                                          //         Icon(
                                                          //           Icons
                                                          //               .tune_rounded,
                                                          //           size: 16,
                                                          //           color: colorScheme
                                                          //               .primary,
                                                          //         ),
                                                          //         const SizedBox(
                                                          //             width: 4),
                                                          //         Text(
                                                          //           getTranslatedValue(
                                                          //               context,
                                                          //               'filter_button'),
                                                          //           style: GoogleFonts
                                                          //               .inter(
                                                          //             color:
                                                          //                 colorScheme
                                                          //                     .primary,
                                                          //             fontSize: 12,
                                                          //             fontWeight:
                                                          //                 FontWeight
                                                          //                     .w600,
                                                          //             letterSpacing:
                                                          //                 -0.1,
                                                          //           ),
                                                          //         ),
                                                          //       ],
                                                          //     ),
                                                          //   ),
                                                          // ),
                                                        ],
                                                      ),

                                                      // Bottom row: Type chips
                                                      // (All, Refined, Cold
                                                      // Pressed, ...) — categories
                                                      // now live in the left sidebar.
                                                      // Commented out for now —
                                                      // not needed.
                                                      /*
                                                      const SizedBox(
                                                          height: 12),
                                                      TypeChipRow(
                                                        types: provider
                                                            .categoryTypes
                                                            .map((e) => e.name)
                                                            .toList(),
                                                        selectedType: provider
                                                            .selectedType,
                                                        onTypeSelected: (type) {
                                                          provider
                                                              .selectType(type);
                                                          // Reload products
                                                          provider.loadProducts(
                                                              context,
                                                              initial: true);
                                                        },
                                                      ),
                                                      */
                                                    ],
                                                  ),
                                                ),
                                                */

                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8),
                                                  child: FilterChipBar(
                                                    filters: [
                                                      FilterChipData(
                                                        label:
                                                            getTranslatedValue(
                                                                context,
                                                                'sort_by_chip'),
                                                        isSelected: provider
                                                                    .selectedSort !=
                                                                'relevance' &&
                                                            provider.selectedSort !=
                                                                'Relevance',
                                                        onTap: () =>
                                                            showUnifiedFilterSheet(
                                                                context,
                                                                initialTab: 0),
                                                      ),
                                                      FilterChipData(
                                                        label:
                                                            getTranslatedValue(
                                                                context,
                                                                'price_chip'),
                                                        isSelected: provider
                                                                    .priceRange
                                                                    .start >
                                                                provider
                                                                    .totalMinPrice ||
                                                            provider.priceRange
                                                                    .end <
                                                                provider
                                                                    .totalMaxPrice,
                                                        onTap: () =>
                                                            showUnifiedFilterSheet(
                                                                context,
                                                                initialTab: 4),
                                                      ),
                                                      FilterChipData(
                                                        label:
                                                            getTranslatedValue(
                                                                context,
                                                                'brands_chip'),
                                                        isSelected: provider
                                                            .selectedBrandIds
                                                            .isNotEmpty,
                                                        onTap: () =>
                                                            showUnifiedFilterSheet(
                                                                context,
                                                                initialTab: 1),
                                                      ),
                                                      FilterChipData(
                                                        label:
                                                            getTranslatedValue(
                                                                context,
                                                                'type_chip'),
                                                        isSelected: provider
                                                                    .selectedType !=
                                                                null &&
                                                            provider
                                                                .selectedType!
                                                                .isNotEmpty,
                                                        onTap: () =>
                                                            showUnifiedFilterSheet(
                                                                context,
                                                                initialTab: 2),
                                                      ),
                                                      FilterChipData(
                                                        label:
                                                            getTranslatedValue(
                                                                context,
                                                                'size_chip'),
                                                        isSelected: provider
                                                            .selectedSizes
                                                            .isNotEmpty,
                                                        onTap: () =>
                                                            showUnifiedFilterSheet(
                                                                context,
                                                                initialTab: 3),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // First row of products (up to 3), shown
                                      // before the Shop By Brands strip.
                                      if (provider.products.isNotEmpty)
                                        SliverPadding(
                                          padding: const EdgeInsets.fromLTRB(
                                              productGridPagePadding,
                                              2,
                                              productGridPagePadding,
                                              2),
                                          sliver: SliverGrid(
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              mainAxisSpacing: productGridGutter,
                                              crossAxisSpacing: productGridGutter,
                                              mainAxisExtent:
                                                  provider.products.any((p) =>
                                                          p.storeId == 19)
                                                      ? _fishProductCellExtent
                                                      : productCardExtent,
                                            ),
                                            delegate:
                                                SliverChildBuilderDelegate(
                                              (ctx, idx) {
                                                final p =
                                                    provider.products[idx];
                                                return MiniProductCardContainer(
                                                  product: p,
                                                  comboId: widget.combo?.id,
                                                );
                                              },
                                              childCount:
                                                  provider.products.length >= 3
                                                      ? 3
                                                      : provider.products.length,
                                            ),
                                          ),
                                        ),

                                      // Brand Strip (after first row of products)
                                      if (provider.brands.isNotEmpty &&
                                          provider.products.length > 3)
                                        SliverToBoxAdapter(
                                          child: ShopByBrandsStrip(
                                              provider: provider),
                                        ),

                                      // Remaining Products (from index 2 onwards)
                                      SliverPadding(
                                        padding: const EdgeInsets.only(
                                            bottom: 120,
                                            left: productGridPagePadding,
                                            right: productGridPagePadding,
                                            top: 2),
                                        sliver: provider.loadingMore &&
                                                provider.products.isEmpty
                                            ? SliverGrid(
                                                gridDelegate:
                                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 2,
                                                  mainAxisSpacing: productGridGutter,
                                                  crossAxisSpacing: productGridGutter,
                                                  // Matches the real grid below
                                                  // so cards don't resize when
                                                  // the shimmer is replaced.
                                                  mainAxisExtent:
                                                      productCardExtent,
                                                ),
                                                delegate:
                                                    SliverChildBuilderDelegate(
                                                  (_, __) =>
                                                      _buildProductShimmer(
                                                          colorScheme),
                                                  childCount: 6,
                                                ),
                                              )
                                            : provider.products.isEmpty
                                                ? SliverToBoxAdapter(
                                                    child: SizedBox(
                                                      height: 300,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .shopping_bag_outlined,
                                                            size: 64,
                                                            color: colorScheme
                                                                .iconDisabled,
                                                          ),
                                                          const SizedBox(
                                                              height: 16),
                                                          Text(
                                                            getTranslatedValue(
                                                                context,
                                                                'no_products_found'),
                                                            style: GoogleFonts
                                                                .inter(
                                                              color: colorScheme
                                                                  .textSecondary,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(
                                                            getTranslatedValue(
                                                                context,
                                                                'try_selecting_another_category'),
                                                            style: GoogleFonts
                                                                .inter(
                                                              color: colorScheme
                                                                  .textTertiary,
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : SliverGrid(
                                                    gridDelegate:
                                                        SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 2,
                                                      mainAxisSpacing:
                                                          productGridGutter,
                                                      crossAxisSpacing:
                                                          productGridGutter,
                                                      mainAxisExtent: provider
                                                              .products
                                                              .any((p) =>
                                                                  p.storeId == 19)
                                                          ? _fishProductCellExtent
                                                          : productCardExtent,
                                                    ),
                                                    delegate:
                                                        SliverChildBuilderDelegate(
                                                      (ctx, idx) {
                                                        // Start from index 3 (after the first row)
                                                        final productIdx =
                                                            idx + 3;
                                                        if (productIdx >=
                                                            provider.products
                                                                .length) {
                                                          if (provider
                                                                  .loadingMore &&
                                                              productIdx <
                                                                  provider.products
                                                                          .length +
                                                                      2) {
                                                            return _buildProductShimmer(
                                                                colorScheme);
                                                          }
                                                          return const SizedBox
                                                              .shrink();
                                                        }
                                                        final p =
                                                            provider.products[
                                                                productIdx];
                                                        return MiniProductCardContainer(
                                                          product: p,
                                                          comboId:
                                                              widget.combo?.id,
                                                        );
                                                      },
                                                      childCount: (provider
                                                                  .products
                                                                  .length <=
                                                              3)
                                                          ? (provider
                                                                  .loadingMore
                                                              ? 2
                                                              : 0)
                                                          : (provider.products
                                                                      .length -
                                                                  3) +
                                                              (provider
                                                                      .loadingMore
                                                                  ? 2
                                                                  : 0),
                                                    ),
                                                  ),
                                      ),
                                      // Bottom padding for cart overlay
                                      const SliverToBoxAdapter(
                                        child: SizedBox(height: 100),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // TOP HINT - Prev Category
                  if (showPrevCategoryHint)
                    Positioned(
                      top: 0,
                      left: 72,
                      right: 0,
                      child: IgnorePointer(
                        child: Consumer<CategoryProductProvider>(
                          builder: (context, provider, _) {
                            final currentIndex = provider.selectedCategoryIdx;
                            if (currentIndex <= 0 ||
                                provider.isSwitchingCategory) {
                              return const SizedBox();
                            }

                            final prevCategory =
                                provider.categories[currentIndex - 1];
                            final progress =
                                (_topOverscroll / 80).clamp(0.0, 1.0);

                            return Opacity(
                              opacity: progress,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - progress)),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        colorScheme.primary
                                            .withOpacity(0.12 * progress),
                                        colorScheme.primary
                                            .withOpacity(0.04 * progress),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons
                                            .keyboard_double_arrow_down_rounded,
                                        size: 28,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(height: 8),
                                      // Category Image
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colorScheme.primary
                                              .withOpacity(0.12),
                                          border: Border.all(
                                              color: colorScheme.primary
                                                  .withOpacity(0.2),
                                              width: 1),
                                        ),
                                        child: ClipOval(
                                          child: (prevCategory
                                                      .imageUrl?.isNotEmpty ??
                                                  false)
                                              ? CachedNetworkImage(
                                                  imageUrl: prevCategory.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Shimmer.fromColors(
                                                    baseColor: const Color(0xFFE0E0E0),
                                                    highlightColor: const Color(0xFFF5F5F5),
                                                    child: Container(color: Colors.white),
                                                  ),
                                                  errorWidget: (context, url, error) => Icon(Icons.category_rounded, color: colorScheme.primary, size: 24),
                                                )
                                              : Icon(Icons.category_rounded,
                                                  color: colorScheme.primary,
                                                  size: 24),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        progress >= 1.0
                                            ? 'Release to switch'
                                            : 'Pull for ${prevCategory.name}',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  if (showNextCategoryHint)
                    Positioned(
                      bottom: 110,
                      left: 72,
                      right: 0,
                      child: IgnorePointer(
                        child: Consumer<CategoryProductProvider>(
                          builder: (context, provider, _) {
                            final currentIndex = provider.selectedCategoryIdx;
                            if (currentIndex >=
                                    provider.categories.length - 1 ||
                                provider.isSwitchingCategory) {
                              return const SizedBox();
                            }

                            final nextCategory =
                                provider.categories[currentIndex + 1];
                            final progress =
                                (_bottomOverscroll / 80).clamp(0.0, 1.0);

                            return Opacity(
                              opacity: progress,
                              child: Transform.translate(
                                offset: Offset(0, -20 * (1 - progress)),
                                child: Container(
                                  padding: const EdgeInsets.only(
                                      top: 12, bottom: 20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        colorScheme.primary
                                            .withOpacity(0.12 * progress),
                                        colorScheme.primary
                                            .withOpacity(0.04 * progress),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.keyboard_double_arrow_up_rounded,
                                        size: 32,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(height: 8),
                                      // Category Image
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colorScheme.primary
                                              .withOpacity(0.12),
                                          border: Border.all(
                                              color: colorScheme.primary
                                                  .withOpacity(0.2),
                                              width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: (nextCategory
                                                      .imageUrl?.isNotEmpty ??
                                                  false)
                                              ? CachedNetworkImage(
                                                  imageUrl: nextCategory.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Shimmer.fromColors(
                                                    baseColor: const Color(0xFFE0E0E0),
                                                    highlightColor: const Color(0xFFF5F5F5),
                                                    child: Container(color: Colors.white),
                                                  ),
                                                  errorWidget: (context, url, error) => Icon(Icons.category_rounded, color: colorScheme.primary, size: 28),
                                                )
                                              : Icon(Icons.category_rounded,
                                                  color: colorScheme.primary,
                                                  size: 28),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        progress >= 1.0
                                            ? 'Release for ${nextCategory.name}'
                                            : 'Next: ${nextCategory.name}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.primary,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Cart Overlay - Separate Consumer to listen to CartProvider
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, _) {
                      if (double.parse(
                              cartProvider.cartData?.data.subTotal ?? "0.0") >
                          0) {
                        return PositionedDirectional(
                          bottom: 0,
                          start: 0,
                          end: 0,
                          child: SafeArea(top: false, child: CartOverlay()),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void showUnifiedFilterSheet(BuildContext context, {int initialTab = 0}) {
    final provider =
        Provider.of<CategoryProductProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: UnifiedFilterSheet(initialTabIndex: initialTab),
      ),
    ).then((_) {
      // Reload products if filters changed (products list is empty)
      if (provider.products.isEmpty && provider.hasMore) {
        provider.loadProducts(context, initial: true);
      }
    });
  }

  Widget categoriesHeader(BuildContext context, String title,
      app_theme.AppColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary,
            colorScheme.surface,
          ],
          stops: const [0.0, 0.7],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryShimmer(app_theme.AppColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          width: 78,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.shimmerBase,
                colorScheme.shimmerHighlight,
                colorScheme.shimmerBase,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(
                _shimmerController.value * 2 * 3.14159,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductShimmer(app_theme.AppColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final animation = Tween<double>(
          begin: -2,
          end: 2,
        ).animate(_shimmerController);

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Base shimmer background
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.shimmerBase,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              // Animated gradient overlay
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Transform.translate(
                  offset: Offset(animation.value * 200, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          colorScheme.shimmerBase.withValues(alpha: 0.0),
                          colorScheme.shimmerHighlight.withValues(alpha: 0.8),
                          colorScheme.shimmerBase.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
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

// Sticky Header Delegate
// class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
//   final Widget child;
//   final app_theme.AppColorScheme colorScheme;

//   _StickyHeaderDelegate({required this.child, required this.colorScheme});

//   @override
//   double get minExtent => 140;

//   @override
//   double get maxExtent => 140;

//   @override
//   Widget build(
//       BuildContext context, double shrinkOffset, bool overlapsContent) {
//     return child;
//   }

//   @override
//   bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
//     return oldDelegate.child != child || oldDelegate.colorScheme != colorScheme;
//   }
// }

class UnifiedFilterSheet extends StatefulWidget {
  final int initialTabIndex;

  const UnifiedFilterSheet({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<UnifiedFilterSheet> createState() => _UnifiedFilterSheetState();
}

class _UnifiedFilterSheetState extends State<UnifiedFilterSheet> {
  late int selectedTabIndex;
  late List<String> filterTabs;

  @override
  void initState() {
    super.initState();
    selectedTabIndex = widget.initialTabIndex;
    // Initialize filterTabs with translations in build method
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    // Initialize filter tabs with translations
    filterTabs = [
      getTranslatedValue(context, 'sort_by_header'),
      getTranslatedValue(context, 'brand_header'),
      getTranslatedValue(context, 'type_header_filter'),
      getTranslatedValue(context, 'size_header_filter'),
      getTranslatedValue(context, 'price_header_filter'),
    ];

    return Consumer<CategoryProductProvider>(
      builder: (context, provider, _) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(colorScheme),

              // Body with left sidebar + right content
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left sidebar
                    _buildLeftSidebar(colorScheme),

                    // Divider
                    Container(
                      width: 1,
                      color: colorScheme.border,
                    ),

                    // Right content
                    Expanded(
                      child: _buildRightContent(provider, colorScheme),
                    ),
                  ],
                ),
              ),

              // Footer
              _buildFooter(provider, colorScheme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(app_theme.AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Filters',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.textPrimary,
              letterSpacing: -0.55,
              height: 1.02,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.textPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 24,
                color: colorScheme.iconSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar(app_theme.AppColorScheme colorScheme) {
    return Container(
      width: 100,
      color: colorScheme.surfaceVariant,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: filterTabs.length,
        itemBuilder: (context, index) {
          final isSelected = selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => selectedTabIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.surface : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color:
                        isSelected ? colorScheme.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                filterTabs[index],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.textPrimary
                      : colorScheme.textSecondary,
                  letterSpacing: -0.55,
                  height: 1.02,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightContent(
      CategoryProductProvider provider, app_theme.AppColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _getContentForTab(selectedTabIndex, provider, colorScheme),
    );
  }

  Widget _getContentForTab(int index, CategoryProductProvider provider,
      app_theme.AppColorScheme colorScheme) {
    switch (index) {
      case 0:
        return _buildSortByContent(provider, colorScheme);
      case 1:
        return _buildBrandContent(provider, colorScheme);
      case 2:
        return _buildTypeContent(provider, colorScheme);
      case 3:
        return _buildSizeContent(provider, colorScheme);
      case 4:
        return _buildPriceContent(provider, colorScheme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildSortByContent(
      CategoryProductProvider provider, app_theme.AppColorScheme colorScheme) {
    final sortOptions = sortByOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, 'sort_by_header'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colorScheme.textSecondary,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 12),
        ...sortOptions.map((option) {
          final isSelected = provider.selectedSort == option.apiValue;
          return GestureDetector(
            onTap: () => provider.setSort(option.apiValue),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.divider,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBrandContent(
      CategoryProductProvider provider, app_theme.AppColorScheme colorScheme) {
    // Use dynamic brands from provider
    final brands = provider.brands;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, 'brand_header'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colorScheme.textSecondary,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 12),
        ...brands.map((brand) {
          final isSelected = provider.selectedBrandIds.contains(brand.id);
          return GestureDetector(
            onTap: () => provider.toggleBrand(brand.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      brand.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.divider,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: colorScheme.buttonPrimaryText,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTypeContent(
      CategoryProductProvider provider, app_theme.AppColorScheme colorScheme) {
    // Use dynamic types from provider
    final types = provider.categoryTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, 'type_header_filter'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colorScheme.textSecondary,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 12),
        ...types.map((type) {
          final isSelected = provider.selectedType == type.name;
          return GestureDetector(
            onTap: () => provider.selectType(type.name),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      type.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.divider,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: colorScheme.buttonPrimaryText,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSizeContent(
      CategoryProductProvider provider, app_theme.AppColorScheme colorScheme) {
    final sizes = ['200 g', '400 g', '1 kg', '3 kg'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, 'size_header_filter'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colorScheme.textSecondary,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 12),
        ...sizes.map((size) {
          final isSelected = provider.selectedSizes.contains(size);
          return GestureDetector(
            onTap: () =>
                provider.toggleSize(size, 1), // TODO: Get actual unit_id
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      size,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.divider,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: colorScheme.buttonPrimaryText,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPriceContent(
      CategoryProductProvider provider, app_theme.AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, 'price_header_filter'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colorScheme.textSecondary,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              getTranslatedValue(context, 'minimum_price'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.textSecondary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            Text(
              getTranslatedValue(context, 'maximum_price'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.textSecondary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            padding: const EdgeInsets.only(top: 16),
            trackHeight: 4,
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.divider,
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            rangeThumbShape:
                const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: RangeSlider(
            values: provider.priceRange,
            min: provider.totalMinPrice.toDouble(),
            max: provider.totalMaxPrice.toDouble(),
            divisions: 100,
            onChanged: (values) => provider.setPriceRange(values),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹ ${provider.priceRange.start.toInt()}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
              ),
            ),
            Text(
              '₹ ${provider.priceRange.end.toInt()}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(
      CategoryProductProvider provider, app_theme.AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                provider.applyFiltersAndReload(context);
                // Apply filters and close sheet
                Navigator.pop(context);
                // Filters are already applied via provider methods
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                getTranslatedValue(context, 'apply_button'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.buttonPrimaryText,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              provider.clearFilters();
              Navigator.pop(context);
            },
            child: Text(
              getTranslatedValue(context, 'clear_button'),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.textSecondary,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SortByFilterSheet extends StatefulWidget {
  const SortByFilterSheet({super.key});

  @override
  State<SortByFilterSheet> createState() => _SortByFilterSheetState();
}

class _SortByFilterSheetState extends State<SortByFilterSheet> {
  late SortByOption selectedSort;
  late List<SortByOption> sortOptions;

  @override
  void initState() {
    super.initState();
    // Initialize with first option - will be set in build
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    // Initialize sort options from model
    sortOptions = sortByOptions;

    // Initialize selectedSort on first build
    // Try to match provider's current sort
    final provider = context.read<CategoryProductProvider>();
    selectedSort = sortOptions.firstWhere(
      (o) => o.apiValue == provider.selectedSort,
      orElse: () => sortOptions[0],
    );

    return FilterBottomSheet(
      title: getTranslatedValue(context, 'filters_header'),
      onApply: () {
        // Apply sort
      },
      onClear: () {
        setState(() => selectedSort = sortOptions[0]);
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslatedValue(context, 'sort_by_header'),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...sortOptions.map((option) {
            final isSelected = selectedSort.apiValue == option.apiValue;
            return GestureDetector(
              onTap: () => setState(() => selectedSort = option),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isSelected ? colorScheme.primary : colorScheme.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.divider,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class FilterChipBar extends StatelessWidget {
  final List<FilterChipData> filters;

  const FilterChipBar({super.key, required this.filters});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) => true, // Absorb scroll notifications
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const ClampingScrollPhysics(),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = filters[index];
            return FilterChipButton(
              label: filter.label,
              isSelected: filter.isSelected,
              onTap: filter.onTap,
            );
          },
        ),
      ),
    );
  }
}

/// Horizontal row of category chips (replaces the old vertical sidebar).
/// Shows the sub-group's categories (e.g. Ghee, Sunflower, Mustard) as pills,
/// highlighting the selected one and switching category on tap.
class CategoryChipRow extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const CategoryChipRow({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.border,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? colorScheme.buttonPrimaryText
                        : colorScheme.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.02,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TypeChipRow extends StatefulWidget {
  final List<String> types;
  final String? selectedType;
  final ValueChanged<String?>? onTypeSelected;

  const TypeChipRow({
    super.key,
    required this.types,
    this.selectedType,
    this.onTypeSelected,
  });

  @override
  State<TypeChipRow> createState() => _TypeChipRowState();
}

class _TypeChipRowState extends State<TypeChipRow> {
  late String? _selectedType;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _chipKeys = {};

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    // Create keys for all chips including "All"
    for (int i = 0; i <= widget.types.length; i++) {
      _chipKeys[i] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToChip(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final key = _chipKeys[index];
      if (key?.currentContext == null) return;

      final RenderBox renderBox =
          key!.currentContext!.findRenderObject() as RenderBox;
      final chipWidth = renderBox.size.width;
      final scrollPosition = _scrollController.position;

      // Calculate the position to scroll to (center the chip)
      double targetScroll = 0;

      // Sum up widths of all chips before this one
      for (int i = 0; i < index; i++) {
        final prevKey = _chipKeys[i];
        if (prevKey?.currentContext != null) {
          final RenderBox prevBox =
              prevKey!.currentContext!.findRenderObject() as RenderBox;
          targetScroll += prevBox.size.width + 8; // 8 is separator width
        }
      }

      // Center the chip in viewport
      final viewportWidth = scrollPosition.viewportDimension;
      targetScroll = targetScroll - (viewportWidth / 2) + (chipWidth / 2);

      // Clamp to valid scroll range
      targetScroll = targetScroll.clamp(
          scrollPosition.minScrollExtent, scrollPosition.maxScrollExtent);

      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return SizedBox(
      height: 32,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) => true, // Absorb scroll notifications
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: widget.types.length + 1, // +1 for "All" button
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
          // First item is "All"
          if (index == 0) {
            final isSelected = _selectedType == null;
            return GestureDetector(
              key: _chipKeys[0],
              onTap: () {
                setState(() => _selectedType = null);
                widget.onTypeSelected?.call(null);
                _scrollToChip(0);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    getTranslatedValue(context, 'all_label'),
                    style: GoogleFonts.inter(
                      color: isSelected
                          ? colorScheme.buttonPrimaryText
                          : colorScheme.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      height: 1.02,
                      letterSpacing: -0.55,
                    ),
                  ),
                ),
              ),
            );
          }

          // Other items are types
          final typeIndex = index - 1;
          final type = widget.types[typeIndex];
          final isSelected = _selectedType == type;

          return GestureDetector(
            key: _chipKeys[index],
            onTap: () {
              setState(() => _selectedType = type);
              widget.onTypeSelected?.call(type);
              _scrollToChip(index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  type.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? colorScheme.buttonPrimaryText
                        : colorScheme.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    height: 1.02,
                    letterSpacing: -0.55,
                  ),
                ),
              ),
            ),
          );
        },
        ),
      ),
    );
  }
}

class FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected
                    ? colorScheme.buttonPrimaryText
                    : colorScheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.02,
                letterSpacing: -0.55,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isSelected
                  ? colorScheme.buttonPrimaryText
                  : colorScheme.iconSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class FilterBottomSheet extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const FilterBottomSheet({
    super.key,
    required this.title,
    required this.content,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close_rounded,
                    size: 24,
                    color: colorScheme.iconSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ),

          // Footer buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colorScheme.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      onApply();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.buttonPrimaryText,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Clear button
                GestureDetector(
                  onTap: onClear,
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textSecondary,
                      letterSpacing: -0.1,
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
}

class FilterChipData {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  FilterChipData({
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });
}

// Sticky Header Delegate for SliverPersistentHeader
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final app_theme.AppColorScheme colorScheme;

  _StickyHeaderDelegate({required this.child, required this.colorScheme});

  @override
  double get minExtent => 56; // Fits the filter chip bar (40 + 8*2 padding)

  @override
  double get maxExtent => 56; // Fits the filter chip bar (40 + 8*2 padding)

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: 0,
      child: ClipRect(
        child: SizedBox.expand(child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return true;
  }
}

class ShopByBrandsStrip extends StatelessWidget {
  final CategoryProductProvider provider;

  const ShopByBrandsStrip({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final brands = provider.brands;
    if (brands.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslatedValue(context, 'shop_by_brands'),
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.58,
              letterSpacing: -0.04,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: brands.length,
              separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final brand = brands[index];
                final isSelected = provider.selectedBrandIds.contains(brand.id);
                return GestureDetector(
                  onTap: () {
                    provider.toggleBrand(brand.id);
                    provider.applyFiltersAndReload(context);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : const Color(0xFFEDEDED),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: setNetworkImg(
                            image: brand.imageUrl,
                            width: 55,
                            height: 55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 55,
                        child: Text(
                          brand.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.02,
                            letterSpacing: -0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
