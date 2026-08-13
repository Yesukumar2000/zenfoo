import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/combo.dart';
import 'package:project/provider/comboDetailProvider.dart';
import 'package:project/screens/categoryProducts/widgets/banners_home.dart';
import 'package:project/screens/mainHomeScreen/categories_page.dart';
import 'package:video_player/video_player.dart';

class ComboDetailScreen extends StatefulWidget {
  final int comboId;
  const ComboDetailScreen({Key? key, required this.comboId}) : super(key: key);

  @override
  State<ComboDetailScreen> createState() => _ComboDetailScreenState();
}

class _ComboDetailScreenState extends State<ComboDetailScreen> with RouteAware {
  VideoPlayerController? _videoController;
  ScrollController _scrollController = ScrollController();
  bool showTitle = false;
  late Map<int, ComboVariant> _originalVariants;
  late Map<int, int> _originalQuantities;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      final provider = context.read<ComboDetailProvider>();
      provider.fetchDetails(context, widget.comboId).then((_) {
        // if (provider.combo?.bannerVideoUrl != null) {
        //   _initializeVideo(provider.combo!.bannerVideoUrl!);
        // }
      });
    });
  }

  @override
  void didPush() {
    super.didPush();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // Refresh combo data when returning from another screen (e.g., adding extra items)
    if (mounted) {
      Future.microtask(() {
        final provider = context.read<ComboDetailProvider>();
        provider.fetchDetails(context, widget.comboId);
      });
    }
  }

  @override
  void didUpdateWidget(ComboDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data if comboId changed
    if (oldWidget.comboId != widget.comboId) {
      Future.microtask(() {
        final provider = context.read<ComboDetailProvider>();
        provider.fetchDetails(context, widget.comboId);
      });
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !showTitle) {
      setState(() => showTitle = true);
    } else if (_scrollController.offset <= 200 && showTitle) {
      setState(() => showTitle = false);
    }
  }

  void _initializeVideo(String videoUrl) {
    _videoController = VideoPlayerController.network(videoUrl)
      ..setVolume(0)
      ..initialize().then((_) {
        setState(() {});
        _videoController?.setLooping(true);
        _videoController?.play();
      });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // Note: RouteAware methods (didPush, didPopNext) are called automatically
  // by the Navigator when this widget is part of a route

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant,
      body: Consumer<ComboDetailProvider>(
        builder: (context, provider, child) {
          if (provider.state == ComboDetailState.loading) {
            return _ComboDetailShimmer(colorScheme: colorScheme);
          }
          if (provider.state == ComboDetailState.error ||
              provider.combo == null) {
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
                      Icons.error_outline,
                      size: 56,
                      color: colorScheme.iconDisabled,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    getTranslatedValue(context, 'failed_to_load_combo'),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textPrimary,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            );
          }

          final combo = provider.combo!;
          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: false,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      background:
                          _buildHeaderWithGradient(context, combo, colorScheme),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _buildComboInfo(combo, provider, colorScheme)),
                  SliverToBoxAdapter(child: _buildCustomizeNote(colorScheme)),
                  if (combo.bannerVideoUrl != null)
                    SliverToBoxAdapter(
                      child: BannerCarousel(
                        mediaUrls: [
                          combo.bannerVideoUrl!,
                        ],
                        interval: Duration(
                            seconds: int.parse(
                                combo.bannerVideoDuration.toString() ?? "10")),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  _buildComboEssentials(combo, provider, colorScheme),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
              _buildStickyTopBar(combo, colorScheme),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<ComboDetailProvider>(
        builder: (context, provider, child) {
          if (provider.combo == null) return const SizedBox();
          return _buildBottomBar(
              context, provider, provider.combo!, colorScheme);
        },
      ),
    );
  }

  Widget _buildStickyTopBar(Combo combo, AppColorScheme colorScheme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: showTitle
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surfaceVariant,
                    colorScheme.surfaceVariant.withValues(alpha: 0.95),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surfaceVariant.withValues(alpha: 0.98),
                    colorScheme.surfaceVariant.withValues(alpha: 0.85),
                    colorScheme.surfaceVariant.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
          boxShadow: showTitle ? colorScheme.cardShadow : [],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PremiumActionButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  iconSize: 18,
                  onTap: () => Navigator.of(context).pop(),
                  colorScheme: colorScheme,
                ),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: showTitle ? 1.0 : 0.0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 200),
                      offset: showTitle
                          ? const Offset(0, 0)
                          : const Offset(0, -0.5),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          combo.name ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
                Consumer<ComboDetailProvider>(
                  builder: (context, provider, _) {
                    final isBookmarked = provider.combo?.isBookmarked ?? false;
                    return _PremiumActionButton(
                      icon: isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border_rounded,
                      iconSize: 22,
                      onTap: () {
                        if (!provider.isBookmarkLoading) {
                          HapticFeedback.lightImpact();
                          provider.toggleComboBookmark(context);
                        }
                      },
                      isActive: isBookmarked,
                      colorScheme: colorScheme,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithGradient(
      BuildContext context, Combo combo, AppColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surfaceVariant,
            colorScheme.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 80, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: colorScheme.surface,
                boxShadow: colorScheme.cardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: combo.imageUrl ?? '',
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: const Color(0xFFE0E0E0),
                    highlightColor: const Color(0xFFF5F5F5),
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => imgErrorWidget(iconSize: 40),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    colorScheme.surface.withValues(alpha: 0.5),
                    colorScheme.surface.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboInfo(
      Combo combo, ComboDetailProvider provider, AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            combo.name ?? '',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.textPrimary,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < (combo.rating?.floor() ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: const Color(0xFFFFB800),
                  size: 16,
                );
              }),
              const SizedBox(width: 6),
              Text(
                '${combo.ratingCount ?? 0}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textSecondary,
                  height: 1.3,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${combo.productCount ?? 0} items',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
              height: 1.3,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          if (combo.description != null && combo.description!.isNotEmpty)
            Text(
              combo.description!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colorScheme.textSecondary,
                height: 1.5,
                letterSpacing: -0.2,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${combo.currency}${provider.totalPrice.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              if (provider.totalSavings > 0) ...[
                Text(
                  '${combo.currency}${provider.totalActualPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                    color: colorScheme.textTertiary,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizeNote(AppColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.textPrimary,
                  height: 1.5,
                  letterSpacing: -0.2,
                ),
                children: [
                  TextSpan(
                    text: '${getTranslatedValue(context, 'note_prefix')} ',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: getTranslatedValue(context, 'combo_customize_note'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner(AppColorScheme colorScheme) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 193,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surfaceVariant,
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: colorScheme.cardShadow,
      ),
      child: AspectRatio(
        aspectRatio: 1.99,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(_videoController!),
              Positioned(
                bottom: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_formatDuration(_videoController!.value.position)} / ${_formatDuration(_videoController!.value.duration)}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildComboEssentials(
      Combo combo, ComboDetailProvider provider, AppColorScheme colorScheme) {
    if (combo.stores == null || combo.stores!.isEmpty) {
      return const SliverToBoxAdapter();
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        color: colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.spa, color: colorScheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      getTranslatedValue(context, 'combo_essentials'),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (combo.isAlreadyAdded == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(getTranslatedValue(
                              context, 'please_add_combo_to_cart')),
                          backgroundColor: Color(0xFFE53E3E),
                        ),
                      );
                      return;
                    }
                    // Toggle inline editing mode
                    if (!provider.isEditingCombo) {
                      // Entering edit mode - capture original state
                      _originalVariants = Map.from(provider.selectedVariants);
                      _originalQuantities =
                          Map.from(provider.productQuantities);
                    }
                    provider.toggleEditingMode();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: provider.isEditingCombo
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: colorScheme.primary, width: 1.5),
                    ),
                    child: Text(
                      provider.isEditingCombo
                          ? getTranslatedValue(context, 'done_label')
                          : getTranslatedValue(context, 'edit_label'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              combo.stores!.length == 1
                  ? (combo.stores!.first.storeName ?? '')
                  : getTranslatedValue(context, 'stores_count')
                      .replaceAll('{count}', combo.stores!.length.toString()),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: colorScheme.textSecondary,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 16),
            ...combo.stores!.map((store) {
              if (store.products == null || store.products!.isEmpty) {
                return const SizedBox();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (combo.stores!.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 22),
                      child: Text(
                        store.storeName ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ...store.products!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;
                    final isLast = index == store.products!.length - 1;
                    return _buildProductItem(
                      context,
                      product,
                      provider,
                      store.storeName,
                      isLast,
                      colorScheme,
                      combo.id!,
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(
      BuildContext context,
      ComboProduct product,
      ComboDetailProvider provider,
      String? storeName,
      bool isLast,
      AppColorScheme colorScheme,
      int comboId) {
    final selectedVariant = provider.selectedVariants[product.productId];
    final quantity = provider.productQuantities[product.productId] ?? 1;
    final isEditing = provider.isEditingCombo;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEditing
            ? colorScheme.surfaceVariant.withValues(alpha: 0.5)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: colorScheme.surfaceVariant,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: product.productImage ?? '',
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: const Color(0xFFE0E0E0),
                      highlightColor: const Color(0xFFF5F5F5),
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => imgErrorWidget(iconSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (product.rating?.floor() ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFFFB800),
                            size: 12,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          '${product.ratingCount ?? 0}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textSecondary,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorScheme.border, width: 1),
                      ),
                      child: Text(
                        'QTY: ${selectedVariant?.measurement} ${selectedVariant?.unit}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (!isEditing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'x$quantity',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textSecondary,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${selectedVariant?.currency}${selectedVariant?.price}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if ((selectedVariant?.actualPrice ?? 0) >
                        (selectedVariant?.price ?? 0))
                      Text(
                        '${selectedVariant?.currency}${selectedVariant?.actualPrice}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.lineThrough,
                          color: colorScheme.textTertiary,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                      ),
                  ],
                ),
            ],
          ),
          // Show edit controls when in editing mode
          if (isEditing) ...[
            const SizedBox(height: 12),
            Divider(color: colorScheme.border, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Variant Selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Variant',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textSecondary,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: colorScheme.border, width: 1),
                          borderRadius: BorderRadius.circular(6),
                          color: colorScheme.surface,
                        ),
                        child: DropdownButton<int>(
                          value: selectedVariant?.id,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          isDense: true,
                          items: product.variants?.map((variant) {
                                return DropdownMenuItem(
                                  value: variant.id,
                                  child: Text(
                                    '${variant.measurement} ${variant.unit}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.textPrimary,
                                    ),
                                  ),
                                );
                              }).toList() ??
                              [],
                          onChanged: (variantId) async {
                            if (variantId != null) {
                              final variant = product.variants
                                  ?.firstWhere((v) => v.id == variantId);
                              if (variant != null) {
                                HapticFeedback.lightImpact();
                                provider.updateSelectedVariant(
                                  product.productId!,
                                  variant,
                                );

                                // Call API to update the product variant
                                final success =
                                    await provider.updateCartComboProduct(
                                  context: context,
                                  comboId: comboId,
                                  productId: product.productId!,
                                );

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Variant updated successfully'),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: colorScheme.primary,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update variant'),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Quantity Editor
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Quantity',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textSecondary,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.border, width: 1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              if (quantity > 1) {
                                provider.updateProductQuantity(
                                  product.productId!,
                                  quantity - 1,
                                );

                                // Call API to update quantity
                                await provider.updateCartComboProduct(
                                  context: context,
                                  comboId: comboId,
                                  productId: product.productId!,
                                );
                              } else {
                                // Remove item when quantity is 1
                                final success = await provider.removeProduct(
                                    context, product.productId!);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Item removed successfully'),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: colorScheme.primary,
                                    ),
                                  );
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to remove item'),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Icon(
                                quantity == 1
                                    ? Icons.delete_outline
                                    : Icons.remove,
                                size: 16,
                                color: quantity == 1
                                    ? colorScheme.error
                                    : colorScheme.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            constraints: const BoxConstraints(minWidth: 30),
                            child: Text(
                              '$quantity',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.textPrimary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              provider.updateProductQuantity(
                                product.productId!,
                                quantity + 1,
                              );

                              // Call API to update quantity
                              await provider.updateCartComboProduct(
                                context: context,
                                comboId: comboId,
                                productId: product.productId!,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleEditDone(
    BuildContext context,
    ComboDetailProvider provider,
    Map<int, ComboVariant> originalVariants,
    Map<int, int> originalQuantities,
  ) async {
    if (provider.combo == null) return;

    bool hasChanges = false;
    List<Future<bool>> apiCalls = [];

    provider.selectedVariants.forEach((productId, currentVariant) {
      final originalVariant = originalVariants[productId];
      final currentQuantity = provider.productQuantities[productId] ?? 1;
      final originalQuantity = originalQuantities[productId] ?? 1;

      final variantChanged = originalVariant?.id != currentVariant.id;
      final quantityChanged = currentQuantity != originalQuantity;

      if (variantChanged || quantityChanged) {
        hasChanges = true;

        if (variantChanged) {
          apiCalls.add(_handleVariantChange(
            context,
            provider,
            productId,
            originalVariant!,
            currentVariant,
            currentQuantity,
          ));
        } else if (quantityChanged) {
          apiCalls.add(provider.updateProductInCart(context, productId));
        }
      }
    });

    if (!hasChanges) {
      Navigator.pop(context);
      setState(() {});
      return;
    }

    try {
      final results = await Future.wait(apiCalls);
      final allSuccess = results.every((result) => result == true);

      if (allSuccess) {
        Navigator.pop(context);
        setState(() {});
        showMessage(
          context,
          'Combo updated successfully',
          MessageType.success,
        );
      } else {
        showMessage(
          context,
          'Some items failed to update',
          MessageType.warning,
        );
      }
    } catch (e) {
      showMessage(
        context,
        'Failed to update combo',
        MessageType.error,
      );
    }
  }

  Future<bool> _handleVariantChange(
    BuildContext context,
    ComboDetailProvider provider,
    int productId,
    ComboVariant oldVariant,
    ComboVariant newVariant,
    int quantity,
  ) async {
    if (provider.combo == null) return false;

    final deleteSuccess = await deleteSingleCustomProduct(
      context: context,
      comboId: provider.combo!.id!,
      productId: productId,
    );

    if (deleteSuccess == null || deleteSuccess['status'] != 1) {
      return false;
    }

    final addSuccess = await addOrEditCustomComboProduct(
      context: context,
      comboId: provider.combo!.id!,
      productId: productId,
      variantId: newVariant.id!,
      quantity: quantity,
    );

    return addSuccess != null && addSuccess['status'] == 1;
  }

  Widget _buildEditableProductItem(
      ComboProduct product,
      ComboDetailProvider provider,
      StateSetter setModalState,
      AppColorScheme colorScheme) {
    final selectedVariant = provider.selectedVariants[product.productId];
    final quantity = provider.productQuantities[product.productId] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: colorScheme.surfaceVariant,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: product.productImage ?? '',
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: const Color(0xFFE0E0E0),
                      highlightColor: const Color(0xFFF5F5F5),
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => imgErrorWidget(iconSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${selectedVariant?.currency}${selectedVariant?.price}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              _buildQuantityControls(
                  product, provider, quantity, setModalState, colorScheme),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              if (product.variants != null && product.variants!.length > 1) {
                HapticFeedback.lightImpact();
                _showVariantSelectionSheet(
                    context, product, provider, setModalState, colorScheme);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.border, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslatedValue(context, 'qty_format')
                        .replaceAll('{measurement}',
                            (selectedVariant?.measurement ?? '').toString())
                        .replaceAll(
                            '{unit}', (selectedVariant?.unit ?? '').toString()),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textPrimary,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (product.variants != null && product.variants!.length > 1)
                    Icon(Icons.keyboard_arrow_down,
                        size: 16, color: colorScheme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(
      ComboProduct product,
      ComboDetailProvider provider,
      int quantity,
      StateSetter setModalState,
      AppColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 100,
        minHeight: 44,
        maxWidth: 100,
        maxHeight: 44,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(
          width: 1.5,
          color: colorScheme.primary,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                if (quantity > 1) {
                  provider.updateProductQuantity(
                    product.productId!,
                    quantity - 1,
                  );
                  setModalState(() {});
                } else {
                  _showDeleteConfirmation(
                      context, product, provider, setModalState, colorScheme);
                }
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: Container(
                width: 36,
                height: 44,
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                '$quantity',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                provider.updateProductQuantity(
                  product.productId!,
                  quantity + 1,
                );
                setModalState(() {});
              },
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Container(
                width: 36,
                height: 44,
                alignment: Alignment.center,
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context,
      ComboProduct product,
      ComboDetailProvider provider,
      StateSetter parentSetState,
      AppColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          getTranslatedValue(context, 'remove_item_confirmation'),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.textPrimary,
            height: 1.2,
            letterSpacing: -0.3,
          ),
        ),
        content: Text(
          getTranslatedValue(context, 'remove_item_message')
              .replaceAll('{product}', product.productName ?? ''),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colorScheme.textSecondary,
            height: 1.5,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Text(
              getTranslatedValue(context, 'cancel_label'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.textSecondary,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              provider.removeProduct(context, product.productId!);
              parentSetState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              getTranslatedValue(context, 'remove_label'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVariantSelectionSheet(
      BuildContext context,
      ComboProduct product,
      ComboDetailProvider provider,
      StateSetter parentSetState,
      AppColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getTranslatedValue(context, 'select_quantity'),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
                height: 1.2,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 20),
            if (product.variants != null)
              ...product.variants!.map((variant) {
                final isSelected =
                    provider.selectedVariants[product.productId]?.id ==
                        variant.id;
                return InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    provider.updateSelectedVariant(
                      product.productId!,
                      variant,
                    );
                    parentSetState(() {});
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colorScheme.border, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.border,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            getTranslatedValue(context, 'qty_format')
                                .replaceAll('{measurement}',
                                    (variant.measurement ?? '').toString())
                                .replaceAll(
                                    '{unit}', (variant.unit ?? '').toString()),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.textPrimary,
                              height: 1.3,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Text(
                          '${variant.currency}${variant.price}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                            height: 1.15,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ComboDetailProvider provider,
      Combo combo, AppColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: colorScheme.cardShadow,
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (combo.isAlreadyAdded == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(getTranslatedValue(
                                context, 'please_add_combo_to_cart')),
                            backgroundColor: Color(0xFFE53E3E),
                          ),
                        );
                        return;
                      }
                      _showAddExtraItemsSheet(context, combo, provider);
                    },
                    icon: Icon(Icons.add, size: 18, color: colorScheme.primary),
                    label: Text(
                      getTranslatedValue(context, 'add_extra_items'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ComboCartButton(
                  comboId: widget.comboId,
                  provider: provider,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddExtraItemsSheet(
      BuildContext context, Combo combo, ComboDetailProvider provider) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: ChangeNotifierProvider.value(
          value: provider,
          child: CategoriesPage(
            combo: combo,
          ),
        ),
      ),
    );
    provider.refreshCartStatus(context);
    provider.fetchDetails(context, combo.id!);
  }
}

class ComboCartButton extends StatelessWidget {
  final int comboId;
  final ComboDetailProvider provider;
  final AppColorScheme colorScheme;

  const ComboCartButton({
    Key? key,
    required this.comboId,
    required this.provider,
    required this.colorScheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isInCart = provider.isComboInCart;
    final isLoading = provider.isAddingToCart || provider.isDeletingCombo;

    if (isLoading) {
      return Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          border: Border.all(width: 1.5, color: colorScheme.primary),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ),
      );
    }

    if (isInCart) {
      return PopupMenuButton<String>(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        offset: const Offset(0, -100),
        onSelected: (value) async {
          HapticFeedback.lightImpact();
          if (value == 'remove') {
            _showRemoveConfirmation(context);
          } else if (value == 'view_cart') {
            Navigator.pushNamed(context, cartScreen);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'view_cart',
            child: Row(
              children: [
                Icon(Icons.shopping_cart, size: 18, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  getTranslatedValue(context, 'view_cart_label'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textPrimary,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFFF4444)),
                const SizedBox(width: 12),
                Text(
                  getTranslatedValue(context, 'remove_label'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF4444),
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            border: Border.all(width: 1.5, color: colorScheme.primary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  getTranslatedValue(context, 'in_cart_label'),
                  style: GoogleFonts.inter(
                    color: colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down,
                    size: 18, color: colorScheme.primary),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onAddTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: colorScheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  getTranslatedValue(context, 'add_to_cart_label'),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAddTap(BuildContext context) async {
    HapticFeedback.lightImpact();
    await provider.addComboToCart(context);
  }

  void _showRemoveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          getTranslatedValue(context, 'remove_combo_confirmation'),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.textPrimary,
            height: 1.2,
            letterSpacing: -0.3,
          ),
        ),
        content: Text(
          getTranslatedValue(context, 'remove_combo_message'),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colorScheme.textSecondary,
            height: 1.5,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Text(
              getTranslatedValue(context, 'cancel_label'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.textSecondary,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              await provider.deleteComboFromCart(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              getTranslatedValue(context, 'remove_label'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumActionButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;
  final bool isActive;
  final AppColorScheme colorScheme;

  const _PremiumActionButton({
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
          color: colorScheme.surface.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.border.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: colorScheme.cardShadow,
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: isActive ? colorScheme.primary : colorScheme.iconPrimary,
          ),
        ),
      ),
    );
  }
}

// Shimmer loading widget for combo details
class _ComboDetailShimmer extends StatefulWidget {
  final AppColorScheme colorScheme;

  const _ComboDetailShimmer({required this.colorScheme});

  @override
  State<_ComboDetailShimmer> createState() => _ComboDetailShimmerState();
}

class _ComboDetailShimmerState extends State<_ComboDetailShimmer>
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
    final shimmerBaseColor = widget.colorScheme.isDark
        ? const Color(0xFF2D3339)
        : const Color(0xFFE0E0E0);
    final shimmerHighlightColor = widget.colorScheme.isDark
        ? const Color(0xFF3C4248)
        : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomScrollView(
          slivers: [
            // Header Image Shimmer
            SliverToBoxAdapter(
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      shimmerBaseColor,
                      shimmerHighlightColor,
                      shimmerBaseColor,
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
            // Combo Info Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: widget.colorScheme.border, width: 1),
                  boxShadow: widget.colorScheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    _buildShimmerBox(
                      width: double.infinity,
                      height: 24,
                      baseColor: shimmerBaseColor,
                      highlightColor: shimmerHighlightColor,
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    _buildShimmerBox(
                      width: 200,
                      height: 16,
                      baseColor: shimmerBaseColor,
                      highlightColor: shimmerHighlightColor,
                    ),
                    const SizedBox(height: 20),
                    // Price and discount
                    Row(
                      children: [
                        _buildShimmerBox(
                          width: 80,
                          height: 28,
                          baseColor: shimmerBaseColor,
                          highlightColor: shimmerHighlightColor,
                        ),
                        const SizedBox(width: 12),
                        _buildShimmerBox(
                          width: 60,
                          height: 20,
                          baseColor: shimmerBaseColor,
                          highlightColor: shimmerHighlightColor,
                        ),
                        const Spacer(),
                        _buildShimmerBox(
                          width: 100,
                          height: 36,
                          baseColor: shimmerBaseColor,
                          highlightColor: shimmerHighlightColor,
                          borderRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Description lines
                    _buildShimmerBox(
                      width: double.infinity,
                      height: 14,
                      baseColor: shimmerBaseColor,
                      highlightColor: shimmerHighlightColor,
                    ),
                    const SizedBox(height: 8),
                    _buildShimmerBox(
                      width: double.infinity,
                      height: 14,
                      baseColor: shimmerBaseColor,
                      highlightColor: shimmerHighlightColor,
                    ),
                    const SizedBox(height: 8),
                    _buildShimmerBox(
                      width: 250,
                      height: 14,
                      baseColor: shimmerBaseColor,
                      highlightColor: shimmerHighlightColor,
                    ),
                  ],
                ),
              ),
            ),
            // Customize Note
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    _buildShimmerBox(
                      width: 20,
                      height: 20,
                      baseColor: shimmerBaseColor,
                      highlightColor: shimmerHighlightColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildShimmerBox(
                        width: double.infinity,
                        height: 14,
                        baseColor: shimmerBaseColor,
                        highlightColor: shimmerHighlightColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Combo Items
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: widget.colorScheme.border, width: 1),
                      boxShadow: widget.colorScheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category header
                        Row(
                          children: [
                            _buildShimmerBox(
                              width: 24,
                              height: 24,
                              baseColor: shimmerBaseColor,
                              highlightColor: shimmerHighlightColor,
                              borderRadius: 8,
                            ),
                            const SizedBox(width: 12),
                            _buildShimmerBox(
                              width: 120,
                              height: 18,
                              baseColor: shimmerBaseColor,
                              highlightColor: shimmerHighlightColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Product items
                        ...List.generate(
                          2,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                _buildShimmerBox(
                                  width: 80,
                                  height: 80,
                                  baseColor: shimmerBaseColor,
                                  highlightColor: shimmerHighlightColor,
                                  borderRadius: 12,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildShimmerBox(
                                        width: double.infinity,
                                        height: 16,
                                        baseColor: shimmerBaseColor,
                                        highlightColor: shimmerHighlightColor,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildShimmerBox(
                                        width: 100,
                                        height: 14,
                                        baseColor: shimmerBaseColor,
                                        highlightColor: shimmerHighlightColor,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildShimmerBox(
                                            width: 60,
                                            height: 18,
                                            baseColor: shimmerBaseColor,
                                            highlightColor:
                                                shimmerHighlightColor,
                                          ),
                                          _buildShimmerBox(
                                            width: 100,
                                            height: 32,
                                            baseColor: shimmerBaseColor,
                                            highlightColor:
                                                shimmerHighlightColor,
                                            borderRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  childCount: 3,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required Color baseColor,
    required Color highlightColor,
    double borderRadius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: [
            _animation.value - 0.3,
            _animation.value,
            _animation.value + 0.3,
          ].map((e) => e.clamp(0.0, 1.0)).toList(),
        ),
      ),
    );
  }
}
