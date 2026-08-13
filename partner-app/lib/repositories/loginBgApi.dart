import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project/helper/utils/constant.dart';

Future<String?> getLoginBgUrl() async {
  try {
    final url = "${Constant.hostUrl}api/seller/login-bg";
    final response = await http.get(
      Uri.parse(url),
      headers: {'x-access-key': '903361'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 1 && data['data'] != null) {
        return data['data']['seller_app_login_bg']?.toString();
      }
    }
  } catch (e) {
    debugPrint('Error fetching login bg: $e');
  }
  return null;
}
