import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project/helper/utils/constant.dart';
import 'package:project/helper/sessionManager.dart';
import 'package:project/models/notification_response.dart';

Future<NotificationResponse?> getNotificationsRepository({
  required BuildContext context,
  required int page,
  int perPage = 10,
}) async {
  try {
    String token = Constant.session.getData(SessionManager.keyAccessToken);
    String baseUrl = "${Constant.hostUrl}api/seller/notifications";

    // Build URL with query params
    String url = "$baseUrl?page=$page&per_page=$perPage";

    debugPrint('=== NOTIFICATION API DEBUG ===');
    debugPrint('URL: $url');
    debugPrint('Token: ${token.isNotEmpty ? "Present" : "Missing"}');

    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'x-access-key': '903361',
    };

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      debugPrint('JSON Parsed Successfully');
      debugPrint('Data type: ${jsonResponse['data'].runtimeType}');
      debugPrint('Data length: ${jsonResponse['data'] is List ? (jsonResponse['data'] as List).length : 'N/A'}');

      final result = NotificationResponse.fromJson(jsonResponse);
      debugPrint('NotificationResponse created: ${result.data?.data?.length ?? 0} items');
      return result;
    } else {
      debugPrint('Notification API error: ${response.statusCode}');
      debugPrint('Error body: ${response.body}');
      return null;
    }
  } catch (e, stackTrace) {
    debugPrint('Error fetching notifications: $e');
    debugPrint('Stack trace: $stackTrace');
    return null;
  }
}
