import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/styles/appColorScheme.dart' as app_theme;
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/heroAnimationHelper.dart';
import 'package:project/screens/productDetailScreen/widget/otherImagesViewWidget.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:video_player/video_player.dart';

import 'package:project/provider/themeProvider.dart' as app_theme;

class ProductDetailScreen extends StatefulWidget {
  final String? title;
  final String id;
  final ProductListItem? productListItem;
  final String? from;

  const ProductDetailScreen({
    Key? key,
    this.title,
    required this.id,
    this.productListItem,
    this.from,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ScrollController scrollController = ScrollController();
  bool isSharing = false;

  scrollListener() {
    if (scrollController.position.pixels > 600) {
      if (mounted) {
        context.read<ProductDetailProvider>().changeVisibility(true);
      }
    } else {
      if (mounted) {
        context.read<ProductDetailProvider>().changeVisibility(false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((value) async {
      if (mounted) {
        scrollController.addListener(scrollListener);
        try {
          Map<String, String> params =
              await Constant.getProductsDefaultParams();
          if (widget.from == "barcode") {
            params[ApiAndParams.barcode] = widget.id;
          } else if (RegExp(r'^\d+$').hasMatch(widget.id)) {
            params[ApiAndParams.id] = widget.id;
          } else {
            params[ApiAndParams.slug] = widget.id;
          }

          // Refresh cart when coming back from coupon screen
          if (mounted) {
            await context.read<CartProvider>().refreshCart(
                  context: context,
                  silent: true,
                );
          }

          context.read<RatingListProvider>().getRatingApiProvider(
            params: {ApiAndParams.productId: widget.id.toString()},
            context: context,
            limit: "5",
          ).then(
            (value) async {
              context.read<RatingListProvider>().getRatingImagesApiProvider(
                  params: {ApiAndParams.productId: widget.id.toString()},
                  limit: "5",
                  context: context).then(
                (value) async => await context
                    .read<ProductDetailProvider>()
                    .getProductDetailProvider(
                      context: context,
                      params: params,
                    ),
              );
            },
          );
        } catch (_) {}
      }
    });
  }

  @override
  dispose() {
    scrollController.dispose();
    super.dispose();
  }

  int currentImage = 0;
  bool isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    // Get bookmark status from API data
    isBookmarked = widget.productListItem?.isBookmarked ?? false;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Consumer<ProductDetailProvider>(
            builder: (context, productDetailProvider, child) {
              // Show content with hero animation during loading if productListItem exists
              // Otherwise show shimmer
              if (productDetailProvider.productDetailState ==
                      ProductDetailState.loaded ||
                  (widget.productListItem != null &&
                      (productDetailProvider.productDetailState ==
                              ProductDetailState.initial ||
                          productDetailProvider.productDetailState ==
                              ProductDetailState.loading))) {
                return ChangeNotifierProvider<SelectedVariantItemProvider>(
                  create: (context) => SelectedVariantItemProvider(),
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            // ========== Sticky Header with Product Image ==========
                            if (productDetailProvider.productDetailState ==
                                ProductDetailState.loaded)
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _ProductImageHeaderDelegate(
                                  productId: widget.id,
                                  product: productDetailProvider.productData,
                                  currentImage: currentImage,
                                  colorScheme: colorScheme,
                                  onWishlistTap: () async {
                                    if (Constant.session.isUserLoggedIn()) {
                                      try {
                                        final result =
                                            await toggleProductBookmarkApi(
                                          context: context,
                                          productId: int.parse(
                                              productDetailProvider
                                                  .productData.id),
                                        );

                                        if (result != null &&
                                            result['status'] == 1) {
                                          if (widget.productListItem != null) {
                                            widget.productListItem!
                                                .isBookmarked = !(widget
                                                    .productListItem!
                                                    .isBookmarked ??
                                                false);
                                          }
                                          setState(() {
                                            isBookmarked = !(isBookmarked);
                                          });

                                          showMessage(
                                            context,
                                            result['message'] ??
                                                'Bookmark updated',
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
                                    } else {
                                      loginUserAccount(context, "bookmark");
                                    }
                                  },
                                  onShareTap: () async {
                                    if (isSharing) return;
                                    setState(() {
                                      isSharing = true;
                                    });
                                    final box = context.findRenderObject()
                                        as RenderBox?;
                                    final sharePositionOrigin =
                                        box!.localToGlobal(Offset.zero) &
                                            box.size;

                                    await SharePlus.instance.share(
                                      ShareParams(
                                        text:
                                            "${productDetailProvider.productData.name}\n\n${Constant.websiteUrl}product/${productDetailProvider.productData.id}?isMobile=true",
                                        subject: getTranslatedValue(
                                            context, 'share_product'),
                                        sharePositionOrigin:
                                            sharePositionOrigin,
                                      ),
                                    );
                                    Future.delayed(const Duration(seconds: 1),
                                        () {
                                      setState(() {
                                        isSharing = false;
                                      });
                                    });
                                  },
                                  isBookmarked: isBookmarked,
                                ),
                              ),

                            // ========== Hero Image Placeholder During Initial/Loading ==========
                            if (widget.productListItem != null &&
                                (productDetailProvider.productDetailState ==
                                        ProductDetailState.initial ||
                                    productDetailProvider.productDetailState ==
                                        ProductDetailState.loading))
                              SliverToBoxAdapter(
                                child: HeroAnimationHelper.createImageHero(
                                  tag: HeroAnimationHelper.productImageTag(
                                      widget.id),
                                  imageWidget: Container(
                                    height: 400,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(24),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(24),
                                      ),
                                      child: widget.productListItem!.imageUrl !=
                                                  null &&
                                              widget.productListItem!.imageUrl!
                                                  .isNotEmpty
                                          ? setNetworkImg(
                                              image: widget
                                                  .productListItem!.imageUrl!,
                                              boxFit: BoxFit.contain,
                                              storeId: widget.productListItem!.storeId,
                                              isMeat: widget.productListItem!.isMeatProduct ?? false,
                                              isSuperMart: widget.productListItem!.isSuperMart ?? false,
                                            )
                                          : imgErrorWidget(
                                              placeholderImageUrl: () {
                                                final url = getStorePlaceholderUrl(
                                                  storeId: widget.productListItem!.storeId,
                                                  isMeat: widget.productListItem!.isMeatProduct ?? false,
                                                  isSuperMart: widget.productListItem!.isSuperMart ?? false,
                                                );
                                                return url.isNotEmpty ? url : null;
                                              }(),
                                            ),
                                    ),
                                  ),
                                ),
                              ),

                            // ========== Product Title & Basic Info ==========
                            SliverToBoxAdapter(
                              child: Consumer<SelectedVariantItemProvider>(
                                builder:
                                    (context, selectedVariantItemProvider, _) {
                                  final isLoading = productDetailProvider
                                              .productDetailState ==
                                          ProductDetailState.loading ||
                                      productDetailProvider
                                              .productDetailState ==
                                          ProductDetailState.initial;

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        top: 12.0,
                                        bottom: 0.0,
                                        left: 12,
                                        right: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Product Title
                                        AnimatedOpacity(
                                          opacity: isLoading ? 0.5 : 1.0,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          child: HeroAnimationHelper
                                              .createMaterialHero(
                                            tag: HeroAnimationHelper
                                                .productNameTag(
                                              widget.id,
                                            ),
                                            child: Text(
                                              productDetailProvider
                                                          .productDetailState ==
                                                      ProductDetailState.loaded
                                                  ? productDetailProvider
                                                      .productData.name
                                                  : (widget.productListItem
                                                          ?.name ??
                                                      ''),
                                              style: GoogleFonts.inter(
                                                color: colorScheme.textPrimary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                height: 1.2,
                                                letterSpacing: -0.4,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            // ========== Rating Section (moved before Price to match card order) ==========
                            // Show rating from card data initially, update when API loads
                            if (productDetailProvider.productDetailState ==
                                ProductDetailState.loaded)
                              SliverToBoxAdapter(
                                child: ProductListRatingBuilderWidget(
                                  averageRating: context
                                      .read<RatingListProvider>()
                                      .productRatingData
                                      .averageRating
                                      .toString()
                                      .toDouble,
                                  totalRatings: context
                                      .read<RatingListProvider>()
                                      .totalData
                                      .toString()
                                      .toInt,
                                  size: 15,
                                  spacing: 2,
                                  fontSize: 16,
                                ).pOnly(left: 6, top: 4),
                              )
                            else if (widget.productListItem != null)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 18, top: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ...List.generate(
                                        5,
                                        (i) {
                                          final rating = double.tryParse(widget
                                                      .productListItem!
                                                      .averageRating
                                                      ?.toString() ??
                                                  "") ??
                                              0;
                                          return Icon(
                                            i < rating
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            color: i < rating
                                                ? const Color(0xFFFFB800)
                                                : colorScheme.divider,
                                            size: 15,
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "(${widget.productListItem!.ratingCount?.toString() ?? '0'})",
                                        style: GoogleFonts.inter(
                                          color: colorScheme.textTertiary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // ========== Price & Cart Section (moved after Rating to match card order) ==========
                            // Only show when data is loaded
                            if (productDetailProvider.productDetailState ==
                                ProductDetailState.loaded)
                              SliverToBoxAdapter(
                                child: Consumer<SelectedVariantItemProvider>(
                                  builder: (context,
                                      selectedVariantItemProvider, _) {
                                    return buildProductMainRow(
                                      context: context,
                                      product:
                                          productDetailProvider.productData,
                                      selectedVariantIndex:
                                          selectedVariantItemProvider
                                              .getSelectedIndex(),
                                      colorScheme: colorScheme,
                                    );
                                  },
                                ),
                              )
                            else if (widget.productListItem != null)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 4, 18, 0),
                                  child: () {
                                    final v = (widget.productListItem!.variants
                                                ?.isNotEmpty ??
                                            false)
                                        ? widget
                                            .productListItem!.variants!.first
                                        : null;
                                    final double price = double.tryParse(
                                            v?.discountedPrice ??
                                                widget.productListItem!
                                                    .discountedPrice
                                                    ?.toString() ??
                                                '0') ??
                                        0;
                                    final double oldPrice = double.tryParse(
                                            v?.price ??
                                                widget.productListItem!.price
                                                    ?.toString() ??
                                                '0') ??
                                        0;
                                    return Row(
                                      children: [
                                        Text(
                                          '₹${price.toStringAsFixed(0)}',
                                          style: GoogleFonts.inter(
                                            color: colorScheme.textPrimary,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            height: 1.2,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        if (oldPrice > price) ...[
                                          const SizedBox(width: 10),
                                          Text(
                                            '₹${oldPrice.toStringAsFixed(0)}',
                                            style: GoogleFonts.inter(
                                              color: colorScheme.textTertiary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationColor:
                                                  colorScheme.textTertiary,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  }(),
                                ),
                              ),

                            // ========== Variants Section ==========
                            if (productDetailProvider.productDetailState ==
                                ProductDetailState.loaded)
                              SliverToBoxAdapter(
                                child: Consumer<SelectedVariantItemProvider>(
                                  builder: (context,
                                      selectedVariantItemProvider, _) {
                                    return variantSelector(
                                      variants: productDetailProvider
                                          .productData.variants,
                                      selectedIndex: selectedVariantItemProvider
                                          .getSelectedIndex(),
                                      onSelect: (i) =>
                                          selectedVariantItemProvider
                                              .setSelectedIndex(i),
                                      colorScheme: colorScheme,
                                    );
                                  },
                                ),
                              )
                            else if (widget.productListItem != null &&
                                (productDetailProvider.productDetailState ==
                                        ProductDetailState.loading ||
                                    productDetailProvider.productDetailState ==
                                        ProductDetailState.initial))
                              SliverToBoxAdapter(
                                child: _ProductDetailVariantsShimmer(
                                    colorScheme: colorScheme),
                              ),

                            // ========== Product Details Widget ==========
                            if (productDetailProvider.productDetailState ==
                                ProductDetailState.loaded)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: ProductDetailWidget(
                                    context: context,
                                    product: productDetailProvider
                                        .productDetail.data,
                                  ),
                                ),
                              )
                            else if (widget.productListItem != null &&
                                (productDetailProvider.productDetailState ==
                                        ProductDetailState.loading ||
                                    productDetailProvider.productDetailState ==
                                        ProductDetailState.initial))
                              SliverToBoxAdapter(
                                child: _ProductDetailDescriptionShimmer(
                                    colorScheme: colorScheme),
                              ),

                            // ========== Bottom Spacing ==========
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 120),
                            ),
                          ],
                        ),
                      ),

                      // ========== Bottom Add to Cart Button ==========
                      // Only show when data is loaded
                      if (productDetailProvider.productDetailState ==
                          ProductDetailState.loaded)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: context.width,
                          height:
                              productDetailProvider.expanded == true ? 70 : 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  colorScheme.surface.withValues(alpha: 0.95),
                                  colorScheme.surface,
                                ],
                              ),
                              borderRadius: const BorderRadiusDirectional.only(
                                topStart: Radius.circular(16),
                                topEnd: Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.textPrimary
                                      .withValues(alpha: 0.04),
                                  offset: const Offset(0, -2),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadiusDirectional.only(
                                topStart: Radius.circular(16),
                                topEnd: Radius.circular(16),
                              ),
                              child: ProductDetailAddToCartButtonWidget(
                                context: context,
                                product: productDetailProvider.productData,
                                bgColor: Colors.transparent,
                                padding: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              } else if (productDetailProvider.productDetailState ==
                      ProductDetailState.loading ||
                  productDetailProvider.productDetailState ==
                      ProductDetailState.initial) {
                return getProductDetailShimmer(
                    context: context, colorScheme: colorScheme);
              } else if (productDetailProvider.productDetailState ==
                  ProductDetailState.error) {
                return DefaultBlankItemMessageScreen(
                  title: getTranslatedValue(context, 'oopsLabel'),
                  description:
                      getTranslatedValue(context, 'productUnavailableLabel'),
                  image: "no_product_icon",
                  buttonTitle: getTranslatedValue(context, 'goBackLabel'),
                  callback: () {
                    Navigator.pop(context);
                  },
                );
              } else {
                return NoInternetConnectionScreen(
                  height: context.height * 0.65,
                  message: productDetailProvider.message,
                  callback: () async {
                    if (mounted) {
                      try {
                        Map<String, String> params =
                            await Constant.getProductsDefaultParams();
                        params[ApiAndParams.id] = widget.id;

                        context.read<RatingListProvider>().getRatingApiProvider(
                          params: {
                            ApiAndParams.productId: widget.id.toString()
                          },
                          context: context,
                          limit: "5",
                        ).then(
                          (value) async {
                            context
                                .read<RatingListProvider>()
                                .getRatingImagesApiProvider(params: {
                              ApiAndParams.productId: widget.id.toString()
                            }, limit: "5", context: context).then(
                              (value) async => await context
                                  .read<ProductDetailProvider>()
                                  .getProductDetailProvider(
                                    context: context,
                                    params: params,
                                  ),
                            );
                          },
                        );
                      } catch (_) {}
                    }
                  },
                );
              }
            },
          ),

          // ========== Cart Overlay - Only show if cart has items ==========
          if (context.watch<CartProvider>().isDataLoaded &&
              (context
                          .watch<CartProvider>()
                          .cartData
                          ?.data
                          .getAllCartItems()
                          .length ??
                      0) >
                  0)
            PositionedDirectional(
              bottom: context.watch<ProductDetailProvider>().expanded == true
                  ? 120
                  : 20,
              start: 0,
              end: 0,
              child: CartOverlay(),
            ),
        ],
      ),
    );
  }

  // ========== Updated Price & Cart Section with Better Spacing ==========
  Widget buildProductMainRow({
    required BuildContext context,
    required ProductData product,
    required int selectedVariantIndex,
    required app_theme.AppColorScheme colorScheme,
  }) {
    final variant = product.variants[selectedVariantIndex];
    final double price = double.tryParse(variant.price) ?? 0;
    final double discountedPrice =
        double.tryParse(variant.discountedPrice) ?? 0;
    final bool hasDiscount = discountedPrice > 0 && discountedPrice < price;
    final int discountPercent =
        getDiscountPercent(variant.price, variant.discountedPrice);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Measurement
                Text(
                  '${variant.measurement} ${variant.stockUnitName} approx',
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                // Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Current Price
                    Text(
                      '₹${hasDiscount ? discountedPrice.toStringAsFixed(0) : price.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 10),
                      // Original Price
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          color: colorScheme.textTertiary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: colorScheme.textTertiary,
                          decorationThickness: 1.5,
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Discount Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF3FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$discountPercent% OFF',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1F5AF8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Cart Button
          ProductCartButton(
            count: int.parse(variant.cartCount.toString()),
            productId: product.id.toString(),
            productVariantId: variant.id.toString(),
            isUnlimitedStock: product.isUnlimitedStock == "1",
            maximumAllowedQuantity:
                double.parse(product.totalAllowedQuantity.toString()),
            availableStock: double.parse(variant.stock.toString()),
            isGrid: false,
            from: "product_details",
            sellerId: product.sellerId.toString(),
          ).w(120),
        ],
      ),
    );
  }

  // ========== Updated Variant Selector with Better Spacing ==========
  Widget variantSelector({
    required List<ProductDetailVariants> variants,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
    required app_theme.AppColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              getTranslatedValue(context, 'available_variants'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.02,
                letterSpacing: -0.55,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Variant Cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(variants.length, (index) {
                final v = variants[index];
                final isSelected = index == selectedIndex;
                final double price = double.tryParse(v.price) ?? 0;
                final double discountedPrice =
                    double.tryParse(v.discountedPrice) ?? 0;
                final bool hasDiscount =
                    discountedPrice > 0 && discountedPrice < price;

                // Check if variant is out of stock
                final isOutOfStock = v.status == "0" ||
                    (v.isUnlimitedStock != "1" &&
                        (double.tryParse(v.stock ?? "0") ?? 0) <= 0);

                return GestureDetector(
                  onTap: isOutOfStock
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          onSelect(index);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.only(
                      right: index == variants.length - 1 ? 0 : 8,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    constraints: const BoxConstraints(minWidth: 140),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? colorScheme.surfaceVariant
                          : isSelected
                              ? colorScheme.primary.withValues(alpha: 0.1)
                              : colorScheme.surface,
                      border: Border.all(
                        color: isOutOfStock
                            ? colorScheme.divider
                            : isSelected
                                ? colorScheme.primary
                                : colorScheme.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected && !isOutOfStock
                          ? [
                              BoxShadow(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                blurRadius: 12,
                                spreadRadius: 0,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Opacity(
                      opacity: isOutOfStock ? 0.5 : 1.0,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Image
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: colorScheme.surface,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: setNetworkImg(
                                    image: v.images.isNotEmpty
                                        ? v.images[0]
                                        : v.product?['image_url'] ??
                                            "https://placehold.co/64x64",
                                    boxFit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Content
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Measurement
                                  Text(
                                    '${v.measurement} ${v.stockUnitName}',
                                    style: GoogleFonts.inter(
                                      color: colorScheme.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 4),
                                  // Price
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '₹${hasDiscount ? discountedPrice.toStringAsFixed(0) : price.toStringAsFixed(0)}',
                                        style: GoogleFonts.inter(
                                          color: colorScheme.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      if (hasDiscount) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '₹${price.toStringAsFixed(0)}',
                                          style: GoogleFonts.inter(
                                            color: colorScheme.textTertiary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationColor:
                                                colorScheme.textTertiary,
                                            height: 1.2,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              // Conditional spacing for checkmark
                              if (isSelected && !isOutOfStock)
                                const SizedBox(width: 8),
                            ],
                          ),
                          // Selected Checkmark
                          if (isSelected && !isOutOfStock)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: colorScheme.buttonPrimaryText,
                                  size: 12,
                                ),
                              ),
                            ),
                          // Out of Stock Badge
                          if (isOutOfStock)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53E3E),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1AE53E3E),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  getTranslatedValue(
                                      context, 'out_of_stock_badge'),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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

  Widget getProductDetailShimmer({
    required BuildContext context,
    required app_theme.AppColorScheme colorScheme,
  }) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Image Shimmer
        SliverToBoxAdapter(
          child: _ProductDetailImageShimmer(
            height: context.width * 0.89,
            width: context.width,
            colorScheme: colorScheme,
          ),
        ),

        // Product Info Card Shimmer
        SliverToBoxAdapter(
          child: _ProductDetailInfoShimmer(colorScheme: colorScheme),
        ),

        // Variants Shimmer
        SliverToBoxAdapter(
          child: _ProductDetailVariantsShimmer(colorScheme: colorScheme),
        ),

        // Product Details Section Shimmer
        SliverToBoxAdapter(
          child: _ProductDetailDescriptionShimmer(colorScheme: colorScheme),
        ),

        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }
}

// Modern Animated Shimmer Components
class _ProductDetailImageShimmer extends StatefulWidget {
  final double height;
  final double width;

  const _ProductDetailImageShimmer({
    Key? key,
    required this.height,
    required this.width,
    required colorScheme,
  }) : super(key: key);

  @override
  State<_ProductDetailImageShimmer> createState() =>
      _ProductDetailImageShimmerState();
}

class _ProductDetailImageShimmerState extends State<_ProductDetailImageShimmer>
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
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

class _ProductDetailInfoShimmer extends StatefulWidget {
  const _ProductDetailInfoShimmer({Key? key, required colorScheme})
      : super(key: key);

  @override
  State<_ProductDetailInfoShimmer> createState() =>
      _ProductDetailInfoShimmerState();
}

class _ProductDetailInfoShimmerState extends State<_ProductDetailInfoShimmer>
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

  Widget _buildShimmerBox(double height, double width) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFFE0E0E0),
            Color(0xFFF5F5F5),
            Color(0xFFE0E0E0),
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title shimmer
              _buildShimmerBox(20, MediaQuery.of(context).size.width * 0.7),
              const SizedBox(height: 8),
              _buildShimmerBox(20, MediaQuery.of(context).size.width * 0.5),
              const SizedBox(height: 16),

              // Measurement shimmer
              _buildShimmerBox(14, 100),
              const SizedBox(height: 12),

              // Price row shimmer
              Row(
                children: [
                  _buildShimmerBox(28, 80),
                  const SizedBox(width: 12),
                  _buildShimmerBox(20, 60),
                  const SizedBox(width: 12),
                  _buildShimmerBox(24, 70),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductDetailVariantsShimmer extends StatefulWidget {
  final app_theme.AppColorScheme colorScheme;

  const _ProductDetailVariantsShimmer({
    Key? key,
    required this.colorScheme,
  }) : super(key: key);

  @override
  State<_ProductDetailVariantsShimmer> createState() =>
      _ProductDetailVariantsShimmerState();
}

class _ProductDetailVariantsShimmerState
    extends State<_ProductDetailVariantsShimmer>
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

  Widget _buildShimmerBox(double height, double width,
      {double borderRadius = 4}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            widget.colorScheme.shimmerBase,
            widget.colorScheme.shimmerHighlight,
            widget.colorScheme.shimmerBase,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildShimmerBox(18, 150),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.colorScheme.cardBackground,
                        border: Border.all(
                          color: widget.colorScheme.border,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: widget.colorScheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          _buildShimmerBox(60, 60, borderRadius: 8),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildShimmerBox(14, 60),
                              const SizedBox(height: 6),
                              _buildShimmerBox(16, 50),
                            ],
                          ),
                        ],
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

class _ProductDetailDescriptionShimmer extends StatefulWidget {
  final app_theme.AppColorScheme colorScheme;

  const _ProductDetailDescriptionShimmer({
    Key? key,
    required this.colorScheme,
  }) : super(key: key);

  @override
  State<_ProductDetailDescriptionShimmer> createState() =>
      _ProductDetailDescriptionShimmerState();
}

class _ProductDetailDescriptionShimmerState
    extends State<_ProductDetailDescriptionShimmer>
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

  Widget _buildShimmerBox(double height, double width) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            widget.colorScheme.shimmerBase,
            widget.colorScheme.shimmerHighlight,
            widget.colorScheme.shimmerBase,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(18, 120),
              const SizedBox(height: 12),
              ...List.generate(
                4,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildShimmerBox(14, double.infinity),
                ),
              ),
              _buildShimmerBox(14, MediaQuery.of(context).size.width * 0.6),
              const SizedBox(height: 24),
              // Ratings section
              _buildShimmerBox(18, 150),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: index == 2 ? 0 : 12),
                    child: _buildShimmerBox(80, 80),
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

// FIXED Sliver Persistent Header Delegate
class _ProductImageHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String productId;
  final ProductData product;
  final int currentImage;
  final VoidCallback onWishlistTap;
  final VoidCallback onShareTap;
  final bool isBookmarked;
  final AppColorScheme colorScheme;

  _ProductImageHeaderDelegate({
    required this.productId,
    required this.product,
    required this.currentImage,
    required this.onWishlistTap,
    required this.onShareTap,
    required this.isBookmarked,
    required this.colorScheme,
  });

  @override
  double get minExtent => 120; // Minimum height when collapsed

  @override
  double get maxExtent => 400; // Maximum height when expanded

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: maxExtent - shrinkOffset,
      child: ProductImageTopSection(
        productId: productId,
        product: product,
        currentImage: currentImage,
        onWishlistTap: onWishlistTap,
        onShareTap: onShareTap,
        isBookmarked: isBookmarked,
        colorScheme: colorScheme,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProductImageHeaderDelegate oldDelegate) {
    return product != oldDelegate.product ||
        currentImage != oldDelegate.currentImage ||
        isBookmarked != oldDelegate.isBookmarked;
  }

  @override
  OverScrollHeaderStretchConfiguration get stretchConfiguration =>
      OverScrollHeaderStretchConfiguration();
}

class ProductImageTopSection extends StatefulWidget {
  final String productId;
  final ProductData product;
  final int currentImage;
  final VoidCallback onWishlistTap;
  final VoidCallback onShareTap;
  final bool isBookmarked;
  final app_theme.AppColorScheme colorScheme;

  const ProductImageTopSection({
    required this.productId,
    required this.product,
    required this.currentImage,
    required this.onWishlistTap,
    required this.onShareTap,
    required this.isBookmarked,
    required this.colorScheme,
    Key? key,
  }) : super(key: key);

  @override
  State<ProductImageTopSection> createState() => _ProductImageTopSectionState();
}

class _ProductImageTopSectionState extends State<ProductImageTopSection>
    with SingleTickerProviderStateMixin {
  bool isKeyFeaturesExpanded = false;
  late AnimationController _panelController;
  late Animation<Offset> _slideAnimation;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;
  late PageController _pageController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.85, 0.0), // off‑screen left
      end: const Offset(0.0, 0.0), // visible
    ).animate(CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOut,
    ));

    _initVideoIfNeeded();
  }

  void _initVideoIfNeeded() {
    final url = widget.product.videoUrl;
    if (url.isNotEmpty && _isVideoUrl(url)) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) {
            _videoController!.setLooping(true);
            _videoController!.setVolume(0);
            _videoController!.play();
            setState(() => _videoInitialized = true);
          }
        }).catchError((e) {
          debugPrint("Product video init error: $e");
          if (mounted) setState(() => _videoError = true);
        });
    }
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains(".mp4") ||
        lower.contains(".mov") ||
        lower.contains(".avi") ||
        lower.contains(".webm");
  }

  bool get _hasVideo =>
      widget.product.videoUrl.isNotEmpty &&
      _isVideoUrl(widget.product.videoUrl) &&
      !_videoError;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _videoController?.dispose();
    _panelController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final provider = context.read<ProductDetailProvider>();
      final total = provider.images.length;
      if (total <= 1) return;
      final next = (provider.currentImage + 1) % total;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _toggleKeyFeatures() {
    setState(() => isKeyFeaturesExpanded = !isKeyFeaturesExpanded);
    if (isKeyFeaturesExpanded) {
      _panelController.forward();
    } else {
      _panelController.reverse();
    }
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final images = context.read<ProductDetailProvider>().images;
    final width = MediaQuery.of(context).size.width;
    final height = width * 0.89;
    final indicatorCount = images.isNotEmpty ? images.length : 1;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.colorScheme.surfaceVariant,
            widget.colorScheme.surface,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: widget.colorScheme.border,
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Full-width swipeable image carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              context.read<ProductDetailProvider>().setCurrentImageIndex(index);
            },
            itemCount: images.isNotEmpty ? images.length : 1,
            itemBuilder: (context, index) {
              // Video on first page
              if (index == 0 && _hasVideo && _videoInitialized) {
                return Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: widget.colorScheme.surface,
                    boxShadow: widget.colorScheme.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  ),
                );
              }

              final imageUrl = images.isNotEmpty
                  ? images[index]
                  : "https://placehold.co/393x350";

              final imageWidget = GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  fullScreenProductImageScreen,
                  arguments: [index, images],
                ),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: widget.colorScheme.surface,
                    boxShadow: widget.colorScheme.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: setNetworkImg(
                      boxFit: BoxFit.contain,
                      image: imageUrl,
                      height: double.infinity,
                      width: double.infinity,
                    ),
                  ),
                ),
              );

