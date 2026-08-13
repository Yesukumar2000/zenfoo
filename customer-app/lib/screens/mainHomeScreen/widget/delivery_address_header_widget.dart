import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_groups.dart';

class DeliveryAddressHeaderWidget extends StatefulWidget {
  const DeliveryAddressHeaderWidget({super.key});

  @override
  State<DeliveryAddressHeaderWidget> createState() =>
      _DeliveryAddressHeaderWidgetState();
}

class _DeliveryAddressHeaderWidgetState
    extends State<DeliveryAddressHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeScreenProvider>();
    final brandTitle = "Zenfoo";
    final price = "₹0";

    final addressLine = Constant.session.getData(SessionManager.keyAddress);

    final selectedIdx = provider.selectedStoreIdx;

    CategoryGroup? group;
    if (selectedIdx > 0 &&
        provider.storeGroups.isNotEmpty &&
        selectedIdx < provider.storeGroups.length) {
      group = provider.storeGroups[selectedIdx];
    }

    late final Color mainColor;
    if (selectedIdx == 0) {
      mainColor = const Color(0xFF9AC444);
    } else {
      mainColor = group != null
          ? Constant.colorFromHex(group.color ?? "#FFA13B")
          : const Color(0xFFFFA13B);
    }

    final bgDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [mainColor, mainColor.withOpacity(0.2)],
        stops: const [0, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        decoration: bgDecoration,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Title
            Text(
              brandTitle,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                height: 1.02,
              ),
            ),

            // Dynamic: show shimmer, error, or actual content
            Builder(
              builder: (context) {
                if (provider.etaState == HomeScreenState.loading)
                  return getEtaShimmer();
                if (provider.etaState == HomeScreenState.error)
                  return Text(
                    "Failed to load ETA",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Delivery info
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final result =
                              await showAddressesBottomSheet(context);
                          if (result != null &&
                              result is UserAddressData &&
                              mounted) {
                            // Update session with new address coordinates
                            Constant.session.setData(SessionManager.keyLatitude,
                                result.latitude ?? "", false);
                            Constant.session.setData(
                                SessionManager.keyLongitude,
                                result.longitude ?? "",
                                false);
                            Constant.session.setData(SessionManager.keyAddress,
                                _buildAddressString(result), true);

                            // Reload store and category data with new location
                            final homeProvider =
                                context.read<HomeScreenProvider>();
                            await homeProvider.loadEta(context);
                            await homeProvider.loadStoreGroups(context);
                            await homeProvider.fetchProductsForStoreGroup(
                              context,
                              homeProvider.selectedStoreIdx == 0
                                  ? null
                                  : homeProvider
                                      .storeGroups[
                                          homeProvider.selectedStoreIdx]
                                      .id,
                            );
                            await homeProvider.fetchHomeCombos(
                              context,
                              storeId: homeProvider.selectedStoreIdx == 0
                                  ? null
                                  : homeProvider.selectedStoreIdx,
                            );
                          }
                          setState(() {});
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.estimatedTime ?? "In 30 Minutes",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                height: 1.02,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    addressLine.isNotEmpty
                                        ? addressLine
                                        : "Tap to add your address",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    RepaintBoundary(
                      child: CartProfileWidget(
                          price: price, iconColor: Colors.black),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget getEtaShimmer() {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Row(
          children: [
            Container(width: 50, height: 50, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 16, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  String _buildAddressString(UserAddressData address) {
    final parts = <String>[];

    if (address.address != null &&
        address.address!.isNotEmpty &&
        address.address != 'null') {
      parts.add(address.address!);
    }
    if (address.landmark != null &&
        address.landmark!.isNotEmpty &&
        address.landmark != 'null') {
      parts.add(address.landmark!);
    }

    return parts.join(', ');
  }
}
