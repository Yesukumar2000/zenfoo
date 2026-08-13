import 'package:project/helper/generalWidgets/ratingImagesWidget.dart';
import 'package:project/helper/utils/generalImports.dart';

import 'package:project/screens/productDetailScreen/widget/productDetailSimilarProductsWidget.dart';
import 'package:flutter_html/flutter_html.dart';

class ProductDetailWidget extends StatefulWidget {
  final BuildContext context;
  final ProductData product;

  ProductDetailWidget(
      {super.key, required this.context, required this.product});

  @override
  State<ProductDetailWidget> createState() => _ProductDetailWidgetState();
}

class _ProductDetailWidgetState extends State<ProductDetailWidget> {
  bool isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // LayoutBuilder(
        //   builder: (context, constraints) {
        //     return Row(
        //       children: [
        //         OtherImagesViewWidget(context, Axis.vertical, constraints),
        //         GestureDetector(
        //           onTap: () {
        //             Navigator.pushNamed(
        //               context,
        //               fullScreenProductImageScreen,
        //               arguments: [
        //                 context.read<ProductDetailProvider>().currentImage,
        //                 context.read<ProductDetailProvider>().images,
        //               ],
        //             );
        //           },
        //           child: Consumer<SelectedVariantItemProvider>(
        //             builder: (context, selectedVariantItemProvider, child) {
        //               return Padding(
        //                 padding: EdgeInsetsDirectional.only(
        //                     start: 10, top: 10, end: 10),
        //                 child: ClipRRect(
        //                   borderRadius: Constant.borderRadius10,
        //                   clipBehavior: Clip.antiAliasWithSaveLayer,
        //                   child: setNetworkImg(
        //                     boxFit: BoxFit.cover,
        //                     image: context.read<ProductDetailProvider>().images[
        //                         context
        //                             .read<ProductDetailProvider>()
        //                             .currentImage],
        //                     height: (context
        //                                 .read<ProductDetailProvider>()
        //                                 .productData
        //                                 .images
        //                                 .length >
        //                             1)
        //                         ? ((constraints.maxWidth * 0.8) - 10)
        //                         : constraints.maxWidth - 20,
        //                     width: (context
        //                                 .read<ProductDetailProvider>()
        //                                 .productData
        //                                 .images
        //                                 .length >
        //                             1)
        //                         ? ((constraints.maxWidth * 0.8) - 10)
        //                         : constraints.maxWidth - 20,
        //                   ),
        //                 ),
        //               );
        //             },
        //           ),
        //         ),
        //       ],
        //     );
        //   },
        // ),

