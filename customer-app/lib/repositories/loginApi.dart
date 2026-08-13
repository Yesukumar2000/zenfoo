import 'package:project/helper/utils/generalImports.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> getLoginApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  print('🔐 [LOGIN API] Starting login request');
  print('📤 [LOGIN API] Parameters: $params');

  var response = await sendApiRequest(
      apiName: ApiAndParams.apiLogin,
      params: params,
      isPost: true,
      context: context);

  final decoded = json.decode(response);
  print('📥 [LOGIN API] Response: $decoded');
  print('✅ [LOGIN API] Login request completed');

  return decoded;
}

Future<Map<String, dynamic>> sendCustomOTPSmsApi({
  required BuildContext context,
  required String phone,
  required String countryCode,
}) async {
  print('📱 [SEND OTP SMS] Starting OTP SMS request');
  print('📤 [SEND OTP SMS] Phone: $phone, Country Code: $countryCode');

  final url = Uri.parse("${Constant.baseUrl}${ApiAndParams.apiSendSms}");
  print('🌐 [SEND OTP SMS] URL: $url');

  try {
    var request = http.MultipartRequest('POST', url);
    request.fields['phone'] = phone;
    request.fields['country_code'] = countryCode;

    print('⏳ [SEND OTP SMS] Sending request...');
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print('📥 [SEND OTP SMS] Status Code: ${response.statusCode}');
    Map<String, dynamic> decoded = json.decode(response.body);
    print('📥 [SEND OTP SMS] Response: $decoded');
    print('✅ [SEND OTP SMS] Request completed successfully');

    return decoded;
  } catch (e) {
    print('❌ [SEND OTP SMS] Error: $e');
    return {"status": 0, "message": "Something went wrong!"};
  }
}

Future<Map<String, dynamic>> getUserVerifyApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  print('✔️ [VERIFY USER] Starting user verification');
  print('📤 [VERIFY USER] Parameters: $params');

  var response = await sendApiRequest(
      apiName: ApiAndParams.apiVerifyUser,
      params: params,
      isPost: true,
      context: context);

  final decoded = json.decode(response);
  print('📥 [VERIFY USER] Response: $decoded');
  print('✅ [VERIFY USER] Verification completed');

  return decoded;
}

Future<Map<String, dynamic>> getVerifyUserExistApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  print('👤 [VERIFY USER EXIST] Checking if user exists');
  print('📤 [VERIFY USER EXIST] Parameters: $params');

  var response = await sendApiRequest(
      apiName: ApiAndParams.apiVerifyUserExist,
      params: params,
      isPost: true,
      context: context);

  final decoded = json.decode(response);
  print('📥 [VERIFY USER EXIST] Response: $decoded');
  print('✅ [VERIFY USER EXIST] Check completed');

  return decoded;
}

Future<Map<String, dynamic>> getRegisterApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  print('📝 [REGISTER] Starting user registration');
  print('📤 [REGISTER] Parameters: $params');

  var response = await sendApiRequest(
    apiName: ApiAndParams.apiRegister,
    params: params,
    isPost: true,
    context: context,
  );

  final decoded = json.decode(response);
  print('📥 [REGISTER] Response: $decoded');
  print('✅ [REGISTER] Registration completed');

  return decoded;
}

Future<Map<String, dynamic>> verifyRegisteredEmailApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  print('📧 [VERIFY EMAIL] Starting email verification');
  print('📤 [VERIFY EMAIL] Parameters: $params');

  var response = await sendApiRequest(
    apiName: ApiAndParams.apiVerifyEmail,
    params: params,
    isPost: true,
    context: context,
  );

  final decoded = json.decode(response);
  print('📥 [VERIFY EMAIL] Response: $decoded');
  print('✅ [VERIFY EMAIL] Verification completed');

  return decoded;
}

Future<Map<String, dynamic>> sendOTPForgotPasswordApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  print('🔑 [FORGOT PASSWORD OTP] Sending OTP for password reset');
  print('📤 [FORGOT PASSWORD OTP] Parameters: $params');

  var response = await sendApiRequest(
    apiName: ApiAndParams.apiForgotPasswordOTP,
    params: params,
    isPost: true,
    context: context,
  );

  final decoded = json.decode(response);
  print('📥 [FORGOT PASSWORD OTP] Response: $decoded');
  print('✅ [FORGOT PASSWORD OTP] OTP sent successfully');

  return decoded;
}

Future<Map<String, dynamic>> forgotPasswordApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  print('🔐 [FORGOT PASSWORD] Processing password reset');
  print('📤 [FORGOT PASSWORD] Parameters: $params');

  var response = await sendApiRequest(
    apiName: ApiAndParams.apiForgotPassword,
    params: params,
    isPost: true,
    context: context,
  );

  final decoded = json.decode(response);
  print('📥 [FORGOT PASSWORD] Response: $decoded');
  print('✅ [FORGOT PASSWORD] Password reset completed');

  return decoded;
}

Future<Map<String, dynamic>> changePasswordApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  print('🔄 [CHANGE PASSWORD] Starting password change');
  print('📤 [CHANGE PASSWORD] Parameters: $params');

  var response = await sendApiRequest(
    apiName: ApiAndParams.apiResetPassword,
    params: params,
    isPost: true,
    context: context,
  );

  final decoded = json.decode(response);
  print('📥 [CHANGE PASSWORD] Response: $decoded');
  print('✅ [CHANGE PASSWORD] Password changed successfully');

  return decoded;
}
