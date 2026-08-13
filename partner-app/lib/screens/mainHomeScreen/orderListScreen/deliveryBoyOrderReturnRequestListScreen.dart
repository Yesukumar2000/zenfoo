import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/deliveryBoyOrderReturnRequestProvider.dart';
import 'package:project/screens/mainHomeScreen/orderListScreen/widget/deliveryBoyOrderReturnRequestContainer.dart';

class DeliveryBoyOrderReturnRequestListScreen extends StatefulWidget {
  const DeliveryBoyOrderReturnRequestListScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryBoyOrderReturnRequestListScreen> createState() => _DeliveryBoyOrderReturnRequestListScreenState();
}

class _DeliveryBoyOrderReturnRequestListScreenState extends State<DeliveryBoyOrderReturnRequestListScreen> {
  late ScrollController scrollController = ScrollController();
  List<String> lblOrderStatusDisplayNames = [];
  List<String> lblOrderStatusUpdateNames = [];
  TextEditingController searchController = TextEditingController();

  String startDate = "";
  String endDate = "";

  scrollListener() {
    // nextPageTrigger will have a value equivalent to 70% of the list size.
    var nextPageTrigger = 0.7 * scrollController.position.maxScrollExtent;

// _scrollController fetches the next paginated data when the current position of the user on the screen has surpassed
    if (scrollController.position.pixels > nextPageTrigger) {
      if (mounted) {
        if (context.read<DeliveryBoyOrderReturnRequestProvider>().hasMoreData &&
            context.read<DeliveryBoyOrderReturnRequestProvider>().requestState !=
                DeliveryBoyOrderReturnRequestState.loadingMore) {
          callApi(reset: false);
        }
      }
    }
  }

  Future callApi({bool? reset, bool? isSilentLoading}) async {
    if (reset == true) {
      resetDate();
      context.read<DeliveryBoyOrderReturnRequestProvider>().offset = 0;
      context.read<DeliveryBoyOrderReturnRequestProvider>().returnRequestList.clear();
    }

    Map<String, String> params = {};
    if (isDateRangeValidate()) {
      params[ApiAndParams.startDate] = startDate;
      params[ApiAndParams.endDate] = endDate;
    }

    params[ApiAndParams.search] = searchController.text.toString();

    await context.read<DeliveryBoyOrderReturnRequestProvider>().getDeliveryBoyOrderReturnRequests(
        context: context,
        params: params,
        silentLoading: isSilentLoading == true);
  }

  bool isDateRangeValidate() {
    return (startDate != getTranslatedValue(context, startDateLabel) &&
        endDate != getTranslatedValue(context, endDateLabel));
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

        lblOrderStatusDisplayNames = [
          getTranslatedValue(context, orderReturnStatusDisplayNamesOutForPickupLabel),
          getTranslatedValue(context, orderReturnStatusDisplayNamesReceivedFromCustomerLabel),
          getTranslatedValue(context, orderReturnStatusDisplayNamesCancelledLabel),
          getTranslatedValue(context, orderReturnStatusDisplayNamesReturnToSellerLabel),
        ];

        lblOrderStatusUpdateNames = [
          getTranslatedValue(context, orderReturnStatusDisplayNamesOutForPickupLabel),
          getTranslatedValue(context, orderReturnStatusDisplayNamesReceivedFromCustomerLabel),
          getTranslatedValue(context, orderReturnStatusDisplayNamesCancelledLabel),
          getTranslatedValue(context, orderReturnStatusDisplayNamesReturnToSellerLabel),
        ];

        callApi(reset: true);

        searchController.addListener(() {
          callApi();
        });

        scrollController.addListener(scrollListener);
      },
    );
    super.initState();
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
        getTranslatedValue(
            context, orderStatusDisplayNamesOutForDeliveryLabel),
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
        getTranslatedValue(
            context, orderStatusDisplayNamesOutForDeliveryLabel),
        getTranslatedValue(context, orderStatusDisplayNamesDeliveredLabel),
        getTranslatedValue(context, orderStatusDisplayNamesCancelledLabel),
        getTranslatedValue(context, orderStatusDisplayNamesReturnedLabel),
      ];
    }

    return Scaffold(
      appBar: getAppBar(
        context: context,
        title: CustomTextLabel(
          jsonKey: orderReturnRequestLabel,
        ),
      ),
      body: Column(
        children: [
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
                    validationFunction: (value)=> optionalFieldValidation("",  ""),
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
                          data: Constant.session
                                  .getBoolData(SessionManager.isDarkTheme)
                              ? ThemeData.dark().copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: ColorsRes.appColor,
                                    onPrimary: ColorsRes.mainTextColor,
                                    surface: Theme.of(context).cardColor,
                                    inverseSurface: ColorsRes.subTitleTextColor,
                                    onSurface: ColorsRes.mainTextColor,
                                    secondary: ColorsRes.appColor,
                                  ),
                                  visualDensity: VisualDensity.compact, dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).cardColor),
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
                                  visualDensity: VisualDensity.compact, dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).cardColor),
                                ),
                          child: child!,
                        );
                      },
                    ).then(
                      (value) {
                        if (value != null) {
                          startDate = value.start.toString().split(" ")[0];
                          endDate = value.end.toString().split(" ")[0];

                          context.read<DeliveryBoyOrderReturnRequestProvider>().offset = 0;
                          context
                              .read<DeliveryBoyOrderReturnRequestProvider>()
                              .returnRequestList
                              .clear();

                          setState(() {});
                          callApi();
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
                padding: EdgeInsetsDirectional.all(
                    (!isDateRangeValidate()) ? 12 : 14),
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
                        text:
                            "$startDate\t\t${getTranslatedValue(context, toLabel)}\t\t$endDate",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    getSizedBox(width: 10),
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
          getSizedBox(height: 10),
          Consumer<DeliveryBoyOrderReturnRequestProvider>(
            builder: (context, ordersProvider, child) {
              if (ordersProvider.requestState == DeliveryBoyOrderReturnRequestState.loaded ||
                  ordersProvider.requestState == DeliveryBoyOrderReturnRequestState.loadingMore ||
                  ordersProvider.requestState ==
                      DeliveryBoyOrderReturnRequestState.silentLoading) {
                return Expanded(
                  child: setRefreshIndicator(
                    context: context,
                    refreshCallback: () {
                      return callApi(reset: true);
                    },
                    child: ListView.builder(
                      physics: ClampingScrollPhysics(),
                      controller: scrollController,
                      itemCount: ordersProvider.returnRequestList.length,
                      itemBuilder: (context, index) {
                        if (index ==
                            ordersProvider.returnRequestList.length - 1) {
                          if (ordersProvider.requestState ==
                              DeliveryBoyOrderReturnRequestState.loadingMore) {
                            return OrderContainerShimmer(context);
                          }
                        }
                        return DeliveryBoyOrderReturnRequestContainer(
                          order: ordersProvider.returnRequestList[index],
                          index: index.toString(),
                          lblOrderStatusDisplayNames:
                              lblOrderStatusDisplayNames,
                          lblOrderStatusUpdateNames: lblOrderStatusUpdateNames,
                          callApi: () =>
                              callApi(reset: true, isSilentLoading: true),
                        );
                      },
                    ),
                  ),
                );
              } else if (ordersProvider.requestState ==
                  DeliveryBoyOrderReturnRequestState.loading) {
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
              } else if (ordersProvider.requestState ==
                  DeliveryBoyOrderReturnRequestState.empty) {
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
                        description:somethingWentWrongMessageDescriptionLabel,
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
        ],
      ),
    );
  }
}