        // Container(
        //   padding: EdgeInsetsDirectional.only(
        //       top: 0, start: 10, end: 10, bottom: 10),
        //   margin: EdgeInsetsDirectional.only(
        //     top: 10,
        //     start: 10,
        //     end: 10,
        //   ),
        //   decoration:
        //       DesignConfig.boxDecoration(Theme.of(context).cardColor, 5),
        //   child: Consumer<SelectedVariantItemProvider>(
        //     builder: (context, selectedVariantItemProvider, _) {
        //       return Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         mainAxisAlignment: MainAxisAlignment.start,
        //         children: [
        //           // Row(
        //           //   children: [
        //           //     Expanded(
        //           //       child: CustomTextLabel(
        //           //         text: widget.product.name,
        //           //         softWrap: true,
        //           //         style: TextStyle(
        //           //           fontSize: 20,
        //           //           fontWeight: FontWeight.bold,
        //           //           color: ColorsRes.mainTextColor,
        //           //         ),
        //           //       ),
        //           //     ),
        //           //   ],
        //           // ),
        //           // getSizedBox(height: Constant.size10),
        //           // Padding(
        //           //   padding: EdgeInsetsDirectional.only(end: 5),
        //           //   child: Row(
        //           //     crossAxisAlignment: CrossAxisAlignment.center,
        //           //     mainAxisAlignment: MainAxisAlignment.start,
        //           //     children: [
        //           //       // CustomTextLabel(
        //           //       //   text: double.parse(widget
        //           //       //               .product
        //           //       //               .variants[selectedVariantItemProvider
        //           //       //                   .getSelectedIndex()]
        //           //       //               .discountedPrice) !=
        //           //       //           0
        //           //       //       ? widget
        //           //       //           .product
        //           //       //           .variants[selectedVariantItemProvider
        //           //       //               .getSelectedIndex()]
        //           //       //           .discountedPrice
        //           //       //           .currency
        //           //       //       : widget
        //           //       //           .product
        //           //       //           .variants[selectedVariantItemProvider
        //           //       //               .getSelectedIndex()]
        //           //       //           .price
        //           //       //           .currency,
        //           //       //   softWrap: true,
        //           //       //   overflow: TextOverflow.ellipsis,
        //           //       //   style: TextStyle(
        //           //       //       fontSize: 17,
        //           //       //       color: ColorsRes.appColor,
        //           //       //       fontWeight: FontWeight.w500),
        //           //       // ),
        //           //       // getSizedBox(width: 5),
        //           //       // RichText(
        //           //       //   maxLines: 2,
        //           //       //   softWrap: true,
        //           //       //   overflow: TextOverflow.clip,
        //           //       //   text: TextSpan(children: [
        //           //       //     TextSpan(
        //           //       //       style: TextStyle(
        //           //       //           fontSize: 17,
        //           //       //           color: ColorsRes.grey,
        //           //       //           decoration: TextDecoration.lineThrough,
        //           //       //           decorationThickness: 2),
        //           //       //       text: double.parse(widget.product.variants[0]
        //           //       //                   .discountedPrice) !=
        //           //       //               0
        //           //       //           ? widget.product.variants[0].price.currency
        //           //       //           : "",
        //           //       //     ),
        //           //       //   ]),
        //           //       // ),
        //           //       // Spacer(),
        // ProductListRatingBuilderWidget(
        //   averageRating: context
        //       .read<RatingListProvider>()
        //       .productRatingData
        //       .averageRating
        //       .toString()
        //       .toDouble,
        //   totalRatings: context
        //       .read<RatingListProvider>()
        //       .totalData
        //       .toString()
        //       .toInt,
        //   size: 15,
        //   spacing: 2,
        //   fontSize: 16,
        // ),
        //           //     ],
        //           //   ),
        //           // ),
        //           // getSizedBox(height: Constant.size10),
        // ProductDetailAddToCartButtonWidget(
        //   context: context,
        //   product: widget.product,
        // ),
        //         ],
        //       );
        //     },
        //   ),
        // ),
        // ProductDetailImportantInformationWidget(context, widget.product),
        // getSizedBox(height: Constant.size10),
        // Container(
        //   margin: EdgeInsetsDirectional.only(
        //     start: 10,
        //     end: 10,
        //     bottom: 10,
        //   ),
        //   decoration: DesignConfig.boxDecoration(
        //     Theme.of(context).cardColor,
        //     10,
        //   ),
        //   child: ExpansionTile(
        //     collapsedShape:
        //         ShapeBorder.lerp(InputBorder.none, InputBorder.none, 0),
        //     shape: ShapeBorder.lerp(InputBorder.none, InputBorder.none, 0),
        //     initiallyExpanded: true,
        //     title: CustomTextLabel(
        //       jsonKey: productSpecificationsLabel,
        //       style: TextStyle(
        //         fontSize: 18,
        //         fontWeight: FontWeight.bold,
        //         color: ColorsRes.mainTextColor,
        //       ),
        //     ),
        //     iconColor: ColorsRes.mainTextColor,
        //     collapsedIconColor: ColorsRes.mainTextColor,
        //     children: [
        //       Padding(
        //         padding: const EdgeInsetsDirectional.only(
        //           start: 5,
        //           end: 5,
        //           bottom: 10,
        //         ),
        //         child: Container(
        //           margin: EdgeInsetsDirectional.all(10),
        //           child: Column(
        //             children: [
        //               getSpecificationItem(
        //                 titleJson: fssaiLicNoLabel,
        //                 value: widget.product.fssaiLicNo.toString(),
        //                 voidCallback: () {},
        //                 isClickable: false,
        //               ),
        //               getSpecificationItem(
        //                 titleJson: categoryLabel,
        //                 value: widget.product.categoryName.toString(),
        //                 voidCallback: () {
        //                   Navigator.pushNamed(
        //                     context,
        //                     productListScreen,
        //                     arguments: [
        //                       "category",
        //                       widget.product.categoryId.toString(),
        //                       widget.product.categoryName.toString(),
        //                     ],
        //                   );
        //                 },
        //                 isClickable: true,
        //               ),
        //               getSpecificationItem(
        //                 titleJson: sellerNameLabel,
        //                 value: widget.product.sellerName,
        //                 voidCallback: () {
        //                   Navigator.pushNamed(
        //                     context,
        //                     productListScreen,
        //                     arguments: [
        //                       "seller",
        //                       widget.product.sellerId.toString(),
        //                       widget.product.sellerName.toString(),
        //                     ],
        //                   );
        //                 },
        //                 isClickable: true,
        //               ),
        //               getSpecificationItem(
        //                 titleJson: brandLabel,
        //                 value: widget.product.brandName,
        //                 voidCallback: () {
        //                   Navigator.pushNamed(
        //                     context,
        //                     productListScreen,
        //                     arguments: [
        //                       "brand",
        //                       widget.product.brandId.toString(),
        //                       widget.product.brandName.toString(),
        //                     ],
        //                   );
        //                 },
        //                 isClickable: true,
        //               ),
        //               getSpecificationItem(
        //                 titleJson: madeInLabel,
        //                 value: widget.product.madeIn,
        //                 voidCallback: () {
        //                   Navigator.pushNamed(
        //                     context,
        //                     productListScreen,
        //                     arguments: [
        //                       "country",
        //                       widget.product.madeInId.toString(),
        //                       widget.product.madeIn.toString(),
        //                     ],
        //                   );
        //                 },
        //                 isClickable: true,
        //               ),
        //               getSpecificationItem(
        //                 titleJson: manufacturerLabel,
        //                 value: widget.product.manufacturer,
        //                 voidCallback: () {},
        //                 isClickable: false,
        //               ),
        //             ],
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        Container(
          decoration: DesignConfig.boxDecoration(
            Theme.of(context).cardColor,
            10,
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            collapsedShape:
                ShapeBorder.lerp(InputBorder.none, InputBorder.none, 0),
            shape: ShapeBorder.lerp(InputBorder.none, InputBorder.none, 0),
            initiallyExpanded: true,
            title: CustomTextLabel(
              jsonKey: productOverviewLabel,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorsRes.mainTextColor,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            iconColor: ColorsRes.mainTextColor,
            collapsedIconColor: ColorsRes.mainTextColor,
            maintainState: true,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: 0),
                child: Container(
                  margin: EdgeInsetsDirectional.zero,
                  child: Html(
                    data: widget.product.description,
                    style: {
                      "body": Style(
                        color: ColorsRes.mainTextColor,
                        fontSize: FontSize(14),
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "*": Style(color: ColorsRes.mainTextColor),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // Other Info Section
        if (widget.product.otherInfo.isNotEmpty &&
            widget.product.otherInfo != 'null')
          Container(
            decoration: DesignConfig.boxDecoration(
              Theme.of(context).cardColor,
              10,
            ),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              collapsedShape:
                  ShapeBorder.lerp(InputBorder.none, InputBorder.none, 0),
              shape: ShapeBorder.lerp(InputBorder.none, InputBorder.none, 0),
              initiallyExpanded: true,
              title: Text(
                getTranslatedValue(context, 'other_information'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorsRes.mainTextColor,
                  letterSpacing: -0.55,
                  height: 1.02,
                ),
              ),
              iconColor: ColorsRes.mainTextColor,
              collapsedIconColor: ColorsRes.mainTextColor,
              maintainState: true,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 0),
                  child: Container(
                    margin: EdgeInsetsDirectional.zero,
                    child: Html(
                      data: widget.product.otherInfo,
                      style: {
                        "body": Style(
                          color: ColorsRes.mainTextColor,
                          fontSize: FontSize(14),
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                        "*": Style(color: ColorsRes.mainTextColor),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Return & Cancellation Policy Section
        _buildReturnCancelPolicySection(context, widget.product),
        Consumer<RatingListProvider>(
          builder: (context, ratingListProvider, child) {
            if (ratingListProvider.ratings.length > 0) {
              return Container(
                margin: EdgeInsetsDirectional.only(
                  start: 10,
                  end: 10,
                  bottom: 10,
                ),
                decoration: DesignConfig.boxDecoration(
                  Theme.of(context).cardColor,
                  10,
                ),
                child: ExpansionTile(
                  collapsedShape:
                      ShapeBorder.lerp(InputBorder.none, InputBorder.none, 0),
                  shape:
                      ShapeBorder.lerp(InputBorder.none, InputBorder.none, 0),
                  initiallyExpanded: true,
                  title: CustomTextLabel(
                    jsonKey: ratingsAndReviewsLabel,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorsRes.mainTextColor,
                    ),
                  ),
                  iconColor: ColorsRes.mainTextColor,
                  collapsedIconColor: ColorsRes.mainTextColor,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          getOverallRatingSummary(
                              context: context,
                              productRatingData:
                                  ratingListProvider.productRatingData,
                              totalRatings:
                                  ratingListProvider.totalData.toString()),
                          if (ratingListProvider.totalImages > 0)
                            getSizedBox(height: 20),
                          if (ratingListProvider.totalImages > 0)
                            CustomTextLabel(
                              text:
                                  "${getTranslatedValue(context, customerPhotosLabel)}(${ratingListProvider.totalImages})",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ColorsRes.mainTextColor,
                              ),
                            ),
                          if (ratingListProvider.totalImages > 0)
                            getSizedBox(height: 20),
                          if (ratingListProvider.totalImages > 0)
                            RatingImagesWidget(
                              images: ratingListProvider.images,
                              from: "productDetails",
                              productId: widget.product.id,
                              totalImages: ratingListProvider.totalImages,
                            ),
                          getSizedBox(height: 20),
                          CustomTextLabel(
                            jsonKey: customerReviewsLabel,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ColorsRes.mainTextColor,
                            ),
                          ),
                          getSizedBox(height: 20),
                          ListView(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            children: List.generate(
                              ratingListProvider.ratings.length,
                              (index) {
                                ProductRatingList rating =
                                    ratingListProvider.ratings[index];
                                return Column(
                                  children: [
                                    getRatingReviewItem(
                                      rating: rating,
                                      context: context,
                                    ),
                                    getSizedBox(height: 10),
                                    getDivider(
                                      color:
                                          ColorsRes.grey.withValues(alpha: 0.5),
                                      height: 0,
                                      endIndent: 0,
                                      indent: 0,
                                    ),
                                    getSizedBox(height: 10),
                                  ],
                                );
                              },
                            ),
                          ),
                          if (ratingListProvider.totalData > 5)
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                    context, ratingAndReviewScreen,
                                    arguments: widget.product.id.toString());
                              },
                              child: Padding(
                                padding: EdgeInsetsDirectional.only(
                                  top: 10,
                                  end: 10,
                                  bottom: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: BorderDirectional(
                                          bottom: BorderSide(
                                              color: ColorsRes.mainTextColor),
                                        ),
                                      ),
                                      child: CustomTextLabel(
                                        text:
                                            "${getTranslatedValue(context, viewAllReviewsTitleLabel)} ${ratingListProvider.totalData.toString().toInt} ${getTranslatedValue(context, reviewsLabel)}",
                                        style: TextStyle(
                                          color: ColorsRes.mainTextColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    getSizedBox(width: 5),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: ColorsRes.mainTextColor,
                                      size: 13,
                                    ),
                                  ],
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                ),
                              ),
                            ),
                          getSizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return SizedBox.shrink();
            }
          },
        ),
        getSizedBox(height: 20),
        ChangeNotifierProvider<ProductListProvider>(
          create: (context) => ProductListProvider(),
          child: ProductDetailSimilarProductsWidget(
            tags: context
                .read<ProductDetailProvider>()
                .productDetail
                .data
                .tagNames,
            slug: context.read<ProductDetailProvider>().productDetail.data.slug,
          ),
        ),
        getSizedBox(
          height: context.watch<ProductDetailProvider>().expanded == true
              ? 120
              : Constant.size80,
        ),
      ],
    );
  }
}

Widget getSpecificationItem({
  required String titleJson,
  required String value,
  required VoidCallback voidCallback,
  required bool isClickable,
}) {
  if (value != "null" && value != "") {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CustomTextLabel(
                jsonKey: titleJson,
                softWrap: true,
                style: TextStyle(
                  color: ColorsRes.subTitleMainTextColor,
                ),
              ),
            ),
            getSizedBox(width: 10),
            CustomTextLabel(
              text: ":",
              softWrap: true,
              style: TextStyle(
                color: ColorsRes.subTitleMainTextColor,
              ),
            ),
            getSizedBox(width: 10),
            Expanded(
              flex: 7,
              child: GestureDetector(
                onTap: voidCallback,
                child: CustomTextLabel(
                  text: value,
                  softWrap: true,
                  style: TextStyle(
                    color: isClickable
                        ? ColorsRes.appColorBlueAccent
                        : ColorsRes.mainTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        getSizedBox(height: 10),
      ],
    );
  } else {
    return SizedBox.shrink();
  }
}

Widget buildProductTopImageSection(BuildContext context, ProductData product,
    int currentImage, Function onBookmarkTap, Function onShareTap,
    {bool isBookmarked = false}) {
  final List<String> images = product.images ?? [];
  final screenWidth = MediaQuery.of(context).size.width;
  final mainImage = (images.isNotEmpty)
      ? images[currentImage]
      : "https://placehold.co/393x350";

  return Container(
    width: screenWidth,
    height: screenWidth * 0.89, // 350 on 393px base
    child: Stack(
      children: [
        // Main product image, with loading indicator
        Positioned.fill(
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                fullScreenProductImageScreen,
                arguments: [
                  context.read<ProductDetailProvider>().currentImage,
                  context.read<ProductDetailProvider>().images,
                ],
              );
            },
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: mainImage,
                  width: screenWidth,
                  height: screenWidth * 0.89,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => Shimmer.fromColors(
                    baseColor: const Color(0xFFE0E0E0),
                    highlightColor: const Color(0xFFF5F5F5),
                    child: Container(
                      width: screenWidth,
                      height: screenWidth * 0.89,
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (ctx, url, error) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image,
                        size: 80, color: Colors.grey[400]),
                  ),
                ),
              ),
            ),
          ),
        ),

