import 'package:flutter/material.dart';

import '../models/order_history_model.dart';
import '../repository/help_center/order_earning_issues/order_earning_issue_repository.dart';
import '../services/status.dart';

class OrderEarningIssueProvider extends ChangeNotifier {
  final OrderEarningIssueRepository _repo = OrderEarningIssueRepository();

  ApiResponse<Data> getOrderEarningIssueState = ApiResponse.nothing();

  Future<void> getOrderEarningIssue({
    required int page,
    required int perPage,
  }) async {
    getOrderEarningIssueState = ApiResponse.loading();
    notifyListeners();

    final response = await _repo.getOrderEarningIssue(
      page: page,
      perPage: perPage,
    );

    if (response.status == ApiStatus.success) {
      try {
        final model = OrderHistoryModel.fromJson(response.data);
        getOrderEarningIssueState = ApiResponse.success(model.data);
      } catch (e) {
        getOrderEarningIssueState =
            ApiResponse.error('Failed to parse order history');
      }
    } else {
      getOrderEarningIssueState =
          ApiResponse.error(response.message ?? 'Something went wrong');
    }

    notifyListeners();
  }

  ApiResponse<dynamic> orderEarningIssueDetailsState = ApiResponse.nothing();

  Future<void> orderEarningIssueDetails({
    required int orderId,
  }) async {
    orderEarningIssueDetailsState = ApiResponse.loading();
    notifyListeners();

    final response = await _repo.orderEarningIssueDetails(
      orderId: orderId,
    );

    orderEarningIssueDetailsState = response;

    notifyListeners();
  }
}
