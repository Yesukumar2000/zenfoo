import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/floating_cash_model.dart';
import 'package:zenfoo_partner/repository/floating_cash_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class FloatingCashProvider with ChangeNotifier {
  final FloatingCashRepository _floatingCashRepository =
      FloatingCashRepository();

  // State for floating cash data
  ApiResponse<FloatingCashResponse> floatingCashState =
      ApiResponse.nothing();
  FloatingCashResponse? _currentFloatingCash;
  FloatingCashResponse? get currentFloatingCash => _currentFloatingCash;

  // Offset tracking for navigation
  int _currentOffset = 0;
  int get currentOffset => _currentOffset;

  // Period tracking
  String _currentPeriod = 'weekly';
  String get currentPeriod => _currentPeriod;

  /// Get floating cash data
  /// Parameters:
  /// - period: 'daily', 'weekly', or 'monthly'
  /// - offset: offset for navigation (0 = current, -1 = previous, 1 = next, etc.)
  Future<void> getFloatingCash({
    String period = 'weekly',
    int? offset,
  }) async {
    dev.log('🔵 Starting getFloatingCash() with period: $period, offset: $offset',
        name: 'FloatingCashProvider');
    floatingCashState = ApiResponse.loading();
    notifyListeners();

    try {
      _currentPeriod = period;
      if (offset != null) {
        _currentOffset = offset;
      }

      final response = await _floatingCashRepository.getFloatingCash(
        period: _currentPeriod,
        offset: _currentOffset,
      );

      dev.log('📥 Repository response status: ${response.status}',
          name: 'FloatingCashProvider');

      if (response.status == ApiStatus.success) {
        final data = response.data;
        dev.log('📦 Response data type: ${data.runtimeType}',
            name: 'FloatingCashProvider');

        // API response structure: { status: 1, message: "success", total: 1, data: {...} }
        if (data != null && data['data'] != null) {
          dev.log('✅ Found data in response', name: 'FloatingCashProvider');

          _currentFloatingCash = FloatingCashResponse.fromJson(data);

          dev.log('✅ Successfully parsed floating cash data',
              name: 'FloatingCashProvider');
          dev.log(
              '💰 Total pending cash: ₹${_currentFloatingCash!.data.summary.totalPendingCash}',
              name: 'FloatingCashProvider');
          dev.log(
              '📊 Total transactions: ${_currentFloatingCash!.data.summary.totalTransactions}',
              name: 'FloatingCashProvider');

          floatingCashState = ApiResponse.success(_currentFloatingCash);
        } else {
          dev.log('⚠️ Response structure is invalid',
              name: 'FloatingCashProvider');
          _currentFloatingCash = null;
          floatingCashState = ApiResponse.success(null);
        }
      } else {
        dev.log('❌ API response error: ${response.message}',
            name: 'FloatingCashProvider');
        _currentFloatingCash = null;
        floatingCashState = ApiResponse.error(response.message);
      }
    } catch (e, stackTrace) {
      dev.log('💥 Unexpected error: $e', name: 'FloatingCashProvider');
      dev.log('Stack trace: $stackTrace', name: 'FloatingCashProvider');
      _currentFloatingCash = null;
      floatingCashState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }
}
