import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/generalMethods.dart' as GeneralMethods;

// New API: orders/status-tracking
Future<Map<String, dynamic>> getOrdersStatusTracking({
  required Map<String, String> params,
  required BuildContext context,
}) async {
  try {
    final result = await sendApiRequest(
      apiName: ApiAndParams.apiOrdersStatusTracking,
      params: params,
      isPost: false,
    );

    return Map.from(
      jsonDecode(result),
    );
  } catch (e) {
    GeneralMethods.showMessage(
      context,
      e.toString(),
      MessageType.warning,
    );
    return {};
  }
}

// Update prep time API
Future<Map<String, dynamic>> updatePrepTime({
  required int orderId,
  required List<dynamic> prepTime,
  required BuildContext context,
  int isPreparation = 1,
}) async {
  try {
    // Convert params to the format expected by the API
    final result = await sendApiRequest(
      apiName: 'orders/update-prep-time',
      params: {
        'order_id': orderId.toString(),
        'prep_time': jsonEncode(prepTime),
        'is_preparation': isPreparation.toString(),
      },
      isPost: true,
    );

    return Map.from(
      jsonDecode(result),
    );
  } catch (e) {
    GeneralMethods.showMessage(
      context,
      e.toString(),
      MessageType.warning,
    );
    return {};
  }
}

// Update tracking status API
Future<Map<String, dynamic>> updateTrackingStatus({
  required int orderId,
  required String status,
  required BuildContext context,
}) async {
  try {
    final result = await sendApiRequest(
      apiName: 'orders/update-tracking-status',
      params: {
        'order_id': orderId.toString(),
        'status': status,
      },
      isPost: true,
    );

    return Map.from(
      jsonDecode(result),
    );
  } catch (e) {
    GeneralMethods.showMessage(
      context,
      e.toString(),
      MessageType.warning,
    );
    return {};
  }
}

// Verify OTP and update status API
Future<Map<String, dynamic>> verifyOtpAndUpdateStatus({
  required int orderId,
  required String otp,
  required BuildContext context,
}) async {
  try {
    final result = await sendApiRequest(
      apiName: 'orders/verify-otp-update-status',
      params: {
        'order_id': orderId.toString(),
        'otp': otp,
      },
      isPost: true,
    );

    if (result == null) {
      return {
        'success': 0,
        'message': 'OTP verification failed. Please try again.'
      };
    }

    final decodedResponse = jsonDecode(result) as Map<String, dynamic>;
    return standardizeApiResponse(decodedResponse);
  } catch (e) {
    GeneralMethods.showMessage(
      context,
      e.toString(),
      MessageType.warning,
    );
    return {};
  }
}

// Get order invoice API
Future<Map<String, dynamic>> getOrderInvoice({
  required int orderId,
  required BuildContext context,
}) async {
  try {
    final result = await sendApiRequest(
      apiName: '${ApiAndParams.apiOrderInvoice}?order_id=$orderId',
      params: {},
      isPost: false,
    );

    if (result == null) {
      return {
        'status': 0,
        'message': 'Failed to fetch invoice'
      };
    }

    return Map.from(
      jsonDecode(result),
    );
  } catch (e) {
    GeneralMethods.showMessage(
      context,
      e.toString(),
      MessageType.warning,
    );
    return {
      'status': 0,
      'message': e.toString()
    };
  }
}

// Legacy API (kept for backward compatibility)
Future<Map<String, dynamic>> getNewOrdersRepository({
  required Map<String, String> params,
  required BuildContext context,
}) async {
  try {
    final result = await sendApiRequest(
      apiName: ApiAndParams.apiGetForSellerOrders,
      params: params,
      isPost: false,
    );

    return Map.from(
      jsonDecode(result),
    );
  } catch (e) {
    return {};
  }
}
