
import 'package:project/helper/utils/generalMethods.dart';


Future<String> fetchPolicyAndTerms({
  required String apiName
}) async {
  try {
    final result = await sendApiRequest(
      apiName: apiName,
      params: {},
      isPost: false,
      privacyAndTerms: true
    );

    return result;
  } catch (e) {
    return e.toString();
  }
}