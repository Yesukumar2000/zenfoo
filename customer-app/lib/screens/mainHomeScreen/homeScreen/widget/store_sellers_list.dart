import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/store_with_category_group.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:velocity_x/velocity_x.dart';

class StoreSellersListWidget extends StatefulWidget {
  final List<StoreSeller> sellers;
  final Function(StoreSeller)? onSellerTap;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final ScrollController? scrollController;

  const StoreSellersListWidget({
    Key? key,
    required this.sellers,
    this.onSellerTap,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.scrollController,
  }) : super(key: key);

  @override
  State<StoreSellersListWidget> createState() => _StoreSellersListWidgetState();
}

class _StoreSellersListWidgetState extends State<StoreSellersListWidget> {
  int? _loadingSellerIndex;
  bool _isListeningToScroll = false;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _isListeningToScroll = true;
      widget.scrollController!.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    try {
      if (widget.scrollController != null && _isListeningToScroll) {
        widget.scrollController!.removeListener(_onScroll);
        _isListeningToScroll = false;
      }
    } catch (e) {
      debugPrint('Error removing scroll listener: $e');
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_isListeningToScroll) return;
    if (widget.scrollController == null) return;
    if (!widget.scrollController!.hasClients) return;
    if (!mounted) return;
    if (_loadingSellerIndex != null) return; // Don't load more while navigating

    try {
      final scrollController = widget.scrollController!;
      // Check if user scrolled near the bottom
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 300) {
        // Load more if available and not already loading
        if (widget.hasMore && !widget.isLoadingMore) {
          widget.onLoadMore?.call();
        }
      }
    } catch (e) {
      // Safely ignore errors during scroll events
      debugPrint('Scroll error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sellers.isEmpty) return const SizedBox.shrink();

    // Filter only active sellers
    final activeSellers = widget.sellers.where((s) => s.status == 1).toList();
    if (activeSellers.isEmpty) return const SizedBox.shrink();

    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Nearby Resturants',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.02,
              letterSpacing: -0.55,
            ),
          ),
        ),
        // Sortings Section
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SortingsSection(),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: activeSellers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final seller = activeSellers[index];
            return _buildSellerCard(context, seller, index, colorScheme);
          },
        ),
        // Load More Indicator at Bottom
        if (widget.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: widget.isLoadingMore
                  ? CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 2.5,
                    )
                  : Text(
                      'Scroll down to load more stores',
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildSellerCard(BuildContext context, StoreSeller seller, int index,
      AppColorScheme colorScheme) {
    final isLoading = _loadingSellerIndex == index;
    final isShopClosed = seller.isShopOpen == false;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              // If shop is closed, show toast message and don't navigate
              if (isShopClosed) {
                showMessage(
                  context,
                  seller.shopStatusMessage ?? 'Shop is currently closed',
                  MessageType.warning,
                );
                return;
              }

              setState(() {
                _loadingSellerIndex = index;
              });

              // Small delay to show loading state
              await Future.delayed(const Duration(milliseconds: 100));

              widget.onSellerTap?.call(seller);

              // Reset loading state after navigation
              if (mounted) {
                setState(() {
                  _loadingSellerIndex = null;
                });
              }
            },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            // padding: const EdgeInsets.all(16),
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
                // Store Image Carousel with interval-based indicators
                _StoreImageCarousel(
                  seller: seller,
                  colorScheme: colorScheme,
                ),

                // Store Info Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Store name, location, delivery time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store Name
                          Text(
                            seller.storeName?.capitalized ??
                                seller.name?.capitalized ??
                                '',
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.55,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Distance + Location
                          Text(
                            '${seller.distanceKm ?? 'N/A'}, ${seller.storeLocation ?? ''}',
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              letterSpacing: -0.55,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Delivery Time with bullet
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
                                seller.travelTimeMin ?? 'N/A',
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  letterSpacing: -0.55,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right: Rating Badge
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: colorScheme.buttonPrimaryText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                seller.rating?.toStringAsFixed(1) ?? '0.0',
                                style: GoogleFonts.inter(
                                  color: colorScheme.buttonPrimaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.02,
                                  letterSpacing: -0.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By ${seller.ratingCount ?? '0'}',
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.02,
                            letterSpacing: -0.55,
                          ),
                        ),
                      ],
                    ),
                  ],
                ).pSymmetric(h: 16, v: 12),
              ],
            ),
          ),

          // Loading Overlay
          if (isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.cardBackground.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: colorScheme.primary,
                        strokeWidth: 2.5,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading store...',
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ]
      )
    );
  }
}

