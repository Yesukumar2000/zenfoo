import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class BankDetailsModel {
  final String? bankName;
  final String? ifscCode;

  BankDetailsModel({
    this.bankName,
    this.ifscCode,
  });

  factory BankDetailsModel.fromJson(Map<String, dynamic> json) {
    return BankDetailsModel(
      bankName: json['BANK'] ?? json['bank'],
      ifscCode: json['IFSC'] ?? json['ifsc'],
    );
  }
}

class RazorpayBankService {
  static const String _baseUrl =
      'https://ifsc.razorpay.com'; // Free public API from Razorpay

  /// Fetch bank details using IFSC code
  /// Returns bank name and IFSC code details
  /// Throws exception if IFSC is invalid or API fails
  static Future<BankDetailsModel> getBankDetailsByIfsc(String ifscCode) async {
    try {
      debugPrint('🏦 Fetching bank details for IFSC: $ifscCode');

      // IFSC code should be exactly 11 characters
      if (ifscCode.length != 11) {
        throw Exception('IFSC code must be exactly 11 characters');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/$ifscCode'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Bank details fetched successfully: ${data['BANK']}');
        return BankDetailsModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Invalid IFSC code');
      } else {
        throw Exception(
            'Failed to fetch bank details. Status: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('❌ Network error: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error fetching bank details: $e');
      rethrow;
    }
  }

  /// Validate IFSC code format
  static bool isValidIfscFormat(String ifscCode) {
    if (ifscCode.length != 11) return false;
    // Standard IFSC format: First 4 characters are letters, 5th character is 0, last 6 are digits
    final regExp = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    return regExp.hasMatch(ifscCode.toUpperCase());
  }
}
