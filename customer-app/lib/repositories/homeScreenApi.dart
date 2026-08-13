import 'dart:developer' as dev;

import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_groups.dart';
import 'package:project/models/seller_category_tree.dart';
import 'package:project/models/store_with_category_group.dart';
import 'package:project/models/category_filter_models.dart';
import 'package:project/models/combo.dart';
import 'package:project/models/combo_models.dart';
import 'package:project/models/seller_product_list.dart';
import 'package:project/models/sweetshop_products.dart';
import 'package:project/models/bookmarkTab.dart';

class CategoryPageData {
  final List<StoreWithCategoryGroups> stores;
  final List<BannerItem> banners;

  CategoryPageData({required this.stores, required this.banners});
}

Future getHomeScreenDataApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  var response = await sendApiRequest(
      apiName: ApiAndParams.apiShop,
      params: params,
      isPost: false,
      context: context);

  return json.decode(response);
}

Future getHomeCategories(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  var response = await sendApiRequest(
    apiName: ApiAndParams.apiHomeCategories,
    params: params,
    isPost: false,
    context: context,
  );

  return json.decode(response);
}

Future<List<CategoryGroup>> fetchCategoryGroups(BuildContext context) async {
  final res = await sendApiRequest(
    apiName: "home-data",
    isPost: false,
    context: context,
    params: {},
  );
  if (res != null) {
    final decoded = json.decode(res);
    if (decoded['status'] == 1 && decoded['data'] is List) {
      return (decoded['data'] as List)
          .map((e) => CategoryGroup.fromJson(e))
          .toList();
    }
  }
  return [];
}

Future<List<ProductData>> getGroupProductsApi({
  required BuildContext context,
  required int categoryGroupId,
  double latitude = 0,
  double longitude = 0,
  int limit = 4,
  int offset = 0,
  int page = 1,
}) async {
  final Map<String, dynamic> params = {
    "latitude": latitude.toStringAsFixed(4),
    "longitude": longitude.toStringAsFixed(4),
    "limit": limit.toString(),
    "offset": offset.toString(),
    "category_groups_id": categoryGroupId.toString(),
    "page": page.toString(),
  };

  final res = await sendApiRequest(
    apiName: "products/group-products",
    isPost: false,
    context: context,
    params: params,
  );

  if (res != null) {
    final decoded = json.decode(res);
    if (decoded['status'] == 1 && decoded['data'] is List) {
      return (decoded['data'] as List)
          .map((e) => ProductData.fromJson(e))
          .toList();
    }
  }
  return [];
}

Future<List<CategoryGroup>> fetchStoreGroups(BuildContext context) async {
  final res = await sendApiRequest(
    apiName: "stores",
    isPost: false,
    context: context,
    params: {},
  );
  if (res != null) {
    final decoded = json.decode(res);
    if (decoded['status'] == 1 && decoded['data'] is List) {
      final all = CategoryGroup(
        id: 0,
        name: 'All',
        icon: '',
        color: "#9AC444",
        iconUrl: '',
      );
      return [
        all,
        ...((decoded['data'] as List)
            .map((e) => CategoryGroup.fromJson(e))
            .where((g) => g.id != 17)
            .toList()),
      ];
    }
  }
  return [];
}

Future<CategoryPageData?> fetchStoreWithCategoryGroups({
  String? storeId,
  required BuildContext context,
  String? sortBy,
  String? categoryId,
  String? foodType,
}) async {
  // Get latitude and longitude from session
  final latitude =
      Constant.session.getData(SessionManager.keyLatitude, defaultValue: "0.0");
  final longitude = Constant.session
      .getData(SessionManager.keyLongitude, defaultValue: "0.0");

  final Map<String, dynamic> params = {
    'lat': latitude,
    'lon': longitude,
    'sort_by': sortBy ?? 'name',
  };
  if (categoryId != null) {
    params['category_id'] = categoryId;
  }
  if (foodType != null) {
    params['food_type'] = foodType;
  }
  print('+++++ api name is +++++');
  print((storeId != null ? "cat_store/$storeId" : "cat_store").toString());
  final res = await sendApiRequest(
    apiName: storeId != null ? "cat_store/$storeId" : "cat_store",
    isPost: false,
    context: context,
    params: params,
  );
  if (res != null) {
    final decoded = json.decode(res);
    if (decoded['status'] == 1) {
      List<StoreWithCategoryGroups> stores = [];
      if (decoded['data'] is List) {
        stores = (decoded['data'] as List<dynamic>)
            .map((e) => StoreWithCategoryGroups.fromJson(e))
            .toList();
      }
      debugPrint('+++++++++debug slider+++++++++');
      debugPrint(decoded['sliders'].toString());
      List<BannerItem> banners = [];
      if (decoded['sliders'] != null && decoded['sliders'] is List) {
        banners = (decoded['sliders'] as List<dynamic>)
            .map((e) => BannerItem.fromJson(e))
            .toList();
      }

      if (stores.isNotEmpty) {
        return CategoryPageData(stores: stores, banners: banners);
      }
    }
  }
  return null;
}

