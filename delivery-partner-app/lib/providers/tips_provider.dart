import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/tips_model.dart';
import 'package:zenfoo_partner/repository/tips_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class TipsProvider with ChangeNotifier {
  final TipsRepository _tipsRepository = TipsRepository();

  // State for tips data
  ApiResponse<TipsResponse> tipsState = ApiResponse.nothing();
  TipsResponse? _currentTips;
  TipsResponse? get currentTips => _currentTips;

  // Offset tracking for navigation
  int _currentOffset = 0;
  int get currentOffset => _currentOffset;

  /// Get weekly tips data
  /// Parameters:
  /// - offset: offset for navigation (0 = current week, -1 = previous, 1 = next)
  Future<void> getWeeklyTips({int? offset}) async {
    dev.log('🔵 Starting getWeeklyTips() with offset: $offset',
        name: 'TipsProvider');
    tipsState = ApiResponse.loading();
    notifyListeners();

    try {
      if (offset != null) {
        _currentOffset = offset;
      }

      final response = await _tipsRepository.getWeeklyTips(
        offset: _currentOffset,
      );

      dev.log('📥 Repository response status: ${response.status}',
          name: 'TipsProvider');

      if (response.status == ApiStatus.success) {
        final data = response.data;
        dev.log('📦 Response data type: ${data.runtimeType}',
            name: 'TipsProvider');

        // API response structure: { status: true, message: "...", data: {...} }
        if (data != null && data['data'] != null) {
          dev.log('✅ Found data in response', name: 'TipsProvider');

          _currentTips = TipsResponse.fromJson(data['data']);

          dev.log('✅ Successfully parsed tips data', name: 'TipsProvider');
          dev.log('💰 Total tips: ₹${_currentTips!.weekSummary.totalTips}',
              name: 'TipsProvider');

          tipsState = ApiResponse.success(_currentTips);
        } else {
          dev.log('⚠️ Response structure is invalid', name: 'TipsProvider');
          _currentTips = null;
          tipsState = ApiResponse.success(null);
        }
      } else {
        dev.log('❌ API response error: ${response.message}',
            name: 'TipsProvider');
        _currentTips = null;
        tipsState = ApiResponse.error(response.message);
      }
    } catch (e, stackTrace) {
      dev.log('💥 Unexpected error: $e', name: 'TipsProvider');
      dev.log('Stack trace: $stackTrace', name: 'TipsProvider');
      _currentTips = null;
      tipsState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }
}
