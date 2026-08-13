import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';

/* Future addOrUpdateProductApi(
    {required Map<String, String> params,
    required Map<String, File> filesMap,
    required BuildContext context,
    required bool isAdd,
    File? mainImage,
    List<File>? otherImage}) async {
  try {
    // var response = {};

    if (filesMap.isNotEmpty) {
      return json.decode(await sendApiMultiPartRequest(
        apiName: isAdd ? ApiAndParams.apiAddProduct : ApiAndParams.apiUpdateProduct,
        params: params,
        filesMap: filesMap,
      ));
    } else {
      return json.decode(await sendApiRequest(
        apiName: isAdd ? ApiAndParams.apiAddProduct : ApiAndParams.apiUpdateProduct,
        params: params,
        isPost: true,
      ));
    }

    // return response;
  } catch (e) {
    print("getResult:$e");
    rethrow;
  }
} */
Future<dynamic> addOrUpdateProductApi({
  required Map<String, String> params,
  required Map<String, File> filesMap,
  required BuildContext context,
  required bool isAdd,
  String? productId,
  File? mainImage,
  List<File>? otherImage,
  List<MapEntry<String, File>>? filesList,
}) async {
  try {
    dynamic response;

    // Determine API endpoint
    String apiEndpoint;
    if (isAdd) {
      apiEndpoint = 'post-product';
    } else {
      // For update, use the new endpoint with product_id in URL
      apiEndpoint = '${ApiAndParams.apiUpdateSingleProduct}/$productId';
    }

    if (filesMap.isNotEmpty || (filesList != null && filesList.isNotEmpty)) {
      response = await sendApiMultiPartRequest(
        apiName: apiEndpoint,
        params: params,
        filesMap: filesMap,
        filesList: filesList,
      );
    } else {
      response = await sendApiRequest(
        apiName: apiEndpoint,
        params: params,
        isPost: true,
      );
    }

    // Decode only if it's a String
    if (response is String) {
      return json.decode(response);
    } else if (response is Map) {
      return response; // Already decoded
    } else {
      throw Exception("Unsupported response type: ${response.runtimeType}");
    }
  } catch (e) {
    print("getResult: $e");
    rethrow;
  }
}

Future deleteProductApi({
  required String productId,
  required BuildContext context,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: 'delete-product/$productId',
      params: {},
      isPost: true,
    );

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future deleteVariantApi({
  required String variantId,
  required BuildContext context,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: 'delete-variant/$variantId',
      params: {},
      isPost: true,
    );

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future getProductById({
  required Map<String, String> params,
  required BuildContext context,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiGetProductProductById,
      params: params,
      isPost: false,
    );

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future getTagsApi({
  required Map<String, String> params,
  required BuildContext context,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiGetTags,
      params: params,
      isPost: false,
    );

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future isCancelableApi({
 
  required BuildContext context,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: "https://wheat-rook-708688.hostingersite.com/api/order_statuses/processing",
      params: {},
      isPost: false,
    );

    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}
