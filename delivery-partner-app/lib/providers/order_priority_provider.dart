import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/order_priority_model.dart';
import 'package:zenfoo_partner/repository/order_priority_repository.dart';

enum OrderPriorityStatus {
  idle,
  loading,
  loaded,
  updating,
  error,
}

class OrderPriorityProvider with ChangeNotifier {
  final OrderPriorityRepository _repository = OrderPriorityRepository();

  OrderPriorityStatus _status = OrderPriorityStatus.idle;
  OrderPriorityData? _orderPriorityData;
  String _errorMessage = '';

  OrderPriorityStatus get status => _status;
  OrderPriorityData? get orderPriorityData => _orderPriorityData;
  String get errorMessage => _errorMessage;
  bool get isLoading =>
      _status == OrderPriorityStatus.loading ||
      _status == OrderPriorityStatus.updating;

  int get currentPriority => _orderPriorityData?.currentPriority ?? 0;
  String get currentPriorityName =>
      _orderPriorityData?.currentPriorityName ?? 'Both';
  List<OrderPriorityOption> get priorityOptions =>
      _orderPriorityData?.priorityOptions ?? [];

  /// Fetch order priority settings
  Future<void> fetchOrderPriority() async {
    _status = OrderPriorityStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _repository.getOrderPriority();
      _orderPriorityData = response.data;
      _status = OrderPriorityStatus.loaded;
      debugPrint(
          '✅ Order priority fetched: ${_orderPriorityData?.currentPriorityName}');
    } catch (e, stackTrace) {
      _status = OrderPriorityStatus.error;
      _errorMessage = e.toString();
      debugPrint('❌ Error fetching order priority: $e\n$stackTrace');
    }

    notifyListeners();
  }

  /// Update order priority
  Future<bool> updateOrderPriority(int ordersPriority) async {
    _status = OrderPriorityStatus.updating;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _repository.updateOrderPriority(ordersPriority);

      // Update local data
      if (_orderPriorityData != null) {
        _orderPriorityData = OrderPriorityData(
          currentPriority: response.data.ordersPriority,
          currentPriorityName: response.data.ordersPriorityName,
          priorityOptions: _orderPriorityData!.priorityOptions,
        );
      }

      _status = OrderPriorityStatus.loaded;
      debugPrint(
          '✅ Order priority updated: ${response.data.ordersPriorityName}');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _status = OrderPriorityStatus.error;
      _errorMessage = e.toString();
      debugPrint('❌ Error updating order priority: $e\n$stackTrace');
      notifyListeners();
      return false;
    }
  }

  /// Clear data
  void clear() {
    _orderPriorityData = null;
    _status = OrderPriorityStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }
}
