import 'package:project/helper/utils/generalImports.dart';

Future<Map<String, dynamic>> getCartListApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  var response = await sendApiRequest(
      apiName: ApiAndParams.apiCart,
      params: params,
      isPost: false,
      context: context);
  return json.decode(response);
}

Future<Map<String, dynamic>> getGuestCartListApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  var response = await sendApiRequest(
      apiName: ApiAndParams.apiGuestCart,
      params: params,
      isPost: false,
      context: context);
  return json.decode(response);
}

Future<Map<String, dynamic>> addItemToCartApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  var response = await sendApiRequest(
      apiName: ApiAndParams.apiCartAdd,
      params: params,
      isPost: true,
      context: context);
  return json.decode(response);
}

Future<Map<String, dynamic>> addGuestCartBulkToCartWhileLogin(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  var response = await sendApiRequest(
      apiName: ApiAndParams.apiGuestCartBulkAddToCartWhileLogin,
      params: params,
      isPost: true,
      context: context);
  return json.decode(response);
}

Future<Map<String, dynamic>> removeItemFromCartApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  var response = await sendApiRequest(
      apiName: ApiAndParams.apiCartRemove,
      params: params,
      isPost: true,
      context: context);

  return json.decode(response);
}

Future<Map<String, dynamic>> saveCartMetadataApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  // Convert nested maps to form-data array format that Laravel expects
  // seller_notes: {30: "note"} becomes seller_notes[30]: "note"
  Map<String, dynamic> processedParams = {};

  params.forEach((key, value) {
    if (value is Map) {
      // Convert nested map to flattened array notation for Laravel
      value.forEach((nestedKey, nestedValue) {
        processedParams['${key}[$nestedKey]'] = nestedValue;
      });
    } else {
      processedParams[key] = value;
    }
  });

  var response = await sendApiRequest(
      apiName: ApiAndParams.apiCartMetadataSave,
      params: processedParams,
      isPost: true,
      context: context);
  return json.decode(response);
}

Future<Map<String, dynamic>> getCartMetadataApi(
    {required BuildContext context}) async {
  var response = await sendApiRequest(
      apiName: ApiAndParams.apiCartMetadata,
      params: {},
      isPost: false,
      context: context);
  return json.decode(response);
}

Future<Map<String, dynamic>> clearCartMetadataApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  var response = await sendApiRequest(
      apiName: ApiAndParams.apiCartMetadataClear,
      params: params,
      isPost: true,
      context: context);
  return json.decode(response);
}

Future<Map<String, dynamic>> removePromocodeApi(
    {required BuildContext context}) async {
  var response = await sendApiRequest(
      apiName: ApiAndParams.apiCartRemovePromocode,
      params: {},
      isPost: true,
      context: context);
  return json.decode(response);
}
