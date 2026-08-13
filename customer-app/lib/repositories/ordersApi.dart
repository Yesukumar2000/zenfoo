import 'package:project/helper/utils/generalImports.dart';

Future<Map<String, dynamic>> fetchOrders(
    {required Map<String, String> params,
    required BuildContext context}) async {
  final response = await sendApiRequest(
      apiName: ApiAndParams.apiOrdersHistory,
      params: params,
      isPost: false,
      context: context);
  // === DEBUG: raw orders response ===
  debugPrint('🟣 [ORDERS RAW] ' + response);
  try {
    final decoded = json.decode(response);
    debugPrint('🟣 [ORDERS DECODED keys] ' + decoded.keys.toList().toString());
    if (decoded is Map && decoded['data'] is List) {
      final list = decoded['data'] as List;
      debugPrint('🟣 [ORDERS] data length = ' + list.length.toString());
      for (var i = 0; i < list.length; i++) {
        final o = list[i];
        debugPrint('🟣 [ORDERS][$i] keys = ' + (o is Map ? o.keys.toList().toString() : o.runtimeType.toString()));
        if (o is Map && o['sellers'] is List) {
          final sellers = o['sellers'] as List;
          for (var j = 0; j < sellers.length; j++) {
            final s = sellers[j];
            debugPrint('🟣 [ORDERS][$i].sellers[$j] = ' + s.toString());
          }
        }
      }
    }
    return decoded;
  } catch (e, st) {
    debugPrint('🔴 [ORDERS DECODE ERR] $e');
    debugPrint('🔴 [ORDERS STACK] $st');
    rethrow;
  }
}

Future<Map<String, dynamic>> updateOrderStatus(
    {required Map<String, String> params,
    required BuildContext context}) async {
  final response = await sendApiRequest(
      apiName: ApiAndParams.apiUpdateOrderStatus,
      params: params,
      isPost: true,
      context: context);

  return json.decode(response);
}

Future deleteAwaitingOrderApi(
    {required Map<String, String> params,
    required BuildContext context}) async {
  final response = await sendApiRequest(
      apiName: ApiAndParams.apiDeleteOrder,
      params: params,
      isPost: true,
      context: context);

  return json.decode(response);
}

Future<Map<String, dynamic>> cancelOrderApi(
    {required Map<String, String> params,
    required BuildContext context}) async {
  final response = await sendApiRequest(
      apiName: ApiAndParams.apiCancelOrder,
      params: params,
      isPost: true,
      context: context);

  return json.decode(response);
}

Future<Map<String, dynamic>> fetchRatings(
    {required Map<String, String> params,
    required BuildContext context}) async {
  final response = await sendApiRequest(
      apiName: ApiAndParams.apiRatingsList,
      params: params,
      isPost: false,
      context: context);

  return json.decode(response);
}

Future<Map<String, dynamic>> submitRating({
  required Map<String, String> params,
  required List<String> fileParamsNames,
  required List<String> fileParamsFilesPath,
  required BuildContext context,
}) async {
  final response = await sendApiMultiPartRequest(
    apiName: ApiAndParams.apiRatingAdd,
    params: params,
    fileParamsFilesPath: fileParamsFilesPath,
    fileParamsNames: fileParamsNames,
    context: context,
  );

  return json.decode(response);
}

Future<Map<String, dynamic>> ratingProduct({
  required int orderId,
  required int productId,
  required int rating,
  String? review,
  required BuildContext context,
}) async {
  final Map<String, dynamic> params = {
    "order_id": orderId.toString(),
    "type": "product",
    "product_id": productId.toString(),
    "rating": rating.toString(),
    "review": review ?? "",
  };

  final response = await sendApiRequest(
    apiName: ApiAndParams.apiSubmitRating,
    params: params,
    isPost: true,
    context: context,
  );

  return json.decode(response);
}

Future<Map<String, dynamic>> ratingDriver({
  required int orderId,
  required int rating,
  String? review,
  required BuildContext context,
}) async {
  final Map<String, dynamic> params = {
    "order_id": orderId.toString(),
    "type": "driver",
    "rating": rating.toString(),
    "review": review ?? "",
  };

  final response = await sendApiRequest(
    apiName: ApiAndParams.apiSubmitRating,
    params: params,
    isPost: true,
    context: context,
  );

  return json.decode(response);
}

Future<Map<String, dynamic>> ratingSeller({
  required int orderId,
  required int storeId,
  required int rating,
  String? review,
  required BuildContext context,
}) async {
  final Map<String, dynamic> params = {
    "order_id": orderId.toString(),
    "type": "seller",
    "store_id": storeId.toString(),
    "rating": rating.toString(),
    "review": review ?? "",
  };

  final response = await sendApiRequest(
    apiName: ApiAndParams.apiSubmitRating,
    params: params,
    isPost: true,
    context: context,
  );

  return json.decode(response);
}

Future<Map<String, dynamic>> orderTrackingBanners(
    {required BuildContext context}) async {
  final response = await sendApiRequest(
      apiName: ApiAndParams.apiPromotionalBanners,
      params: {},
      isPost: false,
      context: context);

  return json.decode(response);
}

Future<Map<String, dynamic>> ratingApi(
    {required int orderId, required BuildContext context}) async {
  final response = await sendApiRequest(
      apiName: "${ApiAndParams.apiOrderRatings}?order_id=$orderId",
      params: {},
      isPost: false,
      context: context);

  return json.decode(response);
}

Future<Map<String, dynamic>> fetchBikeAnimation(
    {required BuildContext context}) async {
  final response = await sendApiRequest(
      apiName: "${ApiAndParams.apiAppMedia}?type=bike_animation",
      params: {},
      isPost: false,
      context: context);

  return json.decode(response);
}

Future<Map<String, dynamic>> fetchAppMedia(
    {required BuildContext context, required String type}) async {
  final response = await sendApiRequest(
      apiName: "${ApiAndParams.apiAppMedia}?type=$type",
      params: {},
      isPost: false,
      context: context);

  return json.decode(response);
}
