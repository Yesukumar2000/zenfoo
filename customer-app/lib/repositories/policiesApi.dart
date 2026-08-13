import 'package:flutter/material.dart';
import 'package:project/helper/utils/apiAndParams.dart';
import 'package:project/helper/utils/generalMethods.dart';

Future<String?> getAboutUsApi({required BuildContext context}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiAboutUs,
        params: {},
        isPost: false,
        context: context);

    if (response == null) return null;

    return response as String;
  } catch (e) {
    rethrow;
  }
}

Future<String?> getContactUsApi({required BuildContext context}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiContactUs,
        params: {},
        isPost: false,
        context: context);

    if (response == null) return null;

    return response as String;
  } catch (e) {
    rethrow;
  }
}

Future<String?> getTermsAndConditionsApi({required BuildContext context}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiTermsAndConditions,
        params: {},
        isPost: false,
        context: context);

    if (response == null) return null;

    return response as String;
  } catch (e) {
    rethrow;
  }
}


Future<String?> getPrivacyPolicyApi({required BuildContext context}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiPrivacyPolicy,
        params: {},
        isPost: false,
        context: context);

    if (response == null) return null;

    return response as String;
  } catch (e) {
    rethrow;
  }
}

Future<String?> getRefundPolicyApi({required BuildContext context}) async {
  try {
    var response = await sendApiRequest(
        apiName: ApiAndParams.apiRefundPolicy,
        params: {},
        isPost: false,
        context: context);

    if (response == null) return null;

    return response as String;
  } catch (e) {
    rethrow;
  }
}
