import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/soundService.dart';
import 'package:project/screens/mainHomeScreen/orderListScreen/widget/orderContainer.dart';
import 'package:project/screens/mainHomeScreen/orderListScreen/widget/orderTypeButtonWidget.dart';
import 'package:project/screens/mainHomeScreen/orderListScreen/widget/pickupOrderContainer.dart';
import 'package:project/provider/pickupOrdersProvider.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({Key? key}) : super(key: key);

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late ScrollController scrollController = ScrollController();
  List<String> lblOrderStatusDisplayNames = [];
  List<String> lblOrderStatusUpdateNames = [];
  TextEditingController searchController = TextEditingController();

  String startDate = "";
  String endDate = "";

  int currentIndex = 0;
  List<Widget> pages = [];

  scrollListener() {
    // nextPageTrigger will have a value equivalent to 70% of the list size.
    var nextPageTrigger = 0.7 * scrollController.position.maxScrollExtent;

// _scrollController fetches the next paginated data when the current position of the user on the screen has surpassed
    if (scrollController.position.pixels > nextPageTrigger) {
      if (mounted) {
        if (currentIndex == 0) {
          if (context.read<SellerOrdersProvider>().hasMoreData && context.read<SellerOrdersProvider>().ordersState != SellerOrdersState.loadingMore) {
            callApi(reset: false);
          }
        } else {
          if (context.read<SellerPickupOrdersProvider>().hasMoreData && context.read<SellerPickupOrdersProvider>().ordersState != SellerPickupOrdersState.loadingMore) {
            callPickupApi(reset: false);
          }
        }
      }
    }
  }

  Future callApi({bool? reset, bool? isSilentLoading}) async {
    if (reset == true) {
      resetDate();
      context.read<SellerOrdersProvider>().offset = 0;
      context.read<SellerOrdersProvider>().sellerOrdersList.clear();
    }

    Map<String, String> params = {};
    if (isDateRangeValidate()) {
      params[ApiAndParams.startDeliveryDate] = startDate;
      params[ApiAndParams.endDeliveryDate] = endDate;
    }

    params[ApiAndParams.search] = searchController.text.toString();

    await context.read<SellerOrdersProvider>().getSellerOrders(context: context, params: params, silentLoading: isSilentLoading == true);
  }

  Future callPickupApi({bool? reset, bool? isSilentLoading}) async {
    if (reset == true) {
      resetDate();
      context.read<SellerPickupOrdersProvider>().offset = 0;
      context.read<SellerPickupOrdersProvider>().sellerOrdersList.clear();
    }

    Map<String, String> params = {};
    if (isDateRangeValidate()) {
      params[ApiAndParams.startDate] = startDate;
      params[ApiAndParams.endDate] = endDate;
    }

    params[ApiAndParams.search] = searchController.text.toString();

    await context.read<SellerPickupOrdersProvider>().getSellerPickupOrders(context: context, params: params, silentLoading: isSilentLoading == true);
  }

  bool isDateRangeValidate() {
    return (startDate != getTranslatedValue(context, startDateLabel) && endDate != getTranslatedValue(context, endDateLabel));
  }

  resetDate() {
    startDate = getTranslatedValue(context, startDateLabel);
    endDate = getTranslatedValue(context, endDateLabel);
  }

  @override
  void initState() {
    Map<String, String> params = {};
    params[ApiAndParams.status] = "1";

    Future.delayed(
      Duration.zero,
      () {
        startDate = getTranslatedValue(context, startDateLabel);
        endDate = getTranslatedValue(context, endDateLabel);

        statusList();

        if (currentIndex == 0) {
          callApi(reset: true);
        } else {
          callPickupApi(reset: true);
        }

        searchController.addListener(() {
          if (currentIndex == 0) {
            callApi();
          } else {
            callPickupApi();
          }
        });

        scrollController.addListener(scrollListener);
      },
    );
    super.initState();
  }

  statusList() {
    lblOrderStatusDisplayNames = currentIndex == 0
        ? [
            getTranslatedValue(context, orderStatusDisplayNamesAllLabel),
            getTranslatedValue(context, orderStatusDisplayNamesAwaitingLabel),
            getTranslatedValue(context, orderStatusDisplayNamesReceivedLabel),
            getTranslatedValue(context, orderStatusDisplayNamesProcessedLabel),
            getTranslatedValue(context, orderStatusDisplayNamesShippedLabel),
            getTranslatedValue(context, orderStatusDisplayNamesOutForDeliveryLabel),
            getTranslatedValue(context, orderStatusDisplayNamesDeliveredLabel),
            getTranslatedValue(context, orderStatusDisplayNamesCancelledLabel),
            getTranslatedValue(context, orderStatusDisplayNamesReturnedLabel),
          ]
        : [
            getTranslatedValue(context, orderStatusDisplayNamesAllLabel),
            getTranslatedValue(context, orderStatusDisplayNamesAwaitingLabel),
            getTranslatedValue(context, orderStatusDisplayNamesPendingLabel),
            getTranslatedValue(context, orderStatusDisplayNamesReadyForPickupLabel),
            getTranslatedValue(context, orderStatusDisplayNamesPickedUpLabel),
            getTranslatedValue(context, orderStatusDisplayNamesCancelledLabel),
            getTranslatedValue(context, orderStatusDisplayNamesReturnedLabel),
          ];

    lblOrderStatusUpdateNames = currentIndex == 0
        ? [
            getTranslatedValue(context, orderStatusDisplayNamesAwaitingLabel),
            getTranslatedValue(context, orderStatusDisplayNamesReceivedLabel),
            getTranslatedValue(context, orderStatusDisplayNamesProcessedLabel),
            getTranslatedValue(context, orderStatusDisplayNamesShippedLabel),
            getTranslatedValue(context, orderStatusDisplayNamesOutForDeliveryLabel),
            getTranslatedValue(context, orderStatusDisplayNamesDeliveredLabel),
            getTranslatedValue(context, orderStatusDisplayNamesCancelledLabel),
            // getTranslatedValue(context, orderStatusDisplayNamesReturnedLabel),
          ]
        : [
            getTranslatedValue(context, orderStatusDisplayNamesAwaitingLabel),
            getTranslatedValue(context, orderStatusDisplayNamesPendingLabel),
            getTranslatedValue(context, orderStatusDisplayNamesReadyForPickupLabel),
            getTranslatedValue(context, orderStatusDisplayNamesPickedUpLabel)
          ];
  }

  @override
  Widget build(BuildContext context) {
    if (lblOrderStatusDisplayNames.isEmpty) {
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
    }
    if (lblOrderStatusDisplayNames.isEmpty) {
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
    }

    return Scaffold(
      appBar: getAppBar(
        context: context,
        title: CustomTextLabel(
          jsonKey: ordersLabel,
        ),
      ),
      body: Consumer<LanguageProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Container(
            color: Theme.of(context).cardColor,
            padding: EdgeInsetsDirectional.all(10),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (currentIndex != 0) {
                        setState(() {
                          currentIndex = 0;
                        });
                        statusList();
                        callApi(reset: true);
                      }
                    },
                    child: OrderTypeButtonWidget(
                      isActive: currentIndex == 0,
                      child: Center(
                        child: CustomTextLabel(
                          jsonKey: homeDeliveryLabel,
                          softWrap: true,
                          style: TextStyle(
                            color: currentIndex == 0
                                ? ColorsRes.appColorWhite
                                : ColorsRes.mainTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (currentIndex != 1) {
                        setState(() {
                          currentIndex = 1;
                        });
                        statusList();
                        callPickupApi(reset: true);
                      }
                    },
                    child: OrderTypeButtonWidget(
                      isActive: currentIndex == 1,
                      child: Center(
                        child: CustomTextLabel(
                          jsonKey: storePickupLabel,
                          softWrap: true,
                          style: TextStyle(
                            color: currentIndex == 1
                                ? ColorsRes.appColorWhite
                                : ColorsRes.mainTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(lblOrderStatusDisplayNames.length, (index) {
                    List<int> selfpickupCustomOrder = [0, 1, 9, 10, 11, 7, 8];
                    return GestureDetector(
                      onTap: () async {
                        // Map the tapped index to your custom order value
                        final statusIndex = selfpickupCustomOrder[index];
                        if (mounted) {
                          if (currentIndex == 0) {
                            await context.read<SellerOrdersProvider>().changeSellerOrderSelectedStatus(index).then((value) async {
                              if (value) {
                                callApi(reset: true);
                              }
                            });
                          } else {
                            await context.read<SellerPickupOrdersProvider>().changeSellerOrderSelectedStatus(statusIndex).then((value) async {
                              if (value) {
                                callPickupApi(reset: true);
                              }
                            });
                          }
                        }
                      },
                      child: getOrderStatusContainer(
                        isActive: currentIndex == 0 
                            ? context.watch<SellerOrdersProvider>().selectedStatus == index
                            : context.watch<SellerPickupOrdersProvider>().selectedStatus == selfpickupCustomOrder[index] /* index */,
                        svgIconName: Constant.orderStatusIcons[index],
                        context: context,
                        title: getTranslatedValue(context, lblOrderStatusDisplayNames[index].toString()),
                      ),
                    );
                  }),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: 10),
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
                  getSizedBox(width: 10),
                  Container(
                    padding: EdgeInsetsDirectional.all(10),
                    decoration: BoxDecoration(
                      color: ColorsRes.appColorLightHalfTransparent,
                      borderRadius: BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                    child: GestureDetector(
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

                              if (currentIndex == 0) {
                                context.read<SellerOrdersProvider>().offset = 0;
                                context.read<SellerOrdersProvider>().sellerOrdersList.clear();
                                setState(() {});
                                callApi();
                              } else {
                                context.read<SellerPickupOrdersProvider>().offset = 0;
                                context.read<SellerPickupOrdersProvider>().sellerOrdersList.clear();
                                setState(() {});
                                callPickupApi();
                              }
                            }
                          },
                        );
                      },
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: ColorsRes.appColor,
                      ),
                    ),
                  ),
                  getSizedBox(width: 10),
                ],
              ),
              if (isDateRangeValidate())
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: 10,
                    end: 10,
                    top: 10,
                  ),
                  child: Container(
                    padding: EdgeInsetsDirectional.all((!isDateRangeValidate()) ? 12 : 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: ColorsRes.subTitleTextColor),
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CustomTextLabel(
                            text: "${startDate}\t\t${getTranslatedValue(context, toLabel)}\t\t$endDate",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        getSizedBox(width: 10),
                        if (isDateRangeValidate())
                          GestureDetector(
                            onTap: () {
                              if (currentIndex == 0) {
                                callApi(reset: true);
                              } else {
                                callPickupApi(reset: true);
                              }
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
              getSizedBox(height: 10),
              if (currentIndex == 0)
                Consumer<SellerOrdersProvider>(
                  builder: (context, ordersProvider, child) {
                    // Play sound when new order arrives
                    if (ordersProvider.hasNewOrder) {
                      Future.delayed(Duration(milliseconds: 100), () {
                        SoundService().playOrderSound();
                        ordersProvider.hasNewOrder = false;
                      });
                    }

                    if (ordersProvider.ordersState == SellerOrdersState.loaded ||
                        ordersProvider.ordersState == SellerOrdersState.loadingMore ||
                        ordersProvider.ordersState == SellerOrdersState.silentLoading) {
                      return Expanded(
                        child: setRefreshIndicator(
                          context: context,
                          refreshCallback: () {
                            return callApi(reset: true);
                          },
                          child: ListView.builder(
                            physics: ClampingScrollPhysics(),
                            controller: scrollController,
                            itemCount: ordersProvider.sellerOrdersList.length,
                            itemBuilder: (context, index) {
                              if (index == ordersProvider.sellerOrdersList.length - 1) {
                                if (ordersProvider.ordersState == SellerOrdersState.loadingMore) {
                                  return OrderContainerShimmer(context);
                                }
                              }
                              return OrderContainer(
                                order: ordersProvider.sellerOrdersList[index],
                                index: index.toString(),
                                lblOrderStatusDisplayNames: lblOrderStatusDisplayNames,
                                lblOrderStatusUpdateNames: lblOrderStatusUpdateNames,
                                callApi: () => callApi(reset: true, isSilentLoading: true),
                              );
                            },
                          ),
                        ),
                      );
                    } else if (ordersProvider.ordersState == SellerOrdersState.loading) {
                      return Expanded(
                        child: setRefreshIndicator(
                          context: context,
                          refreshCallback: () {
                            return callApi(reset: true);
                          },
                          child: ListView.builder(
                            physics: ClampingScrollPhysics(),
                            controller: scrollController,
                            itemCount: 20,
                            itemBuilder: (context, index) {
                              return OrderContainerShimmer(context);
                            },
                          ),
                        ),
                      );
                    } else if (ordersProvider.ordersState == SellerOrdersState.empty) {
                      return Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            DefaultBlankItemMessageScreen(
                              image: "no_order_icon",
                              title: emptyOrdersMessageLabel,
                              description: emptyOrdersDescriptionLabel,
                              buttonTitle: refreshLabel,
                              callback: () async {
                                return callApi();
                              },
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            DefaultBlankItemMessageScreen(
                              image: "something_went_wrong",
                              title: somethingWentWrongMessageTitleLabel,
                              description: somethingWentWrongMessageDescriptionLabel,
                              buttonTitle: tryAgainLabel,
                              callback: () async {
                                return callApi(reset: true);
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              if (currentIndex == 1)
                Consumer<SellerPickupOrdersProvider>(
                  builder: (context, pickupOrdersProvider, child) {
                    // Play sound when new pickup order arrives
                    if (pickupOrdersProvider.hasNewOrder) {
                      Future.delayed(Duration(milliseconds: 100), () {
                        SoundService().playOrderSound();
                        pickupOrdersProvider.hasNewOrder = false;
                      });
                    }

                    if (pickupOrdersProvider.ordersState == SellerPickupOrdersState.loaded ||
                        pickupOrdersProvider.ordersState == SellerPickupOrdersState.loadingMore ||
                        pickupOrdersProvider.ordersState == SellerPickupOrdersState.silentLoading) {
                      return Expanded(
                        child: setRefreshIndicator(
                          context: context,
                          refreshCallback: () {
                            return callPickupApi(reset: true);
                          },
                          child: ListView.builder(
                            physics: ClampingScrollPhysics(),
                            controller: scrollController,
                            itemCount: pickupOrdersProvider.sellerOrdersList.length,
                            itemBuilder: (context, index) {
                              if (index == pickupOrdersProvider.sellerOrdersList.length - 1) {
                                if (pickupOrdersProvider.ordersState == SellerPickupOrdersState.loadingMore) {
                                  return OrderContainerShimmer(context);
                                }
                              }
                              return PickupOrderContainer(
                                order: pickupOrdersProvider.sellerOrdersList[index],
                                index: index.toString(),
                                lblOrderStatusDisplayNames: lblOrderStatusDisplayNames,
                                lblOrderStatusUpdateNames: lblOrderStatusUpdateNames,
                                callApi: () => callPickupApi(reset: true, isSilentLoading: true),
                              );
                            },
                          ),
                        ),
                      );
                    } else if (pickupOrdersProvider.ordersState == SellerPickupOrdersState.loading) {
                      return Expanded(
                        child: setRefreshIndicator(
                          context: context,
                          refreshCallback: () {
                            return callPickupApi(reset: true);
                          },
                          child: ListView.builder(
                            physics: ClampingScrollPhysics(),
                            controller: scrollController,
                            itemCount: 20,
                            itemBuilder: (context, index) {
                              return OrderContainerShimmer(context);
                            },
                          ),
                        ),
                      );
                    } else if (pickupOrdersProvider.ordersState == SellerPickupOrdersState.empty) {
                      return Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            DefaultBlankItemMessageScreen(
                              image: "no_order_icon",
                              title: emptyOrdersMessageLabel,
                              description: emptyOrdersDescriptionLabel,
                              buttonTitle: refreshLabel,
                              callback: () async {
                                return callPickupApi();
                              },
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            DefaultBlankItemMessageScreen(
                              image: "something_went_wrong",
                              title: somethingWentWrongMessageTitleLabel,
                              description: somethingWentWrongMessageDescriptionLabel,
                              buttonTitle: tryAgainLabel,
                              callback: () async {
                                return callPickupApi(reset: true);
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
