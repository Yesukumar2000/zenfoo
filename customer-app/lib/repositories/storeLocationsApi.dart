import 'package:project/helper/utils/generalImports.dart';

Future<List<Map<String, dynamic>>> getStoreLocationsApi({
  required BuildContext context,
}) async {
  try {
    final response = await sendApiRequest(
      apiName: 'store-locations',
      params: {},
      isPost: false,
      context: context,
    );

    final decoded = json.decode(response);
    if (decoded is Map && decoded['data'] is List) {
      return List<Map<String, dynamic>>.from(decoded['data']);
    }
    return [];
  } catch (e) {
    debugPrint('Error in getStoreLocationsApi: $e');
    return [];
  }
}
