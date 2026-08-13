import 'package:flutter/foundation.dart';
import 'package:project/helper/utils/generalImports.dart';

/// Update FCM token on the server whenever it's refreshed
Future<Map<String, dynamic>> updateFCMTokenRepository({
  required String fcmToken,
}) async {
  final apiName = "${Constant.hostUrl}api/seller/update-fcm-token";

  final params = {
    "fcm_token": fcmToken,
    "platform": Platform.isAndroid ? "android" : "ios",
  };

  try {
    final response = await sendApiRequest(
      apiName: apiName,
      params: params,
      isPost: true,
    );

    if (response == null) {
      return {
        "success": 0,
        "message": "Failed to update FCM token",
      };
    }

    final decodedResponse = json.decode(response) as Map<String, dynamic>;
    return standardizeApiResponse(decodedResponse);
  } catch (e) {
    debugPrint('Error updating FCM token: $e');
    return {
      "success": 0,
      "message": "Error: ${e.toString()}",
    };
  }
}
