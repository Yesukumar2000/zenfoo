import 'package:project/models/productListItem.dart';

class SellerProductList {
  final String listType;
  final String title;
  final List<ProductListItem> products;

  SellerProductList({
    required this.listType,
    required this.title,
    required this.products,
  });

  factory SellerProductList.fromJson(Map<String, dynamic> json) {
    return SellerProductList(
      listType: json['list_type'] ?? '',
      title: json['title'] ?? '',
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => ProductListItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SellerProductListsResponse {
  final List<SellerProductList> productLists;

  SellerProductListsResponse({required this.productLists});

  factory SellerProductListsResponse.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 1 && json['data'] != null) {
      final data = json['data'] as Map<String, dynamic>;

      // Extract product_lists array from data
      if (data['product_lists'] != null && data['product_lists'] is List) {
        final productListsJson = data['product_lists'] as List<dynamic>;
        final lists = productListsJson
            .map((e) => SellerProductList.fromJson(e as Map<String, dynamic>))
            .toList();
        return SellerProductListsResponse(productLists: lists);
      }
    }
    return SellerProductListsResponse(productLists: []);
  }
}
