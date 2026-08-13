import 'package:project/helper/utils/generalImports.dart';

Future<Map<String, dynamic>> getUserDetail(
    {required BuildContext context}) async {
      try{
  var response = await sendApiRequest(
    apiName: ApiAndParams.apiUserDetails,
    params: {},
    isPost: false,
    context: context,
  );

  return json.decode(response);
  }catch(e){
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getChildrenAllowed(
    {required BuildContext context}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiGetChildrenAllowed,
      params: {},
      isPost: false,
      context: context,
    );

    return json.decode(response);
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> updateChildrenAllowed({
  required BuildContext context,
  required int isChildrenAllowed,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiUpdateChildrenAllowed,
      params: {
        ApiAndParams.isChildrenAllowed: isChildrenAllowed.toString(),
      },
      isPost: true,
      context: context,
    );

    return json.decode(response);
  } catch (e) {
    throw e.toString();
  }
}
