import 'package:project/helper/utils/generalImports.dart';

/// ==========================================
/// Stage 1: Category APIs
/// ==========================================

/// Get all categories for non-sweet store with pagination and search
Future<dynamic> getThreeStageCategoriesApi({
  int page = 1,
  String? search,
}) async {
  try {
    Map<String, dynamic> params = {
      'page': page.toString(),
    };

    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    var response = await sendApiRequest(
      apiName: 'get-three-stage-categories',
      params: params,
      isPost: false,
    );
    return json.decode(response);
  } catch (e) {
    print("getThreeStageCategoriesApi error: $e");
    rethrow;
  }
}

/// Add category (Stage 1)
Future<dynamic> addThreeStageCategoryApi({
  required String name,
  String? subtitle,
  File? imageFile,
}) async {
  try {
    Map<String, String> params = {
      'name': name,
      if (subtitle != null && subtitle.isNotEmpty) 'subtitle': subtitle,
    };

    dynamic response;

    if (imageFile != null) {
      response = await sendApiMultiPartRequest(
        apiName: 'store-three-stage-category',
        params: params,
        filesMap: {'image': imageFile},
      );
    } else {
      response = await sendApiRequest(
        apiName: 'store-three-stage-category',
        params: params,
        isPost: true,
      );
    }

    if (response is String) {
      return json.decode(response);
    } else if (response is Map) {
      return response;
    } else {
      throw Exception("Unsupported response type");
    }
  } catch (e) {
    print("addThreeStageCategoryApi error: $e");
    rethrow;
  }
}

/// Update category (Stage 1)
Future<dynamic> updateThreeStageCategoryApi({
  required String categoryId,
  required String name,
  String? subtitle,
  File? imageFile,
}) async {
  try {
    Map<String, String> params = {
      'name': name,
      if (subtitle != null && subtitle.isNotEmpty) 'subtitle': subtitle,
    };

    dynamic response;

    if (imageFile != null) {
      response = await sendApiMultiPartRequest(
        apiName: 'update-three-stage-category/$categoryId',
        params: params,
        filesMap: {'image': imageFile},
      );
    } else {
      response = await sendApiRequest(
        apiName: 'update-three-stage-category/$categoryId',
        params: params,
        isPost: true,
      );
    }

    if (response is String) {
      return json.decode(response);
    } else if (response is Map) {
      return response;
    } else {
      throw Exception("Unsupported response type");
    }
  } catch (e) {
    print("updateThreeStageCategoryApi error: $e");
    rethrow;
  }
}

/// Delete category (Stage 1)
Future<dynamic> deleteThreeStageCategoryApi({
  required String categoryId,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: 'delete-three-stage-category/$categoryId',
      params: {},
      isPost: false,
      isDelete: true,
    );
    return json.decode(response);
  } catch (e) {
    print("deleteThreeStageCategoryApi error: $e");
    rethrow;
  }
}

/// ==========================================
/// Stage 2: Category Group APIs
/// ==========================================

/// Get all category groups with pagination
Future<dynamic> getCategoryGroupsApi({
  int page = 1,
  String? search,
}) async {
  try {
    Map<String, dynamic> params = {
      'page': page.toString(),
    };

    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    var response = await sendApiRequest(
      apiName: 'category-groups',
      params: params,
      isPost: false,
    );
    return json.decode(response);
  } catch (e) {
    print("getCategoryGroupsApi error: $e");
    rethrow;
  }
}

/// Add category group (Stage 2)
Future<dynamic> addCategoryGroupApi({
  required String name,
  required List<String> categoryIds,
  File? imageFile,
}) async {
  try {
    Map<String, String> params = {
      'name': name,
      'category_ids': categoryIds.join(','), // Send as comma-separated string
    };

    dynamic response;

    if (imageFile != null) {
      response = await sendApiMultiPartRequest(
        apiName: 'category-groups',
        params: params,
        filesMap: {'image': imageFile},
      );
    } else {
      response = await sendApiRequest(
        apiName: 'category-groups',
        params: params,
        isPost: true,
      );
    }

    if (response is String) {
      return json.decode(response);
    } else if (response is Map) {
      return response;
    } else {
      throw Exception("Unsupported response type");
    }
  } catch (e) {
    print("addCategoryGroupApi error: $e");
    rethrow;
  }
}

