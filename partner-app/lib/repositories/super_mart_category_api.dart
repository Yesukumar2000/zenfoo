import 'dart:convert';
import 'package:project/helper/utils/generalMethods.dart';

/// Get Super Mart Category Groups
Future<Map<String, dynamic>> getSuperMartCategoryGroupsApi({
  required String sellerId,
}) async {
  Map<String, String> params = {
    'seller_id': sellerId,
  };

  var response = await sendApiRequest(
    apiName: 'seller-category-groups',
    params: params,
    isPost: false,
  );

  Map<String, dynamic> mainData = json.decode(response);
  return mainData;
}
