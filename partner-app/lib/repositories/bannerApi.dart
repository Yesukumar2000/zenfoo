import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/generalMethods.dart' as GeneralMethods;
import 'package:project/models/banner.dart';

Future<BannerResponse?> getSellerBanners({
  required BuildContext context,
}) async {
  try {
    final result = await sendApiRequest(
      apiName:
          'https://wheat-rook-708688.hostingersite.com/api/home_slider_images/by_type?type=seller',
      params: {},
      isPost: false,
    );

    final response = BannerResponse.fromJson(
      Map.from(jsonDecode(result)),
    );

    return response;
  } catch (e) {
    GeneralMethods.showMessage(
      context,
      e.toString(),
      MessageType.warning,
    );
    return null;
  }
}