/// Update category group (Stage 2)
Future<dynamic> updateCategoryGroupApi({
  required String groupId,
  required String name,
  required List<String> categoryIds,
  File? imageFile,
}) async {
  try {
    Map<String, String> params = {
      'name': name,
      'category_ids': categoryIds.join(','), // Send as comma-separated string
    };

    dynamic response;

    if (imageFile != null) {
      response = await sendApiMultiPartRequest(
        apiName: 'category-groups/$groupId',
        params: params,
        filesMap: {'image': imageFile},
      );
    } else {
      response = await sendApiRequest(
        apiName: 'category-groups/$groupId',
        params: params,
        isPost: true,
      );
    }

    if (response is String) {
      return json.decode(response);
    } else if (response is Map) {
      return response;
    } else {
      throw Exception("Unsupported response type");
    }
  } catch (e) {
    print("updateCategoryGroupApi error: $e");
    rethrow;
  }
}

/// Delete category group (Stage 2)
Future<dynamic> deleteCategoryGroupApi({
  required String groupId,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: 'category-groups/$groupId',
      params: {},
      isPost: false,
      isDelete: true,
    );
    return json.decode(response);
  } catch (e) {
    print("deleteCategoryGroupApi error: $e");
    rethrow;
  }
}

/// ==========================================
/// Stage 3: Category Grouping APIs
/// ==========================================

/// Get all category groupings with pagination and search
Future<dynamic> getCategoryGroupingsApi({
  int page = 1,
  String? search,
}) async {
  try {
    Map<String, dynamic> params = {
      'page': page.toString(),
    };

    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    var response = await sendApiRequest(
      apiName: 'get-category-grouping',
      params: params,
      isPost: false,
    );
    return json.decode(response);
  } catch (e) {
    print("getCategoryGroupingsApi error: $e");
    rethrow;
  }
}

/// Add category grouping (Stage 3)
Future<dynamic> addCategoryGroupingApi({
  required String name,
  required List<String> groupIds,
  File? imageFile,
}) async {
  try {
    Map<String, String> params = {
      'name': name,
    };

    // Add group IDs as array format: group_ids[] => [1,2,3]
    for (int i = 0; i < groupIds.length; i++) {
      params['group_ids[]'] = groupIds[i];
    }

    dynamic response;

    if (imageFile != null) {
      response = await sendApiMultiPartRequest(
        apiName: 'store-category-grouping',
        params: params,
        filesMap: {'image': imageFile},
      );
    } else {
      response = await sendApiRequest(
        apiName: 'store-category-grouping',
        params: params,
        isPost: true,
      );
    }

    if (response is String) {
      return json.decode(response);
    } else if (response is Map) {
      return response;
    } else {
      throw Exception("Unsupported response type");
    }
  } catch (e) {
    print("addCategoryGroupingApi error: $e");
    rethrow;
  }
}

/// Update category grouping (Stage 3)
Future<dynamic> updateCategoryGroupingApi({
  required String groupingId,
  required String name,
  required List<String> groupIds,
  File? imageFile,
}) async {
  try {
    Map<String, String> params = {
      'name': name,
    };

    // Add group IDs to params
    for (int i = 0; i < groupIds.length; i++) {
      params['group_ids[$i]'] = groupIds[i];
    }

    dynamic response;

    if (imageFile != null) {
      response = await sendApiMultiPartRequest(
        apiName: 'update-category-grouping/$groupingId',
        params: params,
        filesMap: {'image': imageFile},
      );
    } else {
      response = await sendApiRequest(
        apiName: 'update-category-grouping/$groupingId',
        params: params,
        isPost: true,
      );
    }

    if (response is String) {
      return json.decode(response);
    } else if (response is Map) {
      return response;
    } else {
      throw Exception("Unsupported response type");
    }
  } catch (e) {
    print("updateCategoryGroupingApi error: $e");
    rethrow;
  }
}

/// Delete category grouping (Stage 3)
Future<dynamic> deleteCategoryGroupingApi({
  required String groupingId,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: 'delete-category-grouping/$groupingId',
      params: {},
      isPost: false,
      isDelete: true,
    );
    return json.decode(response);
  } catch (e) {
    print("deleteCategoryGroupingApi error: $e");
    rethrow;
  }
}
