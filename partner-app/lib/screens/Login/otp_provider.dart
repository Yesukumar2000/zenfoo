import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';

import 'package:project/screens/Login/otp_repo.dart';

class LoginProvider extends ChangeNotifier {
  bool loading = false;

  /// Call this on "Continue" to send OTP
  Future<bool> sendOtpSellerPhone(BuildContext context, String phone) async {
    loading = true;
    notifyListeners();
    try {
      final result = await sendOtpSellerPhoneRepository(phone: phone);

      // Safely extract success and message from result
      final success = result["success"];
      final message = result["message"] ?? "Failed to send OTP. Please try again.";
      final successValue = success?.toString() ?? "0";

      if (successValue == "1") {
        showMessage(context, message.toString(), MessageType.success);
        loading = false;
        notifyListeners();
        return true;
      } else {
        showMessage(context, message.toString(), MessageType.error);
        loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      developer.log("Error sending OTP: $e");
      showMessage(context, "Failed to send OTP. Please check your connection and try again.", MessageType.error);
      loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Call this on OTP entry to verify
  Future<Map<String, dynamic>?> verifyOtpSellerPhone(
      BuildContext context, String phone, String otp) async {
    loading = true;
    notifyListeners();
    try {
      final result =
          await verifyOtpSellerPhoneRepository(phone: phone, otp: otp);

      // Safely extract success and message from result (standardized field names)
      final success = result["success"];
      final message = result["message"] ?? "OTP verification failed. Please try again.";
      final successValue = success?.toString() ?? "0";

      if (successValue == "1") {
        showMessage(context, message.toString(), MessageType.success);
        try {
          UserLogin userLogin = UserLogin.fromJson(result);
          if (result.isNotEmpty && userLogin.data != null) {
            Constant.session.setData(SessionManager.keyAccessToken,
                userLogin.data!.accessToken.toString(), false);

            Constant.session.setData(SessionManager.email,
                userLogin.data?.user?.email.toString() ?? "", false);
            if (Constant.session.getData(SessionManager.appThemeName).isEmpty) {
              Constant.session.setData(
                  SessionManager.appThemeName, Constant.themeList[0], true);
            }
            await Constant.session
                .setUserData(data: userLogin.data?.user?.seller?.toJson());
          }
          loading = false;
          notifyListeners();
          return userLogin.data?.toJson();
        } catch (parseError) {
          developer.log("Error parsing user data: $parseError");
          showMessage(context, "Error processing login data. Please try again.", MessageType.error);
          loading = false;
          notifyListeners();
          return null;
        }
      } else {
        showMessage(context, message.toString(), MessageType.error);
        loading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      developer.log("Error verifying OTP: $e");
      showMessage(context, "OTP verification failed. Please check your connection and try again.", MessageType.error);
      loading = false;
      notifyListeners();
      return null;
    }
  }
}
