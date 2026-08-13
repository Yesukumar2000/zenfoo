import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';

Future getProductListApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiProducts,
      params: params,
      isPost: false,
    );

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future getProductFilterByListApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiFilterByProduct,
      params: params,
      isPost: false,
    );

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future getProductVariantsApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiGetProductVariants,
      params: params,
      isPost: false,
    );

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future getUpdateProductStockApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiUpdateVariantStock,
      params: params,
      isPost: true,
    );

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future getSellerProductsApi({
  required BuildContext context,
  required Map<String, dynamic> params,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiGetProductsSeller,
      params: params,
      isPost: false,
    );

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future getSingleSellerProductApi({
  required BuildContext context,
  required String productId,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: "${ApiAndParams.apiGetSingleProductSeller}/$productId",
      params: {},
      isPost: false,
    );

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}
