import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';

Future<Map<String, dynamic>> getOrdersRepository(
    {required Map<String, String> params,
    required BuildContext context}) async {
  try {
    final result = await sendApiRequest(
        apiName: ApiAndParams.apiOrdersHistory, params: params, isPost: false);

    return Map.from(
      jsonDecode(result),
    );
  } catch (e) {
    //
    return {};
  }
}Future<Map<String, dynamic>> getPickupOrdersRepository(
    {required Map<String, String> params,
    required BuildContext context}) async {
  try {
    final result = await sendApiRequest(
        apiName: ApiAndParams.apiSelfPickupOrders, params: params, isPost: false);

    return Map.from(
      jsonDecode(result),
    );
  } catch (e) {
    //
    return {};
  }
}

Future<Map<String, dynamic>> getOrderStatusesRepository(
    {required BuildContext context}) async {
  try {
    final result = await sendApiRequest(
        apiName: ApiAndParams.apiOrderStatuses, params: {}, isPost: false);

    return Map.from(
      jsonDecode(result),
    );
  } catch (e) {
    //
    return {};
  }
}


Future<Map<String, dynamic>> getPickupOrderStatusesRepository({required BuildContext context}) async {
  try {
    final result = await sendApiRequest(apiName: ApiAndParams.apiSelfPickupOrderStatuses, params: {}, isPost: false);

    return Map.from(
      jsonDecode(result),
    );
  } catch (e) {
    //
    return {};
  }
}

Future<Map<String, dynamic>> updateOrderStatusRepository(
    {required Map<String, String> params}) async {
  try {
    final response = await sendApiRequest(
        apiName: ApiAndParams.apiUpdateOrderStatus,
        params: params,
        isPost: true);

    if (response == null) {
      throw Exception("Something went wrong");
    }

    return json.decode(response);
  } catch (e) {
    throw e;
  }
}

Future<Map<String, dynamic>> updateReturnOrderStatusRepository({required Map<String, String> params}) async {
  try {
    final response = await sendApiRequest(apiName: ApiAndParams.returnRequestStatusUpdateApi, params: params, isPost: true);

    if (response == null) {
      throw Exception("Something went wrong");
    }

    return json.decode(response);
  } catch (e) {
    throw e;
  }
}

Future<Map<String, dynamic>> updatePickupOrderStatusRepository({required Map<String, String> params}) async {
  try {
    final response = await sendApiRequest(apiName: ApiAndParams.apiUpdateSelfPickupStatus, params: params, isPost: true);

    if (response == null) {
      throw Exception("Something went wrong");
    }

    return json.decode(response);
  } catch (e) {
    throw e;
  }
}

Future<Map<String, dynamic>> updateOrdersDeliveryBoyRepository(
    {required Map<String, String> params}) async {
  try {
    final response = await sendApiRequest(
        apiName: ApiAndParams.apiUpdateOrderDeliveryBoy,
        params: params,
        isPost: true);

    if (response == null) {
      throw Exception("Something went wrong");
    }

    return json.decode(response);
  } catch (e) {
    throw e;
  }
}

Future<Map<String, dynamic>> getSellerOrderReturnRequestsRepository({
  required Map<String, String> params,
  required BuildContext context,
}) async {
  try {
    final result = await sendApiRequest(
      apiName: ApiAndParams.returnRequests,
      params: params,
      isPost: false,
    );

    return json.decode(result);
  } catch (e) {
    return {};
  }
}

Future<Map<String, dynamic>> getDeliveryBoyOrderReturnRequestsRepository({
  required Map<String, String> params,
  required BuildContext context,
}) async {
  try {
    final result = await sendApiRequest(
      apiName: ApiAndParams.returnRequests,
      params: params,
      isPost: false,
    );

    return json.decode(result);
  } catch (e) {
    return {};
  }
}

Future<Map<String, dynamic>> getSellerIssueReportReturnsRepository({
  required Map<String, String> params,
  required BuildContext context,
}) async {
  try {
    final result = await sendApiRequest(
      apiName: ApiAndParams.apiSellerIssueReportReturns,
      params: params,
      isPost: false,
    );

    return json.decode(result);
  } catch (e) {
    return {};
  }
}

Future<Map<String, dynamic>> updateSellerIssueReportReturnStatusRepository({
  required Map<String, String> params,
}) async {
  try {
    final response = await sendApiRequest(
      apiName: ApiAndParams.apiSellerIssueReportReturnsUpdateStatus,
      params: params,
      isPost: true,
    );

    if (response == null) {
      throw Exception("Something went wrong");
    }

    return json.decode(response);
  } catch (e) {
    throw e;
  }
}

Future<Map<String, dynamic>> getFAQInChat({
  required BuildContext context,
}) async {
  try {
    final result = await sendApiRequest(
      apiName: "https://wheat-rook-708688.hostingersite.com/api/seller/chatbot/questions",
      params: {},
      isPost: false,
    );

    return json.decode(result);
  } catch (e) {
    return {};
  }
}

Future<Map<String, dynamic>> sendChatMessageToBot({
  required String orderId,
  required String questionKey,
}) async {
  try {
    final response = await sendApiRequest(
      apiName: "https://wheat-rook-708688.hostingersite.com/api/seller/chatbot/answer",
      params: 
        {
        'order_id': orderId,
        'question': questionKey,
      },
      
      isPost: true,
    );

    if (response == null) {
      throw Exception("Something went wrong");
    }

    return json.decode(response);
  } catch (e) {
    throw e;
  }
}

Future<Map<String, dynamic>> sendNotificationToAdmin({
  required String message,
}) async {
  try {
    final response = await sendApiRequest(
      apiName: "https://wheat-rook-708688.hostingersite.com/api/seller/support-chat/send",
      params:
        {

        'message': message,
      },

      isPost: true,
    );

    if (response == null) {
      throw Exception("Something went wrong");
    }

    return json.decode(response);
  } catch (e) {
    throw e;
  }
}

Future<Map<String, dynamic>> sendChatMessageToAdminForOrder({
  required int orderId,
  required String message,
}) async {
  try {
    final response = await sendApiRequest(
      apiName: ApiAndParams.apiSupportChatOrderSend,
      params: {
        'order_id': orderId.toString(),
        'message': message,
      },
      isPost: true,
    );

    if (response == null) {
      throw Exception("Something went wrong");
    }

    return json.decode(response);
  } catch (e) {
    throw e;
  }
}

