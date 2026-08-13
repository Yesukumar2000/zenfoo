import 'package:flutter/material.dart';
import 'package:project/utils/order_number.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/deliveryBoyOrderReturnRequest.dart';
import 'package:project/provider/returnOrdersStatusUpdateProvider.dart';

class DeliveryBoyOrderReturnRequestContainer extends StatelessWidget {
  final DeliveryBoyOrderReturnRequestData order;
  final String index;
  final VoidCallback? callApi;
  final List<String> lblOrderStatusDisplayNames;
  final List<String> lblOrderStatusUpdateNames;

  const DeliveryBoyOrderReturnRequestContainer({
    super.key,
    required this.order,
    required this.index,
    this.callApi,
    required this.lblOrderStatusDisplayNames,
    required this.lblOrderStatusUpdateNames,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          orderDetail,
          arguments: [order.orderId.toString(), "return", true, order.id.toString()],
        );
      },
      child: Container(
        padding: EdgeInsets.all(Constant.paddingOrMargin10),
        margin: EdgeInsetsDirectional.only(start: Constant.paddingOrMargin10, bottom: Constant.paddingOrMargin10, end: Constant.paddingOrMargin10),
        decoration: DesignConfig.boxDecoration(
          Theme.of(context).cardColor,
          10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: CustomTextLabel(
                    text: "ID ${formatOrderNumber(order.orderId ?? order.id)}",
                    softWrap: true,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: ColorsRes.mainTextColor,
                    ),
                  ),
                ),
                getSizedBox(width: 10),
                CustomTextLabel(
                  text: getCurrencyFormat(
                    double.parse(
                      order.finalTotal.toString(),
                    ),
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ColorsRes.appColor,
                  ),
                  softWrap: true,
                ),
                /* if (order.orderNote.toString().isNotEmpty) getSizedBox(width: 10),
                if (order.orderNote.toString().isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      showDialog<String>(
                        context: context,
                        builder: (BuildContext buildContext) => AlertDialog(
                          backgroundColor: ColorsRes.appColorYellow.shade200,
                          surfaceTintColor: ColorsRes.appColorTransparent,
                          title: CustomTextLabel(
                            jsonKey: orderNoteLabel,
                            softWrap: true,
                            style: TextStyle(
                              color: ColorsRes.lightThemeTextColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          content: CustomTextLabel(
                            text: order.orderNote.toString(),
                            softWrap: true,
                            style: TextStyle(
                              color: ColorsRes.lightThemeTextColor,
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.pop(buildContext);
                              },
                              child: CustomTextLabel(
                                jsonKey: gotItLabel,
                                softWrap: true,
                                style: TextStyle(
                                  color: ColorsRes.appColorRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: defaultImg(image: AppAssets.orderNoteIcon, width: 20, height: 20, iconColor: ColorsRes.appColorRed),
                  ), */
              ],
            ),
            getSizedBox(
              height: 10,
            ),
            Divider(height: 1, color: ColorsRes.grey, thickness: 0),
            getSizedBox(
              height: 10,
            ),
            CustomTextLabel(
              jsonKey: paymentMethodLabel,
              style: TextStyle(fontSize: 14, color: ColorsRes.grey),
              softWrap: true,
            ),
            getSizedBox(height: 2),
            CustomTextLabel(
              text: "${order.paymentMethod}",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: ColorsRes.mainTextColor,
              ),
              softWrap: true,
            ),
            getSizedBox(height: 20),
            CustomTextLabel(
              jsonKey: deliveryTimeLabel,
              style: TextStyle(fontSize: 14, color: ColorsRes.grey),
              softWrap: true,
            ),
            getSizedBox(height: 2),
            CustomTextLabel(
              text: "${Constant.formatDateTime(order.createdAt ?? "")}",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: ColorsRes.mainTextColor,
              ),
              softWrap: true,
            ),
            getSizedBox(
              height: 10,
            ),
            Divider(height: 1, color: ColorsRes.grey, thickness: 0),
            getSizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet<Future>(
                        backgroundColor: Theme.of(context).cardColor,
                        context: context,
                        isScrollControlled: true,
                        shape: DesignConfig.setRoundedBorderSpecific(20, istop: true),
                        builder: (BuildContext context) {
                          return ChangeNotifierProvider(
                            create: (context) => ReturnOrderUpdateStatusProvider(),
                            builder: (context, child) {
                              if (context.read<ReturnOrderUpdateStatusProvider>().ordersStatusState == ReturnOrderUpdateStatusState.initial) {
                                context.read<ReturnOrderUpdateStatusProvider>().setSelectedStatus(
                                      (int.parse(order.status.toString()) - 1).toString(),
                                    );
                                context.read<ReturnOrderUpdateStatusProvider>().getOrdersStatuses(context: context, from: "return");
                              }
                              return Consumer<ReturnOrderUpdateStatusProvider>(builder: (_, ordersProvider, __) {
                                return Container(
                                  padding: EdgeInsetsDirectional.only(
                                    start: Constant.paddingOrMargin15,
                                    end: Constant.paddingOrMargin15,
                                    top: Constant.paddingOrMargin15,
                                    bottom: Constant.paddingOrMargin15,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Center(
                                        child: CustomTextLabel(
                                          jsonKey: updateOrderStatusLabel,
                                          softWrap: true,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.titleMedium!.merge(
                                                TextStyle(
                                                  letterSpacing: 0.5,
                                                  color: ColorsRes.mainTextColor,
                                                ),
                                              ),
                                        ),
                                      ),
                                      getSizedBox(
                                        height: 10,
                                      ),
                                      if (ordersProvider.ordersStatusState == ReturnOrderUpdateStatusState.loaded ||
                                          ordersProvider.ordersStatusState == ReturnOrderUpdateStatusState.updating)
                                        Column(
                                          children: List.generate(
                                              ordersProvider.orderStatusesList.length /*  -
                                                  2 */
                                              , (index) {
                                            return GestureDetector(
                                              onTap: () {
                                                ordersProvider.setSelectedStatus(index.toString());
                                              },
                                              child: Container(
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Padding(
                                                        padding: EdgeInsetsDirectional.only(start: Constant.paddingOrMargin10),
                                                        child: CustomTextLabel(
                                                          jsonKey: Constant.getOrderStatusDisplayName(context, ordersProvider.orderStatusesList[index].id ?? "0", isReturn: true),
                                                        ),
                                                      ),
                                                    ),
                                                    Radio(
                                                      activeColor: ColorsRes.appColor,
                                                      value: ordersProvider.selectedOrderStatus,
                                                      groupValue: context.watch<ReturnOrderUpdateStatusProvider>().orderStatusesList[index].id,
                                                      onChanged: (value) {
                                                        ordersProvider.setSelectedStatus(index.toString());
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      getSizedBox(
                                        height: 10,
                                      ),
                                      if (ordersProvider.ordersStatusState == ReturnOrderUpdateStatusState.loading)
                                        Column(
                                          children: List.generate(8, (index) {
                                            return CustomShimmer(
                                              height: 26,
                                              width: double.maxFinite,
                                              margin: EdgeInsetsDirectional.all(10),
                                            );
                                          }),
                                        ),
                                      if (ordersProvider.ordersStatusState == ReturnOrderUpdateStatusState.loaded ||
                                          ordersProvider.ordersStatusState == ReturnOrderUpdateStatusState.updating)
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: Constant.paddingOrMargin10),
                                          child: gradientBtnWidget(
                                            context,
                                            10,
                                            callback: () {
                                              Map<String, String> params = {};
                                              params[ApiAndParams.orderId] = order.orderId.toString();
                                              params[ApiAndParams.status] = ordersProvider.selectedOrderStatus.toString();
                                              params[ApiAndParams.deliveryBoyId] = order.deliveryBoyId.toString();
                                              params[ApiAndParams.id] = order.id.toString();
                                              ordersProvider
                                                  .updateOrdersStatus(
                                                    params: params,
                                                    context: context,
                                                  )
                                                  .then(
                                                    (value) => Navigator.pop(context),
                                                  );
                                            },
                                            otherWidgets: Container(
                                              child: (ordersProvider.ordersStatusState == ReturnOrderUpdateStatusState.loaded)
                                                  ? CustomTextLabel(
                                                      jsonKey: updateOrderStatusLabel,
                                                      softWrap: true,
                                                      style: Theme.of(context).textTheme.titleMedium!.merge(
                                                            TextStyle(
                                                              color: ColorsRes.appColorWhite,
                                                              letterSpacing: 0.5,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                    )
                                                  : CircularProgressIndicator(
                                                      color: ColorsRes.appColorWhite,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      if (ordersProvider.ordersStatusState == ReturnOrderUpdateStatusState.loading)
                                        Padding(
                                          padding: EdgeInsetsDirectional.only(
                                            top: Constant.paddingOrMargin10,
                                            start: Constant.paddingOrMargin10,
                                            end: Constant.paddingOrMargin10,
                                          ),
                                          child: CustomShimmer(
                                            height: 55,
                                            width: double.maxFinite,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              });
                            },
                          );
                        },
                      ).then(
                        (value) => callApi?.call(),
                      );
                    },
                    child: Container(
                      alignment: AlignmentDirectional.centerStart,
                      padding: EdgeInsetsDirectional.all(Constant.paddingOrMargin5),
                      margin: EdgeInsetsDirectional.only(start: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ColorsRes.appColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomTextLabel(
                                  jsonKey: statusLabel,
                                  style: TextStyle(fontSize: 14, color: ColorsRes.grey),
                                  softWrap: true,
                                ),
                                getSizedBox(height: 2),
                                CustomTextLabel(
                                  text: getTranslatedValue(context, Constant.getOrderStatusDisplayName(context, order.status ?? "0", isReturn: true)),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: ColorsRes.mainTextColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_drop_down)
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
