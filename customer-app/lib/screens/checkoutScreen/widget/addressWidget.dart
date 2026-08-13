import 'package:project/helper/utils/generalImports.dart';


class AddressWidget extends StatelessWidget {
  const AddressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignConfig.boxDecoration(Theme.of(context).cardColor, 10),
      padding: const EdgeInsets.all(10),
      margin: EdgeInsetsDirectional.all(
        10,
      ),
      child: Padding(
        padding: EdgeInsets.all(Constant.size10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextLabel(
              jsonKey: addressDetailLabel,
              softWrap: true,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ColorsRes.mainTextColor,
              ),
            ),
            getSizedBox(
              height: Constant.size10,
            ),
            (context.read<CheckoutProvider>().checkoutAddressState ==
                        CheckoutAddressState.addressLoaded &&
                    context.read<CheckoutProvider>().selectedAddress?.id !=
                        null)
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context
                                    .read<CheckoutProvider>()
                                    .selectedAddress
                                    ?.name ??
                                "",
                            softWrap: true,
                            style: TextStyle(
                                color: ColorsRes.mainTextColor,
                                fontWeight: FontWeight.w500),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, addressListScreen,
                                      arguments: "checkout")
                                  .then((value) {
                                if (value is UserAddressData) {
                                  UserAddressData selectedAddress = value;
                                  context
                                      .read<CheckoutProvider>()
                                      .setSelectedAddress(
                                          context, selectedAddress);
                                }
                              });
                            },
                            child: Container(
                              height: 25,
                              width: 25,
                              decoration: DesignConfig.boxGradient(5),
                              padding: const EdgeInsets.all(5),
                              margin: EdgeInsets.zero,
                              child: defaultImg(
                                  image: AppAssets.editIcon,
                                  iconColor: ColorsRes.mainIconColor,
                                  height: 20,
                                  width: 20),
                            ),
                          )
                        ],
                      ),
                      Text(
                        _buildAddressString(context.read<CheckoutProvider>().selectedAddress!),
                        softWrap: true,
                        style:
                            TextStyle(color: ColorsRes.subTitleMainTextColor),
                      ),
                      getSizedBox(
                        height: Constant.size5,
                      ),
                      Text(
                        context
                                .read<CheckoutProvider>()
                                .selectedAddress
                                ?.mobile ??
                            "",
                        softWrap: true,
                        style:
                            TextStyle(color: ColorsRes.subTitleMainTextColor),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, addressListScreen,
                              arguments: "checkout")
                          .then((value) {
                        context.read<CheckoutProvider>().setSelectedAddress(
                            context, value as UserAddressData);
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: Constant.size10),
                      child: CustomTextLabel(
                          jsonKey: addNewAddressLabel,
                          softWrap: true,
                          style: TextStyle(
                            color: ColorsRes.appColorRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          )),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  String _buildAddressString(UserAddressData address) {
    final parts = <String>[];

    if (address.area != null && address.area!.isNotEmpty && address.area != 'null') parts.add(address.area!);
    if (address.landmark != null && address.landmark!.isNotEmpty && address.landmark != 'null') parts.add(address.landmark!);
    if (address.address != null && address.address!.isNotEmpty && address.address != 'null') parts.add(address.address!);
    if (address.city != null && address.city!.isNotEmpty && address.city != 'null') parts.add(address.city!);
    if (address.state != null && address.state!.isNotEmpty && address.state != 'null') parts.add(address.state!);
    if (address.country != null && address.country!.isNotEmpty && address.country != 'null') parts.add(address.country!);
    if (address.pincode != null && address.pincode!.isNotEmpty && address.pincode != 'null') parts.add(address.pincode!);

    return parts.join(', ');
  }
}
