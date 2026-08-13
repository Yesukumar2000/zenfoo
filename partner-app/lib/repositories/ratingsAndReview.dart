import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';

import '../models/ratings_model.dart';

Future getRatingsList(
    {required BuildContext context,
    required Map<String, String> params}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiProductsRatings,
      params: params,
      isPost: false,
    );
    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future ratings({required BuildContext context}) async {
  try {
    var response = await sendApiRequest(
      apiName: "https://wheat-rook-708688.hostingersite.com/api/seller/ratings",
      params: {},
      isPost: false,
    );
    return RatingsModel.fromJson(json.decode(response));
  } catch (e) {
    rethrow;
  }
}
