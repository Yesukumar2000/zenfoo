import 'package:project/helper/utils/generalImports.dart';

Future getUserOffers({required BuildContext context}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiUserOffers,
        params: {},
        isPost: false,
        context: context);
    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}
