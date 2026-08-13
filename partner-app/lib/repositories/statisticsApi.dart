import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/generalMethods.dart' as GeneralMethods;
import 'package:project/models/statistics.dart';

Future<StatisticsResponse?> getStatistics({
  required BuildContext context,
}) async {
  try {
    final result = await sendApiRequest(
      apiName: 'statistics',
      params: {},
      isPost: false,
    );

    final response = StatisticsResponse.fromJson(
      Map.from(jsonDecode(result)),
    );

    return response;
  } catch (e) {
    GeneralMethods.showMessage(
      context,
      e.toString(),
      MessageType.warning,
    );
    return null;
  }
}
