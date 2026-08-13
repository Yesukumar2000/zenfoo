import 'package:project/helper/utils/generalImports.dart';

class ProductGridItemContainer extends StatefulWidget {
  final ProductListItem product;

  const ProductGridItemContainer({Key? key, required this.product})
      : super(key: key);

  @override
  State<ProductGridItemContainer> createState() => _State();
}

class _State extends State<ProductGridItemContainer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ProductListItem product = widget.product;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          productDetailScreen,
          arguments: [
            product.id.toString(),
            product.name,
            product,
          ],
        );
      },
      child: ChangeNotifierProvider<SelectedVariantItemProvider>(
        create: (context) => SelectedVariantItemProvider(),
        child: product.variants!.length > 0
            ? Container(
                decoration: DesignConfig.boxDecoration(
                  Theme.of(context).cardColor,
                  8,
                  borderwidth: 1,
                  isboarder: true,
                  bordercolor:
                      ColorsRes.subTitleMainTextColor.withValues(alpha: 0.3),
                ),
                padding: EdgeInsetsDirectional.all(5),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: Consumer<SelectedVariantItemProvider>(
                            builder:
                                (context, selectedVariantItemProvider, child) {
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: ColorsRes.appColorWhite,
                                      borderRadius: Constant.borderRadius7,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: Constant.borderRadius7,
                                      clipBehavior: Clip.antiAliasWithSaveLayer,
                                      child: Builder(builder: (ctx) {
                                        print("🛒 GRID product=${product.name} storeId=${product.storeId} imageUrl=${product.imageUrl}");
                                        return setNetworkImg(
                                          // contain, not cover: cover crops to
                                          // fill the tile and slices the edges
                                          // off the product. The container
                                          // behind is already white, so the
                                          // whole item sits on white instead.
                                          boxFit: BoxFit.contain,
                                          fillBackdrop: true,
                                          image: product.imageUrl.toString(),
                                          height: double.maxFinite,
                                          width: double.maxFinite,
                                          storeId: product.storeId,
                                          isMeat: product.isMeatProduct ?? false,
                                          isSuperMart: product.isSuperMart ?? false,
                                        );
                                      }),
                                    ),
                                  ),
                                  if (product.isPreOrderItem == 1)
                                    Positioned(
                                      top: 5,
                                      left: 5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.3),
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
                                  PositionedDirectional(
                                    bottom: 5,
                                    end: 5,
                                    child: Column(
                                      children: [
                                        if (product.indicator.toString() == "1")
                                          defaultImg(
                                            height: 24,
                                            width: 24,
                                            image: AppAssets
                                                .productVegIndicatorIcon,
                                          ),
                                        if (product.indicator.toString() == "2")
                                          defaultImg(
                                            height: 24,
                                            width: 24,
                                            image: AppAssets
                                                .productNonVegIndicatorIcon,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        getSizedBox(
                          height: 5,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.only(start: 5),
                              child: CustomTextLabel(
                                text: product.name.toString(),
                                maxLines: 1,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: ColorsRes.mainTextColor,
                                ),
                              ),
                            ),
                            getSizedBox(
                              height: 5,
                            ),
                            ProductListRatingBuilderWidget(
                              averageRating: widget.product.averageRating
                                  .toString()
                                  .toDouble,
                              totalRatings:
                                  widget.product.ratingCount.toString().toInt,
                              size: 15,
                              spacing: 2,
                            ),
                            getSizedBox(
                              height: Constant.size10,
                            ),
                            if (product.variants!.isNotEmpty)
                              ProductVariantDropDownMenuGrid(
                                from: "",
                                product: product,
                                variants: product.variants,
                                isGrid: true,
                              ),
                          ],
                        )
                      ],
                    ),
                    PositionedDirectional(
                      end: 5,
                      top: 5,
                      child: ProductWishListIcon(
                        product: product,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        double discountPercentage = 0.0;
                        if (product.variants!.first.discountedPrice
                                .toString()
                                .toDouble >
                            0.0) {
                          discountPercentage = product.variants!.first.price
                              .toString()
                              .toDouble
                              .calculateDiscountPercentage(product
                                  .variants!.first.discountedPrice
                                  .toString()
                                  .toDouble);
                        }

                        if (discountPercentage > 0.0) {
                          return PositionedDirectional(
                            start: 5,
                            top: 5,
                            child: Container(
                              padding: EdgeInsetsDirectional.only(
                                start: 7,
                                end: 7,
                              ),
                              decoration: BoxDecoration(
                                color: ColorsRes.appColorRed,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: CustomTextLabel(
                                text:
                                    "${discountPercentage.toStringAsFixed(2)}% ${getTranslatedValue(context, offLabel)}",
                                style: TextStyle(
                                  color: ColorsRes.appColorWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                ),
              )
            : SizedBox.shrink(),
      ),
    );
  }
}
