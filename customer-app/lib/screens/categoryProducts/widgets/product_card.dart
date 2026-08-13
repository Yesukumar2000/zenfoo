import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/heroAnimationHelper.dart';
import 'package:project/screens/productDetailScreen/productDetailScreen.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

/// The product card. One rendering, everywhere.
///
/// This used to carry four styling opt-ins — `enhanced`, `tallImage`,
/// `fitImage` and `hideSellerName` — and screens picked a combination each,
/// so the same product looked like a different component depending on where
/// you found it: bordered white card on the home feed, borderless block with a
/// small centred ADD button in search and bookmarks. The card now renders one
/// way and the host only decides how much room to give it (see
/// `helper/styles/product_card_metrics.dart`).
///
/// [menuStyle] is the one survivor, and only because it changes what the image
/// means rather than how the card looks: a restaurant dish photo fills its box
/// edge to edge, where a packshot must not be cropped.
class MiniProductCardContainer extends StatefulWidget {
  final ProductListItem product;
  final bool disableHero;
  final int? comboId;
  final bool menuStyle;
  const MiniProductCardContainer({
    Key? key,
    required this.product,
    this.disableHero = false,
    this.comboId,
    this.menuStyle = false,
  }) : super(key: key);

  @override
  State<MiniProductCardContainer> createState() =>
      _MiniProductCardContainerState();
}

class _MiniProductCardContainerState extends State<MiniProductCardContainer> {
  Variants? selectedVariant;

  @override
  Widget build(BuildContext context) {
    final Variants? variant = selectedVariant ??
        ((widget.product.variants?.isNotEmpty ?? false)
            ? widget.product.variants!.first
            : null);

    return MiniProductCard(
      product: widget.product,
      selectedVariant: variant,
      onQtyTap: (Variants v) => setState(() => selectedVariant = v),
      disableHero: widget.disableHero,
      comboId: widget.comboId,
      menuStyle: widget.menuStyle,
    );
  }
}

class MiniProductCard extends StatefulWidget {
  final ProductListItem product;
  final Variants? selectedVariant;
  final void Function(Variants)? onQtyTap;
  final bool disableHero;
  final int? comboId;
  final bool menuStyle;

  const MiniProductCard({
    super.key,
    required this.product,
    this.selectedVariant,
    this.onQtyTap,
    this.disableHero = false,
    this.comboId,
    this.menuStyle = false,
  });

  @override
  State<MiniProductCard> createState() => _MiniProductCardState();
}

