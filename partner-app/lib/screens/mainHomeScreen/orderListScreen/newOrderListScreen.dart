import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/new_orders_provider.dart';
import 'package:project/screens/mainHomeScreen/orderListScreen/widget/newOrderContainer.dart';

class NewOrderListScreen extends StatefulWidget {
  const NewOrderListScreen({Key? key}) : super(key: key);

  @override
  State<NewOrderListScreen> createState() => _NewOrderListScreenState();
}

class _NewOrderListScreenState extends State<NewOrderListScreen> {
  late ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      callApi(reset: true);

      searchController.addListener(() {
        callApi(reset: true);
      });

      scrollController.addListener(scrollListener);
    });
  }

  void scrollListener() {
    var nextPageTrigger = 0.7 * scrollController.position.maxScrollExtent;

    if (scrollController.position.pixels > nextPageTrigger) {
      if (mounted) {
        final provider = context.read<NewOrdersProvider>();
        if (provider.hasMoreData && provider.ordersState != NewOrdersState.loadingMore) {
          callApi(reset: false);
        }
      }
    }
  }

  Future<void> callApi({bool reset = false, bool silentLoading = false}) async {
    Map<String, String> params = {};

    if (searchController.text.isNotEmpty) {
      params['search'] = searchController.text;
    }

    await context.read<NewOrdersProvider>().getOrders(
      context: context,
      params: params,
      silentLoading: silentLoading,
      reset: reset,
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(
        context: context,
        title: CustomTextLabel(
          jsonKey: ordersLabel,
        ),
      ),
      body: Column(
        children: [
          // Status Tabs
          Consumer<NewOrdersProvider>(
            builder: (context, provider, child) {
              if (provider.statusOrderCounts.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.statusOrderCounts.length,
                  itemBuilder: (context, index) {
                    final statusItem = provider.statusOrderCounts[index];
                    final isSelected = provider.selectedStatus == (statusItem.id ?? 0);

                    return GestureDetector(
                      onTap: () async {
                        await provider.changeSelectedStatus(statusItem.id ?? 0);
                        callApi(reset: true);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ColorsRes.appColor
                              : ColorsRes.appColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ColorsRes.appColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              statusItem.status ?? '',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : ColorsRes.appColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.3)
                                    : ColorsRes.appColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${statusItem.orderCount ?? 0}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : ColorsRes.appColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(10),
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

          // Orders List
          Expanded(
            child: Consumer<NewOrdersProvider>(
              builder: (context, provider, child) {
                if (provider.ordersState == NewOrdersState.loading) {
                  return ListView.builder(
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return _buildShimmer();
                    },
                  );
                }

                if (provider.ordersState == NewOrdersState.error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: ColorsRes.subTitleTextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.message,
                          style: TextStyle(
                            fontSize: 16,
                            color: ColorsRes.subTitleTextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => callApi(reset: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.ordersState == NewOrdersState.empty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: ColorsRes.subTitleTextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: TextStyle(
                            fontSize: 16,
                            color: ColorsRes.subTitleTextColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => callApi(reset: true),
                  child: ListView.builder(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: provider.ordersList.length +
                        (provider.ordersState == NewOrdersState.loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.ordersList.length) {
                        return _buildShimmer();
                      }

                      final order = provider.ordersList[index];
                      return NewOrderContainer(
                        order: order,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailScreen(orderId: order.orderId.toString() ?? ""),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: ColorsRes.subTitleTextColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: ColorsRes.subTitleTextColor.withOpacity(0.1),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 150,
                      color: ColorsRes.subTitleTextColor.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