Future<List<Combo>> fetchCombosHomePage({
  required BuildContext context,
  int? storeId,
}) async {
  final res = await sendApiRequest(
    apiName: storeId != null
        ? "combos_home_page?store_id=$storeId"
        : "combos_home_page",
    isPost: false,
    context: context,
    params: {},
  );

  if (res != null) {
    final decoded = json.decode(res);
    if (decoded['status'] == 1 && decoded['data'] is List) {
      return (decoded['data'] as List).map((e) => Combo.fromJson(e)).toList();
    }
  }
  return [];
}

Future<CombosPageData?> fetchCombosBasedOnCategoryType({
  required BuildContext context,
  String? comboTypeId,
  double? fromPrice,
  double? toPrice,
  int? fromCount,
  int? toCount,
  String? filter,
  String? search,
}) async {
  final Map<String, dynamic> params = {};
  if (comboTypeId != null) params['combo_type_id'] = comboTypeId;
  if (fromPrice != null) params['from_price'] = fromPrice.toString();
  if (toPrice != null) params['to_price'] = toPrice.toString();
  if (fromCount != null) params['from_count'] = fromCount.toString();
  if (toCount != null) params['to_count'] = toCount.toString();
  if (filter != null) params['filter'] = filter;
  if (search != null) params['search'] = search;

  final res = await sendApiRequest(
    apiName: "combos_based_on_category_type",
    isPost: false,
    context: context,
    params: params,
  );

  if (res != null) {
    final decoded = json.decode(res);
    if (decoded['status'] == 1) {
      return CombosPageData.fromJson(decoded);
    }
  }
  return null;
}

Future<Combo?> fetchComboDetails({
  required BuildContext context,
  required int comboId,
}) async {
  final res = await sendApiRequest(
    apiName: "combo_details?combo_id=$comboId",
    isPost: false,
    context: context,
    params: {},
  );

  if (res != null) {
    var decoded = json.decode(res);
    if (decoded['status'] == 1) {
      return Combo.fromJson(decoded['data']);
    }
  }
  return null;
}

// ======================== COMBO CART APIs ========================

/// Store custom combo cart with multiple products
/// POST: store_custom_combo_cart
/// Format: combo_id=1&products[0][product_id]=12&products[0][variant_id]=29&products[0][quantity]=1
Future<Map<String, dynamic>?> storeCustomComboCart({
  required BuildContext context,
  required int comboId,
  required List<Map<String, dynamic>> products,
}) async {
  // Build query parameters in array format
  final Map<String, dynamic> params = {
    "combo_id": comboId.toString(),
  };

  // Add products as indexed array parameters
  for (int i = 0; i < products.length; i++) {
    params["products[$i][product_id]"] = products[i]["product_id"].toString();
    params["products[$i][variant_id]"] = products[i]["variant_id"].toString();
    params["products[$i][quantity]"] = products[i]["quantity"].toString();
  }

  dev.log('Store Custom Combo Cart - Params: ${json.encode(params)}');

  final res = await sendApiRequest(
    apiName: "store_custom_combo_cart",
    isPost: true,
    context: context,
    params: params,
    returnErrorResponse: true,
  );

  if (res != null) {
    final decoded = json.decode(res);
    dev.log('Store Custom Combo Cart - Response: ${json.encode(decoded)}');

    final message = decoded['message']?.toString() ??
        (decoded.containsKey('pre_order_conflict')
            ? 'You have a preorder item in cart. Adding this will clear it.'
            : decoded.containsKey('combo_conflict')
                ? 'You have a combo item in cart. Adding this will clear it.'
                : 'An error occurred');

    if (decoded['status'] == 1) {
      return decoded;
    } else {
      // Return decoded response so provider can handle conflicts
      // Check both top-level and inside 'data' for conflict keys
      final responseData = decoded['data'];
      final hasConflictInData = responseData is Map &&
          (responseData.containsKey('pre_order_conflict') ||
              responseData.containsKey('combo_conflict'));
      final hasConflictTopLevel = decoded.containsKey('pre_order_conflict') ||
          decoded.containsKey('combo_conflict');

      if (hasConflictInData || hasConflictTopLevel) {
        return decoded;
      }
      // Show error for non-conflict errors
      if (message.isNotEmpty) {
        showMessage(context, message, MessageType.error);
      }
    }
  }
  return null;
}

