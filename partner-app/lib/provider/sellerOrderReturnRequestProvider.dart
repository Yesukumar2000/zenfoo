import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/sellerReturnRequestResponse.dart';

enum SellerOrderReturnRequestState {
  initial,
  loading,
  silentLoading,
  loaded,
  empty,
  loadingMore,
  error,
}

class SellerOrderReturnRequestProvider extends ChangeNotifier {
  String message = '';
  SellerOrderReturnRequestState requestState = SellerOrderReturnRequestState.initial;

  late SellerReturnRequestResponse returnRequest;
  List<SellerReturnRequest> returnRequestList = [];

  bool hasMoreData = false;
  int totalData = 0;
  int offset = 0;
  int selectedStatus = 0;

  Future getSellerOrderReturnRequests({
    required Map<String, String> params,
    required BuildContext context,
    bool? silentLoading,
  }) async {
    if (offset == 0) {
      requestState = SellerOrderReturnRequestState.loading;
    } else {
      requestState = SellerOrderReturnRequestState.loadingMore;
    }
    notifyListeners();

    try {
      Map<String, dynamic> response = {};

      response = await getSellerIssueReportReturnsRepository(
        context: context,
        params: params,
      );

      if (response[ApiAndParams.status].toString() == "1") {
        returnRequest = SellerReturnRequestResponse.fromJson(response);

        totalData = returnRequest.data?.pagination?.total ?? 0;

        if (totalData > 0) {
          List<SellerReturnRequest> tempRequests = returnRequest.data?.returns ?? [];

          returnRequestList.addAll(tempRequests);

          hasMoreData = totalData > returnRequestList.length;

          if (hasMoreData) {
            offset += Constant.defaultDataLoadLimitAtOnce;
          }
          requestState = SellerOrderReturnRequestState.loaded;
          notifyListeners();
        } else {
          requestState = SellerOrderReturnRequestState.empty;
          notifyListeners();
        }
      }
    } catch (e) {
      message = e.toString();
      showMessage(context, message, MessageType.error);
      requestState = SellerOrderReturnRequestState.error;
      notifyListeners();
    }
  }

  Future<bool> changeSelectedReturnRequestStatus(int index) async {
    if (selectedStatus.toString() != index.toString()) {
      selectedStatus = index;
      notifyListeners();
      offset = 0;
      returnRequestList = [];
      return true;
    } else {
      return false;
    }
  }

  Future<bool> updateReturnRequestStatus({
    required int returnId,
    required BuildContext context,
  }) async {
    try {
      Map<String, String> params = {};
      params[ApiAndParams.returnId] = returnId.toString();

      final response = await updateSellerIssueReportReturnStatusRepository(
        params: params,
      );

      if (response[ApiAndParams.status].toString() == "1") {
        showMessage(context, response[ApiAndParams.message] ?? "Status updated successfully", MessageType.success);
        return true;
      } else {
        showMessage(context, response[ApiAndParams.message] ?? "Failed to update status", MessageType.error);
        return false;
      }
    } catch (e) {
      message = e.toString();
      showMessage(context, message, MessageType.error);
      return false;
    }
  }
}
