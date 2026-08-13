import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/payment_history_model.dart';
import 'package:zenfoo_partner/repository/payment_history_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class PaymentHistoryProvider extends ChangeNotifier {
  final PaymentHistoryRepository _repository = PaymentHistoryRepository();

  ApiResponse<PaymentHistoryResponse> historyState = ApiResponse.nothing();
  PaymentHistoryResponse? _currentHistory;
  PaymentHistoryResponse? get currentHistory => _currentHistory;

  int _currentOffset = 0;
  int get currentOffset => _currentOffset;

  String _currentPeriod = 'daily';
  String get currentPeriod => _currentPeriod;

  Future<void> fetchHistory({
    String period = 'daily',
    int? offset,
  }) async {
    dev.log(
        '🔵 Starting fetchHistory() with period: $period, offset: $offset',
        name: 'PaymentHistoryProvider');
    historyState = ApiResponse.loading();
    notifyListeners();

    try {
      _currentPeriod = period;
      if (offset != null) {
        _currentOffset = offset;
      }

      final response = await _repository.getPaymentHistory(
        period: _currentPeriod,
        offset: _currentOffset,
      );

      if (response.status == ApiStatus.success) {
        final data = response.data;

        if (data != null && data['data'] != null) {
          _currentHistory = PaymentHistoryResponse.fromJson(data);
          dev.log(
              '✅ Parsed payment history: ${_currentHistory!.data.summary.totalPayments} payments',
              name: 'PaymentHistoryProvider');
          historyState = ApiResponse.success(_currentHistory);
        } else {
          _currentHistory = null;
          historyState = ApiResponse.success(null);
        }
      } else {
        _currentHistory = null;
        historyState = ApiResponse.error(response.message);
      }
    } catch (e) {
      dev.log('💥 Error: $e', name: 'PaymentHistoryProvider');
      _currentHistory = null;
      historyState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }
}
