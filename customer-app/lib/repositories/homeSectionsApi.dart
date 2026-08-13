import 'package:project/helper/utils/generalImports.dart';

Future getHomeSections({
  required BuildContext context,
  required int page,
  required int perPage,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: "${ApiAndParams.apiHomeSections}?per_page=$perPage&page=$page",
      params: {},
      isPost: false,
      context: context,
    );
    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}
