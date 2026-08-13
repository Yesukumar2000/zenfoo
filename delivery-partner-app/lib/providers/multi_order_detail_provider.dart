import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/multi_order_detail_model.dart';
import 'package:zenfoo_partner/repository/multi_order_detail_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class MultiOrderDetailProvider with ChangeNotifier {
  final MultiOrderDetailRepository _repository = MultiOrderDetailRepository();

  ApiResponse<MultiOrderDetailResponse> detailState = ApiResponse.nothing();
  MultiOrderDetailResponse? _currentDetail;
  MultiOrderDetailResponse? get currentDetail => _currentDetail;

  Future<void> getMultiOrderDetail({required int orderId}) async {
    dev.log('🔵 Starting getMultiOrderDetail() for order: $orderId',
        name: 'MultiOrderDetailProvider');
    detailState = ApiResponse.loading();
    notifyListeners();

    try {
      final response =
          await _repository.getMultiOrderDetail(orderId: orderId);

      if (response.status == ApiStatus.success) {
        final data = response.data;
        if (data != null && data['data'] != null) {
          _currentDetail = MultiOrderDetailResponse.fromJson(
              data['data'] as Map<String, dynamic>);
          detailState = ApiResponse.success(_currentDetail);
          dev.log('✅ Successfully parsed multi-order detail',
              name: 'MultiOrderDetailProvider');
        } else {
          _currentDetail = null;
          detailState = ApiResponse.error('No data found');
        }
      } else {
        _currentDetail = null;
        detailState = ApiResponse.error(response.message);
      }
    } catch (e) {
      dev.log('💥 Error: $e', name: 'MultiOrderDetailProvider');
      _currentDetail = null;
      detailState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }
}
