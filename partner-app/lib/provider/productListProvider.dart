import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/filterProducts.dart';
import 'package:project/models/productList.dart';
import 'package:project/repositories/addProductApi.dart';

enum ProductState {
  initial,
  loaded,
  loading,
  loadingMore,
  empty,
  error,
}

class ProductListProvider extends ChangeNotifier {
  ProductState productState = ProductState.initial;
  String message = '';
  late ProductList productList;
  List<ProductListItem> products = [];
  late FilterProducts filterProduct;
  List<FilterProductsDataProducts> filterProductsData = [];
  bool hasMoreData = false;
  int totalData = 0;
  int offset = 0;

  // Seller products specific
  List<ProductListItem> sellerProducts = [];
  int currentPage = 1;
  int lastPage = 1;
  bool get hasMorePages => currentPage < lastPage;

  // Action loading tracking (e.g., 'delete_<productId>', 'edit_<productId>')
  Map<String, bool> actionLoading = {};

  /// Update loading state for a specific action
  void setActionLoading(String key, bool value) {
    if (value) {
      actionLoading[key] = value;
    } else {
      actionLoading.remove(key);
    }
    notifyListeners();
  }

  /// Check if a specific action is loading
  bool isActionLoading(String key) => actionLoading[key] ?? false;

  getProductListProvider(
      {required Map<String, dynamic> params,
      required BuildContext context}) async {
    if (offset == 0) {
      productState = ProductState.loading;
    } else {
      productState = ProductState.loadingMore;
    }
    notifyListeners();

    params[ApiAndParams.limit] = Constant.defaultDataLoadLimitAtOnce.toString();
    params[ApiAndParams.offset] = offset.toString();

    try {
      Map<String, dynamic> response = {};
      if (params[ApiAndParams.type] == "all") {
        response = await getProductListApi(context: context, params: params);

        if (response[ApiAndParams.status].toString() == "1") {
          productList = ProductList.fromJson(response);

          totalData = int.parse(productList.total.toString());

          if (totalData > 0) {
            products.addAll(productList.data ?? []);

            hasMoreData = totalData > products.length;

            if (hasMoreData) {
              offset += Constant.defaultDataLoadLimitAtOnce;
            }
            productState = ProductState.loaded;
            notifyListeners();
          } else {
            productState = ProductState.empty;
            notifyListeners();
          }
        }
      } else {
        response =
            await getProductFilterByListApi(context: context, params: params);

        if (response[ApiAndParams.status].toString() == "1") {
          filterProduct = FilterProducts.fromJson(response);

          totalData = int.parse(filterProduct.total.toString());

          if (totalData > 0) {
            filterProductsData.addAll(filterProduct.data?.products ?? []);

            hasMoreData = totalData > filterProductsData.length;

            if (hasMoreData) {
              offset += Constant.defaultDataLoadLimitAtOnce;
            }
            productState = ProductState.loaded;
            notifyListeners();
          } else {
            productState = ProductState.empty;
            notifyListeners();
          }
        } else {
          message = "Something went wrong";
          showMessage(context, message, MessageType.error);
          productState = ProductState.empty;
          notifyListeners();
        }
      }
    } catch (e) {
      message = e.toString();
      showMessage(context, message, MessageType.error);
      productState = ProductState.error;
      notifyListeners();
    }
  }

  // Fetch seller products
  Future<void> fetchSellerProducts({
    required BuildContext context,
    bool isRefresh = false,
  }) async {
    try {
      if (isRefresh) {
        currentPage = 1;
        sellerProducts.clear();
      }

      if (productState == ProductState.loading ||
          productState == ProductState.loadingMore) {
        return;
      }

      productState =
          currentPage == 1 ? ProductState.loading : ProductState.loadingMore;
      notifyListeners();

      final response = await getSellerProductsApi(
        context: context,
        params: {
          'page': currentPage.toString(),
        },
      );

      if (response['status'] == 1) {
        final data = response['data'];

        // Parse pagination info
        currentPage = int.parse(data['current_page'].toString());
        lastPage = int.parse(data['last_page'].toString());

        // Parse products
        if (data['data'] != null) {
          final List<dynamic> productList = data['data'];
          final newProducts = productList
              .map((json) => ProductListItem.fromJson(json))
              .toList();

          if (isRefresh) {
            sellerProducts = newProducts;
          } else {
            sellerProducts.addAll(newProducts);
          }
        }

        productState =
            sellerProducts.isEmpty ? ProductState.empty : ProductState.loaded;
        message = '';
      } else {
        productState = ProductState.error;
        message = response['message'] ?? 'Failed to load products';
      }
    } catch (e) {
      productState = ProductState.error;
      message = e.toString();
      print('Error fetching seller products: $e');
    }
    notifyListeners();
  }

  // Load more seller products
  Future<void> loadMoreSellerProducts(BuildContext context) async {
    if (!hasMorePages || productState == ProductState.loadingMore) {
      return;
    }

    currentPage++;
    await fetchSellerProducts(context: context);
  }

  // Delete product
  Future<bool> deleteProduct({
    required BuildContext context,
    required String productId,
  }) async {
    final loadingKey = 'delete_$productId';
    setActionLoading(loadingKey, true);

    try {
      final response = await deleteProductApi(
        productId: productId,
        context: context,
      );

      if (response['status'] == 1) {
        // Remove from local list
        sellerProducts.removeWhere((p) => p.id == productId);
        setActionLoading(loadingKey, false);
        notifyListeners();
        if (context.mounted) {
          showMessage(
              context, 'Product deleted successfully', MessageType.success);
        }
        return true;
      } else {
        setActionLoading(loadingKey, false);
        if (context.mounted) {
          showMessage(
            context,
            response['message'] ?? 'Failed to delete product',
            MessageType.warning,
          );
        }
        return false;
      }
    } catch (e) {
      setActionLoading(loadingKey, false);
      print('Error deleting product: $e');
      if (context.mounted) {
        showMessage(
          context,
          'Error deleting product',
          MessageType.error,
        );
      }
      return false;
    }
  }

  // Reset seller products
  void resetSellerProducts() {
    sellerProducts.clear();
    currentPage = 1;
    lastPage = 1;
    productState = ProductState.initial;
    message = '';
    notifyListeners();
  }
}