        // AppBar fade at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.93),
                  Colors.white.withOpacity(0),
                ],
              ),
            ),
          ),
        ),

        // Back button
        Positioned(
          left: 12,
          top: 26,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 9,
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back_ios_new,
                    size: 22, color: Colors.black87),
              ),
            ),
          ),
        ),

        // Bookmark button (right, before share)
        Positioned(
          right: 68,
          top: 30,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onBookmarkTap(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 11,
                    ),
                  ],
                ),
                child: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 22,
                    color: isBookmarked ? Colors.black : Colors.black87),
              ),
            ),
          ),
        ),

        // Share button
        Positioned(
          right: 16,
          top: 30,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onShareTap(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Icon(Icons.share, size: 22, color: Colors.black87),
              ),
            ),
          ),
        ),

        // Page indicator at bottom center (for multiple images)
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (idx) => AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: idx == currentImage ? 20 : 7,
                  height: 6,
                  decoration: BoxDecoration(
                    color: idx == currentImage
                        ? Colors.black
                        : Colors.black.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(6.86),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

// Description Loading Shimmer Widget
class _DescriptionLoadingShimmer extends StatefulWidget {
  const _DescriptionLoadingShimmer({Key? key}) : super(key: key);

  @override
  State<_DescriptionLoadingShimmer> createState() =>
      _DescriptionLoadingShimmerState();
}

class _DescriptionLoadingShimmerState extends State<_DescriptionLoadingShimmer>
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

  Widget _buildShimmerLine(double width) {
    return Container(
      height: 14,
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
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerLine(double.infinity),
              const SizedBox(height: 8),
              _buildShimmerLine(double.infinity),
              const SizedBox(height: 8),
              _buildShimmerLine(double.infinity),
              const SizedBox(height: 8),
              _buildShimmerLine(double.infinity),
              const SizedBox(height: 8),
              _buildShimmerLine(MediaQuery.of(context).size.width * 0.7),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildReturnCancelPolicySection(
    BuildContext context, ProductData product) {
  String returnStatus = product.returnStatus.toString();
  String cancelableStatus = product.cancelableStatus.toString();
  String returnDays = product.returnDays.toString();
  String skinnedStatus = product.isSkinnedOne.toString();
  String meatProductStatus = product.isMeatProduct.toString();

  bool isReturnable = returnStatus == "1";
  bool isCancelable = cancelableStatus == "1";
  bool isMeatProduct = meatProductStatus == "1";
  bool isSkinned = skinnedStatus == "1";

  // Fish-cut details (Before Cleaning / After / Pieces) shown for cleaned fish items.
  final bool showCutTable = isMeatProduct &&
      (product.beforeCleaningWeight.isNotEmpty ||
          product.afterCleaningWeight.isNotEmpty ||
          product.pieces.isNotEmpty);

  return Padding(
    padding: EdgeInsetsDirectional.only(top: 10, bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _policyBadge(
                icon: isReturnable
                    ? Icons.assignment_return_rounded
                    : Icons.block_rounded,
                label: isReturnable
                    ? "Returnable within $returnDays days after delivery date"
                    : "Not Returnable",
                isPositive: isReturnable),
            _policyBadge(
              icon: isCancelable
                  ? Icons.cancel_outlined
                  : Icons.do_not_disturb_alt_rounded,
              label: isCancelable ? "Cancelable" : "Not Cancelable",
              isPositive: isCancelable,
            ),
            // Only show skinned badge if it's a meat product
            if (isMeatProduct)
              _policyBadge(
                icon: isSkinned
                    ? Icons.content_cut_rounded
                    : Icons.do_not_disturb_alt_rounded,
                label: isSkinned ? "Skinned" : "Not Skinned",
                isPositive: isSkinned,
              ),
            // Cleaned badge
            if (isMeatProduct)
              _policyBadge(
                icon: product.isCleaned
                    ? Icons.clean_hands_rounded
                    : Icons.do_not_disturb_alt_rounded,
                label: product.isCleaned ? "Cleaned" : "Not Cleaned",
                isPositive: product.isCleaned,
              ),
          ],
        ),
        if (showCutTable) ...[
          SizedBox(height: 12),
          _fishCutTable(product),
        ],
      ],
    ),
  );
}

