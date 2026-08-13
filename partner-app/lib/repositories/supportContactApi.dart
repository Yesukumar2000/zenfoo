import 'dart:convert';

import 'package:project/helper/utils/generalMethods.dart';
import 'package:project/helper/utils/apiAndParams.dart';
import 'package:project/models/support_contact_model.dart';

Future<SupportContact?> getSupportContactsRepository() async {
  try {
    final result = await sendApiRequest(
      apiName: ApiAndParams.apiSupportContacts,
      params: {},
      isPost: false,
      privacyAndTerms: true,
    );

    final Map<String, dynamic> jsonResponse = jsonDecode(result);

    if (jsonResponse['status'] == 1 && jsonResponse['data'] != null) {
      return SupportContact.fromJson(jsonResponse['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
}
