import 'package:project/helper/utils/generalImports.dart';

//This is api for the razorpay transaction
Future<Map<String, dynamic>> getInitiatedTransactionApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  if (Platform.isAndroid) {
    params[ApiAndParams.requestFrom] = "android";
  } else if (Platform.isIOS) {
    params[ApiAndParams.requestFrom] = "ios";
  } else {
    params[ApiAndParams.requestFrom] = Platform.operatingSystem;
  }
  var response = await sendApiRequest(
      apiName: ApiAndParams.apiInitiateTransaction,
      params: params,
      isPost: true,
      context: context);
  return json.decode(response);
}

// PhonePe - Initiate Payment (New Laravel Backend Integration)
Future<Map<String, dynamic>> getPhonePePaymentInit({
  required BuildContext context,
  required String amount,
  required String userId,
  required String mobileNumber,
  String? paymentMode,
}) async {
  final params = {
    'amount': amount,
    'user_id': userId,
    'mobile_number': mobileNumber,
    if (paymentMode != null) 'payment_mode': paymentMode,
  };

  var response = await sendApiRequest(
    apiName: 'phonepe/initiate-payment',
    params: params,
    isPost: true,
    context: context,
  );

  return json.decode(response);
}

// phonepe
Future<Map<String, dynamic>> getOrderStatusPhonepeApi({required BuildContext context, required Map<String, dynamic> params}) async {
  var response = await sendApiRequest(apiName: ApiAndParams.apiOrderStatusPhonepe, params: params, isPost: false, context: context);
  return json.decode(response);
}

//This is api for the razorpay transaction
Future<Map<String, dynamic>> getPaytmTransactionTokenApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  var response = await sendApiRequest(
      apiName: ApiAndParams.apiPaytmTransactionToken,
      params: params,
      isPost: false,
      context: context,
      returnErrorResponse: true);

  if (response == null) {
    return {'error': true, 'message': 'No response from server'};
  }
  return json.decode(response);
}

Future<Map<String, dynamic>> getPaytmConfigApi({
  required BuildContext context,
}) async {
  var response = await sendApiRequest(
    apiName: ApiAndParams.apiPaytmConfig,
    params: {},
    isPost: false,
    context: context,
    returnErrorResponse: true,
  );
  if (response == null) {
    return {'status': false, 'message': 'No response from server'};
  }
  return json.decode(response);
}

Future<Map<String, dynamic>> verifyPaytmPaymentApi({
  required BuildContext context,
  required Map<String, dynamic> params,
}) async {
  var response = await sendApiRequest(
    apiName: ApiAndParams.apiPaytmVerifyPayment,
    params: params,
    isPost: true,
    context: context,
    returnErrorResponse: true,
  );
  if (response == null) {
    return {'status': false, 'message': 'No response from server'};
  }
  return json.decode(response);
}

Future<Map<String, dynamic>> placeOrderWithPaytmApi({
  required BuildContext context,
  required Map<String, dynamic> params,
}) async {
  var response = await sendApiRequest(
    apiName: ApiAndParams.apiPlaceOrderWithPaytm,
    params: params,
    isPost: true,
    context: context,
    returnErrorResponse: true,
  );
  if (response == null) {
    return {'status': false, 'message': 'No response from server'};
  }
  return json.decode(response);
}

Future<Map<String, dynamic>> addWalletBalanceApi({
  required BuildContext context,
  required Map<String, dynamic> params,
}) async {
  var response = await sendApiRequest(
    apiName: ApiAndParams.apiAddWalletBalance,
    params: params,
    isPost: true,
    context: context,
    returnErrorResponse: true,
  );
  if (response == null) {
    return {'status': false, 'message': 'No response from server'};
  }
  return json.decode(response);
}
