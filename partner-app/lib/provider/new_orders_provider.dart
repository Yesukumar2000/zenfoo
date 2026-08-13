import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/new_order.dart' as new_order;
import 'package:project/repositories/newOrdersApi.dart';
import 'package:project/services/firebase_orders_service.dart';

enum NewOrdersState {
  initial,
  loading,
  silentLoading,
  loaded,
  empty,
  loadingMore,
  error
}

class NewOrdersProvider extends ChangeNotifier {
  NewOrdersState _ordersState = NewOrdersState.initial;
  String _message = '';
  new_order.NewOrderResponse? _orderResponse;
  List<new_order.OrderData> _ordersList = [];
  List<new_order.StatusOrderCount> _statusOrderCounts = [];
  int _selectedStatus = 0;
  int _currentPage = 1;
  bool _hasMoreData = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _useNewApi = true; // Toggle to use new API
  bool _hasNewOrderNotification = false;

  // Firebase real-time listener
  final FirebaseOrdersService _firebaseService = FirebaseOrdersService();
  StreamSubscription<List<new_order.OrderData>>? _firebaseStreamSubscription;
  bool _useFirebaseRealtimeUpdates = true;

  NewOrdersState get ordersState => _ordersState;
  String get message => _message;
  new_order.NewOrderResponse? get orderResponse => _orderResponse;
  List<new_order.OrderData> get ordersList => _ordersList;
  List<new_order.StatusOrderCount> get statusOrderCounts => _statusOrderCounts;
  int get selectedStatus => _selectedStatus;
  int get currentPage => _currentPage;
  bool get hasMoreData => _hasMoreData;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  bool get hasNewOrderNotification => _hasNewOrderNotification;

  void clearNewOrderNotification() {
    _hasNewOrderNotification = false;
  }

  // Set date range for filtering
  void setDateRange(DateTime? from, DateTime? to) {
    _fromDate = from;
    _toDate = to;
    notifyListeners();
  }

  // Clear date range
  void clearDateRange() {
    _fromDate = null;
    _toDate = null;
    notifyListeners();
  }

  Future<void> changeSelectedStatus(int status) async {
    _selectedStatus = status;
    notifyListeners();
  }

  Future<void> getOrders({
    required BuildContext context,
    Map<String, String>? params,
    bool silentLoading = false,
    bool reset = false,
  }) async {
    try {
      // For silent refresh, don't reset or clear the list to avoid UI flicker
      if (reset && !silentLoading) {
        _currentPage = 1;
        _ordersList.clear();
        _statusOrderCounts = [];
      } else if (reset && silentLoading) {
        // Silent refresh - just reset to page 1 but keep existing data
        _currentPage = 1;
      }

      if (silentLoading) {
        _ordersState = NewOrdersState.silentLoading;
      } else if (_ordersList.isEmpty) {
        _ordersState = NewOrdersState.loading;
      } else {
        _ordersState = NewOrdersState.loadingMore;
      }

      // Don't notify listeners for silent loading to avoid UI updates
      if (!silentLoading) {
        notifyListeners();
      }

      Map<String, String> apiParams = {
        'per_page': '20',
        'page': _currentPage.toString(),
      };

      // Use new API with order_status param
      if (_useNewApi) {
        // "New Orders" tab (id=0) → filter to Awaiting (active_status=1)
        if (_selectedStatus == 0) {
          apiParams[ApiAndParams.orderStatus] = '1';
        } else {
          apiParams[ApiAndParams.orderStatus] = _selectedStatus.toString();
        }

        // Add date range filters
        if (_fromDate != null) {
          apiParams[ApiAndParams.fromDate] =
              '${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}';
        }
        if (_toDate != null) {
          apiParams[ApiAndParams.toDate] =
              '${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}';
        }
      } else {
        // Legacy API uses 'status' param
        if (_selectedStatus != 0) {
          apiParams['status'] = _selectedStatus.toString();
        }
      }

      // Add search and other params
      if (params != null) {
        apiParams.addAll(params);
      }

      // Debug log to verify search is being passed
      debugPrint('=== Orders API Params ===');
      debugPrint('apiParams: $apiParams');

      // Use new API endpoint
      final response = _useNewApi
          ? await getOrdersStatusTracking(params: apiParams, context: context)
          : await getNewOrdersRepository(params: apiParams, context: context);

      if (response[ApiAndParams.status].toString() == "1") {
        _orderResponse = new_order.NewOrderResponse.fromJson(response);

        if (_orderResponse != null) {
          // Update status counts (only on first page)
          if (_currentPage == 1 && _orderResponse!.statusOrderCount != null) {
            _statusOrderCounts = _orderResponse!.statusOrderCount!;
          }

          // Add new orders to the list
          if (_orderResponse!.data != null && _orderResponse!.data!.isNotEmpty) {
            // For silent refresh on page 1, replace the list instead of adding
            if (silentLoading && _currentPage == 1) {
              _ordersList = _orderResponse!.data!;
            } else {
              _ordersList.addAll(_orderResponse!.data!);
            }

            // Check if there are more pages
            if (_orderResponse!.pagination != null) {
              _hasMoreData = _currentPage < (_orderResponse!.pagination!.lastPage ?? 1);
              if (_hasMoreData && !silentLoading) {
                _currentPage++;
              }
            }

            _ordersState = NewOrdersState.loaded;
          } else {
            _ordersState = _ordersList.isEmpty ? NewOrdersState.empty : NewOrdersState.loaded;
            _hasMoreData = false;
          }
        } else {
          _ordersState = _ordersList.isEmpty ? NewOrdersState.empty : NewOrdersState.loaded;
          _hasMoreData = false;
        }
      } else {
        _message = response[ApiAndParams.message] ?? 'Something went wrong';
        _ordersState = NewOrdersState.error;
      }
    } catch (e) {
      _message = e.toString();
      _ordersState = NewOrdersState.error;
    }
    notifyListeners();
  }

  /// Start listening to Firebase real-time order updates
  void startFirebaseListener({required int sellerId}) {
    if (!_useFirebaseRealtimeUpdates) return;

    // Cancel existing subscription
    _firebaseStreamSubscription?.cancel();

    // Start new Firebase listener (only for new order notifications, not list replacement)
    _firebaseStreamSubscription = _firebaseService.listenToSellerOrders(
      sellerId: sellerId,
      onNewOrders: (newOrderIds) {
        debugPrint('🔔 New orders detected: $newOrderIds');
        // New order sound is played automatically by Firebase service
        // Signal that a refresh is needed (the screen will call getOrders with current filters)
        _hasNewOrderNotification = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
      },
    ).listen(
      (_) {
        // Do not replace _ordersList from Firebase — API handles filtered data
      },
      onError: (error) {
        debugPrint('❌ Firebase listener error: $error');
      },
    );
  }

  /// Stop Firebase real-time listener
  void stopFirebaseListener() {
    _firebaseStreamSubscription?.cancel();
    _firebaseStreamSubscription = null;
    _firebaseService.dispose();
  }

  /// Fallback to API if Firebase is not available
  void disableFirebaseAndUseApi() {
    _useFirebaseRealtimeUpdates = false;
    stopFirebaseListener();
  }

  @override
  void dispose() {
    stopFirebaseListener();
    super.dispose();
  }
}
