import 'package:project/helper/utils/generalImports.dart';

Future<Map<String, dynamic>> submitSuggestionApi({
  required BuildContext context,
  required Map<String, dynamic> params,
}) async {
  var response = await sendApiRequest(
    apiName: ApiAndParams.apiSuggestionsSubmit,
    params: params,
    isPost: true,
    context: context,
  );
  return json.decode(response);
}

Future<Map<String, dynamic>> getSuggestionsApi({
  required BuildContext context,
  required Map<String, dynamic> params,
}) async {
  var response = await sendApiRequest(
    apiName: ApiAndParams.apiSuggestions,
    params: params,
    isPost: false,
    context: context,
  );
  return json.decode(response);
}
