import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';

enum SellerPickupOrdersState {
  initial,
  loading,
  silentLoading,
  loaded,
  empty,
  loadingMore,
  error,
}

class SellerPickupOrdersProvider extends ChangeNotifier {
  String message = '';
  SellerPickupOrdersState ordersState = SellerPickupOrdersState.initial;

  late SellerOrder sellerOrder;
  List<SellerOrdersListItem> sellerOrdersList = [];

  bool hasMoreData = false;
  int totalData = 0;
  int offset = 0;
  int selectedStatus = 0;
  bool hasNewOrder = false;

  Future getSellerPickupOrders({
    required Map<String, String> params,
    required BuildContext context,
    bool? silentLoading,
  }) async {
    if (offset == 0) {
      ordersState = SellerPickupOrdersState.loading;
    } else {
      ordersState = SellerPickupOrdersState.loadingMore;
    }
    notifyListeners();

    params[ApiAndParams.limit] = Constant.defaultDataLoadLimitAtOnce.toString();
    params[ApiAndParams.offset] = offset.toString();

    params[ApiAndParams.status] = selectedStatus.toString();
    try {
      Map<String, dynamic> response = {};

      response = await getPickupOrdersRepository(context: context, params: params);

      if (response[ApiAndParams.status].toString() == "1") {
        sellerOrder = SellerOrder.fromJson(response);

        totalData = int.parse(sellerOrder.total.toString());

        if (totalData > 0) {
          List<SellerOrdersListItem> tempOrders =
              sellerOrder.data?.orders ?? [];

          // Check if this is a refresh (offset == 0) and there are existing orders
          hasNewOrder = offset == 0 && sellerOrdersList.isNotEmpty && tempOrders.isNotEmpty;

          sellerOrdersList.addAll(tempOrders);

          hasMoreData = totalData > sellerOrdersList.length;

          if (hasMoreData) {
            offset += Constant.defaultDataLoadLimitAtOnce;
          }
          ordersState = SellerPickupOrdersState.loaded;
          notifyListeners();
        } else {
          ordersState = SellerPickupOrdersState.empty;
          notifyListeners();
        }
      }
    }catch (e) {
      message = e.toString();
      showMessage(context, message, MessageType.error);
      ordersState = SellerPickupOrdersState.error;
      notifyListeners();
    }
  }

  Future<bool> changeSellerOrderSelectedStatus(int index) async {
    if (selectedStatus.toString() != index.toString()) {
      selectedStatus = index;
      notifyListeners();
      offset = 0;
      sellerOrdersList = [];
      return true;
    } else {
      return false;
    }
  }
}
