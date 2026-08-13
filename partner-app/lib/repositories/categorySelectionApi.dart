import 'package:project/helper/utils/generalImports.dart';

// Get category groups based on store
Future<Map<String, dynamic>> getCategoryGroupsRepository({
  required String storeId,
  String? search,
  int page = 1,
  int perPage = 20,
}) async {
  var params = {
    'store_id': storeId,
    'per_page': perPage.toString(),
    'page': page.toString(),
    if (search != null && search.isNotEmpty) 'search': search,
  };

  var response = await sendApiRequest(
    apiName: 'get-categories-by-seller-token',
    params: params,
    isPost: false,
  );

  return json.decode(response);
}

// Get categories based on category group selection
Future<Map<String, dynamic>> getCategoriesByGroupRepository({
  required int categoryGroupId,
  String? search,
  int page = 1,
  int perPage = 20,
}) async {
  var params = {
    'category_group_id': categoryGroupId,
    'per_page': perPage,
    'page': page,
    if (search != null && search.isNotEmpty) 'search': search,
  };

  var response = await sendApiRequest(
    apiName: 'get-data-based-on-category-selection',
    params: params,
    isPost: false,
  );

  return json.decode(response);
}

// Get subcategories based on sub-category group selection
Future<Map<String, dynamic>> getSubCategoriesByGroupRepository({
  required int subCategoryGroupId,
  String? search,
  int page = 1,
  int perPage = 20,
}) async {
  var params = {
    'sub_category_group_id': subCategoryGroupId,
    'per_page': perPage,
    'page': page,
    if (search != null && search.isNotEmpty) 'search': search,
  };

  var response = await sendApiRequest(
    apiName: 'get-data-based-on-sub-category-selection',
    params: params,
    isPost: false,
  );

  return json.decode(response);
}

// Get category types based on category selection
Future<Map<String, dynamic>> getCategoryTypesRepository({
  required String categoryId,
  String? search,
  int page = 1,
  int perPage = 20,
}) async {
  var params = {
    'category_id': categoryId,
    'per_page': perPage.toString(),
    'page': page.toString(),
    if (search != null && search.isNotEmpty) 'search': search,
  };

  var response = await sendApiRequest(
    apiName: 'category-types',
    params: params,
    isPost: false,
  );

  return json.decode(response);
}

// Get all brands
Future<Map<String, dynamic>> getAllBrandsRepository({
  String? search,
  int page = 1,
  int perPage = 20,
  int? categoryId,
}) async {
  var params = {
    'per_page': perPage.toString(),
    'page': page.toString(),
    if (search != null && search.isNotEmpty) 'search': search,
    if (categoryId != null) 'category_id': categoryId,
  };

  var response = await sendApiRequest(
    apiName: 'get-all-brands',
    params: params,
    isPost: false,
  );

  return json.decode(response);
}

// Get all units
Future<Map<String, dynamic>> getAllUnitsRepository({
  String? search,
  int page = 1,
  int perPage = 20,
}) async {
  var params = {
    'per_page': perPage.toString(),
    'page': page.toString(),
    if (search != null && search.isNotEmpty) 'search': search,
  };

  var response = await sendApiRequest(
    apiName: 'get-all-units',
    params: params,
    isPost: false,
  );

  return json.decode(response);
}