// Store Image Carousel Widget with interval-based indicators
class _StoreImageCarousel extends StatefulWidget {
  final StoreSeller seller;
  final dynamic colorScheme;

  const _StoreImageCarousel({
    Key? key,
    required this.seller,
    required this.colorScheme,
  }) : super(key: key);

  @override
  State<_StoreImageCarousel> createState() => _StoreImageCarouselState();
}

class _StoreImageCarouselState extends State<_StoreImageCarousel>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  Timer? _autoTimer;
  int _currentPage = 0;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    // Parse store images
    _parseStoreImages();

    // Start auto-play timer
    _startAutoTimer();
  }

  void _parseStoreImages() {
    // Get images from storeImages field (comma-separated URLs)
    if (widget.seller.storeImages != null &&
        widget.seller.storeImages!.isNotEmpty) {
      _imageUrls = widget.seller.storeImages!;
    }

    // If no store images, use logo as fallback
    if (_imageUrls.isEmpty && widget.seller.logoUrl != null) {
      _imageUrls = [widget.seller.logoUrl!];
    }
  }

  void _startAutoTimer() {
    _animationController.forward(from: 0);
    _autoTimer?.cancel();
    if (_imageUrls.length <= 1) return;
    _autoTimer = Timer(const Duration(seconds: 4), _goNext);
  }

  void _goNext() {
    if (_imageUrls.length <= 1) return;
    final next = (_currentPage + 1) % _imageUrls.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
    );
  }

  void _restartProgress() {
    _animationController.forward(from: 0);
    _autoTimer?.cancel();
    if (_imageUrls.length > 1) {
      _autoTimer = Timer(const Duration(seconds: 4), _goNext);
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.seller.isShopOpen == false) {
      return Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: widget.colorScheme.surfaceVariant,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_imageUrls.isNotEmpty)
              Opacity(
                opacity: 0.35,
                child: CachedNetworkImage(
                  imageUrl: _imageUrls.first,
                  fit: BoxFit.cover,
                  errorWidget: (context, error, stackTrace) => imgErrorWidget(icon: Icons.storefront_rounded),
                ),
              ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
            Center(
              child: Text(
                'Closed',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_imageUrls.isEmpty) {
      // No images, show placeholder
      return Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: widget.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.store_outlined,
          size: 48,
          color: widget.colorScheme.iconDisabled,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Stack(
        children: [
          // PageView for images
          PageView.builder(
            controller: _pageController,
            itemCount: _imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _restartProgress();
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: _imageUrls[index],
                fit: BoxFit.cover,
                errorWidget: (context, error, stackTrace) {
                  return imgErrorWidget(icon: Icons.storefront_rounded, iconSize: 40);
                },
              );
            },
          ),

          // Bookmark Icon (top-right)
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
                  color: widget.colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: widget.colorScheme.cardShadow,
                ),
                child: Icon(
                  widget.seller.isBookmarked == true
                      ? Icons.bookmark
                      : Icons.bookmark_border_rounded,
                  size: 18,
                  color: widget.seller.isBookmarked == true
                      ? const Color(0xFFE8B000)
                      : widget.colorScheme.iconPrimary,
                ),
              ),
            ),
          ),

          // Interval-based indicators (only show if multiple images)
          if (_imageUrls.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_imageUrls.length, (i) {
                  final isActive = i == _currentPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, _) => Container(
                        width: 24,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.grey[400]
                              : Colors.grey[300]?.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: isActive
                            ? FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _animationController.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
