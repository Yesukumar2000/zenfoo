import 'package:project/models/productListItem.dart';

class CampaignProductsResponse {
  final int status;
  final String message;
  final int total;
  final CampaignProductsData? data;

  CampaignProductsResponse({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  factory CampaignProductsResponse.fromJson(Map<String, dynamic> json) {
    return CampaignProductsResponse(
      status: json['status'] is num ? (json['status'] as num).toInt() : 0,
      message: json['message']?.toString() ?? '',
      total: json['total'] is num ? (json['total'] as num).toInt() : 0,
      data: json['data'] is Map<String, dynamic>
          ? CampaignProductsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CampaignProductsData {
  final List<ProductListItem> products;
  final List<CampaignFilterCategory> categories;
  final CampaignProductsPagination? pagination;

  CampaignProductsData({
    required this.products,
    required this.categories,
    required this.pagination,
  });

  factory CampaignProductsData.fromJson(Map<String, dynamic> json) {
    return CampaignProductsData(
      products: (json['products'] as List? ?? [])
          .map((item) => ProductListItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      categories: (json['categories'] as List? ?? [])
          .map((item) => CampaignFilterCategory.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      pagination: json['pagination'] is Map<String, dynamic>
          ? CampaignProductsPagination.fromJson(
              json['pagination'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class CampaignFilterCategory {
  final int id;
  final String name;
  final int productCount;

  CampaignFilterCategory({
    required this.id,
    required this.name,
    required this.productCount,
  });

  factory CampaignFilterCategory.fromJson(Map<String, dynamic> json) {
    return CampaignFilterCategory(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      name: json['name']?.toString() ?? '',
      productCount: json['product_count'] is num
          ? (json['product_count'] as num).toInt()
          : 0,
    );
  }
}

class CampaignProductsPagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;

  CampaignProductsPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory CampaignProductsPagination.fromJson(Map<String, dynamic> json) {
    return CampaignProductsPagination(
      total: json['total'] is num ? (json['total'] as num).toInt() : 0,
      perPage: json['per_page'] is num ? (json['per_page'] as num).toInt() : 0,
      currentPage: json['current_page'] is num
          ? (json['current_page'] as num).toInt()
          : 1,
      lastPage:
          json['last_page'] is num ? (json['last_page'] as num).toInt() : 1,
      from: json['from'] is num ? (json['from'] as num).toInt() : 0,
      to: json['to'] is num ? (json['to'] as num).toInt() : 0,
    );
  }
}
