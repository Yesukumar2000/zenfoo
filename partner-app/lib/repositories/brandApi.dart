import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';

// Get all brands with pagination
Future<Map<String, dynamic>> getBrandApi({
  required BuildContext context,
  required Map<String, dynamic> params,
}) async {
  var response = await sendApiRequest(
    apiName: ApiAndParams.apiBrands,
    params: params,
    isPost: false,
  );

  Map<String, dynamic> mainData = await json.decode(response);
  return mainData;
}

// Create or update brand
Future<Map<String, dynamic>> saveBrandApi({
  required BuildContext context,
  required String name,
  required String status,
  required List<int> categoryIds,
  File? imageFile,
  String? brandId, // null for create, brandId for update
}) async {
  Map<String, dynamic> params = {
    'name': name,
    'status': status,
  };

  // Add category IDs as array
  for (int i = 0; i < categoryIds.length; i++) {
    params['category_ids[$i]'] = categoryIds[i].toString();
  }

  // If updating, add brand ID
  if (brandId != null) {
    params['id'] = brandId;
  }

  // Prepare files map
  Map<String, File> filesMap = {};
  if (imageFile != null) {
    filesMap['image'] = imageFile;
  }

  var response = await sendApiMultiPartRequest(
    apiName: brandId == null ? 'brands' : 'brands',
    params: params,
    filesMap: filesMap,
  );

  Map<String, dynamic> mainData = json.decode(json.encode(response));
  return mainData;
}

// Delete brand
Future<Map<String, dynamic>> deleteBrandApi({
  required BuildContext context,
  required String brandId,
}) async {
  Map<String, String> params = {
    'id': brandId,
  };

  var response = await sendApiRequest(
    apiName: 'brands/$brandId',
    params: params,
    isDelete: true,
    isPost: false
  );

  Map<String, dynamic> mainData = await json.decode(response);
  return mainData;
}

// Get brand details by ID
Future<Map<String, dynamic>> getBrandDetailsApi({
  required BuildContext context,
  required String brandId,
}) async {
  Map<String, String> params = {
    'id': brandId,
  };

  var response = await sendApiRequest(
    apiName: 'brand-details',
    params: params,
    isPost: false,
  );

  Map<String, dynamic> mainData = await json.decode(response);
  return mainData;
}
