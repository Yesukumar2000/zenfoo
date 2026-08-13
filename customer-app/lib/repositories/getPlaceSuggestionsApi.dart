import 'package:project/helper/utils/generalImports.dart';
Future<Map<String, dynamic>> getPlaceSuggestionsApi({
  required BuildContext context,
  required String input,
}) async {
  try {

    debugPrint("=== PLACE SUGGESTIONS API ===");
    debugPrint("Endpoint: ${ApiAndParams.apiGooglePlacesAutocomplete}");
    debugPrint("Input: $input");

    var response = await sendApiRequest(
      apiName: ApiAndParams.apiGooglePlacesAutocomplete,
      params: {ApiAndParams.input:input, ApiAndParams.source: Constant.appKey},
      isPost: false,
      context: context,
    );

    debugPrint("Response: $response");

    if (response == null) {
      return {
        "error": true,
        "message": "No results found. Please try again.",
      };
    }

    return json.decode(response);

  } catch (e) {
    debugPrint("Error in getPlaceSuggestionsApi: $e");
    return {
      "error": true,
      "message": e.toString(),
    };
  }
}
