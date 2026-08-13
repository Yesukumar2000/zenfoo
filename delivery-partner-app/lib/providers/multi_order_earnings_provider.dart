import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/multi_order_earnings_model.dart';
import 'package:zenfoo_partner/repository/multi_order_earnings_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class MultiOrderEarningsProvider with ChangeNotifier {
  final MultiOrderEarningsRepository _multiOrderEarningsRepository =
      MultiOrderEarningsRepository();

  // State for multi-order earnings data
  ApiResponse<MultiOrderEarningsResponse> multiOrderEarningsState =
      ApiResponse.nothing();
  MultiOrderEarningsResponse? _currentMultiOrderEarnings;
  MultiOrderEarningsResponse? get currentMultiOrderEarnings =>
      _currentMultiOrderEarnings;

  // Offset tracking for navigation
  int _currentOffset = 0;
  int get currentOffset => _currentOffset;

  /// Get multi-order earnings data
  /// Parameters:
  /// - period: 'weekly' (monthly is hidden)
  /// - offset: offset for navigation (0 = current period, -1 = previous)
  Future<void> getMultiOrderEarnings({
    String period = 'weekly',
    int? offset,
  }) async {
    dev.log('🔵 Starting getMultiOrderEarnings() with period: $period, offset: $offset',
        name: 'MultiOrderEarningsProvider');
    multiOrderEarningsState = ApiResponse.loading();
    notifyListeners();

    try {
      if (offset != null) {
        _currentOffset = offset;
      }

      final response = await _multiOrderEarningsRepository.getMultiOrderEarnings(
        period: period,
        offset: _currentOffset,
      );

      dev.log('📥 Repository response status: ${response.status}',
          name: 'MultiOrderEarningsProvider');

      if (response.status == ApiStatus.success) {
        final data = response.data;
        dev.log('📦 Response data type: ${data.runtimeType}',
            name: 'MultiOrderEarningsProvider');

        // API response structure: { status: 1, message: "success", total: 1, data: {...} }
        if (data != null && data['data'] != null) {
          dev.log('✅ Found data in response', name: 'MultiOrderEarningsProvider');

          _currentMultiOrderEarnings =
              MultiOrderEarningsResponse.fromJson(data);

          dev.log('✅ Successfully parsed multi-order earnings data',
              name: 'MultiOrderEarningsProvider');
          dev.log(
              '💰 Total bonus: ₹${_currentMultiOrderEarnings!.summary.totalMultiOrderBonus}',
              name: 'MultiOrderEarningsProvider');
          dev.log(
              '📊 Period: ${_currentMultiOrderEarnings!.periodName}',
              name: 'MultiOrderEarningsProvider');

          multiOrderEarningsState =
              ApiResponse.success(_currentMultiOrderEarnings);
        } else {
          dev.log('⚠️ Response structure is invalid',
              name: 'MultiOrderEarningsProvider');
          _currentMultiOrderEarnings = null;
          multiOrderEarningsState = ApiResponse.success(null);
        }
      } else {
        dev.log('❌ API response error: ${response.message}',
            name: 'MultiOrderEarningsProvider');
        _currentMultiOrderEarnings = null;
        multiOrderEarningsState = ApiResponse.error(response.message);
      }
    } catch (e, stackTrace) {
      dev.log('💥 Unexpected error: $e', name: 'MultiOrderEarningsProvider');
      dev.log('Stack trace: $stackTrace', name: 'MultiOrderEarningsProvider');
      _currentMultiOrderEarnings = null;
      multiOrderEarningsState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }
}