class _MiniProductCardState extends State<MiniProductCard> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    final v = widget.selectedVariant ??
        ((widget.product.variants?.isNotEmpty ?? false)
            ? widget.product.variants!.first
            : null);

    final imgUrl = (widget.product.imageUrl ?? "");
    final rating =
        double.tryParse(widget.product.averageRating?.toString() ?? "") ?? 0;
    final ratingCount = widget.product.ratingCount?.toString() ?? "0";
    final unitName = (v?.stockUnitName ?? "").trim();
    final qtyText = v != null
        ? "${v.measurement ?? "1"} ${unitName == "null" || unitName.isEmpty ? "" : unitName}"
            .trim()
        : "-";
    final double price = double.tryParse(v?.discountedPrice ??
            widget.product.discountedPrice?.toString() ??
            '0') ??
        0;
    final double oldPrice =
        double.tryParse(v?.price ?? widget.product.price?.toString() ?? '0') ??
            0;
    final int discount = (oldPrice > 0 && price < oldPrice)
        ? (((oldPrice - price) / oldPrice) * 100).round()
        : 0;

    // Whether the pack-size control actually opens anything. Drives both the
    // tap handler and whether it is styled as a control at all.
    final bool hasVariantChoice = (widget.product.variants?.length ?? 0) > 1;

    // The "QTY" label sits back; the pack size beside it is the fact being
    // read, so it carries the weight and the darker colour.
    final TextStyle qtyStyle = GoogleFonts.inter(
      color: colorScheme.textSecondary,
      fontSize: 9.sp,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.2,
    );
    final TextStyle qtyValueStyle = GoogleFonts.inter(
      color: colorScheme.textPrimary,
      fontSize: 10.sp,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );

    // The name is the card's headline everywhere, bold and free to wrap once.
    const FontWeight nameWeight = FontWeight.w700;
    const int nameMaxLines = 2;

    // The rating is data-driven rather than per-screen: a product that has been
    // rated shows it wherever it appears. It used to depend on which styling
    // flag the host passed, so the same product showed stars in search and hid
    // them on the home feed.
    final bool showRating = (int.tryParse(ratingCount) ?? 0) > 0;

    // Food mark, from the feed's `indicator`: "1" veg, "2" non-veg. Grocery
    // lines send neither, and get no mark rather than a wrong one.
    final String? foodMark = widget.product.indicator == "1"
        ? getTranslatedValue(context, 'vegetarian')
        : widget.product.indicator == "2"
            ? getTranslatedValue(context, 'non_vegetarian')
            : null;
    final Color foodMarkColor = widget.product.indicator == "1"
        ? const Color(0xFF1B8E3D)
        : const Color(0xFFD32F2F);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MultiProvider(
              providers: [
                ChangeNotifierProvider<ProductDetailProvider>(
                  create: (context) => ProductDetailProvider(),
                ),
                ChangeNotifierProvider<RatingListProvider>(
                  create: (context) => RatingListProvider(),
                ),
              ],
              child: ProductDetailScreen(
                id: widget.product.id.toString(),
                title: widget.product.name,
                productListItem: widget.product,
              ),
            ),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              // Fade transition that doesn't interfere with hero animation
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.border, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE AND BOOKMARK
              //
              // The image takes whatever height is left once the text block
              // below has measured itself. The card used to offer a fixed flex
              // split instead — a percentage of the card height — which can't
              // know how tall a two-line name renders, so an enlarged system
              // font pushed the ADD button past the bottom edge. Content
              // measures itself; the image absorbs the difference.
              Expanded(
                child: Stack(
                  // Expand, not the default loose fit. Loose lets the image
                  // size to the photo instead of to the cell, so a square
                  // packshot in a taller cell stopped short and left a white
                  // band under it — with nothing for the blurred backdrop to
                  // fill, since the backdrop can only fill the box it is given.
                  fit: StackFit.expand,
                  children: [
                    widget.disableHero
                        ? _buildProductImage(imgUrl, colorScheme)
                        : HeroAnimationHelper.createImageHero(
                            tag: HeroAnimationHelper.productImageTag(
                              widget.product.id ?? '',
                            ),
                            imageWidget:
                                _buildProductImage(imgUrl, colorScheme),
                          ),
                    // Bookmark
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          if (!Constant.session.isUserLoggedIn()) {
                            loginUserAccount(context, "bookmark");
                            return;
                          }

                          try {
                            final result = await toggleProductBookmarkApi(
                              context: context,
                              productId: int.parse(widget.product.id!),
                            );

                            if (result != null && result['status'] == 1) {
                              setState(() {
                                widget.product.isBookmarked =
                                    !(widget.product.isBookmarked ?? false);
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
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: colorScheme.cardShadow,
                          ),
                          child: Icon(
                            (widget.product.isBookmarked ?? false)
                                ? Icons.bookmark
                                : Icons.bookmark_border_rounded,
                            color: (widget.product.isBookmarked ?? false)
                                ? const Color(0xFFE8B000)
                                : colorScheme.iconPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    if (widget.product.isPreOrderItem == 1)
                      Positioned(
                        top: 5,
                        left: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            "PREORDER",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    // Rating, sitting on the foot of the photo. This was a
                    // five-star row down in the text block, which spent a whole
                    // line saying less than "4.6 (312)" does — and stars read
                    // as decoration at 10sp, where a number reads as a fact.
                    if (showRating)
                      PositionedDirectional(
                        bottom: 6,
                        end: 6,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.sp, vertical: 3.sp),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E2E2E),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 11.sp,
                                color: const Color(0xFFFFC107),
                              ),
                              SizedBox(width: 2.sp),
                              Text(
                                rating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(width: 3.sp),
                              Text(
                                '(${_groupedCount(ratingCount)})',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w500,
                                  height: 1.1,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // CONTENT
              //
              // Even breathing room on all four sides. This block used to hug
              // the bottom edge and rely on the ADD button's own padding for
              // the gap under it, on every card except the menu one.
              Padding(
                  padding: EdgeInsets.fromLTRB(10.sp, 8.sp, 10.sp, 8.sp),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food mark, above the name — the first thing a diner
                      // filters on, and meaningless to read after the price.
                      if (foodMark != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 11.sp,
                              height: 11.sp,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: foodMarkColor, width: 1.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Container(
                                width: 5.sp,
                                height: 5.sp,
                                decoration: BoxDecoration(
                                  color: foodMarkColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.sp),
                            Flexible(
                              child: Text(
                                foodMark.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: foodMarkColor,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  letterSpacing: 0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.sp),
                      ],
                      // Product Name
                      widget.disableHero
                          ? Text(
                              widget.product.name ?? "",
                              style: GoogleFonts.inter(
                                fontWeight: nameWeight,
                                fontSize: 12.sp,
                                height: 1.08,
                                color: const Color(0xFF221F1F),
                                letterSpacing: -0.45,
                              ),
                              maxLines: nameMaxLines,
                              overflow: TextOverflow.ellipsis,
                            )
                          : HeroAnimationHelper.createMaterialHero(
                              tag: HeroAnimationHelper.productNameTag(
                                widget.product.id ?? '',
                              ),
                              child: Text(
                                widget.product.name ?? "",
                                style: GoogleFonts.inter(
                                  fontWeight: nameWeight,
                                  fontSize: 12.sp,
                                  height: 1.08,
                                  color: const Color(0xFF221F1F),
                                  letterSpacing: -0.45,
                                ),
                                maxLines: nameMaxLines,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                      // Seller Name — only reserve height when there's actually a
                      // seller name to show. Collapsing it for products without a
                      // seller (e.g. fish-store items) frees the vertical space a
                      // 2-line product title needs, preventing bottom overflow.
                      if ((widget.product.sellerName ?? "")
                          .trim()
                          .isNotEmpty) ...[
                        SizedBox(height: 2.sp),
                        Text(
                          widget.product.sellerName!,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w400,
                            fontSize: 10.sp,
                            height: 1.0,
                            color: const Color(0xFF7C7B7B),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.sp),
                      ] else
                        const SizedBox.shrink(),
                      SizedBox(height: 6.sp),
                      // QTY Selector Container
                      GestureDetector(
                        onTap: hasVariantChoice
                            ? () async {
                                final selected =
                                    await showModalBottomSheet<Variants>(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (context) {
                                    return _buildVariantBottomSheet(
                                      context,
                                      widget.product,
                                      v,
                                      colorScheme,
                                    );
                                  },
                                );
                                if (selected != null &&
                                    widget.onQtyTap != null) {
                                  widget.onQtyTap!(selected);
                                }
                              }
                            : null,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.sp, vertical: 5.sp),
                          // The card's one tinted field. Everything else in the
                          // text block is static, so the tint is what marks
                          // this as the thing you can change. Inside it the
                          // "QTY:" label sits back in grey and the pack size
                          // carries the weight — the old chip shouted both
                          // equally in the brand green.
                          decoration: ShapeDecoration(
                            color: colorScheme.packSizeFieldBackground,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                strokeAlign: BorderSide.strokeAlignOutside,
                                color: colorScheme.packSizeFieldBorder,
                              ),
                              borderRadius: BorderRadius.circular(8.sp),
                            ),
                          ),
                          // Label and value together at the start; the chevron
                          // alone is pinned to the end.
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                getTranslatedValue(context, 'qty'),
                                style: qtyStyle,
                                maxLines: 1,
                              ),
                              SizedBox(width: 5.sp),
                              Expanded(
                                child: Text(
                                  qtyText,
                                  style: qtyValueStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // The one affordance that says "there are other
                              // pack sizes", so it needs to be legible at this
                              // scale.
                              if (hasVariantChoice)
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14.sp,
                                  color: colorScheme.iconPrimary,
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Fish-cut info (Before Cleaning / After / Pieces) for fish store
                      if (widget.product.storeId == 19 &&
                          _hasFishCut(widget.product)) ...[
                        // Slightly larger gap above the cleaning block, with a
                        // smaller gap below it, so the QTY↔cleaning spacing grows
                        // without making the card any taller (avoids overflow).
                        SizedBox(height: 4.sp),
                        _buildFishCutInfo(),
                        SizedBox(height: 1.sp),
                      ] else
                        SizedBox(height: 6.sp),
                      // PRICES — one line: what it costs, what it cost, and
                      // how much that saves. Stacking the discount underneath
                      // spent a second line on a figure that reads faster
                      // beside the price it applies to.
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "₹${price.toStringAsFixed(0)}",
                            style: GoogleFonts.instrumentSans(
                              color: const Color(0xFF221F1F),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.04,
                              height: 1.2,
                            ),
                            maxLines: 1,
                          ),
                          if (oldPrice > price) ...[
                            SizedBox(width: 4.sp),
                            Flexible(
                              child: Text(
                                "₹${oldPrice.toStringAsFixed(0)}",
                                style: GoogleFonts.instrumentSans(
                                  color: const Color(0xFF9D9898),
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: const Color(0xFF9D9898),
                                  letterSpacing: -0.02,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (discount > 0) ...[
                            SizedBox(width: 5.sp),
                            Flexible(
                              child: Text(
                                '${discount.toStringAsFixed(0)}% off',
                                style: GoogleFonts.instrumentSans(
                                  color: const Color(0xFF1B8E3D),
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.04,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // No Spacer here: this column is sized to its content and
                      // the image above it takes the slack, so the button
                      // already sits at the card's bottom edge with nothing
                      // left to push against.
                      // CART BUTTON (use detail page ProductCartButton here!)
                      Builder(builder: (context) {
                        final cartBtn = MiniProductCartButton(
                          // A product with no variant has nothing to add: the
                          // tap would post an empty product_variant_id and the
                          // card is already showing "QTY: -" and ₹0. -1 is the
                          // button's "don't offer ADD" sentinel, so it renders
                          // the unavailable state instead of a dead control.
                          count: v == null
                              ? -1
                              : (int.tryParse(v.cartCount ?? "0") ?? 0),
                          productId: widget.product.id ?? '',
                          productVariantId: v?.id ?? '',
                          isUnlimitedStock: v?.isUnlimitedStock == "1",
                          maximumAllowedQuantity: double.tryParse(
                                  widget.product.totalAllowedQuantity ?? "1") ??
                              1,
                          availableStock: double.tryParse(v?.stock ?? "0") ?? 0,
                          isGrid: true,
                          from: "product_grid",
                          sellerId: widget.product.sellerId ?? '',
                          comboId: widget.comboId,
                        );
                        // Full width on every card. A small centred button was
                        // the compact card's tell — same product, different
                        // affordance depending on the screen.
                        return SizedBox(width: double.infinity, child: cartBtn)
                            .pOnly(top: 8.sp);
                      }),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Bottom Sheet Method
  Widget _buildVariantBottomSheet(
    BuildContext context,
    ProductListItem productDetail,
    Variants? currentVariant,
    dynamic colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTranslatedValue(context, 'select_size'),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          height: 1.3,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        productDetail.name ?? "",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.textSecondary,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: colorScheme.iconSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Variants List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: productDetail.variants?.length ?? 0,
              itemBuilder: (context, index) {
                final variant = productDetail.variants![index];
                final isSelected = currentVariant?.id == variant.id;
                final isOutOfStock = variant.status == "0" ||
                    (variant.isUnlimitedStock != "1" &&
                        (double.tryParse(variant.stock ?? "0") ?? 0) <= 0);

                final double price =
                    double.tryParse(variant.discountedPrice ?? '0') ?? 0;
                final double oldPrice =
                    double.tryParse(variant.price ?? '0') ?? 0;
                final int discount = (oldPrice > 0 && price < oldPrice)
                    ? (((oldPrice - price) / oldPrice) * 100).round()
                    : 0;

                final variantText =
                    "${variant.measurement} ${variant.stockUnitName}";
                final stockText = variant.isUnlimitedStock == "1"
                    ? getTranslatedValue(context, 'in_stock')
                    : (double.tryParse(variant.stock ?? "0") ?? 0) > 10
                        ? getTranslatedValue(context, 'in_stock')
                        : (double.tryParse(variant.stock ?? "0") ?? 0) > 0
                            ? getTranslatedValue(context, 'low_stock')
                            : getTranslatedValue(context, 'out_of_stock');

                return GestureDetector(
                  onTap: isOutOfStock
                      ? null
                      : () => Navigator.pop(context, variant),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isSelected ? colorScheme.surfaceGradient : null,
                      color: isSelected ? null : colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isOutOfStock
                            ? colorScheme.divider
                            : isSelected
                                ? colorScheme.primary
                                : colorScheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected && !isOutOfStock
                          ? [
                              BoxShadow(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ]
                          : colorScheme.cardShadow,
                    ),
                    child: Opacity(
                      opacity: isOutOfStock ? 0.5 : 1.0,
                      child: Row(
                        children: [
                          // Product Image
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: colorScheme.cardShadow,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: variant.images?.isNotEmpty ?? false
                                  ? CachedNetworkImage(
                                      imageUrl: variant.images?[0].toString() ?? '',
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Shimmer.fromColors(
                                        baseColor: const Color(0xFFE0E0E0),
                                        highlightColor: const Color(0xFFF5F5F5),
                                        child: Container(color: Colors.white),
                                      ),
                                      errorWidget: (context, url, error) => imgErrorWidget(iconSize: 28),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: productDetail.imageUrl ?? '',
                                      fit: BoxFit.contain,
                                      errorListener: (context) => Icon(
                                        Icons.image_outlined,
                                        size: 32,
                                        color: colorScheme.iconDisabled,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Variant Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Size
                                Text(
                                  variantText,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.textPrimary,
                                    height: 1.3,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Price Row
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "₹${price.toStringAsFixed(0)}",
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme.textPrimary,
                                          height: 1.2,
                                          letterSpacing: -0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (oldPrice > price) ...[
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          "₹${oldPrice.toStringAsFixed(0)}",
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.textTertiary,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationColor:
                                                colorScheme.textTertiary,
                                            height: 1.2,
                                            letterSpacing: -0.2,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    if (discount > 0) ...[
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient:
                                                colorScheme.primaryGradient,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.15),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            "$discount% OFF",
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  colorScheme.buttonPrimaryText,
                                              height: 1.2,
                                              letterSpacing: 0.2,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Stock Status
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isOutOfStock
                                            ? const Color(0xFFE53E3E)
                                            : stockText == "Low Stock"
                                                ? const Color(0xFFED8936)
                                                : const Color(0xFF48BB78),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isOutOfStock
                                                    ? const Color(0xFFE53E3E)
                                                    : stockText == "Low Stock"
                                                        ? const Color(
                                                            0xFFED8936)
                                                        : const Color(
                                                            0xFF48BB78))
                                                .withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      stockText,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isOutOfStock
                                            ? const Color(0xFFE53E3E)
                                            : stockText == "Low Stock"
                                                ? const Color(0xFFED8936)
                                                : const Color(0xFF48BB78),
                                        height: 1.2,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Selection Indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isSelected ? 32 : 24,
                            height: isSelected ? 32 : 24,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? colorScheme.primaryGradient
                                  : null,
                              color: isSelected ? null : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: colorScheme.divider,
                                      width: 2,
                                    ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check_rounded,
                                    color: colorScheme.buttonPrimaryText,
                                    size: 20,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _hasFishCut(ProductListItem p) =>
      (p.beforeCleaningWeight ?? '').isNotEmpty ||
      (p.afterCleaningWeight ?? '').isNotEmpty ||
      (p.pieces ?? '').isNotEmpty;

  // Compact Before Cleaning | After | Pieces box for fish-store grid cards.
  Widget _buildFishCutInfo() {
    final p = widget.product;
    // (cell, flex) — "Before Cleaning" gets a wider column so its longer
    // label fits across two lines instead of truncating.
    final cells = <(Widget, int)>[
      if ((p.beforeCleaningWeight ?? '').isNotEmpty)
        (_fishCutCell('Before Clean..', p.beforeCleaningWeight!), 6),
      if ((p.afterCleaningWeight ?? '').isNotEmpty)
        (_fishCutCell('After', p.afterCleaningWeight!), 3),
      if ((p.pieces ?? '').isNotEmpty)
        (_fishCutCell('Pieces', p.pieces!), 3),
    ];

    final rowChildren = <Widget>[];
    for (var i = 0; i < cells.length; i++) {
      rowChildren.add(Expanded(flex: cells[i].$2, child: cells[i].$1));
      if (i != cells.length - 1) {
        rowChildren.add(Container(
          width: 1,
          height: 22.sp,
          color: const Color(0xFFE0E0E0),
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(4.sp),
      ),
      padding: EdgeInsets.symmetric(vertical: 1.sp),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: rowChildren,
        ),
      ),
    );
  }

  Widget _fishCutCell(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.sp),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 8.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B6B6B),
              height: 1.05,
            ),
          ),
          SizedBox(height: 1.sp),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }

  // "1345" -> "1,345". Indian grouping isn't used here: a rating count reads
  // as a plain quantity, and the reference card groups in thousands.
  String _groupedCount(String raw) {
    final digits = int.tryParse(raw.trim());
    if (digits == null) return raw;
    final s = digits.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _buildProductImage(String imgUrl, AppColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: colorScheme.surface),
      child: imgUrl.isEmpty
          ? imgErrorWidget(
              width: double.infinity,
              placeholderImageUrl: () {
                final url = getStorePlaceholderUrl(
                  storeId: widget.product.storeId,
                  isMeat: widget.product.isMeatProduct ?? false,
                  isSuperMart: widget.product.isSuperMart ?? false,
                );
                return url.isNotEmpty ? url : null;
              }(),
            )
          : setNetworkImg(
              image: imgUrl,
              // Menu photos fill the box: a dish shot has no packshot margin
              // to preserve, and `contain` left a white band above and below
              // every landscape photo. A packshot is the opposite — cropping
              // slices the edges off the product — so it stays `contain`.
              boxFit: widget.menuStyle ? BoxFit.cover : BoxFit.contain,
              fillBackdrop: !widget.menuStyle,
              storeId: widget.product.storeId,
              isMeat: widget.product.isMeatProduct ?? false,
              isSuperMart: widget.product.isSuperMart ?? false,
            ),
    );
  }
}
