import 'package:project/models/productList.dart';

class SweetShopProductsResponse {
  final int status;
  final String message;
  final SweetShopProductsData? data;

  SweetShopProductsResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory SweetShopProductsResponse.fromJson(Map<String, dynamic> json) {
    return SweetShopProductsResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? SweetShopProductsData.fromJson(json['data'])
          : null,
    );
  }
}

class SweetShopProductsData {
  final List<CategoryWithTypes> categoriesWithTypes;
  final List<ProductsByCategory> productsByCategory;
  final int totalProducts;

  SweetShopProductsData({
    required this.categoriesWithTypes,
    required this.productsByCategory,
    required this.totalProducts,
  });

  factory SweetShopProductsData.fromJson(Map<String, dynamic> json) {
    return SweetShopProductsData(
      categoriesWithTypes: (json['categories_with_types'] as List<dynamic>?)
              ?.map((e) => CategoryWithTypes.fromJson(e))
              .toList() ??
          [],
      productsByCategory: (json['products_by_category'] as List<dynamic>?)
              ?.map((e) => ProductsByCategory.fromJson(e))
              .toList() ??
          [],
      totalProducts: json['total_products'] ?? 0,
    );
  }
}

class CategoryWithTypes {
  final int id;
  final String name;
  final String? imageUrl;
  final List<CategoryType> types;

  CategoryWithTypes({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.types,
  });

  factory CategoryWithTypes.fromJson(Map<String, dynamic> json) {
    return CategoryWithTypes(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imageUrl: json['image_url'],
      types: (json['types'] as List<dynamic>?)
              ?.map((e) => CategoryType.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CategoryType {
  final int id;
  final String name;
  final int categoryId;

  CategoryType({
    required this.id,
    required this.name,
    required this.categoryId,
  });

  factory CategoryType.fromJson(Map<String, dynamic> json) {
    return CategoryType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      categoryId: json['category_id'] ?? 0,
    );
  }
}

class ProductsByCategory {
  final int categoryId;
  final String categoryName;
  final String? categoryImageUrl;
  final int productCount;
  final List<ProductListItem> products;

  ProductsByCategory({
    required this.categoryId,
    required this.categoryName,
    this.categoryImageUrl,
    required this.productCount,
    required this.products,
  });

  factory ProductsByCategory.fromJson(Map<String, dynamic> json) {
    return ProductsByCategory(
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      categoryImageUrl: json['category_image_url'],
      productCount: json['product_count'] ?? 0,
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => ProductListItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
