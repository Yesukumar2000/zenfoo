import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/weekly_summary_model.dart';
import 'package:zenfoo_partner/repository/weekly_summary_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class WeeklySummaryProvider with ChangeNotifier {
  final WeeklySummaryRepository _weeklySummaryRepository =
      WeeklySummaryRepository();

  // State for weekly summary data
  ApiResponse<WeeklySummaryResponse> weeklySummaryState =
      ApiResponse.nothing();
  WeeklySummaryResponse? _currentWeeklySummary;
  WeeklySummaryResponse? get currentWeeklySummary => _currentWeeklySummary;

  // Offset tracking for navigation
  int _currentOffset = 0;
  int get currentOffset => _currentOffset;

  /// Get weekly summary data
  /// Parameters:
  /// - period: 'weekly'
  /// - offset: offset for navigation (0 = current week)
  Future<void> getWeeklySummary({
    String period = 'weekly',
    int? offset,
  }) async {
    dev.log('🔵 Starting getWeeklySummary() with period: $period, offset: $offset',
        name: 'WeeklySummaryProvider');
    weeklySummaryState = ApiResponse.loading();
    notifyListeners();

    try {
      if (offset != null) {
        _currentOffset = offset;
      }

      final response = await _weeklySummaryRepository.getWeeklySummary(
        period: period,
        offset: _currentOffset,
      );

      dev.log('📥 Repository response status: ${response.status}',
          name: 'WeeklySummaryProvider');

      if (response.status == ApiStatus.success) {
        final data = response.data;
        dev.log('📦 Response data type: ${data.runtimeType}',
            name: 'WeeklySummaryProvider');

        // API response structure: { status: 1, message: "success", total: 1, data: {...} }
        if (data != null && data['data'] != null) {
          dev.log('✅ Found data in response', name: 'WeeklySummaryProvider');

          _currentWeeklySummary = WeeklySummaryResponse.fromJson(data);

          dev.log('✅ Successfully parsed weekly summary data',
              name: 'WeeklySummaryProvider');
          dev.log(
              '💰 Total earnings: ₹${_currentWeeklySummary!.summary.totalEarnings}',
              name: 'WeeklySummaryProvider');
          dev.log(
              '📊 Period: ${_currentWeeklySummary!.periodName}',
              name: 'WeeklySummaryProvider');

          weeklySummaryState = ApiResponse.success(_currentWeeklySummary);
        } else {
          dev.log('⚠️ Response structure is invalid',
              name: 'WeeklySummaryProvider');
          _currentWeeklySummary = null;
          weeklySummaryState = ApiResponse.success(null);
        }
      } else {
        dev.log('❌ API response error: ${response.message}',
            name: 'WeeklySummaryProvider');
        _currentWeeklySummary = null;
        weeklySummaryState = ApiResponse.error(response.message);
      }
    } catch (e, stackTrace) {
      dev.log('💥 Unexpected error: $e', name: 'WeeklySummaryProvider');
      dev.log('Stack trace: $stackTrace', name: 'WeeklySummaryProvider');
      _currentWeeklySummary = null;
      weeklySummaryState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }
}