              return index == 0
                  ? HeroAnimationHelper.createImageHero(
                      tag: HeroAnimationHelper.productImageTag(widget.productId),
                      imageWidget: imageWidget,
                    )
                  : imageWidget;
            },
          ),

          // Top gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.colorScheme.surface.withValues(alpha: 0.7),
                    widget.colorScheme.surface.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Top action bar
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
                    // Back button
                    _PremiumActionButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconSize: 18,
                      onTap: () => Navigator.of(context).pop(),
                      colorScheme: widget.colorScheme,
                    ),
                    // Right actions
                    Row(
                      children: [
                        // Wishlist button
                        _PremiumActionButton(
                          icon: widget.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border_rounded,
                          iconSize: 22,
                          onTap: widget.onWishlistTap,
                          isActive: widget.isBookmarked,
                          colorScheme: widget.colorScheme,
                        ),
                        const SizedBox(width: 10),
                        // Share button
                        _PremiumActionButton(
                          icon: Icons.share_outlined,
                          iconSize: 20,
                          onTap: widget.onShareTap,
                          colorScheme: widget.colorScheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // PreOrder badge
          if (widget.product.isPreOrderItem == 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: widget.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  "PREORDER",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          //Key features
          // Positioned(
          //   left: 0,
          //   top: MediaQuery.of(context).padding.top + 70,
          //   child: SlideTransition(
          //     position: _slideAnimation,
          //     child: Container(
          //       constraints: BoxConstraints(
          //         maxWidth: width * 0.5,
          //         maxHeight: height * 0.95,
          //       ),
          //       decoration: const BoxDecoration(
          //         borderRadius: BorderRadius.only(
          //           topRight: Radius.circular(12),
          //           bottomRight: Radius.circular(12),
          //           topLeft: Radius.circular(12),
          //           bottomLeft: Radius.circular(12),
          //         ),
          //       ),
          //       child: Row(
          //         crossAxisAlignment: CrossAxisAlignment.center,
          //         children: [
          //           // Content area
          //           Expanded(
          //             child: Container(
          //               decoration: BoxDecoration(
          //                 color: widget.colorScheme.textPrimary
          //                     .withValues(alpha: 0.55),
          //                 borderRadius: const BorderRadius.only(
          //                   topRight: Radius.circular(12),
          //                   bottomRight: Radius.circular(12),
          //                 ),
          //               ),
          //               child: Padding(
          //                 padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          //                 child: SingleChildScrollView(
          //                   physics: const BouncingScrollPhysics(),
          //                   child: Column(
          //                     crossAxisAlignment: CrossAxisAlignment.start,
          //                     mainAxisSize: MainAxisSize.min,
          //                     children: [
          //                       Text(
          //                         getTranslatedValue(context, 'key_features'),
          //                         style: GoogleFonts.inter(
          //                           color: widget.colorScheme.surface,
          //                           fontSize: 16,
          //                           fontWeight: FontWeight.w700,
          //                           height: 1.2,
          //                         ),
          //                       ),
          //                       const SizedBox(height: 14),
          //                       _buildFeatureItem(
          //                         context: context,
          //                         title: 'serve_size',
          //                         content: 'Serves 1–2',
          //                       ),
          //                       const SizedBox(height: 12),
          //                       _buildFeatureItem(
          //                         context: context,
          //                         title: 'health_benefits',
          //                         content:
          //                             'Rich in fibre and beta‑carotene, helps support digestion and maintain blood sugar levels.',
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //               ),
          //             ),
          //           ),

          //           // Arrow handler ATTACHED to overlay
          //           GestureDetector(
          //             onTap: _toggleKeyFeatures,
          //             child: Container(
          //               width: 32,
          //               height: 60,
          //               decoration: BoxDecoration(
          //                 color: widget.colorScheme.textPrimary
          //                     .withValues(alpha: 0.55),
          //                 borderRadius: const BorderRadius.only(
          //                   topRight: Radius.circular(12),
          //                   bottomRight: Radius.circular(12),
          //                 ),
          //               ),
          //               child: Center(
          //                 child: AnimatedRotation(
          //                   duration: const Duration(milliseconds: 250),
          //                   turns: isKeyFeaturesExpanded ? 0.0 : 0.5,
          //                   child: Icon(
          //                     Icons.keyboard_arrow_right_rounded,
          //                     color: widget.colorScheme.surface,
          //                     size: 24,
          //                   ),
          //                 ),
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),

          // Page indicators
          if (indicatorCount > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Consumer<ProductDetailProvider>(
                builder: (context, provider, _) => Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: widget.colorScheme.cardShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        indicatorCount,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == provider.currentImage ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: i == provider.currentImage
                                ? widget.colorScheme.primaryGradient
                                : null,
                            color: i == provider.currentImage
                                ? null
                                : widget.colorScheme.textPrimary
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom shadow
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
                    widget.colorScheme.surface.withValues(alpha: 0.5),
                    widget.colorScheme.surface.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, title),
          style: GoogleFonts.inter(
            color: widget.colorScheme.surface.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: GoogleFonts.inter(
            color: widget.colorScheme.surface,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.4,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

// Updated Premium Action Button Widget
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
    this.isActive = false,
    Key? key,
    required this.colorScheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: isActive ? colorScheme.primaryGradient : null,
          color: isActive ? null : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.transparent : colorScheme.border,
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : colorScheme.cardShadow,
        ),
        child: Center(
          child: Icon(
            icon,
            color: isActive
                ? colorScheme.buttonPrimaryText
                : colorScheme.iconPrimary,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

// Calculate discount percent
int getDiscountPercent(String price, String discounted) {
  final numPrice = double.tryParse(price) ?? 0;
  final numDiscounted = double.tryParse(discounted) ?? 0;
  if (numPrice == 0 || numDiscounted == 0 || numDiscounted >= numPrice)
    return 0;
  return (((numPrice - numDiscounted) * 100) / numPrice).round();
}
