import 'package:project/helper/utils/generalImports.dart';

Future getFreeDeliveryOffer({required BuildContext context}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiFreeDeliveryOffer,
        params: {},
        isPost: false,
        context: context);
    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}
