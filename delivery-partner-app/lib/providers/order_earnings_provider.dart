import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/order_earnings_model.dart';
import 'package:zenfoo_partner/repository/order_earnings_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class OrderEarningsProvider with ChangeNotifier {
  final OrderEarningsRepository _orderEarningsRepository =
      OrderEarningsRepository();

  // State for order earnings data
  ApiResponse<OrderEarningsResponse> orderEarningsState =
      ApiResponse.nothing();
  OrderEarningsResponse? _currentOrderEarnings;
  OrderEarningsResponse? get currentOrderEarnings => _currentOrderEarnings;

  // Offset tracking for navigation
  int _currentOffset = 0;
  int get currentOffset => _currentOffset;

  // Period tracking
  String _currentPeriod = 'daily';
  String get currentPeriod => _currentPeriod;

  // Cancelled tracking
  int _currentIsCancelled = 0;
  int get currentIsCancelled => _currentIsCancelled;

  Future<void> getOrderEarnings({
    String period = 'daily',
    int? offset,
    int isCancelled = 0,
  }) async {
    dev.log(
        '🔵 Starting getOrderEarnings() with period: $period, offset: $offset, isCancelled: $isCancelled',
        name: 'OrderEarningsProvider');
    orderEarningsState = ApiResponse.loading();
    notifyListeners();

    try {
      _currentPeriod = period;
      _currentIsCancelled = isCancelled;
      if (offset != null) {
        _currentOffset = offset;
      }

      final response = await _orderEarningsRepository.getOrderEarnings(
        period: _currentPeriod,
        offset: _currentOffset,
        isCancelled: _currentIsCancelled,
      );

      if (response.status == ApiStatus.success) {
        final data = response.data;

        if (data != null && data['data'] != null) {
          _currentOrderEarnings = OrderEarningsResponse.fromJson(data);
          dev.log(
              '✅ Parsed order earnings: ${_currentOrderEarnings!.data.summary.totalOrders} orders',
              name: 'OrderEarningsProvider');
          orderEarningsState = ApiResponse.success(_currentOrderEarnings);
        } else {
          _currentOrderEarnings = null;
          orderEarningsState = ApiResponse.success(null);
        }
      } else {
        _currentOrderEarnings = null;
        orderEarningsState = ApiResponse.error(response.message);
      }
    } catch (e) {
      dev.log('💥 Error: $e', name: 'OrderEarningsProvider');
      _currentOrderEarnings = null;
      orderEarningsState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }
}
