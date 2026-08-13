import 'package:project/helper/utils/generalImports.dart';

Future getProductListApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiProducts,
        params: params,
        isPost: true,
        context: context);

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future getProductDetailApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  try {
    var data = json.decode(await sendApiRequest(
        apiName: ApiAndParams.apiProductDetail,
        params: params,
        isPost: true,
        context: context));

    return data;
  } catch (e) {
    rethrow;
  }
}

Future addOrRemoveFavoriteApi(
    {required BuildContext context,
    required Map<String, dynamic> params,
    required isAdd}) async {
  try {
    var response = await sendApiRequest(
        apiName: isAdd
            ? ApiAndParams.apiAddProductToFavorite
            : ApiAndParams.apiRemoveProductFromFavorite,
        params: params,
        isPost: true,
        context: context);

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future getSimilarFromCartApi({
  required BuildContext context,
  required Map<String, dynamic> params,
}) async {
  try {
    debugPrint("=== SIMILAR FROM CART API REQUEST ===");
    debugPrint("Endpoint: ${ApiAndParams.apiSimilarFromCart}");
    debugPrint("Params: $params");

    var response = await sendApiRequest(
      apiName: ApiAndParams.apiSimilarFromCart,
      params: params,
      isPost: false,
      context: context,
    );

    debugPrint("=== SIMILAR FROM CART API RESPONSE ===");
    debugPrint("Raw response: $response");

    if (response == null) {
      debugPrint("SimilarFromCart: response is null");
      return {"status": 0, "message": "No response from server"};
    }

    final decoded = json.decode(response);
    debugPrint("SimilarFromCart decoded status: ${decoded['status']}");
    debugPrint("SimilarFromCart decoded data length: ${decoded['data']?.length}");
    return decoded;
  } catch (e, stackTrace) {
    debugPrint("SimilarFromCart API ERROR: $e");
    debugPrint("SimilarFromCart API STACK: $stackTrace");
    rethrow;
  }
}

Future getProductWishListApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiFavorite,
        params: params,
        isPost: false,
        context: context);

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}
