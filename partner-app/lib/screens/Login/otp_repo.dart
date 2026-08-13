import 'dart:convert';
import 'dart:io';

import 'package:project/helper/sessionManager.dart';
import 'package:project/helper/utils/constant.dart';
import 'package:project/helper/utils/generalMethods.dart';

Future<Map<String, dynamic>> sendOtpSellerPhoneRepository(
    {required String phone}) async {
  final apiName = "${Constant.hostUrl}api/send-otp-seller-phone";
  final params = {"phone": phone};
  // Structure: always uses sendApiRequest, per your architecture
  final response = await sendApiRequest(
    apiName: apiName,
    params: params,
    isPost: true,
  );

  // Handle null response (error from API)
  if (response == null) {
    return {
      "success": 0,
      "message": "Failed to send OTP. Please try again later."
    };
  }

  final decodedResponse = json.decode(response) as Map<String, dynamic>;
  return standardizeApiResponse(decodedResponse);
}

Future<Map<String, dynamic>> verifyOtpSellerPhoneRepository({
  required String phone,
  required String otp,
}) async {
  final apiName = "${Constant.hostUrl}api/verify-otp-seller-phone";
  final params = {
    "phone": phone,
    "otp": otp,
    "fcm_token": Constant.session.getData(SessionManager.keyFCMToken),
    "platform": Platform.isAndroid ? "android" : "ios",
  };
  final response = await sendApiRequest(
    apiName: apiName,
    params: params,
    isPost: true,
  );

  // Handle null response (error from API)
  if (response == null) {
    return {
      "success": 0,
      "message": "OTP verification failed. Please try again later."
    };
  }

  final decodedResponse = json.decode(response) as Map<String, dynamic>;
  return standardizeApiResponse(decodedResponse);
}
