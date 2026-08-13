import 'package:flutter/material.dart';
import 'package:project/utils/order_number.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/keyboardOverlay.dart';
import 'package:project/models/sellerDashBoard.dart';
import 'package:project/provider/sellerStatusProvider.dart';

class HomeScreen extends StatefulWidget {
  final dynamic Function(int index) changeTab;

  const HomeScreen({Key? key, required this.changeTab}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();

  List lblOrderStatusDisplayNames = [];
  List lblOrderStatusUpdateNames = [];
  List lblSellerStatusDisplayNames = [];

  String startDate = "";
  String endDate = "";

  scrollListener() {
    // nextPageTrigger will have a value equivalent to 70% of the list size.
    var nextPageTrigger = scrollController.position.maxScrollExtent;

    // _scrollController fetches the next paginated data when the current position of the user on the screen has surpassed
    if (scrollController.position.pixels > nextPageTrigger) {
      if (mounted) {
        if (context.read<DeliveryBoyOrdersProvider>().hasMoreData &&
            context.read<DeliveryBoyOrdersProvider>().ordersState != DeliveryBoyOrdersState.loadingMore) {
          callApi(reset: false);
        }
      }
    }
  }

  Future callApi({bool? reset, bool? silentLoading}) async {
    if (reset == true) {
      resetDate();
      context.read<DeliveryBoyOrdersProvider>().offset = 0;
      context.read<DeliveryBoyOrdersProvider>().deliveryBoyOrdersList.clear();
    }

    Map<String, String> params = {};
    params[ApiAndParams.status] = context.read<DeliveryBoyOrdersProvider>().selectedStatus.toString();
    params[ApiAndParams.search] = searchController.text;
    if (isDateRangeValidate()) {
      params[ApiAndParams.startDeliveryDate] = startDate;
      params[ApiAndParams.endDeliveryDate] = endDate;
    }

    params[ApiAndParams.status] = context.read<DeliveryBoyOrdersProvider>().selectedStatus.toString();

    await context.read<DeliveryBoyOrdersProvider>().getDeliveryBoyOrders(params: params, context: context, silentLoading: silentLoading ?? false);
  }

  bool isDateRangeValidate() {
    return (startDate != getTranslatedValue(context, startDateLabel) && endDate != getTranslatedValue(context, endDateLabel));
  }

  resetDate() {
    startDate = getTranslatedValue(context, startDateLabel);
    endDate = getTranslatedValue(context, endDateLabel);
  }

  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      bool hasFocus = focusNode.hasFocus;
      if (hasFocus) {
        KeyboardOverlay.showOverlay(context);
      } else {
        KeyboardOverlay.removeOverlay();
      }
    });
    Future.delayed(Duration.zero, () async {
      scrollController.addListener(scrollListener);

      context.read<SettingsProvider>().getSettingsApiProvider({}, context).then(
        (value) {
          lblOrderStatusDisplayNames = [
            orderStatusDisplayNamesAllLabel,
            orderStatusDisplayNamesAwaitingLabel,
            orderStatusDisplayNamesReceivedLabel,
            orderStatusDisplayNamesProcessedLabel,
            orderStatusDisplayNamesShippedLabel,
            orderStatusDisplayNamesOutForDeliveryLabel,
            orderStatusDisplayNamesDeliveredLabel,
            orderStatusDisplayNamesCancelledLabel,
            orderStatusDisplayNamesReturnedLabel,
          ];

          /* lblOrderStatusUpdateNames = [
            getTranslatedValue(context, orderStatusDisplayNamesAwaitingLabel),
            getTranslatedValue(context, orderStatusDisplayNamesReceivedLabel),
            getTranslatedValue(context, orderStatusDisplayNamesProcessedLabel),
            getTranslatedValue(context, orderStatusDisplayNamesShippedLabel),
            getTranslatedValue(context, orderStatusDisplayNamesOutForDeliveryLabel),
            getTranslatedValue(context, orderStatusDisplayNamesDeliveredLabel),
          ]; */

          lblSellerStatusDisplayNames = [
            sellerStatusActiveLabel,
            sellerStatusInactiveLabel,
          ];

          if (Constant.appMaintenanceMode != "1") {
            context.read<DashboardProvider>().dashboardApiProvider({}, context).then((value) {
              if (!Constant.session.isSeller()) {
                // callApi(reset: true);
                Future.delayed(Duration.zero).then((value) async {
                  searchController.addListener(() {
                    if (mounted) {
                      setState(() {});
                      callApi(reset: true);
                    }
                  });
                  scrollController.addListener(scrollListener);
                  callApi(reset: true);
                });
              } else {
                context.read<SellerStatusProvider>().getSellerStatusProvider(context: context);
              }
            });
          } else {
            Navigator.pushReplacementNamed(context, underMaintenanceScreen);
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: getAppBar(
            context: context,
            centerTitle: false,
            title: CustomTextLabel(
              text: getTranslatedValue(context, homeLabel),
              style: TextStyle(color: ColorsRes.mainTextColor),
            ),
            actions: [
              if (Constant.session.isSeller())
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 15),
                  child: Consumer<SellerStatusProvider>(
                    builder: (context, sellerStatusProvider, child) {
                      if (sellerStatusProvider.sellerState == SellerState.loading) {
                        return CustomShimmer(
                          width: context.width * 0.37,
                          height: 30,
                          borderRadius: 60,
                        );
                      } else {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: ColorsRes.appColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              lblSellerStatusDisplayNames.length,
                              (index) {
                                return GestureDetector(
                                  onTap: () {
                                    if (index == context.read<SellerStatusProvider>().selectedIndex) {
                                      showMessage(
                                        context,
                                        getTranslatedValue(
                                          context,
                                          // "seller_already_${index == 0 ? "active" : "inactive"}_message",
                                          index == 0 ? sellerAlreadyActiveMessageLabel : sellerAlreadyInactiveMessageLabel,
                                        ),
                                        MessageType.warning,
                                      );
                                    } else {
                                      showDialog<String>(
                                        context: context,
                                        builder: (BuildContext buildContext) => AlertDialog(
                                          backgroundColor: Theme.of(buildContext).cardColor,
                                          surfaceTintColor: ColorsRes.appColorTransparent,
                                          title: CustomTextLabel(
                                            jsonKey: areYouSureLabel,
                                            softWrap: true,
                                          ),
                                          content: CustomTextLabel(
                                            jsonKey: index == 0 ? activateAccountConfirmationLabel : deactivateAccountConfirmationLabel,
                                            softWrap: true,
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () => Navigator.pop(buildContext),
                                              child: CustomTextLabel(
                                                jsonKey: cancelLabel,
                                                softWrap: true,
                                                style: TextStyle(color: ColorsRes.subTitleTextColor),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(buildContext);
                                                context.read<SellerStatusProvider>().updateSellerStatusProvider(
                                                  context: context,
                                                  params: {ApiAndParams.status: index == 0 ? "1" : "3"},
                                                );
                                              },
                                              child: CustomTextLabel(
                                                jsonKey: okLabel,
                                                softWrap: true,
                                                style: TextStyle(color: ColorsRes.appColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 30,
                                    padding: EdgeInsetsDirectional.only(start: index == 0 ? 10 : 7, end: index == 0 ? 7 : 10, top: 5, bottom: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: context.read<SellerStatusProvider>().selectedIndex == index
                                          ? ColorsRes.appColor
                                          : ColorsRes.appColorTransparent,
                                    ),
                                    child: CustomTextLabel(
                                      text: getTranslatedValue(context, lblSellerStatusDisplayNames[index]),
                                      style: TextStyle(
                                        color: context.read<SellerStatusProvider>().selectedIndex == index
                                            ? ColorsRes.appColorWhite
                                            : ColorsRes.appColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
          body: Consumer<DashboardProvider>(
            builder: (context, dashboardProvider, _) {
              if (Constant.session.isSeller()) {
                List<CategoryProductCount> categoryProductCounts = [];
                try {
                  categoryProductCounts = dashboardProvider.sellerDashBoard.data?.categoryProductCount ?? [];
                } catch (_) {}
                return dashboardProvider.dashboardState == DashboardState.loaded
                    ? setRefreshIndicator(
                        context:  context,
                        refreshCallback: () async {
                          context.read<SellerStatusProvider>().getSellerStatusProvider(context: context);

                          context.read<DashboardProvider>().dashboardApiProvider({}, context).then((value) {
                            if (!Constant.session.isSeller()) {
                              callApi(reset: true);
                            } else {
                              context.read<SellerStatusProvider>().getSellerStatusProvider(context: context);
                            }
                          });
                        },
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: [
                            GridView.count(
                              childAspectRatio: 1.0,
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              crossAxisCount: 2,
                              physics: NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.symmetric(vertical: 8),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              children: [
                                getStatisticsContainer(
                                  context: context,
                                  bgColor: ColorsRes.sellerStatisticsColors[0],
                                  svgIconName: "orders",
                                  title: getTranslatedValue(context, ordersLabel),
                                  itemCount: dashboardProvider.sellerDashBoard.data?.sellerOrderCount.toString() ?? "0",
                                  voidCallback: () {
                                    widget.changeTab(2);
                                  },
                                ),
                                getStatisticsContainer(
                                  context: context,
                                  bgColor: ColorsRes.sellerStatisticsColors[1],
                                  svgIconName: "products",
                                  title: getTranslatedValue(context, productsLabel),
                                  itemCount: dashboardProvider.sellerDashBoard.data?.productCount.toString() ?? "0",
                                  voidCallback: () {
                                    widget.changeTab(2);
                                  },
                                ),
                                getStatisticsContainer(
                                  svgIconName: "sold_out_products",
                                  bgColor: ColorsRes.sellerStatisticsColors[2],
                                  context: context,
                                  title: getTranslatedValue(context, soldOutProductsLabel),
                                  itemCount: dashboardProvider.sellerDashBoard.data?.soldOutCount.toString() ?? "0",
                                  voidCallback: () {
                                    Navigator.pushNamed(
                                      context,
                                      productListScreen,
                                      arguments: 2,
                                    );
                                  },
                                ),
                                getStatisticsContainer(
                                  svgIconName: "low_stock_products",
                                  bgColor: ColorsRes.sellerStatisticsColors[3],
                                  context: context,
                                  title: getTranslatedValue(context, lowStockProductsLabel),
                                  itemCount: dashboardProvider.sellerDashBoard.data?.lowStockCount.toString() ?? "0",
                                  voidCallback: () {
                                    Navigator.pushNamed(
                                      context,
                                      productListScreen,
                                      arguments: 1,
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Container(
                              height: MediaQuery.sizeOf(context).height * 0.5,
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 20,
                                    offset: Offset(0, 4),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: WeeklySalesBarChart(
                                  weeklySales: dashboardProvider.sellerDashBoard.data?.weeklySales ?? [],
                                  maxSaleLimit: dashboardProvider.maxSaleLimit),
                            ),
                            if (categoryProductCounts.length > 0) ...[
                              SizedBox(height: 16),
                              Container(
                                height: MediaQuery.sizeOf(context).height * 0.30,
                                width: MediaQuery.sizeOf(context).width,
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 20,
                                      offset: Offset(0, 4),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: CategoryPieChart(
                                  categoryProductCounts: categoryProductCounts,
                                ),
                              ),
                            ],
                            SizedBox(height: 16),
                          ],
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          GridView.count(
                            childAspectRatio: 1.0,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            crossAxisCount: 2,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(vertical: 8),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              CustomShimmer(width: double.maxFinite, borderRadius: 20, height: 150),
                              CustomShimmer(width: double.maxFinite, borderRadius: 20, height: 150),
                              CustomShimmer(width: double.maxFinite, borderRadius: 20, height: 150),
                              CustomShimmer(width: double.maxFinite, borderRadius: 20, height: 150),
                            ],
                          ),
                          SizedBox(height: 16),
                          CustomShimmer(
                            width: double.maxFinite,
                            borderRadius: 20,
                            height: 300,
                          ),
                          SizedBox(height: 16),
                          CustomShimmer(
                            width: double.maxFinite,
                            borderRadius: 20,
                            height: 150,
                          ),
                        ],
                      );
              } else if (dashboardProvider.dashboardState == DashboardState.loaded) {
                return setRefreshIndicator(
                  context: context,
                  refreshCallback: () async {
                    context.read<DashboardProvider>().dashboardApiProvider({}, context).then((value) {
                      if (!Constant.session.isSeller()) {
                        callApi(reset: true);
                      } else {
                        context.read<SellerStatusProvider>().getSellerStatusProvider(context: context);
                      }
                    });
                  },
                  child: SingleChildScrollView(
                    physics: ClampingScrollPhysics(),
                    controller: scrollController,
                    child: Column(
                      children: [
                        GridView.count(
                          childAspectRatio: 1.0,
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          crossAxisCount: 2,
                          physics: ClampingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            getStatisticsContainer(
                              context: context,
                              bgColor: ColorsRes.sellerStatisticsColors[0],
                              svgIconName: "orders",
                              title: getTranslatedValue(context, ordersLabel),
                              itemCount: dashboardProvider.deliveryBashBoard.data?.orderCount.toString() ?? "0",
                              voidCallback: () {
                                scrollController.animateTo(scrollController.offset + (MediaQuery.of(context).size.width * .5),
                                    duration: Duration(milliseconds: 600), curve: Curves.easeIn);
                              },
                            ),
                            getStatisticsContainer(
                              context: context,
                              svgIconName: "balance",
                              bgColor: ColorsRes.sellerStatisticsColors[1],
                              title: getTranslatedValue(context, balanceLabel),
                              itemCount: dashboardProvider.deliveryBashBoard.data?.balance.toString() ?? "0",
                              voidCallback: () {
                                Navigator.pushNamed(context, withdrawalRequestsListScreen);
                              },
                            ),
                          ],
                        ),
                        Consumer<LanguageProvider>(
                          builder: (contexts, languageProvider, child) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(lblOrderStatusDisplayNames.length, (statusIndex) {
                                  return GestureDetector(onTap: () async {
                                    if (mounted) {
                                      await context
                                          .read<DeliveryBoyOrdersProvider>()
                                          .changeDeliveryBoyOrderSelectedStatus(statusIndex)
                                          .then((value) async {
                                        if (value) {
                                          callApi();
                                        }
                                      });
                                    }
                                  }, child: getOrderStatusContainer(
                                      isActive: context.watch<DeliveryBoyOrdersProvider>().selectedStatus == statusIndex,
                                      svgIconName: Constant.orderStatusIcons[statusIndex],
                                      context: context,
                                      title: getTranslatedValue(contexts, lblOrderStatusDisplayNames[statusIndex].toString())));
                                }),
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              border: Border.all(color: ColorsRes.subTitleTextColor.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  offset: Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: CustomTextLabel(
                                    text: "$startDate\t\t${getTranslatedValue(context, toLabel)}\t\t$endDate",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                getSizedBox(width: 10),
                                if (!isDateRangeValidate())
                                  GestureDetector(
                                    onTap: () {
                                      showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(DateTime.now().year - 100, 1, 1),
                                        lastDate: DateTime.now(),
                                        currentDate: DateTime.now(),
                                        keyboardType: TextInputType.datetime,
                                        builder: (context, child) {
                                          return Theme(
                                            data: Constant.session.getBoolData(SessionManager.isDarkTheme)
                                                ? ThemeData.dark().copyWith(
                                                    colorScheme: ColorScheme.dark(
                                                      primary: ColorsRes.appColor,
                                                      onPrimary: ColorsRes.mainTextColor,
                                                      surface: Theme.of(context).cardColor,
                                                      inverseSurface: ColorsRes.subTitleTextColor,
                                                      onSurface: ColorsRes.mainTextColor,
                                                      secondary: ColorsRes.appColor,
                                                    ),
                                                    visualDensity: VisualDensity.compact,
                                                    dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).cardColor),
                                                  )
                                                : ThemeData.light().copyWith(
                                                    colorScheme: ColorScheme.dark(
                                                      primary: ColorsRes.appColor,
                                                      onPrimary: ColorsRes.mainTextColor,
                                                      surface: Theme.of(context).cardColor,
                                                      onSurface: ColorsRes.mainTextColor,
                                                      inverseSurface: ColorsRes.subTitleTextColor,
                                                      secondary: ColorsRes.appColor,
                                                    ),
                                                    visualDensity: VisualDensity.compact,
                                                    dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).cardColor),
                                                  ),
                                            child: child!,
                                          );
                                        },
                                      ).then(
                                        (value) {
                                          if (value != null) {
                                            startDate = value.start.toString().split(" ")[0];
                                            endDate = value.end.toString().split(" ")[0];

                                            context.read<DeliveryBoyOrdersProvider>().offset = 0;
                                            context.read<DeliveryBoyOrdersProvider>().deliveryBoyOrdersList.clear();

                                            setState(() {});
                                            callApi();
                                          }
                                        },
                                      );
                                    },
                                    child: Icon(
                                      Icons.calendar_month_rounded,
                                      color: ColorsRes.mainTextColor,
                                    ),
                                  ),
                                if (isDateRangeValidate())
                                  GestureDetector(
                                    onTap: () {
                                      callApi(reset: true);
                                      setState(() {});
                                    },
                                    child: CustomTextLabel(
                                      jsonKey: clearLabel,
                                      style: TextStyle(
                                        color: ColorsRes.appColorRed,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  offset: Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: editBoxWidget(
                              maxlines: 1,
                              context: context,
                              edtController: searchController,
                              validationFunction: (value) => optionalFieldValidation("", ""),
                              label: getTranslatedValue(context, searchLabel),
                              hint: getTranslatedValue(context, searchLabel),
                              bgcolor: Theme.of(context).cardColor,
                              inputType: TextInputType.text,
                              tailIcon: searchController.text.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        searchController.clear();
                                      },
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: ColorsRes.mainTextColor,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        getSizedBox(height: 10),
                        Consumer<DeliveryBoyOrdersProvider>(
                          builder: (context, DeliveryBoyOrdersProvider, child) {
                            if (DeliveryBoyOrdersProvider.ordersState == DeliveryBoyOrdersState.loaded ||
                                DeliveryBoyOrdersProvider.ordersState == DeliveryBoyOrdersState.loadingMore ||
                                DeliveryBoyOrdersProvider.ordersState == DeliveryBoyOrdersState.silentLoading) {
                              return ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: DeliveryBoyOrdersProvider.deliveryBoyOrdersList.length,
                                  itemBuilder: (context, index) {
                                    if (index == DeliveryBoyOrdersProvider.deliveryBoyOrdersList.length - 1) {
                                      if (DeliveryBoyOrdersProvider.ordersState == DeliveryBoyOrdersState.loadingMore) {
                                        return _buildOrderContainerShimmer();
                                      }
                                    }
                                    return _buildOrderContainer(DeliveryBoyOrdersProvider.deliveryBoyOrdersList[index], index.toString());
                                  });
                            } else if (DeliveryBoyOrdersProvider.ordersState == DeliveryBoyOrdersState.loaded ||
                                DeliveryBoyOrdersProvider.ordersState == DeliveryBoyOrdersState.loading) {
                              return Column(
                                children: List.generate(
                                  20,
                                  (index) => _buildOrderContainerShimmer(),
                                ),
                              );
                            } else if (DeliveryBoyOrdersProvider.ordersState == DeliveryBoyOrdersState.empty) {
                              return Container(
                                width: context.width,
                                child: DefaultBlankItemMessageScreen(
                                  image: "no_order_icon",
                                  title: emptyOrdersMessageLabel,
                                  description: emptyOrdersDescriptionLabel,
                                  buttonTitle: refreshLabel,
                                  callback: () async {
                                    return callApi();
                                  },
                                ),
                              );
                            } else {
                              return Container(
                                width: context.width,
                                child: DefaultBlankItemMessageScreen(
                                  image: "something_went_wrong",
                                  title: somethingWentWrongMessageTitleLabel,
                                  description: somethingWentWrongMessageDescriptionLabel,
                                  buttonTitle: tryAgainLabel,
                                  callback: () async {
                                    return callApi(reset: true);
                                  },
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    GridView.count(
                      childAspectRatio: 1.0,
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      crossAxisCount: 2,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        CustomShimmer(width: double.maxFinite, borderRadius: 20, height: 150),
                        CustomShimmer(width: double.maxFinite, borderRadius: 20, height: 150),
                        CustomShimmer(width: double.maxFinite, borderRadius: 20, height: 150),
                        CustomShimmer(width: double.maxFinite, borderRadius: 20, height: 150),
                      ],
                    ),
                    SizedBox(height: 16),
                    CustomShimmer(
                      width: double.maxFinite,
                      borderRadius: 20,
                      height: 300,
                    ),
                    SizedBox(height: 16),
                    CustomShimmer(
                      width: double.maxFinite,
                      borderRadius: 20,
                      height: 150,
                    ),
                  ],
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderContainer(DeliveryBoyOrdersListItem order, String index) {
    lblOrderStatusDisplayNames = [
      getTranslatedValue(context, orderStatusDisplayNamesAllLabel),
      getTranslatedValue(context, orderStatusDisplayNamesAwaitingLabel),
      getTranslatedValue(context, orderStatusDisplayNamesReceivedLabel),
      getTranslatedValue(context, orderStatusDisplayNamesProcessedLabel),
      getTranslatedValue(context, orderStatusDisplayNamesShippedLabel),
      getTranslatedValue(context, orderStatusDisplayNamesOutForDeliveryLabel),
      getTranslatedValue(context, orderStatusDisplayNamesDeliveredLabel),
      getTranslatedValue(context, orderStatusDisplayNamesCancelledLabel),
      getTranslatedValue(context, orderStatusDisplayNamesReturnedLabel),
    ];
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          orderDetail,
          arguments: [order.orderId.toString(), "", false, ""],
        ).then(
          (value) => callApi(reset: true, silentLoading: true),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorsRes.mainTextColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                getSizedBox(width: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ColorsRes.appColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomTextLabel(
                    text: getCurrencyFormat(
                      double.parse(
                        order.finalTotal.toString(),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ColorsRes.appColor,
                      letterSpacing: -0.3,
                    ),
                    softWrap: true,
                  ),
                ),
                if (order.orderNote.toString().isNotEmpty) getSizedBox(width: 10),
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
                  ),
              ],
            ),
            getSizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextLabel(
                              jsonKey: paymentMethodLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorsRes.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                            ),
                            getSizedBox(height: 4),
                            CustomTextLabel(
                              text: "${order.paymentMethod}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ColorsRes.mainTextColor,
                                letterSpacing: -0.2,
                              ),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  getSizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextLabel(
                              jsonKey: deliveryTimeLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorsRes.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                            ),
                            getSizedBox(height: 4),
                            CustomTextLabel(
                              text: "${order.deliveryTime ?? ""}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ColorsRes.mainTextColor,
                                letterSpacing: -0.2,
                              ),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            getSizedBox(height: 16),
            order.activeStatus == "8" ? const SizedBox.shrink() : Divider(height: 1, color: ColorsRes.grey.withValues(alpha: 0.2), thickness: 1),
            order.activeStatus == "8"
                ? const SizedBox.shrink()
                : getSizedBox(
                    height: 10,
                  ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: order.activeStatus == "8"
                      ? const SizedBox.shrink()
                      : GestureDetector(
                          onTap: () {
                            showModalBottomSheet<void>(
                              backgroundColor: Theme.of(context).cardColor,
                              context: context,
                              isScrollControlled: true,
                              shape: DesignConfig.setRoundedBorderSpecific(20, istop: true),
                              builder: (BuildContext context) {
                                return ChangeNotifierProvider(
                                    create: (context) => OrderUpdateStatusProvider(),
                                    builder: (context, value) {
                                      return Consumer<OrderUpdateStatusProvider>(
                                        builder: (context, DeliveryBoyOrdersProvider, child) {
                                          if (context.read<OrderUpdateStatusProvider>().ordersStatusState == OrderUpdateStatusState.initial) {
                                            context.read<OrderUpdateStatusProvider>().setSelectedStatus(
                                                  (int.parse(order.activeStatus.toString()) - 1).toString(),
                                                );
                                            context.read<OrderUpdateStatusProvider>().getOrdersStatuses(context: context, from: "");
                                          }

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
                                                if (DeliveryBoyOrdersProvider.ordersStatusState == OrderUpdateStatusState.loaded ||
                                                    DeliveryBoyOrdersProvider.ordersStatusState == OrderUpdateStatusState.updating)
                                                  Column(
                                                    children: List.generate(DeliveryBoyOrdersProvider.orderStatusesList.length - 2, (index) {
                                                      return GestureDetector(
                                                        onTap: () {
                                                          DeliveryBoyOrdersProvider.setSelectedStatus(index.toString());
                                                        },
                                                        child: Container(
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                child: Padding(
                                                                  padding: EdgeInsetsDirectional.only(start: Constant.paddingOrMargin10),
                                                                  child: CustomTextLabel(
                                                                    jsonKey: Constant.getOrderStatusDisplayName(
                                                                        context, DeliveryBoyOrdersProvider.orderStatusesList[index].id ?? "0"),
                                                                  ),
                                                                ),
                                                              ),
                                                              Radio(
                                                                activeColor: ColorsRes.appColor,
                                                                value: DeliveryBoyOrdersProvider.selectedOrderStatus,
                                                                groupValue: context.watch<OrderUpdateStatusProvider>().orderStatusesList[index].id,
                                                                onChanged: (value) {
                                                                  DeliveryBoyOrdersProvider.setSelectedStatus(index.toString());
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
                                                if (DeliveryBoyOrdersProvider.ordersStatusState == OrderUpdateStatusState.loading)
                                                  Column(
                                                    children: List.generate(8, (index) {
                                                      return CustomShimmer(
                                                        height: 26,
                                                        width: double.maxFinite,
                                                        margin: EdgeInsetsDirectional.all(10),
                                                      );
                                                    }),
                                                  ),
                                                if (DeliveryBoyOrdersProvider.ordersStatusState == OrderUpdateStatusState.loaded ||
                                                    DeliveryBoyOrdersProvider.ordersStatusState == OrderUpdateStatusState.updating)
                                                  Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: Constant.paddingOrMargin10),
                                                    child: gradientBtnWidget(
                                                      context,
                                                      10,
                                                      callback: () {
                                                        Map<String, String> params = {};
                                                        if (DeliveryBoyOrdersProvider.selectedOrderStatus.toString() == "6" && order.otp != "0") {
                                                          TextEditingController editTextController = TextEditingController();

                                                          showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return StatefulBuilder(
                                                                builder: (BuildContext context, StateSetter setState) {
                                                                  return AlertDialog(
                                                                    backgroundColor: Theme.of(context).cardColor,
                                                                    content: Column(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        const CustomTextLabel(
                                                                          jsonKey: 'customer_will_share_the_otp_for_delivered_the_order',
                                                                          softWrap: true,
                                                                        ),
                                                                        const SizedBox(height: 10),
                                                                        TextField(
                                                                          controller: editTextController,
                                                                          focusNode: Platform.isIOS ? focusNode : FocusNode(),
                                                                          keyboardType: TextInputType.number,
                                                                          style: TextStyle(color: ColorsRes.mainTextColor),
                                                                          inputFormatters: [
                                                                            FilteringTextInputFormatter.digitsOnly,
                                                                            // Allow digits only
                                                                            LengthLimitingTextInputFormatter(6),
                                                                            // Limit to 6 digits
                                                                          ],
                                                                          decoration: InputDecoration(
                                                                            hintText: 'Enter 6-digit OTP',
                                                                            hintStyle: TextStyle(color: ColorsRes.grey),
                                                                            counterText: '',
                                                                          ),
                                                                          onChanged: (value) {
                                                                            // Update the dialog state when the input changes
                                                                            setState(() {});
                                                                          },
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed: () {
                                                                          Navigator.of(context).pop();
                                                                        },
                                                                        child: const Text('Cancel'),
                                                                      ),
                                                                      ElevatedButton(
                                                                        onPressed: editTextController.text.length == 6
                                                                            ? () {
                                                                                if (editTextController.text == order.otp.toString()) {
                                                                                  params[ApiAndParams.orderId] = order.id.toString();
                                                                                  params[ApiAndParams.statusId] =
                                                                                      DeliveryBoyOrdersProvider.selectedOrderStatus.toString();
                                                                                  params[ApiAndParams.deliveryBoyId] = order.deliveryBoyId.toString();
                                                                                  DeliveryBoyOrdersProvider.updateOrdersStatus(
                                                                                    params: params,
                                                                                    context: context,
                                                                                  ).then(
                                                                                    (value) {
                                                                                      Navigator.pop(context, value);
                                                                                      callApi(reset: true, silentLoading: true);
                                                                                    },
                                                                                  );
                                                                                } else {
                                                                                  showMessage(
                                                                                    context,
                                                                                    getTranslatedValue(context, invalidOtpLabel),
                                                                                    MessageType.warning,
                                                                                  );
                                                                                }
                                                                              }
                                                                            : null,
                                                                        child: const Text('Submit'),
                                                                      ),
                                                                    ],
                                                                  );
                                                                },
                                                              );
                                                            },
                                                          ).then(
                                                            (value) => Navigator.pop(context, value),
                                                          );
                                                        } else {
                                                          params[ApiAndParams.orderId] = order.orderId.toString();
                                                          params[ApiAndParams.statusId] = DeliveryBoyOrdersProvider.selectedOrderStatus.toString();
                                                          params[ApiAndParams.deliveryBoyId] = order.deliveryBoyId.toString();
                                                          DeliveryBoyOrdersProvider.updateOrdersStatus(
                                                            params: params,
                                                            context: context,
                                                          ).then(
                                                            (value) => Navigator.pop(context, value),
                                                          );
                                                        }
                                                      },
                                                      otherWidgets: Container(
                                                        child: (DeliveryBoyOrdersProvider.ordersStatusState == OrderUpdateStatusState.loaded)
                                                            ? CustomTextLabel(
                                                                jsonKey: updateOrderStatusLabel,
                                                                softWrap: true,
                                                                style: Theme.of(context).textTheme.titleMedium!.merge(
                                                                      TextStyle(
                                                                        color: Colors.white,
                                                                        letterSpacing: 0.5,
                                                                        fontWeight: FontWeight.w500,
                                                                      ),
                                                                    ),
                                                              )
                                                            : CircularProgressIndicator(color: ColorsRes.appColorWhite),
                                                      ),
                                                    ),
                                                  ),
                                                if (DeliveryBoyOrdersProvider.ordersStatusState == OrderUpdateStatusState.loading)
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
                                        },
                                      );
                                    });
                              },
                            ).then((value) async {
                              if (!Constant.session.isSeller()) {
                                callApi(reset: true);
                              }
                            });
                          },
                          child: Container(
                            alignment: AlignmentDirectional.centerStart,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: ColorsRes.appColorLight,
                              border: Border.all(color: ColorsRes.appColor.withValues(alpha: 0.3), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomTextLabel(
                                        jsonKey: statusLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ColorsRes.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        softWrap: true,
                                      ),
                                      getSizedBox(height: 4),
                                      CustomTextLabel(
                                        text: getTranslatedValue(context, Constant.getOrderStatusDisplayName(context, order.activeStatus ?? "0")),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: ColorsRes.appColor,
                                          letterSpacing: -0.2,
                                        ),
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
                if (order.activeStatus.toString() == "5") getSizedBox(width: 10),
                if (order.activeStatus.toString() == "5")
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          orderTrackerScreen,
                          arguments: [
                            order.latitude?.toDouble,
                            order.longitude?.toDouble,
                            order.address.toString(),
                            order.id.toString(),
                            order.userName.toString(),
                            order.userMobile.toString(),
                          ],
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: ColorsRes.appColor,
                          boxShadow: [
                            BoxShadow(
                              color: ColorsRes.appColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        height: 55,
                        alignment: Alignment.center,
                        child: CustomTextLabel(
                          jsonKey: startTrackingLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  )
              ],
            )
          ],
        ),
      ),
    );
  }

  _buildOrderContainerShimmer() {
    return CustomShimmer(
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height * 0.25,
      borderRadius: 20,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
