import 'package:project/helper/utils/generalImports.dart';

Future getCategoryList(
    {required BuildContext context,
    required Map<String, String> params}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiCategories,
        params: params,
        isPost: false,
        context: context);
    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>> getSubCategoriesAndProductsApi({
  required BuildContext context,
  required int subCategoryGroupsId,
  required double latitude,
  required double longitude,
  int limit = 16,
  int offset = 0,
}) async {
  var params = {
    "sub_category_groups_id": subCategoryGroupsId,
    "latitude": latitude,
    "longitude": longitude,
    "limit": limit,
    "offset": offset,
  };
  var response = await sendApiRequest(
    apiName: "products/group-products",
    params: params,
    isPost: false,
    context: context,
  );
  return json.decode(response);
}

Future<Map<String, dynamic>> getProductsApi({
  required BuildContext context,
  required int categoryId,
  required double latitude,
  required double longitude,
  int limit = 16,
  int offset = 0,
  String? sort,
  String? brandIds,
  String? sizes,
  String? unitIds,
  int? minPrice,
  int? maxPrice,
  String? categoryIds,
}) async {
  Map<String, dynamic> params = {
    "category_id": categoryId,
    "latitude": latitude,
    "longitude": longitude,
    "limit": limit,
    "offset": offset,
  };

  // Add optional filter parameters
  if (sort != null) params["sort"] = sort;
  if (brandIds != null && brandIds.isNotEmpty) params["brand_ids"] = brandIds;
  if (sizes != null && sizes.isNotEmpty) params["sizes"] = sizes;
  if (unitIds != null && unitIds.isNotEmpty) params["unit_ids"] = unitIds;
  if (minPrice != null) params["min_price"] = minPrice;
  if (maxPrice != null) params["max_price"] = maxPrice;
  if (categoryIds != null && categoryIds.isNotEmpty)
    params["category_ids"] = categoryIds;

  var response = await sendApiRequest(
    apiName: "products",
    params: params,
    isPost: true,
    context: context,
  );
  return json.decode(response);
}
