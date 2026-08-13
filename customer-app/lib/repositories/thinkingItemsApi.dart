import 'package:project/helper/utils/generalImports.dart';

Future getThinkingItems({required BuildContext context}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiThinkingItems,
        params: {},
        isPost: false,
        context: context);
    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future getThinkingItemsTitle({required BuildContext context}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiThinkingItemsTitle,
        params: {},
        isPost: false,
        context: context);
    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}
