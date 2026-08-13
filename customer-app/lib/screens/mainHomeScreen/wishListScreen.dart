import 'package:project/helper/styles/product_card_metrics.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/screens/categoryProducts/widgets/product_card.dart';

class WishListScreen extends StatefulWidget {
  final ScrollController scrollController;

  const WishListScreen({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<WishListScreen> createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen> {
  void scrollListener() {
    final nextPageTrigger =
        0.7 * widget.scrollController.position.maxScrollExtent;

    if (widget.scrollController.position.pixels > nextPageTrigger) {
      if (!mounted) return;
      final provider = context.read<ProductWishListProvider>();
      if (provider.hasMoreData) {
        callApi(isReset: false);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero).then((_) async {
      try {
        widget.scrollController.addListener(scrollListener);
        await callApi(isReset: true);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    try {
      widget.scrollController.removeListener(scrollListener);
      Constant.resetTempFilters();
    } catch (_) {}
    super.dispose();
  }

  Future<void> callApi({required bool isReset}) async {
    if (Constant.session.isUserLoggedIn()) {
      final provider = context.read<ProductWishListProvider>();
      if (isReset) {
        provider.offset = 0;
        provider.wishlistProducts = [];
      }
      final params = await Constant.getProductsDefaultParams();
      await provider.getProductWishListProvider(
        context: context,
        params: params,
      );
    } else {
      setState(() {
        context.read<ProductWishListProvider>().productWishListState =
            ProductWishListState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: AppHeader(
            title: getTranslatedValue(context, wishListLabel),
            label: getTranslatedValue(context, 'saved_items'),
            onBackPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            showBackButton: true,
          )),
      body: Stack(
        children: [
          setRefreshIndicator(
            refreshCallback: () async {
              context
                  .read<CartListProvider>()
                  .getAllCartItems(context: context);
              await callApi(isReset: true);
            },
            child: CustomScrollView(
              controller: widget.scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      getSearchWidget(context: context),
                    ],
                  ),
                ),
                productWidget(colorScheme),
              ],
            ),
          ),
          if (cartProvider.totalItemsCount > 0)
            PositionedDirectional(
              bottom: 0,
              start: 0,
              end: 0,
              child: CartOverlay(),
            ),
        ],
      ),
    );
  }

  Widget productWidget(AppColorScheme colorScheme) {
    return Consumer<ProductWishListProvider>(
      builder: (context, productWishlistProvider, _) {
        final state = productWishlistProvider.productWishListState;
        final wishlistProducts = productWishlistProvider.wishlistProducts;

        if (state == ProductWishListState.initial ||
            state == ProductWishListState.loading) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: productGridGutter,
                crossAxisSpacing: productGridGutter,
                mainAxisExtent: productCardExtent,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, idx) => _buildProductShimmer(colorScheme),
                childCount: 6,
              ),
            ),
          );
        }

        if (state == ProductWishListState.loaded ||
            state == ProductWishListState.loadingMore) {
          if (wishlistProducts.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(colorScheme),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: productGridGutter,
                crossAxisSpacing: productGridGutter,
                mainAxisExtent: productCardExtent,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, idx) {
                  if (idx < wishlistProducts.length) {
                    final product = wishlistProducts[idx];
                    return MiniProductCardContainer(product: product);
                  }
                  if (state == ProductWishListState.loadingMore) {
                    return _buildProductShimmer(colorScheme);
                  }
                  return const SizedBox.shrink();
                },
                childCount: wishlistProducts.length +
                    (state == ProductWishListState.loadingMore ? 2 : 0),
              ),
            ),
          );
        }

        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(colorScheme),
        );
      },
    );
  }

  Widget _buildProductShimmer(AppColorScheme colorScheme) {
    return Container(
      decoration: ShapeDecoration(
        color: colorScheme.cardBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.border, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomShimmer(
            height: 180,
            width: double.infinity,
            borderRadius: 16,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomShimmer(
                  height: 16,
                  width: double.infinity,
                  borderRadius: 8,
                ),
                const SizedBox(height: 8),
                CustomShimmer(
                  height: 14,
                  width: 100,
                  borderRadius: 8,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CustomShimmer(
                      height: 20,
                      width: 60,
                      borderRadius: 8,
                    ),
                    const SizedBox(width: 8),
                    CustomShimmer(
                      height: 20,
                      width: 40,
                      borderRadius: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  width: 8,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 72,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              getTranslatedValue(context, emptyWishListMessageLabel),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              getTranslatedValue(context, emptyWishListDescriptionLabel),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
