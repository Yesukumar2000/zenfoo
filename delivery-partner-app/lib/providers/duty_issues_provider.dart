import 'package:flutter/foundation.dart';

import '../models/not_getting_orders_model.dart';
import '../repository/help_center/duty_issues/duty_issues_repository.dart';
import '../services/status.dart';

class DutyIssuesProvider extends ChangeNotifier {
  final DutyIssuesRepository _repo = DutyIssuesRepository();

  ApiResponse getNotGettingOrdersState = ApiResponse.nothing();

  NotGettingOrdersData? notGettingOrdersData;

  Future<void> getNotGettingOrders() async {
    getNotGettingOrdersState = ApiResponse.loading();
    notifyListeners();

    final response = await _repo.dutyIssues();

    if (response.status == ApiStatus.success) {
      try {
        final model = NotGettingOrdersModel.fromJson(response.data);
        notGettingOrdersData = model.data;
        getNotGettingOrdersState = ApiResponse.success(model.data);
      } catch (e) {
        getNotGettingOrdersState = ApiResponse.error('Failed to parse data');
      }
    } else {
      getNotGettingOrdersState =
          ApiResponse.error(response.message ?? 'Failed to fetch data');
    }

    notifyListeners();
  }

  ApiResponse ordersIssueState = ApiResponse.nothing();

  Future<void> raiseOrdersIssue() async {
    ordersIssueState = ApiResponse.loading();
    notifyListeners();

    ordersIssueState = await _repo.ordersIssue();

    notifyListeners();
  }

  void resetOrdersIssueState() {
    ordersIssueState = ApiResponse.nothing();
    notifyListeners();
  }
}
