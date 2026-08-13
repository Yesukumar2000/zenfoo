import 'package:project/helper/utils/generalImports.dart';

Future getAppLaunchBanner({required BuildContext context}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiAppLaunchBanner,
        params: {},
        isPost: false,
        context: context);
    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}
