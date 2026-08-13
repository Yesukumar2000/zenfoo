class Combo {
  int? id;
  String? name;
  String? description;
  num? price;
  num? rating;
  int? ratingCount;
  int? productCount;
  String? type;
  CategoryType? categoryType;
  int? status;
  String? imageUrl;
  num? totalProductsPrice;
  num? totalActualPrice;
  num? discountPercentage;
  String? currency;
  String? bannerVideoUrl;
  num? bannerVideoDuration;
  String? updatedAt;
  List<ComboStore>? stores;
  List<ComboProduct>? products;
  int? isAlreadyAdded; // ✅ Add this field
  int? cartQuantity; // ✅ Add this field (if API provides it)
  bool? isBookmarked;

  Combo({
    this.id,
    this.name,
    this.description,
    this.price,
    this.rating,
    this.ratingCount,
    this.productCount,
    this.type,
    this.categoryType,
    this.status,
    this.imageUrl,
    this.totalProductsPrice,
    this.totalActualPrice,
    this.discountPercentage,
    this.currency,
    this.products,
    this.bannerVideoUrl,
    this.bannerVideoDuration,
    this.updatedAt,
    this.stores,
    this.isAlreadyAdded,
    this.cartQuantity,
    this.isBookmarked,
  });

  Combo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    price = json['price'];
    rating = json['rating'];
    ratingCount = json['rating_count'];
    productCount = json['product_count'];
    type = json['type'];
    categoryType = json['category_type'] != null
        ? CategoryType.fromJson(json['category_type'])
        : null;
    status = json['status'];
    imageUrl = json['image_url'];
    totalProductsPrice = json['total_products_price'];
    totalActualPrice = json['total_actual_price'];
    discountPercentage = json['discount_percentage'];
    currency = json['currency'];
    bannerVideoUrl = json['banner_video_url'];
    bannerVideoDuration = json['banner_video_duration'];
    updatedAt = json['updated_at'];
    // Parse is_already_added as int - handle both string and int values from API
    isAlreadyAdded = json['is_already_added'] != null
        ? int.tryParse(json['is_already_added'].toString())
        : null;
    // Parse cart_quantity as int - handle both string and int values from API
    cartQuantity = json['cart_quantity'] != null
        ? int.tryParse(json['cart_quantity'].toString())
        : null;
    // Parse is_bookmarked - handle both string and bool values from API
    isBookmarked = json['is_bookmarked'] == true || json['is_bookmarked'] == 1;
    if (json['products'] != null) {
      products = <ComboProduct>[];
      json['products'].forEach((v) {
        products!.add(ComboProduct.fromJson(v));
      });
    }
    if (json['stores'] != null && json['stores'] != []) {
      stores = <ComboStore>[];
      json['stores'].forEach((v) {
        stores!.add(ComboStore.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['price'] = price;
    data['rating'] = rating;
    data['rating_count'] = ratingCount;
    data['product_count'] = productCount;
    data['type'] = type;
    if (categoryType != null) {
      data['category_type'] = categoryType!.toJson();
    }
    data['status'] = status;
    data['image_url'] = imageUrl;
    data['total_products_price'] = totalProductsPrice;
    data['total_actual_price'] = totalActualPrice;
    data['discount_percentage'] = discountPercentage;
    data['currency'] = currency;
    data['banner_video_url'] = bannerVideoUrl;
    data['banner_video_duration'] = bannerVideoDuration;
    data['updated_at'] = updatedAt;
    data['is_already_added'] = isAlreadyAdded;
    data['cart_quantity'] = cartQuantity;
    data['is_bookmarked'] = isBookmarked;
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    if (stores != null) {
      data['stores'] = stores!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CategoryType {
  int? id;
  String? name;
  String? createdAt;
  String? updatedAt;

  CategoryType({this.id, this.name, this.createdAt, this.updatedAt});

  CategoryType.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class ComboStore {
  int? storeId;
  String? storeName;
  List<ComboProduct>? products;

  ComboStore({this.storeId, this.storeName, this.products});

  ComboStore.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    storeName = json['store_name'];
    if (json['products'] != null) {
      products = <ComboProduct>[];
      json['products'].forEach((v) {
        products!.add(ComboProduct.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['store_id'] = storeId;
    data['store_name'] = storeName;
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ComboProduct {
  int? productId;
  String? productName;
  String? productImage;
  int? variantId;
  num? variantMeasurement;
  String? variantUnit;
  int? variantStock;
  num? price;
  num? actualPrice;
  int? quantity;
  num? rating;
  int? ratingCount;
  String? currency;
  List<Images>? images;
  List<ComboVariant>? variants;

  ComboProduct(
      {this.productId,
      this.productName,
      this.productImage,
      this.variantId,
      this.variantMeasurement,
      this.variantUnit,
      this.variantStock,
      this.price,
      this.actualPrice,
      this.quantity,
      this.rating,
      this.ratingCount,
      this.currency,
      this.images,
      this.variants});

  ComboProduct.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    productName = json['product_name'];
    productImage = json['product_image'];
    variantId = json['variant_id'];
    variantMeasurement = json['variant_measurement'];
    variantUnit = json['variant_unit'];
    variantStock = json['variant_stock'];
    price = json['price'];
    actualPrice = json['actual_price'];
    quantity = json['quantity'];
    rating = json['rating'];
    ratingCount = json['rating_count'];
    currency = json['currency'];
    if (json['images'] != null) {
      images = <Images>[];
      json['images'].forEach((v) {
        images!.add(new Images.fromJson(v));
      });
    }
    if (json['variants'] != null) {
      variants = <ComboVariant>[];
      json['variants'].forEach((v) {
        variants!.add(new ComboVariant.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    data['product_image'] = this.productImage;
    data['variant_id'] = this.variantId;
    data['variant_measurement'] = this.variantMeasurement;
    data['variant_unit'] = this.variantUnit;
    data['variant_stock'] = this.variantStock;
    data['price'] = this.price;
    data['actual_price'] = this.actualPrice;
    data['quantity'] = this.quantity;
    data['rating'] = this.rating;
    data['rating_count'] = this.ratingCount;
    data['currency'] = this.currency;
    if (this.images != null) {
      data['images'] = this.images!.map((v) => v.toJson()).toList();
    }
    if (this.variants != null) {
      data['variants'] = this.variants!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Images {
  int? id;
  String? imageUrl;

  Images({this.id, this.imageUrl});

  Images.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    imageUrl = json['image_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['image_url'] = this.imageUrl;
    return data;
  }
}

class ComboVariant {
  int? id;
  num? measurement;
  String? unit;
  int? stock;
  num? price;
  num? actualPrice;
  num? discountedPrice;
  String? currency;

  ComboVariant({
    this.id,
    this.measurement,
    this.unit,
    this.stock,
    this.price,
    this.actualPrice,
    this.discountedPrice,
    this.currency,
  });

  ComboVariant.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    measurement = json['measurement'];
    unit = json['unit'];
    stock = json['stock'];
    price = json['price'];
    actualPrice = json['actual_price'];
    discountedPrice = json['discounted_price'];
    currency = json['currency'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['measurement'] = measurement;
    data['unit'] = unit;
    data['stock'] = stock;
    data['price'] = price;
    data['actual_price'] = actualPrice;
    data['discounted_price'] = discountedPrice;
    data['currency'] = currency;
    return data;
  }
}
