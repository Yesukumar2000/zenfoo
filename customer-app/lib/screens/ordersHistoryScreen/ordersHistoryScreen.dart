import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/screens/ordersHistoryScreen/activeOrdersListScreen.dart';
import 'package:project/screens/ordersHistoryScreen/previousOrdersListScreen.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/styles/appColorScheme.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  int currentIndex = 0;
  int currentFilterIndex = 0; // 0: All, 1: Home Delivery, 2: Store Pickup
  late ActiveOrdersProvider activeOrdersProvider;
  late PreviousOrdersProvider previousOrdersProvider;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    activeOrdersProvider = ActiveOrdersProvider();
    previousOrdersProvider = PreviousOrdersProvider();

    pages = [
      ChangeNotifierProvider<ActiveOrdersProvider>.value(
        value: activeOrdersProvider,
        child: const ActiveOrderListScreen(),
      ),
      ChangeNotifierProvider<PreviousOrdersProvider>.value(
        value: previousOrdersProvider,
        child: const PreviousOrderListScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;
        return Scaffold(
          backgroundColor: colorScheme.background,
          appBar: PreferredSize(
            preferredSize: Size(double.infinity, double.maxFinite),
            child: AppHeader(
              label: getTranslatedValue(context, ordersHistoryLabel),
              title: currentIndex == 0
                  ? getTranslatedValue(context, activeOrdersLabel)
                  : getTranslatedValue(context, previousOrdersLabel),
              showBackButton: true,
            ),
          ),
          body: CustomScrollView(
            slivers: [
              // ====== Content: Active / Previous via IndexedStack ======
              SliverFillRemaining(
                child: IndexedStack(
                  index: currentIndex,
                  children: pages,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Segmented control chip
  Widget _buildSegmentChip({
    required BuildContext context,
    required AppColorScheme colorScheme,
    required int index,
    required String label,
  }) {
    final bool selected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (currentIndex == index) return;
          setState(() {
            currentIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: selected
                  ? colorScheme.buttonPrimaryText
                  : colorScheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ------- filter bottom sheet & helpers (unchanged logic) -------

  void _openFilterSheet(BuildContext context) {
    final filterOptions = [
      allOrdersLabel,
      homeDeliveryLabel,
      storePickupLabel,
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: DesignConfig.setRoundedBorderSpecific(20, istop: true),
      builder: (BuildContext context1) {
        return Wrap(
          children: [
            Container(
              decoration: DesignConfig.boxDecorationSpecific(
                Theme.of(context).cardColor,
                10,
                true,
                false,
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: CustomTextLabel(
                      jsonKey: filterLabel,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorsRes.mainTextColor,
                          ),
                    ),
                  ),
                  ...List.generate(filterOptions.length, (index) {
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        setState(() {
                          currentFilterIndex = index;
                        });
                        _applyFilter();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Icon(
                              currentFilterIndex == index
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: ColorsRes.appColor,
                            ),
                            getSizedBox(width: 10),
                            Expanded(
                              child: CustomTextLabel(
                                jsonKey: filterOptions[index],
                                softWrap: true,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      fontSize: 16,
                                      color: ColorsRes.mainTextColor,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _applyFilter() {
    activeOrdersProvider.orders.clear();
    activeOrdersProvider.offset = 0;
    previousOrdersProvider.orders.clear();
    previousOrdersProvider.offset = 0;

    final filterParams = _getFilterParams();

    activeOrdersProvider.getOrders(
      params: {
        ApiAndParams.type: ApiAndParams.active,
        ...filterParams,
      },
      context: context,
    );

    previousOrdersProvider.getOrders(
      params: {
        ApiAndParams.type: ApiAndParams.previous,
        ...filterParams,
      },
      context: context,
    );
  }

  Map<String, String> _getFilterParams() {
    switch (currentFilterIndex) {
      case 1:
        return {ApiAndParams.orderDeliveryType: "doorstep"};
      case 2:
        return {ApiAndParams.orderDeliveryType: "selfpickup"};
      default:
        return {};
    }
  }
}