/// Add or edit a single product in custom combo
/// POST: product_add_or_edit_custom_combo
Future<Map<String, dynamic>?> addOrEditCustomComboProduct({
  required BuildContext context,
  required int comboId,
  required int productId,
  required int variantId,
  required int quantity,
}) async {
  final Map<String, dynamic> params = {
    "combo_id": comboId.toString(),
    "product_id": productId.toString(),
    "variant_id": variantId.toString(),
    "quantity": quantity.toString(),
  };

  dev.log('Add/Edit Custom Combo Product - Params: ${json.encode(params)}');

  final res = await sendApiRequest(
    apiName: "product_add_or_edit_custom_combo",
    isPost: true,
    context: context,
    params: params,
    returnErrorResponse: true,
  );

  if (res != null) {
    final decoded = json.decode(res);
    dev.log(
        'Add/Edit Custom Combo Product - Response: ${json.encode(decoded)}');

    if (decoded['status'] == 1) {
      return decoded;
    } else {
      if (decoded['message'] != null) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(decoded['message'].toString()),
              backgroundColor: ColorsRes.appColorRed,
            ),
          );
      }
    }
  }
  return null;
}

/// Delete entire custom combo from cart
/// DELETE: delete_custom_combo_cart
Future<Map<String, dynamic>?> deleteCustomComboCart({
  required BuildContext context,
  required int comboId,
}) async {
  final Map<String, dynamic> params = {
    "combo_id": comboId.toString(),
  };

  dev.log('Delete Custom Combo Cart - Params: ${json.encode(params)}');

  final res = await sendApiRequest(
    apiName: "delete_custom_combo_cart",
    isPost: false,
    isDelete: true, // ✅ Use DELETE method
    context: context,
    params: params,
  );

  if (res != null) {
    final decoded = json.decode(res);
    dev.log('Delete Custom Combo Cart - Response: ${json.encode(decoded)}');

    if (decoded['status'] == 1) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? 'Combo removed from cart'),
            backgroundColor: ColorsRes.appColorGreen,
          ),
        );
      return decoded;
    } else {
      if (decoded['message'] != null) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(decoded['message'].toString()),
              backgroundColor: ColorsRes.appColorRed,
            ),
          );
      }
    }
  }
  return null;
}

/// Delete single product from custom combo
/// DELETE: delete_single_custom_product
Future<Map<String, dynamic>?> deleteSingleCustomProduct({
  required BuildContext context,
  required int comboId,
  required int productId,
}) async {
  final Map<String, dynamic> params = {
    "combo_id": comboId.toString(),
    "product_id": productId.toString(),
  };

  dev.log('Delete Single Custom Product - Params: ${json.encode(params)}');

  final res = await sendApiRequest(
    apiName: "delete_single_custom_product",
    isPost: false,
    isDelete: true, // ✅ Use DELETE method
    context: context,
    params: params,
  );

  if (res != null) {
    final decoded = json.decode(res);
    dev.log('Delete Single Custom Product - Response: ${json.encode(decoded)}');

    if (decoded['status'] == 1) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? 'Product removed from combo'),
            backgroundColor: ColorsRes.appColorGreen,
          ),
        );
      return decoded;
    } else {
      if (decoded['message'] != null) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(decoded['message'].toString()),
              backgroundColor: ColorsRes.appColorRed,
            ),
          );
      }
    }
  }
  return null;
}

/// Get custom combo cart details
/// GET: get_custom_combo_cart
Future<Map<String, dynamic>?> getCustomComboCart({
  required BuildContext context,
  int? comboId,
}) async {
  final Map<String, dynamic> params = {};
  if (comboId != null) params['combo_id'] = comboId.toString();

  final res = await sendApiRequest(
    apiName: "get_custom_combo_cart",
    isPost: false,
    context: context,
    params: params,
  );

  if (res != null) {
    final decoded = json.decode(res);
    if (decoded['status'] == 1) {
      return decoded;
    }
  }
  return null;
}

