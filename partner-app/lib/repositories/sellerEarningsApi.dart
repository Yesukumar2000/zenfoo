import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/generalMethods.dart' as GeneralMethods;
import 'package:project/models/order_earnings.dart';

Future<SellerEarningsResponse?> getSellerEarnings({
  required BuildContext context,
  String?
      status, // Optional status filter: 'delivered', 'cancelled', 'returned', etc.
}) async {
  try {
    // Build params with optional status filter
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }

    final result = await sendApiRequest(
      apiName: 'earnings',
      params: params,
      isPost: false,
    );

    final response = SellerEarningsResponse.fromJson(
      Map.from(jsonDecode(result)),
    );

    return response;
  } catch (e) {
    GeneralMethods.showMessage(
      context,
      e.toString(),
      MessageType.warning,
    );
    return null;
  }
}
