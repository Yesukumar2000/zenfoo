import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_by_admin.dart';
import 'package:project/models/category_products_by_admin.dart';

Future<Map<String, dynamic>> getCategoryListRepository(
    {required Map<String, dynamic> params}) async {
  var response = await sendApiRequest(
      apiName: /* ApiAndParams.apiMainCategories */ ApiAndParams.apiSellerCategoriesList, params: params, isPost: false);

  return json.decode(response);
}

/// Get store categories (for admin-managed stores)
/// API: store-categories
Future<CategoryByAdmin?> getStoreCategoriesApi({
  required BuildContext context,
}) async {
  try {
    final response = await sendApiRequest(
      apiName: 'store-categories',
      params: {},
      isPost: false,
    );

    return CategoryByAdmin.fromJson(json.decode(response));
  } catch (e) {
    if (context.mounted) {
      showMessage(
        context,
        'Error fetching categories: $e',
        MessageType.error,
      );
    }
    return null;
  }
}

Future<Map<String, dynamic>> getMainCategoryListRepository() async {
  var response = await sendApiRequest(
      apiName: ApiAndParams.apiCategories,
      params: {ApiAndParams.sellerId: Constant.session.getData("id")},
      isPost: false);

  return json.decode(response);
}

/// Add or update seller category
/// API: store-seller-sweet-house-category
/// Requires: name, subtitle, image (File), types (List<String>)
Future<dynamic> addOrUpdateCategoryApi({
  required Map<String, String> params,
  File? imageFile,
  List<String>? types,
  bool isAdd = true,
  String? categoryId,
}) async {
  try {
    dynamic response;

    // Determine API endpoint
    String apiEndpoint;
    if (isAdd) {
      apiEndpoint = 'store-seller-sweet-house-category';
    } else {
      // For update, append category ID
      apiEndpoint = 'update-seller-sweet-house-category/$categoryId';
    }

    // Add types to params if provided
    Map<String, String> finalParams = Map.from(params);
    if (types != null && types.isNotEmpty) {
      for (int i = 0; i < types.length; i++) {
        finalParams['types[$i]'] = types[i];
      }
    }

    // If image file is provided, use multipart request
    if (imageFile != null) {
      Map<String, File> filesMap = {'image': imageFile};

      response = await sendApiMultiPartRequest(
        apiName: apiEndpoint,
        params: finalParams,
        filesMap: filesMap,
      );
    } else {
      // Without image, use regular POST request
      response = await sendApiRequest(
        apiName: apiEndpoint,
        params: finalParams,
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
    print("addOrUpdateCategoryApi error: $e");
    rethrow;
  }
}

/// Delete seller category
Future<dynamic> deleteCategoryApi({
  required String categoryId,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: 'delete-seller-sweet-house-category/$categoryId',
      params: {},
      isPost: false,
      isDelete: true,
    );

    return json.decode(response);
  } catch (e) {
    print("deleteCategoryApi error: $e");
    rethrow;
  }
}

/// Get seller categories list
Future<dynamic> getSellerCategoriesApi({
  Map<String, String>? params,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: 'get-seller-sweet-house-category',
      params: params ?? {},
      isPost: false,
    );

    return json.decode(response);
  } catch (e) {
    print("getSellerCategoriesApi error: $e");
    rethrow;
  }
}

/// Add category type
/// API: seller/store-category-type (POST)
/// Requires: name, category_id
Future<dynamic> addCategoryTypeApi({
  required String name,
  required String categoryId,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: 'store-category-type',
      params: {
        'name': name,
        'category_id': categoryId,
      },
      isPost: true,
    );

    return json.decode(response);
  } catch (e) {
    print("addCategoryTypeApi error: $e");
    rethrow;
  }
}

/// Update category type
/// API: category-types/{typeId} (PUT)
/// Requires: name, category_id
Future<dynamic> updateCategoryTypeApi({
  required String typeId,
  required String name,
  required String categoryId,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: 'category-types/$typeId',
      params: {
        'name': name,
        'category_id': categoryId,
        '_method': 'PUT', // Laravel method spoofing for PUT request
      },
      isPost: true,
    );

    return json.decode(response);
  } catch (e) {
    print("updateCategoryTypeApi error: $e");
    rethrow;
  }
}

/// Delete category type
/// API: category-types/{typeId} (DELETE)
Future<dynamic> deleteCategoryTypeApi({
  required String typeId,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: 'category-types/$typeId',
      params: {},
      isPost: false,
      isDelete: true,
    );

    return json.decode(response);
  } catch (e) {
    print("deleteCategoryTypeApi error: $e");
    rethrow;
  }
}

/// Get products by category
/// API: products-by-category?category_id={categoryId}
Future<CategoryProductsByAdmin?> getProductsByCategoryApi({
  required BuildContext context,
  required int categoryId,
}) async {
  try {
    final response = await sendApiRequest(
      apiName: 'products-by-category',
      params: {
        'category_id': categoryId.toString(),
      },
      isPost: false,
    );

    return CategoryProductsByAdmin.fromJson(json.decode(response));
  } catch (e) {
    if (context.mounted) {
      showMessage(
        context,
        'Error fetching products: $e',
        MessageType.error,
      );
    }
    return null;
  }
}
