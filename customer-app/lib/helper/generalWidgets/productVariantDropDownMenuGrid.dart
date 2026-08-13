import 'package:project/helper/utils/generalImports.dart';

class ProductVariantDropDownMenuGrid extends StatefulWidget {
  final List<Variants>? variants;
  final String from;
  final ProductListItem product;
  final bool isGrid;

  const ProductVariantDropDownMenuGrid({
    Key? key,
    this.variants,
    required this.from,
    required this.product,
    required this.isGrid,
  }) : super(key: key);

  @override
  State<ProductVariantDropDownMenuGrid> createState() =>
      _ProductVariantDropDownMenuGridState();
}

class _ProductVariantDropDownMenuGridState
    extends State<ProductVariantDropDownMenuGrid> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedVariantItemProvider>(
      builder: (context, selectedVariantItemProvider, _) {
        if (widget.variants?.length != 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: 5, end: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomTextLabel(
                            text: (double.tryParse(widget
                                            .variants![selectedVariantItemProvider
                                                .getSelectedIndex()]
                                            .discountedPrice
                                            ?.toString() ??
                                        "0") ??
                                    0.0) !=
                                0
                                ? widget
                                    .variants![selectedVariantItemProvider
                                        .getSelectedIndex()]
                                    .discountedPrice
                                    ?.toString() ??
                                    "0"
                                    .currency
                                : widget
                                    .variants![selectedVariantItemProvider
                                        .getSelectedIndex()]
                                    .price
                                    .toString()
                                    .currency,
                            softWrap: true,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontSize: 15,
                              color: ColorsRes.appColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          getSizedBox(width: 5),
                          if ((double.tryParse(widget.variants![0].discountedPrice
                                      ?.toString() ??
                                  "0") ??
                              0.0) !=
                              0)
                            RichText(
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.clip,
                              text: TextSpan(children: [
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ColorsRes.grey,
                                    decoration: TextDecoration.lineThrough,
                                    decorationThickness: 2,
                                  ),
                                  text: ((double.tryParse(widget.variants![0].discountedPrice
                                              ?.toString() ??
                                          "0") ??
                                      0.0)) !=
                                          0
                                      ? widget.variants![0].price
                                          ?.toString() ??
                                          "0"
                                          .currency
                                      : "",
                                ),
                              ]),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (widget.variants!.length > 1) {
                          {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              shape: DesignConfig.setRoundedBorderSpecific(20,
                                  istop: true),
                              backgroundColor: Theme.of(context).cardColor,
                              builder: (BuildContext context) {
                                return Container(
                                  padding: EdgeInsetsDirectional.only(
                                      start: Constant.size15,
                                      end: Constant.size15,
                                      top: Constant.size15,
                                      bottom: Constant.size15),
                                  child: Wrap(
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.only(
                                            start: Constant.size15,
                                            end: Constant.size15),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  Constant.borderRadius10,
                                              clipBehavior:
                                                  Clip.antiAliasWithSaveLayer,
                                              child: setNetworkImg(
                                                // contain so the product isn't cropped
                                                boxFit: BoxFit.contain,
                                                fillBackdrop: true,
                                                image: widget.product.imageUrl
                                                    .toString(),
                                                height: 70,
                                                width: 70,
                                              ),
                                            ),
                                            getSizedBox(
                                              width: Constant.size10,
                                            ),
                                            Expanded(
                                              child: CustomTextLabel(
                                                text: widget.product.name
                                                    .toString(),
                                                softWrap: true,
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color:
                                                      ColorsRes.mainTextColor,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsetsDirectional.only(
                                            start: Constant.size15,
                                            end: Constant.size15,
                                            top: Constant.size15,
                                            bottom: Constant.size15),
                                        child: ListView.separated(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount: widget.variants!.length,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(
                                                        child: RichText(
                                                          maxLines: 2,
                                                          softWrap: true,
                                                          overflow:
                                                              TextOverflow.clip,
                                                          // maxLines: 1,
                                                          text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          15,
                                                                      color: ColorsRes
                                                                          .mainTextColor,
                                                                      decorationThickness:
                                                                          2),
                                                                  text:
                                                                      "${widget.variants![index].measurement} ",
                                                                ),
                                                                WidgetSpan(
                                                                  child:
                                                                      CustomTextLabel(
                                                                    text: widget
                                                                        .variants![
                                                                            index]
                                                                        .stockUnitName
                                                                        .toString(),
                                                                    softWrap:
                                                                        true,
                                                                    //superscript is usually smaller in size
                                                                    // textScaleFactor: 0.7,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: ColorsRes
                                                                          .mainTextColor,
                                                                    ),
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                    text: (double.tryParse(widget.variants![index].discountedPrice?.toString() ?? "0") ?? 0.0) !=
                                                                            0
                                                                        ? " | "
                                                                        : "",
                                                                    style: TextStyle(
                                                                        color: ColorsRes
                                                                            .mainTextColor)),
                                                                TextSpan(
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      color: ColorsRes
                                                                          .subTitleMainTextColor,
                                                                      decoration:
                                                                          TextDecoration
                                                                              .lineThrough,
                                                                      decorationThickness:
                                                                          2),
                                                                  text: (double.tryParse(widget
                                                                              .variants![
                                                                                  index]
                                                                              .discountedPrice
                                                                              ?.toString() ?? "0") ?? 0.0) !=
                                                                          0
                                                                      ? widget
                                                                          .variants![
                                                                              index]
                                                                          .price
                                                                          ?.toString() ?? "0"
                                                                          .currency
                                                                      : "",
                                                                ),
                                                              ]),
                                                        ),
                                                      ),
                                                      CustomTextLabel(
                                                        text: (double.tryParse(widget
                                                                    .variants![
                                                                        index]
                                                                    .discountedPrice
                                                                    ?.toString() ?? "0") ?? 0.0) !=
                                                                0
                                                            ? widget
                                                                .variants![
                                                                    index]
                                                                .discountedPrice
                                                                ?.toString() ?? "0"
                                                                .currency
                                                            : widget
                                                                .variants![
                                                                    index]
                                                                .price
                                                                ?.toString() ?? "0"
                                                                .currency,
                                                        softWrap: true,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            fontSize: 17,
                                                            color: ColorsRes
                                                                .appColor,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                ProductCartButton(
                                                  productId: widget.product.id
                                                      .toString(),
                                                  productVariantId: widget
                                                      .variants![index].id
                                                      .toString(),
                                                  count: (int.tryParse(widget
                                                              .variants![index]
                                                              .status
                                                              ?.toString() ?? "0") ?? 0) ==
                                                          0
                                                      ? -1
                                                      : (int.tryParse(widget
                                                          .variants![index]
                                                          .cartCount
                                                          ?.toString() ?? "0") ?? 0),
                                                  isUnlimitedStock: widget
                                                          .product
                                                          .isUnlimitedStock ==
                                                      "1",
                                                  maximumAllowedQuantity:
                                                      double.tryParse(widget
                                                          .product
                                                          .totalAllowedQuantity
                                                          ?.toString() ?? "0") ??
                                                          0.0,
                                                  availableStock: double.tryParse(
                                                      widget.variants![index]
                                                          .stock
                                                          ?.toString() ?? "0") ?? 0.0,
                                                  isGrid: false,
                                                  sellerId: widget
                                                      .product.sellerId
                                                      .toString(),
                                                  from: widget.from,
                                                ),
                                              ],
                                            );
                                          },
                                          separatorBuilder:
                                              (BuildContext context,
                                                  int index) {
                                            return Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: Constant.size7),
                                              child: getDivider(
                                                color: ColorsRes
                                                    .subTitleMainTextColor
                                                    .withValues(alpha:0.3),
                                                height: 5,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: Constant.borderRadius5,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        margin: EdgeInsetsDirectional.only(end: 5),
                        child: Container(
                          padding: widget.variants!.length > 1
                              ? EdgeInsets.zero
                              : EdgeInsets.all(5),
                          alignment: AlignmentDirectional.center,
                          height: 35,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.variants!.length > 1) Spacer(),
                              if (widget.variants!.length > 1)
                                Expanded(
                                  flex: 22,
                                  child: Padding(
                                    padding:
                                        EdgeInsetsDirectional.only(start: 5),
                                    child: CustomTextLabel(
                                      text:
                                          "${widget.variants![0].measurement} ${widget.variants![0].stockUnitName}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ColorsRes.mainTextColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              if (widget.variants!.length == 1)
                                Expanded(
                                  child: CustomTextLabel(
                                    text:
                                        "${widget.variants![0].measurement} ${widget.variants![0].stockUnitName}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ColorsRes.mainTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (widget.variants!.length > 1)
                                Expanded(
                                  flex: 7,
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.only(
                                        start: 5, end: 5),
                                    child: defaultImg(
                                      image: AppAssets.icDropDownIcon,
                                      height: 10,
                                      width: 10,
                                      boxFit: BoxFit.cover,
                                      iconColor: ColorsRes.mainTextColor,
                                    ),
                                  ),
                                ),
                              if (widget.variants!.length > 1) Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              getSizedBox(
                height: 5,
              ),
              getDivider(
                color: ColorsRes.subTitleMainTextColor.withValues(alpha:0.3),
                height: 1,
                thickness: 1,
              ),
              getSizedBox(
                height: 5,
              ),
              Container(
                width: double.maxFinite,
                child: ProductCartButton(
                  productId: widget.product.id.toString(),
                  productVariantId: widget
                      .variants![selectedVariantItemProvider.getSelectedIndex()]
                      .id
                      .toString(),
                  count: (int.tryParse(widget
                              .variants![selectedVariantItemProvider
                                  .getSelectedIndex()]
                              .status
                              ?.toString() ?? "0") ?? 0) ==
                          0
                      ? -1
                      : int.tryParse(widget
                              .variants![
                                  selectedVariantItemProvider.getSelectedIndex()]
                              .cartCount
                              ?.toString() ??
                          "0") ??
                          0,
                  isUnlimitedStock: widget.product.isUnlimitedStock == "1",
                  maximumAllowedQuantity: double.tryParse(
                          widget.product.totalAllowedQuantity?.toString() ?? "0") ??
                      0.0,
                  availableStock: double.tryParse(widget
                              .variants![selectedVariantItemProvider.getSelectedIndex()]
                              .stock
                              ?.toString() ??
                          "0") ??
                      0.0,
                  isGrid: widget.isGrid,
                  sellerId: widget.product.sellerId.toString(),
                  from: widget.from,
                ),
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
