import 'package:project/helper/utils/generalImports.dart';

class OrderDeliveryAddressWidget extends StatelessWidget {
  final Order order;
  final String from;

  const OrderDeliveryAddressWidget({super.key, required this.order, required this.from});

  void _openMap(String lat, String lng) async {
    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return (order.orderType == "selfpickup")
        ? Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsetsDirectional.all(10),
            width: context.width,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Theme.of(context).cardColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.store_outlined,
                      color: ColorsRes.appColor,
                      size: 20,
                    ),
                    getSizedBox(width: Constant.size8),

                    Expanded(
                      child: CustomTextLabel(
                        jsonKey: pickupFromStoreLabel,
                        style: TextStyle(
                          color: ColorsRes.mainTextColor,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    // const Spacer(),
                    gradientBtnWidget(
                      context,
                      Constant.size5,
                      callback: () {
                        final lat = order.pickupAddress?.pickupLatitude;
                        final lng = order.pickupAddress?.pickupLongitude;
                        if (lat != null && lng != null) {
                          _openMap(lat, lng);
                        }
                      },
                      height: 35,
                      width: 90,
                      otherWidgets: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_outlined,
                            color: ColorsRes.mainIconColor,
                            size: 14,
                          ),
                          getSizedBox(width: Constant.size3),
                          CustomTextLabel(
                            text: getTranslatedValue(context, directionLabel),
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorsRes.mainIconColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                getDivider(color: ColorsRes.subTitleMainTextColor.withValues(alpha: 0.15)),
                getSizedBox(height: Constant.size5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: ColorsRes.appColor,
                      size: 20,
                    ),
                    getSizedBox(width: Constant.size8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextLabel(
                            text: "${order.pickupAddress?.pickupStoreAddress ?? ""}",
                            style: TextStyle(
                              fontSize: 14,
                              color: ColorsRes.subTitleMainTextColor,
                            ),
                            maxLines: 3,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                getSizedBox(height: Constant.size12),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      color: ColorsRes.appColor,
                      size: 18,
                    ),
                    getSizedBox(width: Constant.size8),
                    CustomTextLabel(
                      text: order.pickupAddress?.sellerMobile ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorsRes.subTitleMainTextColor,
                      ),
                    ),
                  ],
                ),
                getSizedBox(height: Constant.size12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      color: ColorsRes.appColor,
                      size: 18,
                    ),
                    getSizedBox(width: Constant.size8),
                    CustomTextLabel(
                      text:
                          "${getTranslatedValue(context, openHoursLabel)}: ${order.pickupAddress?.openingTime ?? "--"} - ${order.pickupAddress?.closingTime ?? "--"}",
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorsRes.subTitleMainTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextLabel(
                jsonKey: from == "previousOrders" ? deliveredAtLabel : deliveryToLabel,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: ColorsRes.mainTextColor,
                ),
              ),
              getSizedBox(
                height: 10,
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsetsDirectional.all(10),
                width: context.width,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Theme.of(context).cardColor),
                child: CustomTextLabel(
                  text: order.orderAddress,
                  style: TextStyle(
                    color: ColorsRes.subTitleMainTextColor,
                    fontSize: 13.0,
                  ),
                ),
              ),
            ],
          );
  }
}
