import 'package:project/models/productListItem.dart';

// Category Type model
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

// Category with Types model
class CategoryWithTypes {
  final int id;
  final String name;
  final String imageUrl;
  final List<CategoryType> types;

  CategoryWithTypes({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
  });

  factory CategoryWithTypes.fromJson(Map<String, dynamic> json) {
    return CategoryWithTypes(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      types: (json['types'] as List<dynamic>?)
              ?.map((e) => CategoryType.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// Products by Category model
class ProductsByCategory {
  final int categoryId;
  final String categoryName;
  final String categoryImageUrl;
  final int productCount;
  final List<ProductListItem> products;

  ProductsByCategory({
    required this.categoryId,
    required this.categoryName,
    required this.categoryImageUrl,
    required this.productCount,
    required this.products,
  });

  factory ProductsByCategory.fromJson(Map<String, dynamic> json) {
    return ProductsByCategory(
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      categoryImageUrl: json['category_image_url'] ?? '',
      productCount: json['product_count'] ?? 0,
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => ProductListItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// Seller Info model
class SweetshopSeller {
  final int id;
  final String name;
  final int storeId;
  final bool isBookmarked;
  final String? storeName;
  final String? logoUrl;
  final List<dynamic>? storeImages;
  final String? storeLocation;
  final String? distanceKm;
  final String? storeCity;
  final String? travelTimeMin;
  final String? fssaiNumber;
  final String? latLong;
  final String? mobile;

  /// Seller's own shop hours, "HH:mm:ss". Null when the seller has never set
  /// them (or when talking to an API that predates them) — the header then
  /// shows no hours rather than guessing.
  final String? shopOpeningTime;
  final String? shopClosingTime;

  SweetshopSeller({
    required this.id,
    required this.name,
    required this.storeId,
    required this.isBookmarked,
    this.storeName,
    this.logoUrl,
    this.storeImages,
    this.storeLocation,
    this.distanceKm,
    this.storeCity,
    this.travelTimeMin,
    this.fssaiNumber,
    this.latLong,
    this.mobile,
    this.shopOpeningTime,
    this.shopClosingTime,
  });

  factory SweetshopSeller.fromJson(Map<String, dynamic> json) {
    return SweetshopSeller(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      storeId: json['store_id'] ?? 0,
      isBookmarked: json['is_bookmarked'].toString() == '1' ? true : false,
      storeName: json['store_name'],
      logoUrl: json['logo_url'],
      storeImages: json['store_images'],
      storeLocation: json['store_location'],
      distanceKm: json['distance_km']?.toString(),
      storeCity: json['store_city'],
      travelTimeMin: json['travel_time_min']?.toString(),
      fssaiNumber: json['fssai_number'],
      latLong: json['lat_long'],
      mobile: json['mobile']?.toString(),
      shopOpeningTime: json['shop_opening_time']?.toString(),
      shopClosingTime: json['shop_closing_time']?.toString(),
    );
  }
}

// Sort Option model
class SortOption {
  final String value;
  final String label;

  SortOption({
    required this.value,
    required this.label,
  });

  factory SortOption.fromJson(Map<String, dynamic> json) {
    return SortOption(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

// Main response model
class SweetshopProductsResponse {
  final SweetshopSeller seller;
  final List<CategoryWithTypes> categoriesWithTypes;
  final List<ProductsByCategory> productsByCategory;
  final int totalProducts;
  final List<SortOption> availableSortOptions;
  final Map<String, dynamic> appliedFilters;

  SweetshopProductsResponse({
    required this.seller,
    required this.categoriesWithTypes,
    required this.productsByCategory,
    required this.totalProducts,
    this.availableSortOptions = const [],
    this.appliedFilters = const {},
  });

  factory SweetshopProductsResponse.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 1 && json['data'] != null) {
      final data = json['data'] as Map<String, dynamic>;

      return SweetshopProductsResponse(
        seller: SweetshopSeller.fromJson(data['seller'] ?? {}),
        categoriesWithTypes: (data['categories_with_types'] as List<dynamic>?)
                ?.map((e) =>
                    CategoryWithTypes.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        productsByCategory: (data['products_by_category'] as List<dynamic>?)
                ?.map((e) =>
                    ProductsByCategory.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        totalProducts: data['total_products'] ?? 0,
        availableSortOptions: (data['available_sort_options'] as List<dynamic>?)
                ?.map((e) => SortOption.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        appliedFilters: data['applied_filters'] is Map
            ? (data['applied_filters'] as Map<String, dynamic>)
            : {},
      );
    }
    return SweetshopProductsResponse(
      seller: SweetshopSeller(
        id: 0,
        name: '',
        storeId: 0,
        isBookmarked: false,
        storeName: null,
        logoUrl: null,
        storeLocation: null,
        distanceKm: null,
        storeCity: null,
        travelTimeMin: null,
        fssaiNumber: null,
        latLong: null,
        mobile: null,
      ),
      categoriesWithTypes: [],
      productsByCategory: [],
      totalProducts: 0,
      availableSortOptions: [],
      appliedFilters: {},
    );
  }
}
