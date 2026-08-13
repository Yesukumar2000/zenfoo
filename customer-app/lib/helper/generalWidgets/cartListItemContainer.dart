import 'package:project/helper/utils/generalImports.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class CartListItemContainerProvider extends StatelessWidget {
  final CartItem cart;
  final String from;
  const CartListItemContainerProvider(
      {Key? key, required this.cart, required this.from})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductDetailProvider>(
      create: (_) => ProductDetailProvider(),
      child: CartListItemContainer(cart: cart, from: from),
    );
  }
}

class CartListItemContainer extends StatefulWidget {
  final CartItem cart;
  final String from;
  const CartListItemContainer({
    Key? key,
    required this.cart,
    required this.from,
  }) : super(key: key);

  @override
  State<CartListItemContainer> createState() => _CartListItemContainerState();
}

class _CartListItemContainerState extends State<CartListItemContainer> {
  ProductData? productDetail;
  ProductDetailVariants? selectedVariant;
  bool loadingDetail = false;

  @override
  void initState() {
    super.initState();
    fetchProductDetail();
  }

  Future<void> fetchProductDetail() async {
    if (!mounted) return;

    setState(() {
      loadingDetail = true;
    });

    try {
      final Map<String, String> params =
          await Constant.getProductsDefaultParams();
      params[ApiAndParams.id] = widget.cart.productId;

      await context.read<ProductDetailProvider>().getProductDetailProvider(
            context: context,
            params: params,
          );

      if (!mounted) return;

      // Check if product data was successfully loaded
      final provider = context.read<ProductDetailProvider>();
      if (provider.productDetailState == ProductDetailState.loaded) {
        final prod = provider.productData;
        if (!mounted) return;

        setState(() {
          productDetail = prod;
          selectedVariant =
              prod.variants.cast<ProductDetailVariants?>().firstWhere(
                    (v) => v?.id.toString() == widget.cart.productVariantId,
                  );
          loadingDetail = false;
        });
      } else {
        // Handle error case
        if (!mounted) return;

        setState(() {
          loadingDetail = false;
        });
      }
    } catch (e) {
      // Handle exception
      if (!mounted) return;

      setState(() {
        loadingDetail = false;
      });
    }
  }

