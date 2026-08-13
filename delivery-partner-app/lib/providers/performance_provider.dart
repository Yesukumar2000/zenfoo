import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/performance_earnings_model.dart';
import 'package:zenfoo_partner/repository/performance_repository.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'dart:developer' as dev;

class PerformanceProvider with ChangeNotifier {
  final PerformanceRepository _performanceRepository = PerformanceRepository();

  // State for performance data
  ApiResponse<PerformanceEarnings> performanceState =
      ApiResponse.nothing();
  PerformanceEarnings? _currentPerformance;
  PerformanceEarnings? get currentPerformance => _currentPerformance;

  // Current filter
  String _currentPeriod = 'daily';
  String get currentPeriod => _currentPeriod;

  // Offset tracking for navigation
  int _currentOffset = 0;
  int get currentOffset => _currentOffset;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  /// Get performance earnings data
  /// Parameters:
  /// - period: 'daily', 'weekly', or 'monthly'
  /// - offset: offset for navigation (0 = current, -1 = previous, 1 = next)
  /// - date: specific date (used when offset is not provided)
  /// - fromDate: start date for range queries
  /// - toDate: end date for range queries
  Future<void> getPerformanceEarnings({
    String period = 'daily',
    int? offset,
    String? date,
    String? fromDate,
    String? toDate,
  }) async {
    dev.log('🔵 Starting getPerformanceEarnings() with period: $period, offset: $offset',
        name: 'PerformanceProvider');
    performanceState = ApiResponse.loading();
    notifyListeners();

    try {
      _currentPeriod = period;
      if (offset != null) {
        _currentOffset = offset;
      }

      final response = await _performanceRepository.getPerformanceEarnings(
        period: period,
        offset: offset,
        date: date,
        fromDate: fromDate,
        toDate: toDate,
      );

      dev.log('📥 Repository response status: ${response.status}',
          name: 'PerformanceProvider');

      if (response.status == ApiStatus.success) {
        final data = response.data;
        dev.log('📦 Response data type: ${data.runtimeType}',
            name: 'PerformanceProvider');

        // API response structure: { status: true, message: "...", data: {...} }
        if (data != null && data['data'] != null) {
          dev.log('✅ Found data in response',
              name: 'PerformanceProvider');

          _currentPerformance =
              PerformanceEarnings.fromJson(data['data']);

          dev.log('✅ Successfully parsed performance data',
              name: 'PerformanceProvider');
          dev.log(
              '📋 Total earnings: ₹${_currentPerformance!.earningsOverview.totalEarnings}',
              name: 'PerformanceProvider');

          performanceState = ApiResponse.success(_currentPerformance);
        } else {
          dev.log('⚠️ Response structure is invalid',
              name: 'PerformanceProvider');
          _currentPerformance = null;
          performanceState = ApiResponse.success(null);
        }
      } else {
        dev.log('❌ API response error: ${response.message}',
            name: 'PerformanceProvider');
        _currentPerformance = null;
        performanceState = ApiResponse.error(response.message);
      }
    } catch (e, stackTrace) {
      dev.log('💥 Unexpected error: $e', name: 'PerformanceProvider');
      dev.log('Stack trace: $stackTrace', name: 'PerformanceProvider');
      _currentPerformance = null;
      performanceState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }

  /// Update selected date
  void updateSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Refresh current data
  void refresh() {
    getPerformanceEarnings(
      period: _currentPeriod,
      date: _currentPeriod == 'daily'
          ? _formatDate(_selectedDate)
          : null,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
