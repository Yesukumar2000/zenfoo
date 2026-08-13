import 'package:flutter/material.dart';
import 'package:project/models/campaign_products_response.dart';
import 'package:project/models/productListItem.dart';
import 'package:project/repositories/brandCampaignApi.dart';

enum CampaignProductsState { initial, loading, loaded, loadingMore, empty, error }

class CampaignProductsProvider extends ChangeNotifier {
  CampaignProductsProvider({
    required this.campaignId,
    this.perPage = 20,
  });

  final int campaignId;
  final int perPage;

  CampaignProductsState state = CampaignProductsState.initial;
  List<ProductListItem> products = [];
  List<CampaignFilterCategory> categories = [];
  CampaignProductsPagination? pagination;
  String message = '';
  String searchQuery = '';
  int? selectedCategoryId;

  bool get isLoading => state == CampaignProductsState.loading;
  bool get isLoadingMore => state == CampaignProductsState.loadingMore;
  bool get hasProducts => products.isNotEmpty;
  bool get hasMore =>
      (pagination?.currentPage ?? 0) < (pagination?.lastPage ?? 0);

  Future<void> loadInitial(BuildContext context) async {
    await _fetchProducts(context, reset: true);
  }

  Future<void> refresh(BuildContext context) async {
    await _fetchProducts(context, reset: true);
  }

  Future<void> loadMore(BuildContext context) async {
    if (isLoading || isLoadingMore || !hasMore) {
      return;
    }

    await _fetchProducts(
      context,
      reset: false,
      page: (pagination?.currentPage ?? 1) + 1,
    );
  }

  Future<void> updateSearch(BuildContext context, String value) async {
    final normalized = value.trim();
    if (searchQuery == normalized) {
      return;
    }

    searchQuery = normalized;
    await _fetchProducts(context, reset: true);
  }

  Future<void> selectCategory(BuildContext context, int? categoryId) async {
    if (selectedCategoryId == categoryId) {
      return;
    }

    selectedCategoryId = categoryId;
    await _fetchProducts(context, reset: true);
  }

  Future<void> _fetchProducts(
    BuildContext context, {
    required bool reset,
    int page = 1,
  }) async {
    if (reset) {
      state = CampaignProductsState.loading;
      if (page == 1) {
        products = [];
      }
    } else {
      state = CampaignProductsState.loadingMore;
    }
    notifyListeners();

    try {
      final response = await getBrandCampaignProducts(
        context: context,
        params: {
          'campaign_id': campaignId.toString(),
          'page': page.toString(),
          'per_page': perPage.toString(),
          if (searchQuery.isNotEmpty) 'search': searchQuery,
          if (selectedCategoryId != null)
            'category_id': selectedCategoryId.toString(),
        },
      );

      final parsed = CampaignProductsResponse.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      if (parsed.status != 1 || parsed.data == null) {
        message = parsed.message.isNotEmpty
            ? parsed.message
            : 'Failed to load campaign products';
        state = CampaignProductsState.error;
        notifyListeners();
        return;
      }

      final data = parsed.data!;
      categories = data.categories;
      pagination = data.pagination;

      if (reset) {
        products = data.products;
      } else {
        products = [...products, ...data.products];
      }

      if (products.isEmpty) {
        state = CampaignProductsState.empty;
      } else {
        state = CampaignProductsState.loaded;
      }
    } catch (e) {
      message = e.toString();
      state = CampaignProductsState.error;
    }

    notifyListeners();
  }
}
