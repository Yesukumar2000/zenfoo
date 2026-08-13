import 'package:project/helper/utils/generalImports.dart';

// Get reorderable orders
Future<Map<String, dynamic>> getReorderableOrdersApi({
  required BuildContext context,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: 'orders/reorderable',
      params: {},
      isPost: false,
      context: context,
    );
    debugPrint("==== REORDERABLE RAW RESPONSE START ====");
    debugPrint(response.toString());
    debugPrint("==== REORDERABLE RAW RESPONSE END ====");
    return json.decode(response);
  } catch (e) {
    debugPrint("Error in getReorderableOrdersApi: $e");
    rethrow;
  }
}
