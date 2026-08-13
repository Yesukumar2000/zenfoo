import 'package:project/helper/utils/generalImports.dart';

Future getBrandCampaignDetails({required BuildContext context}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiBrandCampaignDetails,
        params: {},
        
        isPost: false,
        context: context);
    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}

Future getBrandCampaignProducts({
  required BuildContext context,
  required Map<String, dynamic> params,
}) async {
  try {
    final response = await sendApiRequest(
      apiName: ApiAndParams.apiBrandCampaignProducts,
      params: params,
      isPost: false,
      context: context,
    );
    return json.decode(response);
  } catch (e) {
    rethrow;
  }
}