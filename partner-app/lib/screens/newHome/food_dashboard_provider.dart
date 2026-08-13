import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/statistics.dart';
import 'package:project/models/stock_product.dart';
import 'package:project/repositories/statisticsApi.dart';

class FoodDashboardProvider extends ChangeNotifier {
  // Store data
  String storeName = '';
  String storeLocation = '';
  String businessName = '';
  double? latitude;
  double? longitude;
  bool isStoreOpen = false;
  String? storeId;

  // Statistics data
  StatisticsData? statistics;
  SellerInfo? sellerInfo;
  Overview? overview;
  List<OrderStatusCount>? orderStatusCounts;
  List<CategoryWiseProduct>? categoryWiseProducts;

  // Stock products data
  List<StockProduct> soldOutProducts = [];
  List<StockProduct> lowStockProducts = [];
  int soldOutCount = 0;
  int lowStockCount = 0;
  bool isLoadingSoldOut = false;
  bool isLoadingLowStock = false;

  // Loading states
  bool isLoading = false;
  bool isLoadingStats = false;
  bool isUpdatingLocation = false;
  bool isUpdatingStatus = false;

  /// Fetch seller/store data from API
  Future<void> fetchStoreData() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await sendApiRequest(
        apiName: 'registration-data-dev',
        params: {},
        isPost: false,
      );

      final Map<String, dynamic> data = json.decode(response);

      if (data['status'] == 1 && data['data'] != null) {
        final seller = data['data']['seller'];

        // Parse store data
        storeName = seller['store_name'] ?? '';
        storeLocation = seller['store_location'] ?? '';
        businessName = seller['name'] ?? 'Zenfoo Business';
        storeId = seller['store_id']?.toString();
        final userId = seller['id']?.toString();

        Constant.session.setUserData(data: seller);
        Constant.session
            .setData(SessionManager.keyStoreId, storeId ?? '', true);
        Constant.session.setData(SessionManager.keyUserId, userId ?? '', true);

        // Parse store status using safe parsing
        isStoreOpen = safeParseBool(seller['shop_status']);

        // Parse lat/long
        if (seller['lat_long'] != null &&
            seller['lat_long'].toString().isNotEmpty) {
          final latLong = seller['lat_long'].toString().split(',');
          if (latLong.length == 2) {
            latitude = double.tryParse(latLong[0].trim());
            longitude = double.tryParse(latLong[1].trim());
          }
        }

        // Store FSSAI number from registration data
        if (seller['fssai_number'] != null) {
          Constant.session.setData(
            SessionManager.fssai_number,
            seller['fssai_number'].toString(),
            false,
          );
        }

        // Store store type name from registration data
        if (seller['store_type_name'] != null) {
          Constant.session.setData(
            SessionManager.store_type_name,
            seller['store_type_name'].toString(),
            false,
          );
        }

        isLoading = false;
        notifyListeners();
      } else {
        isLoading = false;
        notifyListeners();
        throw Exception(data['message'] ?? 'Failed to fetch store data');
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch statistics data from API
  Future<void> fetchStatistics(BuildContext context) async {
    isLoadingStats = true;
    notifyListeners();

    try {
      final response = await getStatistics(context: context);

      if (response != null && response.data != null) {
        statistics = response.data;
        sellerInfo = response.data!.sellerInfo;
        overview = response.data!.overview;
        orderStatusCounts = response.data!.orderStatusCounts;
        categoryWiseProducts = response.data!.categoryWiseProducts;
      }

      isLoadingStats = false;
      notifyListeners();
    } catch (e) {
      isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Fetch sold out products for home screen
  Future<void> fetchSoldOutProducts() async {
    isLoadingSoldOut = true;
    notifyListeners();

    try {
      final response = await sendApiRequest(
        apiName: ApiAndParams.apiSoldOutProducts,
        params: {'page': '1', 'per_page': '5'},
        isPost: false,
      );

      final Map<String, dynamic> data = json.decode(response);
      final parsed = StockProductResponse.fromJson(data);

      if (parsed.status == 1 &&
          parsed.data?.data != null) {
        soldOutProducts = parsed.data!.data!;
        soldOutCount = parsed.totalCount ?? 0;
      }
    } catch (e) {
      debugPrint('Error fetching sold out products: $e');
    } finally {
      isLoadingSoldOut = false;
      notifyListeners();
    }
  }

  /// Fetch low stock products for home screen
  Future<void> fetchLowStockProducts() async {
    isLoadingLowStock = true;
    notifyListeners();

    try {
      final response = await sendApiRequest(
        apiName: ApiAndParams.apiLowStockProducts,
        params: {'page': '1', 'per_page': '5'},
        isPost: false,
      );

      final Map<String, dynamic> data = json.decode(response);
      final parsed = StockProductResponse.fromJson(data);

      if (parsed.status == 1 &&
          parsed.data?.data != null) {
        lowStockProducts = parsed.data!.data!;
        lowStockCount = parsed.totalCount ?? 0;
      }
    } catch (e) {
      debugPrint('Error fetching low stock products: $e');
    } finally {
      isLoadingLowStock = false;
      notifyListeners();
    }
  }

  /// Update store location
  Future<bool> updateStoreLocation({
    required BuildContext context,
    required String newLocation,
    required double lat,
    required double lng,
  }) async {
    isUpdatingLocation = true;
    notifyListeners();

    try {
      final response = await sendApiRequest(
        apiName: 'update-store-location-dev',
        params: {
          'store_id': storeId ?? '',
          'store_location': newLocation,
          'latitude': lat.toString(),
          'longitude': lng.toString(),
        },
        isPost: true,
      );

      final Map<String, dynamic> data = json.decode(response);

      if (data['status'] == 1) {
        // Update local state
        storeLocation = newLocation;
        latitude = lat;
        longitude = lng;

        isUpdatingLocation = false;
        notifyListeners();

        showMessage(
          context,
          data['message'] ?? 'Store location updated successfully',
          MessageType.success,
        );
        return true;
      } else {
        isUpdatingLocation = false;
        notifyListeners();

        showMessage(
          context,
          data['message'] ?? 'Failed to update store location',
          MessageType.warning,
        );
        return false;
      }
    } catch (e) {
      isUpdatingLocation = false;
      notifyListeners();

      showMessage(
        context,
        'Error updating location: ${e.toString()}',
        MessageType.error,
      );
      return false;
    }
  }

  /// Update store open/close status
  Future<bool> updateStoreStatus({
    required BuildContext context,
    required bool isOpen,
  }) async {
    isUpdatingStatus = true;
    notifyListeners();

    try {
      final response = await sendApiRequest(
        apiName:
            'update-shop-status-of-seller?shop_id=${storeId}&status=${isOpen ? 1 : 0}',
        params: {},
        isPost: true,
      );

      final Map<String, dynamic> data = json.decode(response);

      if (data['status'] == 1) {
        // Update local state
        isStoreOpen = isOpen;

        isUpdatingStatus = false;
        notifyListeners();

        showMessage(
          context,
          data['message'] ?? 'Store status updated successfully',
          MessageType.success,
        );
        return true;
      } else {
        isUpdatingStatus = false;
        notifyListeners();

        showMessage(
          context,
          data['message'] ?? 'Failed to update store status',
          MessageType.warning,
        );
        return false;
      }
    } catch (e) {
      isUpdatingStatus = false;
      notifyListeners();

      showMessage(
        context,
        'Error updating status: ${e.toString()}',
        MessageType.error,
      );
      return false;
    }
  }
}
