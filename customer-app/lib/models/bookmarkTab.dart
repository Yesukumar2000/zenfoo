import 'package:project/models/combo.dart';

class BookmarkTabsResponse {
  late final int status;
  late final String message;
  late final int total;
  late final List<BookmarkTab> data;

  BookmarkTabsResponse({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  BookmarkTabsResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'] ?? 0;
    message = json['message'] ?? '';
    total = json['total'] ?? 0;
    if (json['data'] != null) {
      data = <BookmarkTab>[];
      json['data'].forEach((v) {
        data.add(BookmarkTab.fromJson(v));
      });
    } else {
      data = [];
    }
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['status'] = status;
    itemData['message'] = message;
    itemData['total'] = total;
    itemData['data'] = data.map((v) => v.toJson()).toList();
    return itemData;
  }
}

class BookmarkTab {
  late final String tabType;
  late final String name;
  late final int count;
  late final List<BookmarkItem> items;

  BookmarkTab({
    required this.tabType,
    required this.name,
    required this.count,
    required this.items,
  });

  BookmarkTab.fromJson(Map<String, dynamic> json) {
    tabType = json['tab_type'] ?? '';
    name = json['name'] ?? '';
    count = json['count'] ?? 0;
    if (json['items'] != null) {
      items = <BookmarkItem>[];
      json['items'].forEach((v) {
        items.add(BookmarkItem.fromJson(v));
      });
    } else {
      items = [];
    }
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['tab_type'] = tabType;
    itemData['name'] = name;
    itemData['count'] = count;
    itemData['items'] = items.map((v) => v.toJson()).toList();
    return itemData;
  }
}

class BookmarkItem {
  late final int id;
  late final String name;
  late final String image;
  late final bool isSuperMart;

  BookmarkItem({
    required this.id,
    required this.name,
    required this.image,
    this.isSuperMart = false,
  });

  BookmarkItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    name = json['name'] ?? '';
    image = json['image'] ?? '';
    isSuperMart = json['is_super_mart'] == true || json['is_super_mart'] == 1;
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['id'] = id;
    itemData['name'] = name;
    itemData['image'] = image;
    itemData['is_super_mart'] = isSuperMart;
    return itemData;
  }
}

/// Response for bookmark tab data (detailed items)
class BookmarkTabDataResponse {
  late final int status;
  late final String message;
  late final int total;
  late final List<BookmarkTabDataItem> data;

  BookmarkTabDataResponse({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  BookmarkTabDataResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'] ?? 0;
    message = json['message'] ?? '';
    total = json['total'] ?? 0;
    if (json['data'] != null) {
      data = <BookmarkTabDataItem>[];
      json['data'].forEach((v) {
        data.add(BookmarkTabDataItem.fromJson(v));
      });
    } else {
      data = [];
    }
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['status'] = status;
    itemData['message'] = message;
    itemData['total'] = total;
    itemData['data'] = data.map((v) => v.toJson()).toList();
    return itemData;
  }
}

/// Variant information for a bookmark item
class BookmarkVariant {
  late final String id;
  late final String? measurement;
  late final String? price;
  late final String? discountedPrice;
  late final String? stock;
  late final String? stockUnitName;
  late final String? isUnlimitedStock;
  late final String? cartCount;

  BookmarkVariant({
    required this.id,
    this.measurement,
    this.price,
    this.discountedPrice,
    this.stock,
    this.stockUnitName,
    this.isUnlimitedStock,
    this.cartCount,
  });

  BookmarkVariant.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString() ?? '';
    measurement = json['measurement']?.toString();
    price = json['price']?.toString();
    discountedPrice = json['discounted_price']?.toString();
    stock = json['stock']?.toString();
    stockUnitName = json['stock_unit_name'];
    isUnlimitedStock = json['is_unlimited_stock']?.toString();
    cartCount = json['cart_count']?.toString() ?? '0';
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['id'] = id;
    itemData['measurement'] = measurement;
    itemData['price'] = price;
    itemData['discounted_price'] = discountedPrice;
    itemData['stock'] = stock;
    itemData['stock_unit_name'] = stockUnitName;
    itemData['is_unlimited_stock'] = isUnlimitedStock;
    itemData['cart_count'] = cartCount;
    return itemData;
  }
}

/// Individual item in bookmark tab data
class BookmarkTabDataItem {
  late final int id;
  late final String name;
  late final String image;
  late final double price;
  late final double? discountedPrice;
  late final double? totalProductPrice;
  late final double? totalActualPrice;
  late final double? discountPercentage;
  late final double? rating;
  late final int? ratingCount;
  late final bool? isBookmarked;
  late final bool? isAlreadyAdded;
  late final String? logoUrl;
  late final int? storeId;
  late final bool? isSuperMart;
  late final int? categoryId;
  late final int? sellerId;
  late final String? sellerName;
  // Both arrive pre-formatted with their unit attached ("2.53 km", "8 min"),
  // so they are display strings, not numbers.
  late final String? distanceKm;
  late final String? travelTimeMin;
  late final String? latLong;
  late final double? tax;
  late final List<BookmarkVariant>? variants;
  late final String? description;
  late final int? productCount;
  late final String? type;
  late final CategoryType? categoryType;
  late final int? status;
  late final String? currency;
  late final List<ComboProduct>? products;
  late final int? cartQuantity;

  BookmarkTabDataItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.discountedPrice,
    this.totalProductPrice,
    this.totalActualPrice,
    this.discountPercentage,
    this.rating,
    this.ratingCount,
    this.isBookmarked,
    this.isAlreadyAdded,
    this.logoUrl,
    this.storeId,
    this.isSuperMart,
    this.categoryId,
    this.sellerId,
    this.sellerName,
    this.distanceKm,
    this.travelTimeMin,
    this.latLong,
    this.tax,
    this.variants,
    this.description,
    this.productCount,
    this.type,
    this.categoryType,
    this.status,
    this.currency,
    this.products,
    this.cartQuantity,
  });

  BookmarkTabDataItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    name = json['name'] ?? '';
    // Handle both 'image' (bookmark response) and 'image_url' (combo API)
    image = json['image'] ?? json['image_url'] ?? '';
    price = double.tryParse(json['price']?.toString() ?? '0') ?? 0;
    discountedPrice = double.tryParse(json['discounted_price']?.toString() ?? '');
    // Handle both 'total_product_price' (bookmark) and 'total_products_price' (combo API)
    totalProductPrice =
        double.tryParse(json['total_product_price']?.toString() ?? '') ??
        double.tryParse(json['total_products_price']?.toString() ?? '');
    totalActualPrice =
        double.tryParse(json['total_actual_price']?.toString() ?? '');
    discountPercentage =
        double.tryParse(json['discount_percentage']?.toString() ?? '');
    // Handle both 'average_rating' and 'rating' fields
    rating = double.tryParse(json['average_rating']?.toString() ?? json['rating']?.toString() ?? '');
    ratingCount = json['rating_count'];
    // Safe boolean parser - handles both int (0/1) and bool values
    isBookmarked = _parseBool(json['is_bookmarked']);
    isAlreadyAdded = _parseBool(json['is_already_added']);
    logoUrl = json['logo_url'];
    storeId = json['store_id'];
    isSuperMart = _parseBool(json['is_super_mart']);
    categoryId = json['category_id'];
    sellerId = json['seller_id'];
    sellerName = json['seller_name'];
    distanceKm = json['distance_km']?.toString();
    travelTimeMin = json['travel_time_min']?.toString();
    latLong = json['lat_long'];
    tax = double.tryParse(json['tax']?.toString() ?? '');

    // Parse variants if available (for product bookmarks)
    if (json['variants'] != null) {
      variants = <BookmarkVariant>[];
      json['variants'].forEach((v) {
        variants!.add(BookmarkVariant.fromJson(v));
      });
    }

    // Combo-specific fields
    description = json['description'];
    productCount = json['product_count'];
    type = json['type'];
    categoryType = json['category_type'] != null
        ? CategoryType.fromJson(json['category_type'])
        : null;
    status = json['status'];
    currency = json['currency'];
    cartQuantity = json['cart_quantity'] != null
        ? int.tryParse(json['cart_quantity'].toString())
        : null;

    // Parse products if available (for combo bookmarks)
    if (json['products'] != null) {
      products = <ComboProduct>[];
      json['products'].forEach((v) {
        products!.add(ComboProduct.fromJson(v));
      });
    }
  }

  // Safe boolean parser - converts int (0/1) or bool to bool?
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['id'] = id;
    itemData['name'] = name;
    itemData['image'] = image;
    itemData['price'] = price;
    itemData['discounted_price'] = discountedPrice;
    itemData['total_product_price'] = totalProductPrice;
    itemData['total_actual_price'] = totalActualPrice;
    itemData['discount_percentage'] = discountPercentage;
    itemData['rating'] = rating;
    itemData['rating_count'] = ratingCount;
    itemData['is_bookmarked'] = isBookmarked;
    itemData['is_already_added'] = isAlreadyAdded;
    itemData['logo_url'] = logoUrl;
    itemData['category_id'] = categoryId;
    itemData['seller_id'] = sellerId;
    itemData['seller_name'] = sellerName;
    itemData['distance_km'] = distanceKm;
    itemData['travel_time_min'] = travelTimeMin;
    itemData['lat_long'] = latLong;
    itemData['tax'] = tax;
    if (variants != null) {
      itemData['variants'] = variants!.map((v) => v.toJson()).toList();
    }
    itemData['description'] = description;
    itemData['product_count'] = productCount;
    itemData['type'] = type;
    if (categoryType != null) {
      itemData['category_type'] = categoryType!.toJson();
    }
    itemData['status'] = status;
    itemData['currency'] = currency;
    itemData['cart_quantity'] = cartQuantity;
    if (products != null) {
      itemData['products'] = products!.map((v) => v.toJson()).toList();
    }
    return itemData;
  }
}
