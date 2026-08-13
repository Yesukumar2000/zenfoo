import 'package:flutter/services.dart';
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_groups.dart';
import 'package:project/models/store_with_category_group.dart';
import 'package:project/provider/notesProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/notes/notesListScreen.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:project/screens/supermartDetail/supermart_detail_screen.dart';
import 'package:project/screens/categoryProducts/widgets/banners_home.dart';

class SupermartScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const SupermartScreen({
    Key? key,
    this.scrollController,
  }) : super(key: key);

  @override
  State<SupermartScreen> createState() => _SupermartScreenState();
}

class _SupermartScreenState extends State<SupermartScreen> {
  late ScrollController _scrollController;
  final RefreshController _refreshController = RefreshController();
  final GlobalKey _headerKey = GlobalKey();
  bool _isSticked = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _currentSearchQuery = '';

  // Debounce timer for search
  Timer? _searchDebounceTimer;

  // Pagination state
  List<StoreSeller> sellers = [];
  List<StoreSlider> banners = [];
  SupermartSellersResponse? sellersResponse;
  bool isLoadingMore = false;
  bool isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    // Use provided scrollController or create a new one
    _scrollController = widget.scrollController ?? ScrollController();
    try {
      _scrollController.addListener(_scrollListener);
    } catch (e) {
      // ScrollController might be disposed if parent widget was disposed
      debugPrint('Warning: Could not add listener to ScrollController: $e');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialSellers();
    });
  }

  Future<void> _loadInitialSellers() async {
    if (!mounted) return;

    setState(() {
      isInitialLoading = true;
    });

    final response = await fetchSupermartSellers(context, perPage: 20, page: 1);
    if (response != null && mounted) {
      setState(() {
        sellersResponse = response;
        sellers = response.data;
        banners = response.banners;
        isInitialLoading = false;
      });
    } else if (mounted) {
      setState(() {
        isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMoreSellers() async {
    if (isLoadingMore ||
        sellersResponse == null ||
        !sellersResponse!.hasMorePages) {
      return;
    }

    setState(() {
      isLoadingMore = true;
    });

    final nextPage = sellersResponse!.currentPage + 1;
    final response = await fetchSupermartSellers(
      context,
      perPage: 20,
      page: nextPage,
    );

    if (response != null && mounted) {
      setState(() {
        sellersResponse = response;
        sellers.addAll(response.data);
        isLoadingMore = false;
      });
    } else if (mounted) {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void _scrollListener() {
    if (_headerKey.currentContext != null) {
      final RenderBox? renderBox =
          _headerKey.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final headerHeight = renderBox.size.height;
        final isSticked = _scrollController.offset >= headerHeight - 5;
        if (isSticked != _isSticked) {
          setState(() {
            _isSticked = isSticked;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    try {
      _scrollController.removeListener(_scrollListener);
      // Only dispose if we created the controller (not passed from parent)
      if (widget.scrollController == null) {
        _scrollController.dispose();
      }
      _searchController.dispose();
      _searchDebounceTimer?.cancel();
      _refreshController.dispose();
    } catch (e) {
      debugPrint('Warning: Error disposing ScrollController: $e');
    }
    super.dispose();
  }

  void _startVoiceSearch() {
    showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: DesignConfig.setRoundedBorderSpecific(20, istop: true),
      builder: (context) {
        return ChangeNotifierProvider<VoiceSearchProvider>(
          create: (context) => VoiceSearchProvider(),
          child: const SpeechToTextSearch(),
        );
      },
    ).then((value) {
      if (value != null && value.isNotEmpty) {
        _searchController.text = value;
        _searchDebounceTimer?.cancel();
        _performSearch(value);
      }
    });
  }

  Future<void> _searchSupermart(String query) async {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      // Reset to initial load if search is cleared
      await _loadInitialSellers();
      return;
    }

    // Set new timer for debounced search
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _currentSearchQuery = query;
      _isSearching = true;
    });

    final latitude = Constant.session
        .getData(SessionManager.keyLatitude, defaultValue: "0.0");
    final longitude = Constant.session
        .getData(SessionManager.keyLongitude, defaultValue: "0.0");

    final Map<String, dynamic> params = {
      'lat': latitude,
      'lon': longitude,
      'per_page': '20',
      'page': '1',
      'search': query,
    };

    final res = await sendApiRequest(
      apiName: "supermart-sellers",
      isPost: false,
      context: context,
      params: params,
    );

    if (res != null && mounted) {
      final decoded = json.decode(res);
      if (decoded['status'] == 1) {
        final response = SupermartSellersResponse.fromJson(decoded);
        setState(() {
          sellersResponse = response;
          sellers = response.data;
          _isSearching = false;
        });
      } else if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    } else if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> refreshList() async {
    _searchController.clear();
    _searchDebounceTimer?.cancel();
    await _loadInitialSellers();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return ChangeNotifierProvider(
      create: (_) => HomeScreenProvider(),
      child: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final provider = context.read<HomeScreenProvider>();
            if (provider.storeGroups.isEmpty) {
              await getAppSettings(context: context);
              final params = await Constant.getProductsDefaultParams();
              provider.loadSections(params: params, context: context);
            }
          });

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            child: Scaffold(
            backgroundColor: colorScheme.surface,
            body: SmartRefresher(
              controller: _refreshController,
              // header: CustomHeader(
              //   builder: (context, mode) => Container(
              //     alignment: Alignment.center,
              //     height: 80,
              //     child: mode == RefreshStatus.refreshing
              //         ? Row(
              //             mainAxisAlignment: MainAxisAlignment.center,
              //             children: [
              //               CircularProgressIndicator(
              //                 color: colorScheme.primary,
              //                 strokeWidth: 2.5,
              //               ),
              //               const SizedBox(width: 12),
              //               Text(
              //                 'Refreshing...',
              //                 style: GoogleFonts.inter(
              //                   fontSize: 14,
              //                   fontWeight: FontWeight.w600,
              //                   color: colorScheme.textSecondary,
              //                   height: 1.12,
              //                   letterSpacing: -0.55,
              //                 ),
              //               ),
              //             ],
              //           )
              //         : Icon(
              //             Icons.arrow_downward,
              //             color: colorScheme.primary,
              //           ),
              //   ),
              // ),
              onRefresh: refreshList,
              enablePullDown: true,
              enablePullUp: false,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      key: _headerKey,
                      child: const SupermartDeliveryHeaderWidget(),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SupermartStickySearchDelegate(
                      minHeight: _isSticked
                          ? 80 + MediaQuery.of(context).padding.top
                          : 80,
                      maxHeight: _isSticked
                          ? 80 + MediaQuery.of(context).padding.top
                          : 80,
                      topPadding: MediaQuery.of(context).padding.top,
                      isSticked: _isSticked,
                      searchController: _searchController,
                      onSearch: _searchSupermart,
                      onMicTap: _startVoiceSearch,
                    ),
                  ),
                  if (banners.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 160,
                        child: BannerCarousel(
                          mediaUrls: banners
                              .map((e) => e.imageUrl ?? '')
                              .where((e) => e.isNotEmpty)
                              .toList(),
                          interval: const Duration(seconds: 4),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            getTranslatedValue(context, 'nearby_super_marts'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.textPrimary,
                              letterSpacing: -0.55,
                              height: 1.02,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  if (isInitialLoading)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildStoreCardShimmer();
                          },
                          childCount: 3,
                        ),
                      ),
                    ),
                  if (!isInitialLoading && sellers.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final seller = sellers[index];
                            return StoreCard(
                              storeName: seller.storeName ?? seller.name ?? '',
                              distance: seller.distanceKm ?? 'N/A',
                              location: seller.storeLocation ?? '',
                              deliveryTime: seller.travelTimeMin ?? 'N/A',
                              discount: null,
                              rating: seller.rating ?? 0.0,
                              imageUrl: seller.logoUrl ?? '',
                              seller: seller,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SupermartDetailScreen(
                                      sellerId: seller.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: sellers.length,
                        ),
                      ),
                    ),
                  if (!isInitialLoading &&
                      sellersResponse != null &&
                      sellersResponse!.hasMorePages)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: isLoadingMore
                              ? Container(
                                  padding: const EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    color: colorScheme.primary,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : GestureDetector(
                                  onTap: _loadMoreSellers,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: colorScheme.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          getTranslatedValue(
                                              context, 'load_more_stores'),
                                          style: GoogleFonts.inter(
                                            color: colorScheme.primary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  if (!isInitialLoading && sellers.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.store_outlined,
                                size: 64,
                                color: colorScheme.iconDisabled,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                getTranslatedValue(
                                    context, 'no_stores_available'),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }

  // Shimmer loading widget for store cards
  Widget _buildStoreCardShimmer() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image shimmer
          CustomShimmer(
            height: 140,
            width: double.infinity,
            borderRadius: 12,
          ),
          const SizedBox(height: 12),
          // Store name shimmer
          CustomShimmer(
            height: 20,
            width: 180,
            borderRadius: 8,
          ),
          const SizedBox(height: 8),
          // Location shimmer
          CustomShimmer(
            height: 16,
            width: 220,
            borderRadius: 8,
          ),
          const SizedBox(height: 12),
          // Info row shimmer
          Row(
            children: [
              CustomShimmer(
                height: 16,
                width: 80,
                borderRadius: 8,
              ),
              const SizedBox(width: 16),
              CustomShimmer(
                height: 16,
                width: 80,
                borderRadius: 8,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SupermartDeliveryHeaderWidget extends StatefulWidget {
  const SupermartDeliveryHeaderWidget({super.key});

  @override
  State<SupermartDeliveryHeaderWidget> createState() =>
      _SupermartDeliveryHeaderWidgetState();
}

class _SupermartDeliveryHeaderWidgetState
    extends State<SupermartDeliveryHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final provider = context.watch<HomeScreenProvider>();
    final brandTitle = "Zenfoo";
    final price = "₹0";

    final addressLine = Constant.session.getData(SessionManager.keyAddress);
    final selectedIdx = provider.selectedStoreIdx;

    CategoryGroup? group;
    if (selectedIdx > 0 &&
        provider.storeGroups.isNotEmpty &&
        selectedIdx < provider.storeGroups.length) {
      group = provider.storeGroups[selectedIdx];
    }

    late final Color mainColor;
    if (selectedIdx == 0) {
      mainColor = const Color(0xFFFFA13B);
    } else {
      mainColor = group != null
          ? Constant.colorFromHex(group.color ?? "#FFA13B")
          : const Color(0xFFFFA13B);
    }

    final bgDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [mainColor, mainColor.withValues(alpha: 0.2)],
        stops: const [0, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        decoration: bgDecoration,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              brandTitle,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                height: 1.02,
              ),
            ),
            Builder(
              builder: (context) {
                if (provider.etaState == HomeScreenState.loading)
                  return _getEtaShimmer(colorScheme);
                if (provider.etaState == HomeScreenState.error)
                  return Text(
                    getTranslatedValue(context, 'failed_to_load_eta'),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final result = await showAddressesBottomSheet(context);

                          // If an address was selected, fetch estimated time without waiting
                          if (result != null && mounted) {
                            final homeProvider = context.read<HomeScreenProvider>();
                            // Don't await - load in background for smooth UI
                            homeProvider.loadEta(context);
                          }
                          setState(() {});
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.estimatedTime ??
                                  getTranslatedValue(context, 'in_30_minutes'),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                height: 1.02,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    addressLine.isNotEmpty
                                        ? addressLine
                                        : getTranslatedValue(
                                            context, 'tap_to_add_your_address'),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    RepaintBoundary(
                      child: CartProfileWidget(
                        price: price,
                        iconColor: colorScheme.textPrimary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _getEtaShimmer(AppColorScheme colorScheme) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.shimmerBase,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Shimmer.fromColors(
        baseColor: colorScheme.shimmerBase,
        highlightColor: colorScheme.shimmerHighlight,
        child: Row(
          children: [
            Container(width: 50, height: 50, color: colorScheme.surface),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 16, color: colorScheme.surface)),
          ],
        ),
      ),
    );
  }
}

class SupermartStickySearchDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final double topPadding;
  final bool isSticked;
  final TextEditingController searchController;
  final Function(String) onSearch;
  final VoidCallback onMicTap;

  SupermartStickySearchDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.topPadding,
    required this.isSticked,
    required this.searchController,
    required this.onSearch,
    required this.onMicTap,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      padding: EdgeInsets.only(top: isSticked ? topPadding : 0),
      decoration: BoxDecoration(
        color: isSticked ? colorScheme.surface : null,
        gradient: isSticked
            ? null
            : LinearGradient(
                colors: [
                  const Color(0xFFFFA13B).withValues(alpha: 0.2),
                  const Color(0xFFFFA13B).withValues(alpha: 0)
                ],
                stops: const [0, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        boxShadow: isSticked ? colorScheme.cardShadow : [],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.border,
              width: 1,
            ),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: colorScheme.iconSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: searchController,
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: getTranslatedValue(context, 'search_for'),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                      height: 1.3,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    height: 1.3,
                  ),
                  cursorColor: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMicTap,
                child: Image.asset(
                  "assets/icons/mic.png",
                  width: 22,
                  height: 22,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 20,
                color: Colors.black,
              ),
              const SizedBox(width: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MultiProvider(providers: [
                        ChangeNotifierProvider(
                            create: (context) => NotesProvider()),
                      ], child: NotesListScreen()),
                    ),
                  );
                },
                child: Image.asset(
                  "assets/icons/note.png",
                  width: 22,
                  height: 22,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(SupermartStickySearchDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        topPadding != oldDelegate.topPadding ||
        isSticked != oldDelegate.isSticked;
  }
}

class StoreCard extends StatefulWidget {
  final String storeName;
  final String distance;
  final String location;
  final String deliveryTime;
  final String? discount;
  final double rating;
  final String imageUrl;
  final VoidCallback? onTap;
  final StoreSeller seller;

  const StoreCard({
    super.key,
    required this.storeName,
    required this.distance,
    required this.location,
    required this.deliveryTime,
    required this.rating,
    required this.imageUrl,
    required this.seller,
    this.discount,
    this.onTap,
  });

  @override
  State<StoreCard> createState() => _StoreCardState();
}

class _StoreCardState extends State<StoreCard> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEDED), width: 1),
          boxShadow: colorScheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 140,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: const Color(0xFFE0E0E0),
                        highlightColor: const Color(0xFFF5F5F5),
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.store_outlined,
                          size: 48,
                          color: colorScheme.iconDisabled,
                        ),
                      ),
                    ),
                  ),
                  if (widget.discount != null)
                    Positioned(
                      left: 8,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.discount!,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            height: 1.02,
                            letterSpacing: -0.55,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    top: 10,
                    child: GestureDetector(
                      onTap: () async {
                        // Toggle bookmark
                        widget.seller.isBookmarked = !(widget.seller.isBookmarked ?? false);
                        setState(() {});

                        // Call API
                        final result = await toggleSellerBookmarkApi(
                          context: context,
                          sellerId: widget.seller.id!,
                        );

                        if (result != null && result['status'] == 1) {
                          showMessage(
                            context,
                            result['message'] ?? 'Bookmark updated',
                            MessageType.success,
                          );
                        } else {
                          // Revert the toggle if API call failed
                          widget.seller.isBookmarked = !(widget.seller.isBookmarked ?? false);
                          setState(() {});
                          showMessage(
                            context,
                            result?['message'] ?? 'Failed to update bookmark',
                            MessageType.error,
                          );
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: colorScheme.cardShadow,
                        ),
                        child: Icon(
                          widget.seller.isBookmarked == true
                              ? Icons.bookmark
                              : Icons.bookmark_border_rounded,
                          size: 18,
                          color: widget.seller.isBookmarked == true
                              ? const Color(0xFFE8B000)
                              : colorScheme.iconPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.storeName,
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.02,
                          letterSpacing: -0.55,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.distance}, ${widget.location}',
                        style: GoogleFonts.inter(
                          color: colorScheme.textTertiary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.02,
                          letterSpacing: -0.55,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.textPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.deliveryTime,
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.02,
                              letterSpacing: -0.55,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.02,
                          letterSpacing: -0.55,
                        ),
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
}