  void onVariantChange(ProductDetailVariants newVariant) async {
    final cartListProvider = context.read<CartListProvider>();
    final currentQty = int.tryParse(widget.cart.qty) ?? 1;

    await cartListProvider.addRemoveCartItem(
      context: context,
      params: {
        ApiAndParams.productId: widget.cart.productId,
        ApiAndParams.productVariantId: newVariant.id.toString(),
        ApiAndParams.qty: "$currentQty",
      },
      isUnlimitedStock: newVariant.isUnlimitedStock == "1",
      maximumAllowedQuantity:
          double.tryParse(widget.cart.totalAllowedQuantity) ?? 1,
      availableStock: double.tryParse(newVariant.stock ?? "0") ?? 0,
      actionFor: "add",
      from: widget.from,
      sellerId: widget.cart.sellerId,
    );

    await cartListProvider.addRemoveCartItem(
      context: context,
      params: {
        ApiAndParams.productId: widget.cart.productId,
        ApiAndParams.productVariantId: widget.cart.productVariantId,
        ApiAndParams.qty: "0",
      },
      isUnlimitedStock: widget.cart.isUnlimitedStock == "1",
      maximumAllowedQuantity:
          double.tryParse(widget.cart.totalAllowedQuantity) ?? 1,
      availableStock: double.tryParse(widget.cart.stock) ?? 0,
      actionFor: "remove",
      from: widget.from,
      sellerId: widget.cart.sellerId,
    );

    await context.read<CartProvider>().getCartListProvider(context: context);
    await fetchProductDetail();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final wishlisted =
        Constant.favorite.contains(int.parse(widget.cart.productId));
    final v = selectedVariant;
    final price =
        double.tryParse(v?.discountedPrice ?? widget.cart.discountedPrice) != 0
            ? double.tryParse(
                    v?.discountedPrice ?? widget.cart.discountedPrice) ??
                0
            : double.tryParse(v?.price ?? widget.cart.price) ?? 0;
    final oldPrice = double.tryParse(v?.price ?? widget.cart.price) ?? 0;
    final discount = (oldPrice > 0 && price < oldPrice)
        ? (((oldPrice - price) / oldPrice) * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // IMAGE SECTION
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: v?.product?['image_url'] ?? widget.cart.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: const Color(0xFFE0E0E0),
                      highlightColor: const Color(0xFFF5F5F5),
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => imgErrorWidget(
                      iconSize: 28,
                      placeholderImageUrl: () {
                        final url = getStorePlaceholderUrl(
                          storeId: int.tryParse(widget.cart.storeId ?? ''),
                          isMeat: widget.cart.sellerStore?.isMeat ?? false,
                          isSuperMart: widget.cart.sellerStore?.isSuperMart ?? false,
                        );
                        return url.isNotEmpty ? url : null;
                      }(),
                    ),
                  ),
                ),
              ),
              // Preorder Badge
              if (widget.cart.isPreOrderItem == 1 ||
                  productDetail?.isPreOrderItem == 1)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "PRE ORDER",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12),
          // CONTENT SECTION
          Expanded(
            child: loadingDetail || v == null
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        v.product?['name'] ?? widget.cart.name,
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      // QTY dropdown for variant change
                      GestureDetector(
                        onTap: () async {
                          if ((productDetail?.variants.length ?? 1) > 1) {
                            final selected = await showModalBottomSheet<
                                ProductDetailVariants>(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => _buildVariantBottomSheet(
                                context,
                                productDetail!,
                                v,
                              ),
                            );
                            if (selected != null && selected.id != v.id) {
                              onVariantChange(selected);
                            }
                          }
                        },
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.straighten_outlined,
                                size: 12,
                                color: colorScheme.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "${v.measurement} ${v.stockUnitName}",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.textPrimary,
                                  height: 1.2,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if ((productDetail?.variants.length ?? 1) >
                                  1) ...[
                                SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      // Price + Old Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "₹${price.toStringAsFixed(0)}",
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (discount > 0) ...[
                            SizedBox(width: 6),
                            Text(
                              "₹${oldPrice.toStringAsFixed(0)}",
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                                letterSpacing: -0.1,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: colorScheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Discount percentage
                      if (discount > 0) ...[
                        SizedBox(height: 2),
                        Text(
                          '${discount.toStringAsFixed(0)}% Off',
                          style: GoogleFonts.inter(
                            color: colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          SizedBox(width: 8),
          // MINI CART BUTTON (top-aligned)
          MiniProductCartButton(
            count: int.tryParse(widget.cart.qty) ?? 0,
            productId: widget.cart.productId,
            productVariantId: widget.cart.productVariantId,
            isUnlimitedStock: widget.cart.isUnlimitedStock == "1",
            maximumAllowedQuantity:
                double.tryParse(widget.cart.totalAllowedQuantity) ?? 1,
            availableStock: double.tryParse(widget.cart.stock) ?? 0,
            isGrid: true,
            from: widget.from,
            sellerId: widget.cart.sellerId,
          ).w(90),
        ],
      ),
    );
  }

// Bottom Sheet Method
  Widget _buildVariantBottomSheet(
    BuildContext context,
    ProductData productDetail,
    ProductDetailVariants currentVariant,
  ) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 16, 12),
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
                        "Select Size",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          height: 1.3,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 4),
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
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: productDetail.variants.length,
              itemBuilder: (context, index) {
                final variant = productDetail.variants[index];
                final isSelected = currentVariant.id == variant.id;
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
                    ? "In Stock"
                    : (double.tryParse(variant.stock ?? "0") ?? 0) > 10
                        ? "In Stock"
                        : (double.tryParse(variant.stock ?? "0") ?? 0) > 0
                            ? "Low Stock"
                            : "Out of Stock";

                return GestureDetector(
                  onTap: isOutOfStock
                      ? null
                      : () => Navigator.pop(context, variant),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isOutOfStock
                            ? colorScheme.border
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
                                offset: Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
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
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: variant.images.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: variant.images[0],
                                          fit: BoxFit.contain,
                                          placeholder: (context, url) => Shimmer.fromColors(
                                            baseColor: const Color(0xFFE0E0E0),
                                            highlightColor: const Color(0xFFF5F5F5),
                                            child: Container(color: Colors.white),
                                          ),
                                          errorWidget: (context, url, error) => imgErrorWidget(
                                            iconSize: 28,
                                            placeholderImageUrl: () {
                                              final u = getStorePlaceholderUrl(
                                                storeId: int.tryParse(widget.cart.storeId ?? ''),
                                                isMeat: widget.cart.sellerStore?.isMeat ?? false,
                                                isSuperMart: widget.cart.sellerStore?.isSuperMart ?? false,
                                              );
                                              return u.isNotEmpty ? u : null;
                                            }(),
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: variant.product?['image_url'] ?? '',
                                          fit: BoxFit.contain,
                                          placeholder: (context, url) => Shimmer.fromColors(
                                            baseColor: const Color(0xFFE0E0E0),
                                            highlightColor: const Color(0xFFF5F5F5),
                                            child: Container(color: Colors.white),
                                          ),
                                          errorWidget: (context, url, error) => imgErrorWidget(
                                            iconSize: 28,
                                            placeholderImageUrl: () {
                                              final u = getStorePlaceholderUrl(
                                                storeId: int.tryParse(widget.cart.storeId ?? ''),
                                                isMeat: widget.cart.sellerStore?.isMeat ?? false,
                                                isSuperMart: widget.cart.sellerStore?.isSuperMart ?? false,
                                              );
                                              return u.isNotEmpty ? u : null;
                                            }(),
                                          ),
                                        ),
                                ),
                                if (productDetail.isPreOrderItem == 1)
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "PRE ORDER",
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 6,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: 14),
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
                                SizedBox(height: 6),
                                // Price Row
                                Row(
                                  children: [
                                    Text(
                                      "₹${price.toStringAsFixed(0)}",
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.textPrimary,
                                        height: 1.2,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    if (oldPrice > price) ...[
                                      SizedBox(width: 6),
                                      Text(
                                        "₹${oldPrice.toStringAsFixed(0)}",
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.textSecondary,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          decorationColor:
                                              colorScheme.textSecondary,
                                          height: 1.2,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                    if (discount > 0) ...[
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.15),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
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
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 6),
                                // Stock Status
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isOutOfStock
                                            ? Color(0xFFE53E3E)
                                            : stockText == "Low Stock"
                                                ? Color(0xFFED8936)
                                                : Color(0xFF48BB78),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isOutOfStock
                                                    ? Color(0xFFE53E3E)
                                                    : stockText == "Low Stock"
                                                        ? Color(0xFFED8936)
                                                        : Color(0xFF48BB78))
                                                .withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      stockText,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isOutOfStock
                                            ? Color(0xFFE53E3E)
                                            : stockText == "Low Stock"
                                                ? Color(0xFFED8936)
                                                : Color(0xFF48BB78),
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
                            duration: Duration(milliseconds: 250),
                            width: isSelected ? 32 : 24,
                            height: isSelected ? 32 : 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: colorScheme.border,
                                      width: 2,
                                    ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
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
}

// import 'package:project/helper/utils/generalImports.dart';

// class CartListItemContainer extends StatefulWidget {
//   final CartItem cart;
//   final String from;

//   const CartListItemContainer(
//       {Key? key, required this.cart, required this.from})
//       : super(key: key);

//   @override
//   State<CartListItemContainer> createState() => _State();
// }

// class _State extends State<CartListItemContainer> {
//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     CartItem cart = widget.cart;
//     return Padding(
//       padding: const EdgeInsetsDirectional.only(top: 10),
//       child: ChangeNotifierProvider<SelectedVariantItemProvider>(
//         create: (context) => SelectedVariantItemProvider(),
//         child: Container(
//           decoration:
//               DesignConfig.boxDecoration(Theme.of(context).cardColor, 8),
//           child: Stack(
//             children: [
//               Row(
//                 mainAxisSize: MainAxisSize.max,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ClipRRect(
//                       borderRadius: Constant.borderRadius10,
//                       clipBehavior: Clip.antiAliasWithSaveLayer,
//                       child: setNetworkImg(
//                         height: 125,
//                         width: 125,
//                         boxFit: BoxFit.cover,
//                         image: cart.imageUrl,
//                       )),
//                   Expanded(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(
//                           vertical: Constant.size10,
//                           horizontal: Constant.size10),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Consumer<SelectedVariantItemProvider>(
//                             builder:
//                                 (context, selectedVariantItemProvider, child) {
//                               return (cart.status == "0")
//                                   ? CustomTextLabel(
//                                       jsonKey: outOfStockLabel,
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                       softWrap: true,
//                                       style: TextStyle(
//                                         fontSize: 17,
//                                         fontWeight: FontWeight.bold,
//                                         color: ColorsRes.appColorRed,
//                                       ),
//                                     )
//                                   : const SizedBox.shrink();
//                             },
//                           ),
//                           getSizedBox(
//                             height: Constant.size10,
//                           ),
//                           CustomTextLabel(
//                             text: cart.name,
//                             softWrap: true,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                               color: ColorsRes.mainTextColor,
//                             ),
//                           ),
//                           getSizedBox(
//                             height: Constant.size10,
//                           ),
//                           RichText(
//                             maxLines: 2,
//                             softWrap: true,
//                             overflow: TextOverflow.clip,
//                             // maxLines: 1,
//                             text: TextSpan(children: [
//                               TextSpan(
//                                 style: TextStyle(
//                                     fontSize: 12,
//                                     color: ColorsRes.mainTextColor,
//                                     decorationThickness: 2),
//                                 text: "${cart.measurement} ${cart.unit_code}",
//                               ),
//                               TextSpan(
//                                 text: double.parse(cart.discountedPrice) != 0
//                                     ? " | "
//                                     : "",
//                               ),
//                               TextSpan(
//                                 style: TextStyle(
//                                     fontSize: 12,
//                                     color: ColorsRes.grey,
//                                     decoration: TextDecoration.lineThrough,
//                                     decorationThickness: 2),
//                                 text: double.parse(cart.discountedPrice) != 0
//                                     ? "${cart.price.currency}"
//                                     : "",
//                               ),
//                             ]),
//                           ),
//                           getSizedBox(
//                             height: Constant.size10,
//                           ),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: CustomTextLabel(
//                                   text: double.parse(cart.discountedPrice) != 0
//                                       ? cart.discountedPrice.currency
//                                       : cart.price.currency,
//                                   softWrap: true,
//                                   overflow: TextOverflow.ellipsis,
//                                   style: TextStyle(
//                                       fontSize: 17,
//                                       color: ColorsRes.appColor,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                               Consumer<CartListProvider>(
//                                 builder: (context, cartListProvider, child) {
//                                   return int.parse(cart.status) == 1
//                                       ? ProductCartButton(
//                                           productId: cart.productId.toString(),
//                                           productVariantId:
//                                               cart.productVariantId.toString(),
//                                           sellerId: cart.sellerId.toString(),
//                                           count: int.parse(
//                                                       cart.status.toString()) ==
//                                                   "0"
//                                               ? -1
//                                               : int.parse(cart.qty),
//                                           isUnlimitedStock:
//                                               cart.isUnlimitedStock == "1",
//                                           maximumAllowedQuantity: double.parse(
//                                               cart.totalAllowedQuantity
//                                                   .toString()),
//                                           availableStock: double.parse(
//                                               cart.stock.toString()),
//                                           from: widget.from,
//                                           isGrid: false,
//                                         )
//                                       : SizedBox(
//                                           height: 30,
//                                           width: 30,
//                                           child: gradientBtnWidget(
//                                             context,
//                                             5,
//                                             callback: () async {
//                                               Map<String, String> params = {};
//                                               params[ApiAndParams.productId] =
//                                                   cart.productId.toString();
//                                               params[ApiAndParams
//                                                       .productVariantId] =
//                                                   cart.productVariantId
//                                                       .toString();
//                                               params[ApiAndParams.qty] = "0";

//                                               await cartListProvider
//                                                   .addRemoveCartItem(
//                                                 context: context,
//                                                 params: params,
//                                                 isUnlimitedStock:
//                                                     cart.isUnlimitedStock ==
//                                                         "1",
//                                                 maximumAllowedQuantity:
//                                                     double.parse(cart
//                                                         .totalAllowedQuantity),
//                                                 availableStock:
//                                                     double.parse(cart.stock),
//                                                 from: widget.from,
//                                                 sellerId:
//                                                     cart.sellerId.toString(),
//                                                 actionFor: "remove",
//                                               );
//                                             },
//                                             otherWidgets: defaultImg(
//                                               image: AppAssets.cartDeleteIcon,
//                                               width: 20,
//                                               height: 20,
//                                               padding:
//                                                   const EdgeInsetsDirectional
//                                                       .all(5),
//                                               iconColor:
//                                                   ColorsRes.mainIconColor,
//                                             ),
//                                           ),
//                                         );
//                                 },
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
