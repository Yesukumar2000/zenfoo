class StockProductResponse {
  int? status;
  String? message;
  int? totalCount;
  StockProductPaginatedData? data;

  StockProductResponse({
    this.status,
    this.message,
    this.totalCount,
    this.data,
  });

  factory StockProductResponse.fromJson(Map<String, dynamic> json) {
    return StockProductResponse(
      status: json['status'],
      message: json['message'],
      totalCount: json['total_sold_out_count'] ?? json['total_low_stock_count'],
      data: json['data'] != null
          ? StockProductPaginatedData.fromJson(json['data'])
          : null,
    );
  }
}

class StockProductPaginatedData {
  int? currentPage;
  List<StockProduct>? data;
  int? lastPage;
  int? total;
  int? perPage;

  StockProductPaginatedData({
    this.currentPage,
    this.data,
    this.lastPage,
    this.total,
    this.perPage,
  });

  factory StockProductPaginatedData.fromJson(Map<String, dynamic> json) {
    return StockProductPaginatedData(
      currentPage: json['current_page'],
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => StockProduct.fromJson(e))
              .toList()
          : null,
      lastPage: json['last_page'],
      total: json['total'],
      perPage: json['per_page'],
    );
  }
}

class StockProduct {
  int? id;
  String? name;
  List<StockProductVariant>? variants;
  StockProductCategory? category;
  List<StockProductImage>? images;

  StockProduct({
    this.id,
    this.name,
    this.variants,
    this.category,
    this.images,
  });

  factory StockProduct.fromJson(Map<String, dynamic> json) {
    return StockProduct(
      id: json['id'],
      name: json['name'],
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((e) => StockProductVariant.fromJson(e))
              .toList()
          : null,
      category: json['category'] != null
          ? StockProductCategory.fromJson(json['category'])
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((e) => StockProductImage.fromJson(e))
              .toList()
          : null,
    );
  }

  /// Get the first available image URL from variants or product images
  String? get imageUrl {
    // Try variant images first
    if (variants != null) {
      for (final variant in variants!) {
        if (variant.images != null && variant.images!.isNotEmpty) {
          return variant.images!.first.image;
        }
      }
    }
    // Fall back to product images
    if (images != null && images!.isNotEmpty) {
      return images!.first.image;
    }
    return null;
  }

  /// Get stock from first variant
  int get stock => variants?.isNotEmpty == true ? (variants!.first.stock ?? 0) : 0;

  /// Get stock unit name from first variant
  String get stockUnitName =>
      variants?.isNotEmpty == true ? (variants!.first.stockUnit?.name ?? '') : '';
}

class StockProductVariant {
  int? id;
  int? productId;
  int? stock;
  int? status;
  StockUnit? stockUnit;
  List<StockProductImage>? images;

  StockProductVariant({
    this.id,
    this.productId,
    this.stock,
    this.status,
    this.stockUnit,
    this.images,
  });

  factory StockProductVariant.fromJson(Map<String, dynamic> json) {
    return StockProductVariant(
      id: json['id'],
      productId: json['product_id'],
      stock: json['stock'],
      status: json['status'],
      stockUnit: json['stock_unit'] != null
          ? StockUnit.fromJson(json['stock_unit'])
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((e) => StockProductImage.fromJson(e))
              .toList()
          : null,
    );
  }
}

class StockUnit {
  int? id;
  String? name;

  StockUnit({this.id, this.name});

  factory StockUnit.fromJson(Map<String, dynamic> json) {
    return StockUnit(
      id: json['id'],
      name: json['name'],
    );
  }
}

class StockProductImage {
  int? id;
  String? image;

  StockProductImage({this.id, this.image});

  factory StockProductImage.fromJson(Map<String, dynamic> json) {
    return StockProductImage(
      id: json['id'],
      image: json['image'],
    );
  }
}

class StockProductCategory {
  int? id;
  String? name;

  StockProductCategory({this.id, this.name});

  factory StockProductCategory.fromJson(Map<String, dynamic> json) {
    return StockProductCategory(
      id: json['id'],
      name: json['name'],
    );
  }
}
