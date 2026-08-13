import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project/helper/utils/constant.dart';
import 'package:project/helper/sessionManager.dart';
import 'package:project/models/transaction_response.dart';

Future<TransactionResponse?> getTransactionsRepository({
  required BuildContext context,
  int page = 1,
  int perPage = 15,
  String? type,
  String? paymentStatus,
  String? fromDate,
  String? toDate,
  String? search,
  String? sortBy,
  String? sortOrder,
}) async {
  try {
    String token = Constant.session.getData(SessionManager.keyAccessToken);
    String baseUrl = "${Constant.hostUrl}api/seller/my-transactions";

    // Build query params
    List<String> queryParams = [
      'page=$page',
      'per_page=$perPage',
    ];

    if (type != null && type.isNotEmpty) {
      queryParams.add('type=$type');
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      queryParams.add('payment_status=$paymentStatus');
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams.add('from_date=$fromDate');
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams.add('to_date=$toDate');
    }
    if (search != null && search.isNotEmpty) {
      queryParams.add('search=$search');
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams.add('sort_by=$sortBy');
    }
    if (sortOrder != null && sortOrder.isNotEmpty) {
      queryParams.add('sort_order=$sortOrder');
    }

    String url = "$baseUrl?${queryParams.join('&')}";

    debugPrint('=== TRANSACTION API DEBUG ===');
    debugPrint('URL: $url');

    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'x-access-key': '903361',
    };

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    debugPrint('Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return TransactionResponse.fromJson(jsonResponse);
    } else {
      debugPrint('Transaction API error: ${response.statusCode}');
      debugPrint('Error body: ${response.body}');
      return null;
    }
  } catch (e, stackTrace) {
    debugPrint('Error fetching transactions: $e');
    debugPrint('Stack trace: $stackTrace');
    return null;
  }
}