// Boxed 3-column table: Before Cleaning | After | Pieces
Widget _fishCutTable(ProductData product) {
  final cells = <Widget>[
    if (product.beforeCleaningWeight.isNotEmpty)
      _fishCutCell("Before Cleaning", product.beforeCleaningWeight),
    if (product.afterCleaningWeight.isNotEmpty)
      _fishCutCell("After", product.afterCleaningWeight),
    if (product.pieces.isNotEmpty) _fishCutCell("Pieces", product.pieces),
  ];

  // Build row with thin dividers between cells.
  final rowChildren = <Widget>[];
  for (var i = 0; i < cells.length; i++) {
    rowChildren.add(Expanded(child: cells[i]));
    if (i != cells.length - 1) {
      rowChildren.add(Container(
        width: 1,
        height: 34,
        color: Color(0xFFE0E0E0),
      ));
    }
  }

  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Color(0xFFE0E0E0)),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: EdgeInsets.symmetric(vertical: 10),
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
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF9E9E9E),
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
        ),
      ],
    ),
  );
}

Widget _policyBadge({
  required IconData icon,
  required String label,
  required bool isPositive,
}) {
  final color = isPositive ? Color(0xFF2E7D32) : Color(0xFFc62828);
  final bgColor = isPositive ? Color(0xFFE8F5E9) : Color(0xFFFFEBEE);

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    ),
  );
}
