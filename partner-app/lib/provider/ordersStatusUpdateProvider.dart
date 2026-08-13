import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';

enum OrderUpdateStatusState {
  initial,
  loading,
  updating,
  loaded,
  error,
}

class OrderUpdateStatusProvider extends ChangeNotifier {
  String message = '';
  int selectedStatus = 0;

  Future<bool> changeOrderSelectedStatus(int index) async {
    if (selectedStatus.toString() != index.toString()) {
      selectedStatus = index;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  OrderUpdateStatusState ordersStatusState = OrderUpdateStatusState.initial;
  late OrderStatuses orderStatuses;
  List<OrderStatusesData> orderStatusesList = [];
  String selectedOrderStatus = "0";

  Future getOrdersStatuses({
    required BuildContext context,
    required String from,
  }) async {
    try {
      ordersStatusState = OrderUpdateStatusState.loading;
      notifyListeners();

      Map<String, dynamic> getStatusData =
          (await getOrderStatusesRepository(context: context));

      if (getStatusData[ApiAndParams.status].toString() == "1") {
        orderStatuses = OrderStatuses.fromJson(getStatusData);
        if (from == "return") {
          orderStatusesList = orderStatuses.returnStatuses ?? [];
          orderStatusesList = (orderStatuses.data ?? []).where((item) => item.id != "8" && item.id !="7").toList();
        } else {
          orderStatusesList = orderStatuses.data ?? [];
          orderStatusesList = (orderStatuses.data ?? []).where((item) => item.id != "8" && item.id != "7").toList();
        }
        ordersStatusState = OrderUpdateStatusState.loaded;
        notifyListeners();
      } else {
        ordersStatusState = OrderUpdateStatusState.loaded;
        showMessage(
            context, getStatusData[ApiAndParams.message], MessageType.warning);
        notifyListeners();
      }
    }catch (e) {
      message = e.toString();
      ordersStatusState = OrderUpdateStatusState.error;
      showMessage(context, message, MessageType.error);
      notifyListeners();
    }
  }

  Future updateOrdersStatus({
    required Map<String, String> params,
    required BuildContext context,
  }) async {
    try {
      ordersStatusState = OrderUpdateStatusState.updating;
      notifyListeners();

      Map<String, dynamic> getUpdatedOrderData =
          await updateOrderStatusRepository(params: params);

      if (getUpdatedOrderData[ApiAndParams.status].toString() == "1") {
        ordersStatusState = OrderUpdateStatusState.loaded;
        showMessage(context, getUpdatedOrderData[ApiAndParams.message], MessageType.success);
        notifyListeners();
        return true;
      } else {
        ordersStatusState = OrderUpdateStatusState.error;
        showMessage(context, getUpdatedOrderData[ApiAndParams.message],
            MessageType.warning);
        notifyListeners();
        return false;
      }
    }catch (e) {
      message = e.toString();
      ordersStatusState = OrderUpdateStatusState.error;
      showMessage(context, message, MessageType.error);
      notifyListeners();
      return false;
    }
  }

  setSelectedStatus(String index) {
    selectedOrderStatus = (int.parse(index) + 1).toString();
    if (orderStatusesList.isNotEmpty && int.parse(index) < orderStatusesList.length) {
      selectedOrderStatus = orderStatusesList[int.parse(index)].id.toString();
    } else {
      selectedOrderStatus = (int.parse(index) + 1).toString();
    }
    notifyListeners();
  }
}
