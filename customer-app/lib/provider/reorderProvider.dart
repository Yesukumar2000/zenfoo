import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/reorderableOrder.dart';
import 'package:project/repositories/reorderApi.dart';

enum ReorderState {
  initial,
  loading,
  loaded,
  error,
}

class ReorderProvider extends ChangeNotifier {
  ReorderState state = ReorderState.initial;
  String message = '';
  List<ReorderableOrder> orders = [];
  bool isDataLoaded = false;

  // Get all reorderable orders
  Future<void> getReorderableOrders({required BuildContext context}) async {
    state = ReorderState.loading;
    notifyListeners();

    try {
      Map<String, dynamic> response =
          await getReorderableOrdersApi(context: context);

      if (response['status'].toString() == '1') {
        ReorderableOrdersResponse reorderResponse =
            ReorderableOrdersResponse.fromJson(response);
        orders = reorderResponse.data ?? [];
        isDataLoaded = true;
        state = ReorderState.loaded;
        notifyListeners();
      } else {
        message = response['message'] ?? 'Failed to load reorderable orders';
        state = ReorderState.error;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      state = ReorderState.error;
      notifyListeners();
    }
  }

  // Get available orders count
  int getAvailableOrdersCount() {
    return orders.where((order) => order.canReorderAll).length;
  }

  // Get total available items count
  int getTotalAvailableItemsCount() {
    return orders.fold(
        0, (sum, order) => sum + (order.availableItemsCount ?? 0));
  }

  // Get total unavailable items count
  int getTotalUnavailableItemsCount() {
    return orders.fold(
        0, (sum, order) => sum + (order.unavailableItemsCount ?? 0));
  }

  // Clear data
  void clearData() {
    orders.clear();
    isDataLoaded = false;
    state = ReorderState.initial;
    notifyListeners();
  }
}
