import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';

Future<Map<String, dynamic>> getSweetShopProductsByCategoryApi({
  required BuildContext context,
  String? search,
  String? sortBy,
}) async {
  try {
    Map<String, String> params = {};
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      params['sort_by'] = sortBy;
    }

    final response = await sendApiRequest(
      apiName: ApiAndParams.sweetshopProductsByCategory,
      params: params,
      isPost: false,
    );

    return jsonDecode(response);
  } catch (e) {
    print('Error in getSweetShopProductsByCategoryApi: $e');
    return {
      'status': 0,
      'message': 'Failed to fetch products: $e',
    };
  }
}
