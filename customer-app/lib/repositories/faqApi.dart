import 'package:project/helper/utils/generalImports.dart';

Future<Map<String, dynamic>> getFaqApi(
    {required BuildContext context,
    required Map<String, dynamic> params}) async {
  var response = await sendApiRequest(
      apiName: ApiAndParams.apiFaq,
      params: params,
      isPost: false,
      context: context);
  return json.decode(response);
}

Future<Map<String, dynamic>> getChatFAQApi(
    {required BuildContext context,
    required String orderId}) async {
  var response = await sendApiRequest(
      apiName: 'chatbot/questions',
      params: {'order_id': orderId},
      isPost: false,
      context: context);
  return json.decode(response);
}

Future<Map<String, dynamic>> ChatFAQSentAPI(
    {required BuildContext context,
    required String orderId,
    required String questionKey}) async {
  var response = await sendApiRequest(
      apiName: 'chatbot/answer',
      params: {
        'order_id': orderId,
        'question': questionKey,
      },
      isPost: true,
      context: context);
  return json.decode(response);
}