// Fetch supermart sellers with pagination
Future<SupermartSellersResponse?> fetchSupermartSellers(
  BuildContext context, {
  int perPage = 20,
  int page = 1,
  int? sellerId,
}) async {
  // Get latitude and longitude from session
  final latitude =
      Constant.session.getData(SessionManager.keyLatitude, defaultValue: "0.0");
  final longitude = Constant.session
      .getData(SessionManager.keyLongitude, defaultValue: "0.0");

  final Map<String, dynamic> params = {
    'lat': latitude,
    'lon': longitude,
    'per_page': perPage.toString(),
    'page': page.toString(),
    if (sellerId != null) 'seller_id': sellerId.toString(),
  };

  final res = await sendApiRequest(
    apiName: "supermart-sellers",
    isPost: false,
    context: context,
    params: params,
  );

  if (res != null) {
    final decoded = json.decode(res);
    if (decoded['status'] == 1) {
      return SupermartSellersResponse.fromJson(decoded);
    }
  }
  return null;
}

// Fetch seller full category tree (groups → sub-groups → flat categories)
Future<SellerCategoryTree?> fetchSellerCategoryTree(
  BuildContext context, {
  required int sellerId,
}) async {
  final res = await sendApiRequest(
    apiName: "seller-category-tree",
    isPost: false,
    context: context,
    params: {'seller_id': sellerId.toString()},
  );

  if (res != null) {
    final decoded = json.decode(res);
    if (decoded['status'] == 1 && decoded['data'] is Map) {
      return SellerCategoryTree.fromJson(decoded['data'] as Map<String, dynamic>);
    }
  }
  return null;
}

// Fetch seller category groups for supermart detail screen
Future<List<CategoryGroup>> fetchSellerCategoryGroups(
  BuildContext context, {
  required int sellerId,
}) async {
  print('🌐 API - Fetching seller category groups for seller_id: $sellerId');

  final res = await sendApiRequest(
    apiName: "seller-category-groups",
    isPost: false,
    context: context,
    params: {'seller_id': sellerId.toString()},
  );

  if (res != null) {
    final decoded = json.decode(res);
    print(
        '📡 API Response - Status: ${decoded['status']}, Data type: ${decoded['data'].runtimeType}');

    if (decoded['status'] == 1 && decoded['data'] is Map) {
      final data = decoded['data'] as Map<String, dynamic>;
      final List<CategoryGroup> groups = [];

      if (data['category_groups'] is List) {
        groups.addAll((data['category_groups'] as List)
            .map((e) => CategoryGroup.fromJson(e)));
      }

      // Also parse flat categories (returned when no category_groups exist)
      if (data['categories'] is List) {
        groups.addAll((data['categories'] as List)
            .map((e) => CategoryGroup.fromJson(e)));
      }

      print('✅ API - Parsed ${groups.length} category groups');
      return groups;
    } else {
      print('⚠️ API - Invalid response structure or status != 1');
    }
  } else {
    print('❌ API - Response is null');
  }
  return [];
}

// Fetch seller product lists for supermart detail screen Explore tab
Future<SellerProductListsResponse?> fetchSellerProductLists(
  BuildContext context, {
  required int sellerId,
}) async {
  final res = await sendApiRequest(
    apiName: "supermart-product-lists",
    isPost: false,
    context: context,
    params: {'seller_id': sellerId.toString(), 'limit_per_list': '15'},
  );

  if (res != null) {
    final decoded = json.decode(res);
    if (decoded['status'] == 1) {
      return SellerProductListsResponse.fromJson(decoded);
    }
  }
  return null;
}

// Fetch sweetshop products by category with types
Future<SweetshopProductsResponse?> fetchSweetshopProducts(
  BuildContext context, {
  required int sellerId,
  String? sortBy,
  List<int>? categoryIds,
  String? searchQuery,
  String? foodType,
}) async {
  final params = {'seller_id': sellerId.toString()};
  if (sortBy != null && sortBy.isNotEmpty) {
    params['sort_by'] = sortBy;
  }
  if (categoryIds != null && categoryIds.isNotEmpty) {
    params['category_id'] = categoryIds.join(',');
  }
  if (searchQuery != null && searchQuery.isNotEmpty) {
    params['search'] = searchQuery;
  }
  if (foodType != null && foodType.isNotEmpty) {
    params['food_type'] = foodType;
  }
  //include user_lat and user_lon
  final latitude =
      Constant.session.getData(SessionManager.keyLatitude, defaultValue: "0.0");
  final longitude = Constant.session
      .getData(SessionManager.keyLongitude, defaultValue: "0.0");
  params['user_lat'] = latitude;
  params['user_lon'] = longitude;

  final res = await sendApiRequest(
    apiName: "sweetshop/products-by-category",
    isPost: false,
    context: context,
    params: params,
  );

  if (res != null) {
    final decoded = json.decode(res);
    if (decoded['status'] == 1) {
      return SweetshopProductsResponse.fromJson(decoded);
    }
  }
  return null;
}

