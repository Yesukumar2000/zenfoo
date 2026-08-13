import 'package:project/helper/styles/product_card_metrics.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/store_with_category_group.dart';
import 'package:project/models/sweetshop_products.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/categoryProducts/widgets/product_card.dart';
import 'package:project/screens/productDetailScreen/productDetailScreen.dart';
import 'package:project/screens/sweetHouseDetail/widgets/shop_hours_status.dart';

class SweetHouseDetailScreen extends StatefulWidget {
  final String sellerId;
  final String? foodType; // 'veg' or 'non_veg' filter from nearby stores

  const SweetHouseDetailScreen({
    Key? key,
    required this.sellerId,
    this.foodType,
  }) : super(key: key);

  @override
  State<SweetHouseDetailScreen> createState() => _SweetHouseDetailScreenState();
}

class _SweetHouseDetailScreenState extends State<SweetHouseDetailScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _categoryKeys = {};
  final Set<int> _expandedCategories = {};
  bool isBookmarked = false;
  bool isBookmarkLoading = false;

  // Sweetshop products state
  SweetshopProductsResponse? sweetshopData;
  bool isLoadingProducts = true;
  bool isRefreshing = false;

  // Selected filters
  int? selectedCategoryId;
  int? selectedTypeId;
  String currentSortBy = 'name_asc';
  List<int> currentCategoryIds = [];
  String searchQuery = '';
  String? currentFoodType;

  // Debounce timer for search
  Timer? _searchDebounceTimer;

  // Animation controller for shimmer
  late AnimationController _shimmerController;

  // Carousel state
  late PageController _carouselController;
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize bookmark state from seller data
    // isBookmarked = sweetshopData?.seller.isBookmarked ?? false;

    currentFoodType = widget.foodType;

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _carouselController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSweetshopProducts();
    });
  }

  Future<void> _loadSweetshopProducts() async {
    setState(() {
      isLoadingProducts = true;
    });

    final response = await fetchSweetshopProducts(
      context,
      sellerId: int.parse(widget.sellerId ?? "0"),
      foodType: currentFoodType,
    );

    if (mounted) {
      setState(() {
        sweetshopData = response;
        isLoadingProducts = false;

        // Create keys for each category for scrolling
        if (response != null) {
          for (final category in response.productsByCategory) {
            _categoryKeys[category.categoryId] = GlobalKey();
          }
        }
      });

      // Start carousel auto-scroll if images exist
      _startCarouselAutoScroll();
    }
  }

  void _startCarouselAutoScroll() {
    // Cancel existing timer if any
    _carouselTimer?.cancel();

    // Check if there are images to carousel
    final images = _getCarouselImages();
    if (images.isEmpty) return;

    // Start auto-scroll timer
    _carouselTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (_carouselController.hasClients) {
          _currentCarouselIndex = (_currentCarouselIndex + 1) % images.length;
          _carouselController.animateToPage(
            _currentCarouselIndex,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      },
    );
  }

  List<String> _getCarouselImages() {
    final storeImages = sweetshopData?.seller.storeImages;
    if (storeImages != null && storeImages.isNotEmpty) {
      return storeImages.cast<String>().toList();
    }
    // Fallback to logo if no store images
    if (sweetshopData?.seller.logoUrl != null) {
      return [sweetshopData!.seller.logoUrl!];
    }
    return [];
  }

  Future<void> _handleRefresh() async {
    setState(() {
      isRefreshing = true;
    });
    await _loadSweetshopProducts();
    setState(() {
      isRefreshing = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shimmerController.dispose();
    _searchDebounceTimer?.cancel();
    _carouselController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Set new timer for debounced search
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      searchQuery = query;
    });

    // Call API with search parameter
    final response = await fetchSweetshopProducts(
      context,
      sellerId: int.parse(widget.sellerId ?? "0"),
      sortBy: currentSortBy,
      categoryIds: currentCategoryIds,
      searchQuery: query,
      foodType: currentFoodType,
    );

    if (mounted) {
      setState(() {
        sweetshopData = response;
      });
    }
  }

  void _showMenuPopup() {
    if (sweetshopData == null) return;

    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showDialog(
      context: context,
      barrierColor: colorScheme.overlay,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              right: 16,
              bottom:
                  85, // Position above the floating button (45px height + 20px padding + 20px gap)
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Container(
                    width: 280,
                    constraints: const BoxConstraints(maxHeight: 446),
                    decoration: BoxDecoration(
                      color: colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: colorScheme.cardShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with title and close button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 30, 16, 20),
                          child: Row(
                            children: [
                              Text(
                                getTranslatedValue(context, 'menu_label'),
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: colorScheme.textPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Category list with products
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(bottom: 30),
                            itemCount: sweetshopData!.productsByCategory.length,
                            itemBuilder: (context, index) {
                              final category =
                                  sweetshopData!.productsByCategory[index];
                              return _buildMenuCategoryItem(
                                category,
                                setDialogState,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuCategoryItem(
    ProductsByCategory category,
    StateSetter setDialogState,
  ) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;
    final isExpanded = _expandedCategories.contains(category.categoryId);

    return Column(
      children: [
        // Category header
        Material(
          color: colorScheme.cardBackground,
          child: InkWell(
            onTap: () {
              setDialogState(() {
                if (isExpanded) {
                  _expandedCategories.remove(category.categoryId);
                } else {
                  _expandedCategories.add(category.categoryId);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 12, 25, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.categoryName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.textPrimary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Divider
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 25),
          height: 1,
          color: colorScheme.divider,
        ),

        // Product items (shown when expanded)
        if (isExpanded)
          ...category.products.map((product) {
            return Column(
              children: [
                Material(
                  color: colorScheme.cardBackground,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _scrollToCategory(category.categoryId);
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(40, 10, 25, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Divider between products
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  height: 1,
                  color: colorScheme.divider,
                ),
              ],
            );
          }).toList(),
      ],
    );
  }

  void _scrollToCategory(int categoryId) {
    final key = _categoryKeys[categoryId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  Widget _buildCarousel(AppColorScheme colorScheme) {
    final images = _getCarouselImages();

    if (images.isEmpty) {
      return Container(
        color: colorScheme.surfaceVariant,
        child: Icon(
          Icons.store,
          size: 60,
          color: colorScheme.iconDisabled,
        ),
      );
    }

    if (images.length == 1) {
      return CachedNetworkImage(
        imageUrl: images[0],
        fit: BoxFit.cover,
        memCacheWidth: 800,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => Container(
          color: colorScheme.surfaceVariant,
        ),
        errorWidget: (context, url, error) => imgErrorWidget(icon: Icons.storefront_rounded, iconSize: 48),
      );
    }

    return PageView.builder(
      controller: _carouselController,
      onPageChanged: (index) {
        setState(() {
          _currentCarouselIndex = index;
        });
      },
      itemCount: images.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: images[index],
          fit: BoxFit.cover,
          memCacheWidth: 800,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => Container(
            color: colorScheme.surfaceVariant,
          ),
          errorWidget: (context, url, error) => Container(
            color: colorScheme.surfaceVariant,
            child: Icon(
              Icons.store,
              size: 60,
              color: colorScheme.iconDisabled,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      bottomNavigationBar: context.watch<CartProvider>().totalItemsCount > 0
          ? SafeArea(
              top: false,
              child: CartOverlay(),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: colorScheme.primary,
        child: SafeArea(
          top: false,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header with Store Image
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                elevation: 0,
                backgroundColor: colorScheme.surface,
                leading: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: colorScheme.cardShadow,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colorScheme.textPrimary,
                      size: 16,
                    ),
                  ),
                ),
                actions: [
                  // Share store
                  GestureDetector(
                    onTap: _shareStore,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: colorScheme.cardShadow,
                      ),
                      child: Icon(
                        Icons.share_rounded,
                        color: colorScheme.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: isBookmarkLoading
                        ? null
                        : () async {
                            setState(() {
                              isBookmarkLoading = true;
                            });

                            try {
                              final result = await toggleSellerBookmarkApi(
                                context: context,
                                sellerId: int.parse(widget.sellerId),
                              );

                              if (result != null && result['status'] == 1) {
                                setState(() {
                                  isBookmarked = !isBookmarked;
                                });

                                showMessage(
                                  context,
                                  result['message'] ?? 'Bookmark updated',
                                  MessageType.success,
                                );
                              } else {
                                showMessage(
                                  context,
                                  result?['message'] ??
                                      'Failed to update bookmark',
                                  MessageType.error,
                                );
                              }
                            } catch (e) {
                              showMessage(
                                context,
                                'Failed to update bookmark',
                                MessageType.error,
                              );
                            }

                            if (mounted) {
                              setState(() {
                                isBookmarkLoading = false;
                              });
                            }
                          },
                    child: Container(
                      margin:
                          const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: colorScheme.cardShadow,
                      ),
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border_rounded,
                        color: isBookmarked
                            ? const Color(0xFFE8B000)
                            : colorScheme.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double appBarHeight = constraints.maxHeight;
                    final double collapsedHeight =
                        kToolbarHeight + MediaQuery.of(context).padding.top;
                    final bool isCollapsed =
                        appBarHeight <= collapsedHeight + 10;

                    return FlexibleSpaceBar(
                      title: isCollapsed
                          ? Text(
                              sweetshopData?.seller.storeName ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            )
                          : null,
                      centerTitle: false,
                      titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                      background: Column(
                        children: [
                          // Store Header Image with overlay info
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Store Images Carousel
                                _buildCarousel(colorScheme),

                                // White overlay info card at bottom
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: colorScheme.cardBackground,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: colorScheme.cardShadow,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Delivery time badge + shop hours + Call button
                                        Row(
                                          children: [
                                            // The two timing pills share the
                                            // free space and the Call button
                                            // keeps its own width, so a long
                                            // "Closed · Opens 9:00 AM" trims
                                            // itself instead of overflowing.
                                            Expanded(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (sweetshopData?.seller
                                                          .travelTimeMin !=
                                                      null) ...[
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: colorScheme
                                                            .surfaceVariant,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .access_time_rounded,
                                                            size: 12,
                                                            color: colorScheme
                                                                .textPrimary,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            sweetshopData
                                                                    ?.seller
                                                                    .travelTimeMin ??
                                                                '',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: colorScheme
                                                                  .textPrimary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                  ],
                                                  Flexible(
                                                    child: ShopHoursStatus(
                                                      openingTime: sweetshopData
                                                          ?.seller
                                                          .shopOpeningTime,
                                                      closingTime: sweetshopData
                                                          ?.seller
                                                          .shopClosingTime,
                                                      colorScheme: colorScheme,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if ((sweetshopData?.seller.mobile ?? '').isNotEmpty)
                                              GestureDetector(
                                                onTap: () => launchUrl(Uri(scheme: 'tel', path: sweetshopData!.seller.mobile)),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: ColorsRes.appColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: ColorsRes.appColor.withValues(alpha: 0.3)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.phone_rounded, size: 13, color: ColorsRes.appColor),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        'Call',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: ColorsRes.appColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Store Name
                                        Text(
                                          sweetshopData?.seller.storeName ??
                                              'Restaurant',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.textPrimary,
                                            letterSpacing: -0.3,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Location
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                sweetshopData
                                                        ?.seller.storeLocation ??
                                                    '',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color:
                                                      colorScheme.textSecondary,
                                                  letterSpacing: -0.1,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Navigation / directions
                                            GestureDetector(
                                              onTap: _openDirections,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: ColorsRes.appColor
                                                      .withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.directions_rounded,
                                                  size: 14,
                                                  color: ColorsRes.appColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Distance
                                        Text(
                                          sweetshopData?.seller.distanceKm !=
                                                  null
                                              ? '${sweetshopData?.seller.distanceKm}, ${sweetshopData?.seller.storeCity ?? ''}'
                                              : '',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.textTertiary,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Offer carousel
                                        OfferCarouselWidget(
                                            colorScheme: colorScheme),
                                      ],
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
                ),
              ),

              // Sticky Header - Search and Filters
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchFilterDelegate(
                  colorScheme: colorScheme,
                  child: Container(
                    color: colorScheme.surface,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: CustomTextFormField(
                            title: '',
                            hintText: getTranslatedValue(
                                context, 'search_for_food_items'),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: colorScheme.iconSecondary,
                              size: 20,
                            ),
                            showClearButton: false,
                            onChanged: _onSearchChanged,
                          ),
                        ),

                        // Filters
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: 5,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              if (index == 0) return _buildFoodTypeChip('veg');
                              if (index == 1) return _buildFoodTypeChip('non_veg');
                              final labels = [
                                getTranslatedValue(context, 'sort_by_label'),
                                getTranslatedValue(context, 'price_label'),
                                getTranslatedValue(context, 'category_label'),
                              ];
                              return _buildFilterChipButton(labels[index - 2]);
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),

              // Product Grid
              ..._buildProductGrid(),
            ],
          ),
        ),
      ),

      // Floating Menu Button
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: GestureDetector(
          onTap: () {
            _showMenuPopup();
          },
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: ShapeDecoration(
              color: colorScheme.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadows: colorScheme.elevatedShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedMenu01,
                  color: colorScheme.background,
                  size: 20,
                ),
                const SizedBox(width: 7),
                Text(
                  getTranslatedValue(context, 'menu_label'),
                  style: GoogleFonts.inter(
                    color: colorScheme.background,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.50,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _shareStore() {
    final seller = sweetshopData?.seller;
    final name = seller?.storeName ?? 'this store';
    final location = (seller?.storeLocation ?? '').trim();
    final buffer = StringBuffer('Check out $name on Zenfoo');
    if (location.isNotEmpty) buffer.write('\n$location');
    SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: name,
      ),
    );
  }

  Future<void> _openDirections() async {
    final seller = sweetshopData?.seller;
    final latLong = (seller?.latLong ?? '').trim();
    final location = (seller?.storeLocation ?? '').trim();

    Uri? uri;
    if (latLong.contains(',')) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latLong',
      );
    } else if (location.isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}',
      );
    }

    if (uri == null) {
      showMessage(context, 'Location not available', MessageType.warning);
      return;
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) showMessage(context, 'Could not open maps', MessageType.error);
    }
  }

  Widget _buildFilterChipButton(String label) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    // Map label to tab index
    int getTabIndex() {
      switch (label) {
        case 'Sort by':
          return 0;
        case 'Price':
          return 1;
        case 'Category':
          return 2;
        default:
          return 0;
      }
    }

    return GestureDetector(
      onTap: () {
        _showFilterBottomSheet(getTabIndex());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.borderStrong,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
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
              color: colorScheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodTypeChip(String type) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;
    final isSelected = currentFoodType == type;
    final isVeg = type == 'veg';
    final color = isVeg ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C);
    final label = isVeg ? 'Veg' : 'Non-Veg';

    return GestureDetector(
      onTap: () async {
        final newFoodType = isSelected ? null : type;
        setState(() {
          currentFoodType = newFoodType;
        });
        await _applyFilters(currentSortBy, currentCategoryIds);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : colorScheme.borderStrong,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? color : colorScheme.textPrimary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                height: 1.02,
                letterSpacing: -0.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(int initialTab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SweetHouseFilterSheet(
        initialTabIndex: initialTab,
        sweetshopData: sweetshopData,
        initialSortBy: currentSortBy,
        initialCategoryIds: currentCategoryIds,
        onApply: (sortBy, categoryIds) {
          _applyFilters(sortBy, categoryIds);
        },
      ),
    );
  }

  Future<void> _applyFilters(String sortBy, List<int> categoryIds) async {
    // Call API with sort_by and category_id parameters
    final response = await fetchSweetshopProducts(
      context,
      sellerId: sweetshopData?.seller.id ?? 0,
      sortBy: sortBy,
      categoryIds: categoryIds,
      foodType: currentFoodType,
    );

    if (mounted) {
      setState(() {
        sweetshopData = response;
        // Store the current filters
        currentSortBy = sortBy;
        currentCategoryIds = categoryIds;
      });
    }
  }

  List<Widget> _buildProductGrid() {
    if (isLoadingProducts) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: productGridGutter,
              mainAxisSpacing: productGridGutter,
              mainAxisExtent: productCardExtent,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, __) => _buildProductShimmer(),
              childCount: 6,
            ),
          ),
        ),
      ];
    }

    if (sweetshopData == null || sweetshopData!.productsByCategory.isEmpty) {
      final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;
      return [
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                getTranslatedValue(context, 'no_products_available'),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ];
    }

    List<Widget> slivers = [];

    List<ProductsByCategory> sortedCategories = List.from(sweetshopData!.productsByCategory);

    for (final categoryProducts in sortedCategories) {
      // Filter by selected category
      if (selectedCategoryId != null &&
          categoryProducts.categoryId != selectedCategoryId) {
        continue;
      }

      // Filter products by selected type
      List<dynamic> products = categoryProducts.products;
      if (selectedTypeId != null) {
        products = products.where((p) {
          final productTypeId = int.tryParse(p.itemTypeId ?? '0');
          return productTypeId == selectedTypeId;
        }).toList();
      }

      // Filter products by food type
      if (currentFoodType != null) {
        final matchIndicator = currentFoodType == 'veg' ? '1' : '2';
        products = products.where((p) => p.indicator?.toString() == matchIndicator).toList();
      }

      if (products.isEmpty) continue;

      // Category header
      final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          sliver: SliverToBoxAdapter(
            child: Container(
              key: _categoryKeys[categoryProducts.categoryId],
              // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              // decoration: BoxDecoration(
              //   color: colorScheme.primary.withValues(alpha: 0.1),
              //   borderRadius: BorderRadius.circular(12),
              //   border: Border.all(
              //     color: colorScheme.primary.withValues(alpha: 0.2),
              //     width: 1,
              //   ),
              // ),
              child: Row(
                children: [
                  // Container(
                  //   padding: const EdgeInsets.all(6),
                  //   decoration: BoxDecoration(
                  //     color: colorScheme.primary.withValues(alpha: 0.15),
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Icon(
                  //     Icons.restaurant_menu_rounded,
                  //     size: 16,
                  //     color: colorScheme.primary,
                  //   ),
                  // ),
                  // const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      categoryProducts.categoryName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Text(
                    getTranslatedValue(context, 'items_count')
                        .replaceAll('{count}', products.length.toString()),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Products grid
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: productGridGutter,
              mainAxisSpacing: productGridGutter,
              mainAxisExtent: productCardExtent,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                // The menu variant of the shared card: photo filled edge to
                // edge, star row, and a text block packed against the ADD
                // button instead of floating above it.
                return MiniProductCardContainer(
                  product: product,
                  menuStyle: true,
                );
              },
              childCount: products.length,
            ),
          ),
        ),
      );
    }

    if (slivers.isEmpty) {
      final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;
      return [
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                getTranslatedValue(context, 'no_products_found_filters'),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ];
    }

    // Add combined footer section
    slivers.add(_buildCombinedFooter());

    slivers.add(const SliverToBoxAdapter(
      child: SizedBox(height: 100),
    ));

    return slivers;
  }

  Widget _buildCombinedFooter() {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;
    final hasFSSAI = (sweetshopData?.seller.fssaiNumber ?? '').isNotEmpty;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.textTertiary.withValues(alpha: 0.6),
              colorScheme.textTertiary.withValues(alpha: 0.3),
            ],
          ).createShader(bounds),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Disclaimer Section
              Icon(
                Icons.info_outline_rounded,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                getTranslatedValue(context, 'pricing_disclaimer'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  getTranslatedValue(context, 'pricing_disclaimer_message'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // FSSAI Section (only if FSSAI number exists)
              if (hasFSSAI) ...[
                const SizedBox(height: 40),
                Container(
                  height: 1,
                  width: 60,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/fssai_logo.png',
                  height: 56,
                  color: Colors.white,
                  errorBuilder: (context, error, stackTrace) => Text(
                    'FSSAI',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'LIC NO. ${sweetshopData?.seller.fssaiNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  (sweetshopData?.seller.storeName ??
                          sweetshopData?.seller.name ??
                          'SWEET HOUSE')
                      .toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2.2,
                    height: 0.95,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    (sweetshopData?.seller.storeLocation ??
                            sweetshopData?.seller.latLong ??
                            '')
                        .toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.8,
                      height: 1.7,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if ((sweetshopData?.seller.mobile ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    sweetshopData!.seller.mobile!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductShimmer() {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;
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
            border: Border.all(color: colorScheme.borderStrong, width: 1),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image shimmer.
              //
              // Expanded, not AspectRatio: the cell is a fixed 296dp
              // (productCardExtent), so a square image derived from the tile
              // width plus the ~142dp content block below it overflows on any
              // screen where the tile is wider than ~154dp — which is most of
              // them. Letting the image take whatever is left is the same rule
              // the real card follows, and it cannot overflow at any width.
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Stack(
                    children: [
                      // Base shimmer background
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.shimmerHighlight,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                      ),
                      // Animated gradient overlay
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Transform.translate(
                          offset: Offset(animation.value * 200, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  colorScheme.surfaceVariant,
                                  colorScheme.surface,
                                  colorScheme.surfaceVariant,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content shimmer
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title shimmer
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Rating shimmer
                    Container(
                      height: 20,
                      width: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Price shimmer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 20,
                          width: 60,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          height: 36,
                          width: 80,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
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
}

// Sticky Header Delegate for Search and Filters
class _StickySearchFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final AppColorScheme colorScheme;

  _StickySearchFilterDelegate({required this.child, required this.colorScheme});

  @override
  double get minExtent =>
      116; // Fixed height for sticky header (48 search + 40 filters + padding)

  @override
  double get maxExtent => 116; // Fixed height for sticky header

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
  bool shouldRebuild(_StickySearchFilterDelegate oldDelegate) {
    return true;
  }
}

// Filter Bottom Sheet
class SweetHouseFilterSheet extends StatefulWidget {
  final int initialTabIndex;
  final Function(String sortBy, List<int> categoryIds)? onApply;
  final SweetshopProductsResponse? sweetshopData;
  final String initialSortBy;
  final List<int> initialCategoryIds;

  const SweetHouseFilterSheet({
    super.key,
    this.initialTabIndex = 0,
    this.onApply,
    this.sweetshopData,
    this.initialSortBy = 'name_asc',
    this.initialCategoryIds = const [],
  });

  @override
  State<SweetHouseFilterSheet> createState() => _SweetHouseFilterSheetState();
}

class _SweetHouseFilterSheetState extends State<SweetHouseFilterSheet> {
  late int selectedTabIndex;
  late String selectedSort;
  late String selectedSortLabel;
  RangeValues priceRange = const RangeValues(0, 1000);
  late Set<int> selectedCategoryIds;

  final List<String> filterTabs = [
    'Sort By',
    'Price',
    'Category',
  ];

  final List<Map<String, String>> sortOptions = [
    {'label': 'A-Z', 'value': 'name_asc'},
    {'label': 'Z-A', 'value': 'name_desc'},
    {'label': 'Price: Low to High', 'value': 'price_asc'},
    {'label': 'Price: High to Low', 'value': 'price_desc'},
  ];

  @override
  void initState() {
    super.initState();
    // Clamp initialTabIndex to valid range (0-2 since we removed Brand filter)
    selectedTabIndex = widget.initialTabIndex.clamp(0, 2);
    selectedSort = widget.initialSortBy;
    selectedCategoryIds = Set.from(widget.initialCategoryIds);

    // Set the label based on the initial sort value
    final sortOptions = widget.sweetshopData?.availableSortOptions ?? [];
    final selectedOption = sortOptions.firstWhere(
      (option) => option.value == widget.initialSortBy,
      orElse: () => sortOptions.isNotEmpty
          ? sortOptions.first
          : SortOption(value: 'name_asc', label: 'A-Z'),
    );
    selectedSortLabel = selectedOption.label;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Body with left sidebar + right content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left sidebar
                _buildLeftSidebar(),

                // Divider
                Container(
                  width: 1,
                  color: colorScheme.border,
                ),

                // Right content
                Expanded(
                  child: _buildRightContent(),
                ),
              ],
            ),
          ),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

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
            getTranslatedValue(context, 'filters_label'),
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
                color: colorScheme.surfaceVariant,
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

  Widget _buildLeftSidebar() {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

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

  Widget _buildRightContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _getContentForTab(selectedTabIndex),
    );
  }

  Widget _getContentForTab(int index) {
    switch (index) {
      case 0:
        return _buildSortByContent();
      case 1:
        return _buildPriceContent();
      case 2:
        return _buildCategoryContent();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSortByContent() {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;
    final sortOptions = widget.sweetshopData?.availableSortOptions ?? [];

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
          final isSelected = selectedSort == option.value;
          return GestureDetector(
            onTap: () => setState(() {
              selectedSort = option.value;
              selectedSortLabel = option.label;
            }),
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
                            : colorScheme.borderStrong,
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
        }).toList(),
      ],
    );
  }

  Widget _buildPriceContent() {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, 'price_header'),
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
              'Minimum',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.textSecondary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            Text(
              'Maximum',
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
            inactiveTrackColor: colorScheme.borderStrong,
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            rangeThumbShape:
                const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: RangeSlider(
            values: priceRange,
            min: 0,
            max: 1000,
            divisions: 100,
            onChanged: (values) => setState(() => priceRange = values),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹ ${priceRange.start.toInt()}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
              ),
            ),
            Text(
              '₹ ${priceRange.end.toInt()}',
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

  Widget _buildCategoryContent() {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    // Get all category IDs that have products
    final categoriesWithProducts =
        widget.sweetshopData?.productsByCategory ?? [];
    final categoryIdsWithProducts =
        categoriesWithProducts.map((e) => e.categoryId).toSet();

    // Filter categories to show only those with products
    final filteredCategories = (widget.sweetshopData?.categoriesWithTypes ?? [])
        .where((category) => categoryIdsWithProducts.contains(category.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, 'category_header'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colorScheme.textSecondary,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 12),
        ...filteredCategories.map((category) {
          final isSelected = selectedCategoryIds.contains(category.id);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedCategoryIds.remove(category.id);
                } else {
                  selectedCategoryIds.add(category.id);
                }
              });
            },
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
                      category.name,
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
                            : colorScheme.borderStrong,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFooter() {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

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
                // Apply filters with sort_by and category_id parameters
                widget.onApply
                    ?.call(selectedSort, selectedCategoryIds.toList());
                Navigator.pop(context);
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
                  color: Colors.white,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              setState(() {
                selectedSort = 'name_asc';
                selectedSortLabel = 'A-Z';
                priceRange = const RangeValues(0, 1000);
                selectedCategoryIds.clear();
              });
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

// Offer Carousel Widget with BannerCarousel pattern
class OfferCarouselWidget extends StatefulWidget {
  final AppColorScheme colorScheme;

  const OfferCarouselWidget({
    Key? key,
    required this.colorScheme,
  }) : super(key: key);

  @override
  State<OfferCarouselWidget> createState() => _OfferCarouselWidgetState();
}

class _OfferCarouselWidgetState extends State<OfferCarouselWidget>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  Timer? _autoTimer;
  int _active = 0;

  List<String> _offers = [];
  bool _isLoading = true;

  final Duration _interval = const Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(vsync: this, duration: _interval)
      ..forward();
    _fetchOffer();
  }

  Future<void> _fetchOffer() async {
    try {
      final response =
          await getFreeDeliveryOffer(context: context);
      if (response['success'] == true && response['offer'] != null) {
        if (mounted) {
          setState(() {
            _offers = [response['offer'] as String];
            _isLoading = false;
          });
          _startAutoTimer();
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoTimer() {
    _progressController.forward(from: 0);
    _autoTimer?.cancel();
    if (_offers.length <= 1) return;
    _autoTimer = Timer(_interval, _goNext);
  }

  void _goNext() {
    if (_offers.length <= 1) return;
    final next = (_active + 1) % _offers.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
    );
  }

  // Highlights the price amount (any token with a digit, e.g. "₹500") and the
  // word "FREE" with a heavier weight while keeping the rest of the offer text
  // at the base weight.
  TextSpan _buildOfferSpans(
    String text, {
    required TextStyle base,
    required TextStyle highlight,
  }) {
    final tokens = text.split(' ');
    final spans = <TextSpan>[];
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final isHighlight =
          token.toUpperCase().contains('FREE') || RegExp(r'\d').hasMatch(token);
      spans.add(TextSpan(
        text: i == tokens.length - 1 ? token : '$token ',
        style: isHighlight ? highlight : base,
      ));
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _offers.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          // PageView with offer text and icon
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _offers.length,
              onPageChanged: (i) {
                setState(() => _active = i);
                _startAutoTimer();
              },
              itemBuilder: (ctx, index) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.colorScheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: widget.colorScheme.info,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.percent,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text.rich(
                          _buildOfferSpans(
                            _offers[index],
                            base: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: widget.colorScheme.info,
                            ),
                            highlight: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: widget.colorScheme.info,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_offers.length > 1) const SizedBox(width: 6),
          // Indicators in a row on the right
          if (_offers.length > 1) Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_offers.length, (i) {
              final selected = i == _active;
              return Padding(
                padding: EdgeInsets.only(right: i < _offers.length - 1 ? 3 : 0),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, _) {
                    // For selected indicator, show counter with progress bar
                    if (selected) {
                      return Container(
                        width: 26,
                        height: 12,
                        decoration: BoxDecoration(
                          color:
                              widget.colorScheme.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Stack(
                          children: [
                            // Animated progress fill (seekbar style)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _progressController.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: widget.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            // Counter text
                            Center(
                              child: Text(
                                '${i + 1}/${_offers.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // For non-selected indicators, show simple dot
                    return Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: widget.colorScheme.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
