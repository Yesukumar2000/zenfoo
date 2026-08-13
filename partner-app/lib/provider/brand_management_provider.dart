import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/brand.dart';
import 'package:project/repositories/brandApi.dart';

class BrandManagementProvider extends ChangeNotifier {
  List<BrandData> brands = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasError = false;
  String errorMessage = '';
  bool hasMorePages = true;

  int currentPage = 1;
  int totalBrands = 0;
  final int perPage = 20;

  // Fetch brands with pagination
  Future<void> fetchBrands(
      {bool isRefresh = false, BuildContext? context}) async {
    if (isRefresh) {
      currentPage = 1;
      brands.clear();
      hasMorePages = true;
    }

    if (isLoading || isLoadingMore) return;

    if (brands.isEmpty) {
      isLoading = true;
    } else {
      isLoadingMore = true;
    }
    hasError = false;
    notifyListeners();

    try {
      Map<String, dynamic> params = {
        'page': currentPage.toString(),
        'per_page': perPage.toString(),
      };

      // Use provided context or try to get from Constant.navigatorKay
      final ctx = context ?? Constant.navigatorKay.currentContext;
      if (ctx == null) {
        throw Exception('Context not available');
      }

      final response = await getBrandApi(
        context: ctx,
        params: params,
      );

      if (response['status'].toString() == '1') {
        // final brandModel = Brand.fromJson(response);
        final brandsData = response['data']['data'] as List<dynamic>? ?? [];
        final newBrands = brandsData
            .map((x) => BrandData.fromJson(x as Map<String, dynamic>))
            .toList();

        if (isRefresh) {
          brands = newBrands;
        } else {
          brands.addAll(newBrands);
        }

        totalBrands = int.tryParse(response['data']['total'].toString()) ?? 0;
        hasMorePages = brands.length < totalBrands;

        if (hasMorePages) {
          currentPage++;
        }

        isLoading = false;
        isLoadingMore = false;
        notifyListeners();
      } else {
        hasError = true;
        errorMessage = response['message'] ?? 'Failed to load brands';
        isLoading = false;
        isLoadingMore = false;
        notifyListeners();
      }
    } catch (e) {
      hasError = true;
      errorMessage = e.toString();

      isLoading = false;
      isLoadingMore = false;
      notifyListeners();
    }
  }

  // Load more brands
  Future<void> loadMoreBrands() async {
    if (!hasMorePages || isLoadingMore) return;
    await fetchBrands();
  }

  // Create or update brand
  Future<bool> saveBrand({
    required BuildContext context,
    required String name,
    required String status,
    required List<int> categoryIds,
    File? imageFile,
    String? brandId, // null for create, brandId for update
  }) async {
    try {
      final response = await saveBrandApi(
        context: context,
        name: name,
        status: status,
        categoryIds: categoryIds,
        imageFile: imageFile,
        brandId: brandId,
      );

      if (response['status'].toString() == '1' || response['success'] == true) {
        // Refresh the brand list after successful save
        await fetchBrands(isRefresh: true, context: context);

        showMessage(
          context,
          response['message'] ??
              (brandId == null
                  ? 'Brand created successfully'
                  : 'Brand updated successfully'),
          MessageType.success,
        );
        return true;
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to save brand',
          MessageType.error,
        );
        return false;
      }
    } catch (e) {
      showMessage(context, 'Error: $e', MessageType.error);
      return false;
    }
  }

  // Delete brand
  Future<bool> deleteBrand(BuildContext context, String brandId) async {
    try {
      final response = await deleteBrandApi(
        context: context,
        brandId: brandId,
      );

      if (response['status'].toString() == '1' || response['success'] == true) {
        // Remove from local list
        brands.removeWhere((brand) => brand.id == brandId);
        totalBrands--;
        notifyListeners();
        return true;
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to delete brand',
          MessageType.error,
        );
        return false;
      }
    } catch (e) {
      showMessage(context, 'Error: $e', MessageType.error);
      return false;
    }
  }

  // Reset provider
  void reset() {
    brands.clear();
    currentPage = 1;
    totalBrands = 0;
    hasMorePages = true;
    isLoading = false;
    isLoadingMore = false;
    hasError = false;
    errorMessage = '';
    notifyListeners();
  }
}