// Fetch weather
Future<Map<String, dynamic>?> fetchWeather(BuildContext context) async {
  final latitude = double.tryParse(Constant.session
          .getData(SessionManager.keyLatitude, defaultValue: "0.0")) ??
      0.0;

  final longitude = double.tryParse(Constant.session
          .getData(SessionManager.keyLongitude, defaultValue: "0.0")) ??
      0.0;

  final String url =
      "https://wheat-rook-708688.hostingersite.com/api/weather/rain-check";

  final res = await sendApiRequest(
    apiName: url,
    isPost: true,
    context: context,
    params: {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
    },
  );

  if (res != null) {
    try {
      final decoded = json.decode(res);

      return decoded;
    } catch (e) {
      return null;
    }
  }
  return null;
}

/// Toggle combo bookmark status via API
Future<Map<String, dynamic>?> toggleComboBookmarkApi({
  required BuildContext context,
  required int comboId,
}) async {
  try {
    final params = {
      "type": "combo",
      "item_id": comboId,
    };

    final response = await sendApiRequest(
      apiName: ApiAndParams.apiBookmarksToggle,
      params: params,
      isPost: true,
      context: context,
    );

    if (response != null) {
      return json.decode(response);
    }
  } catch (e) {
    dev.log("Error toggling combo bookmark: $e");
  }
  return null;
}

/// Toggle seller/store bookmark status via API
Future<Map<String, dynamic>?> toggleSellerBookmarkApi({
  required BuildContext context,
  required int sellerId,
}) async {
  try {
    final params = {
      "type": "seller",
      "item_id": sellerId,
    };

    final response = await sendApiRequest(
      apiName: ApiAndParams.apiBookmarksToggle,
      params: params,
      isPost: true,
      context: context,
    );

    if (response != null) {
      return json.decode(response);
    }
  } catch (e) {
    dev.log("Error toggling seller bookmark: $e");
  }
  return null;
}

/// Toggle product bookmark status via API
Future<Map<String, dynamic>?> toggleProductBookmarkApi({
  required BuildContext context,
  required int productId,
}) async {
  try {
    final params = {
      "type": "product",
      "item_id": productId,
    };

    final response = await sendApiRequest(
      apiName: ApiAndParams.apiBookmarksToggle,
      params: params,
      isPost: true,
      context: context,
    );

    if (response != null) {
      return json.decode(response);
    }
  } catch (e) {
    dev.log("Error toggling product bookmark: $e");
  }
  return null;
}

/// Fetch all bookmarks with tabs
Future<BookmarkTabsResponse?> fetchBookmarksListApi({
  required BuildContext context,
}) async {
  try {
    final Map<String, String> params = {};

    final response = await sendApiRequest(
      apiName: "bookmarks/list/tabs",
      params: params,
      isPost: false,
      context: context,
    );

    if (response != null) {
      final jsonResponse = json.decode(response);
      return BookmarkTabsResponse.fromJson(jsonResponse);
    }
  } catch (e) {
    dev.log("Error fetching bookmarks list: $e");
  }
  return null;
}

/// Fetch detailed bookmark data for a specific tab
Future<BookmarkTabDataResponse?> fetchBookmarkTabDataApi({
  required BuildContext context,
  required String tabType,
  required int id,
}) async {
  try {
    final Map<String, String> params = {
      'tab_type': tabType,
      'id': id.toString(),
    };

    final response = await sendApiRequest(
      apiName: "bookmarks/list/tab-data",
      params: params,
      isPost: true,
      context: context,
    );

    if (response != null) {
      final jsonResponse = json.decode(response);
      dev.log(
          "=== BOOKMARK TAB DATA API RESPONSE (tabType: $tabType, id: $id) ===");
      dev.log("Raw JSON: ${json.encode(jsonResponse)}");
      return BookmarkTabDataResponse.fromJson(jsonResponse);
    }
  } catch (e) {
    dev.log("Error fetching bookmark tab data: $e");
  }
  return null;
}
