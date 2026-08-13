class ProductList {
  String? status;
  String? message;
  String? total;
  List<ProductListItem>? data;

  ProductList({this.status, this.message, this.total, this.data});

  ProductList.fromJson(Map<String, dynamic> json) {
    status = json['status']?.toString();
    message = json['message']?.toString();
    total = json['total']?.toString();
    if (json['data'] != null) {
      data = <ProductListItem>[];
      json['data'].forEach((v) {
        data!.add(new ProductListItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['total'] = this.total;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ProductListItem {
  String? id;
  String? name;
  String? taxId;
  String? brandId;
  String? slug;
  String? categoryId;
  String? categoryGroupId;
  String? subCategoryGroupId;
  String? categoryGroupName;
  String? subCategoryGroupName;
  String? categoryName;
  String? brandName;
  String? itemTypeId;
  String? itemTypeName;
  String? indicator;
  String? isApproved;
  String? manufacturer;
  String? madeIn;
  String? type;
  String? isUnlimitedStock;
  String? totalAllowedQuantity;
  String? taxIncludedInPrice;
  String? taxPercentage;
  String? fssaiLicNo;
  String? returnStatus;
  String? returnDays;
  String? cancelableStatus;
  String? tillStatus;

  String? description;
  String? tags;
  String? otherInfo;
  List<Variants>? variants;
  String? imageUrl;
  double? avgRating;
  int? ratingCount;

  ProductListItem(
      {this.id,
      this.name,
      this.taxId,
      this.brandId,
      this.slug,
      this.categoryId,
      this.categoryGroupId,
      this.subCategoryGroupId,
      this.categoryGroupName,
      this.subCategoryGroupName,
      this.categoryName,
      this.brandName,
      this.itemTypeId,
      this.itemTypeName,
      this.indicator,
      this.isApproved,
      this.manufacturer,
      this.madeIn,
      this.type,
      this.isUnlimitedStock,
      this.totalAllowedQuantity,
      this.taxIncludedInPrice,
      this.taxPercentage,
      this.fssaiLicNo,
      this.returnStatus,
      this.returnDays,
      this.cancelableStatus,
      this.tillStatus,
      this.description,
      this.tags,
      this.otherInfo,
      this.variants,
      this.imageUrl,
      this.avgRating,
      this.ratingCount});

  ProductListItem.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    name = json['name']?.toString();
    taxId = json['tax_id']?.toString();
    brandId = json['brand_id']?.toString();
    slug = json['slug']?.toString();
    categoryId = json['category_id']?.toString();
    categoryGroupId = json['category_group_id']?.toString();
    subCategoryGroupId = json['sub_category_group_id']?.toString();

    if (json['category_type'] != null) {
      itemTypeName = json['category_type']['name']?.toString();
      itemTypeId = json['category_type']['id']?.toString();
    }

    if (json['category_group'] != null) {
      categoryGroupName = json['category_group']['name']?.toString();
    }
    if (json['sub_category_group'] != null) {
      subCategoryGroupName = json['sub_category_group']['name']?.toString();
    }
    if (json['category'] != null) {
      categoryName = json['category']['name']?.toString();
    }
    if (json['brand'] != null) {
      brandName = json['brand']['name']?.toString();
    }

    indicator = json['indicator']?.toString();
    isApproved = json['is_approved']?.toString();
    manufacturer = json['manufacturer']?.toString();
    madeIn = json['made_in']?.toString();
    type = json['type']?.toString();
    isUnlimitedStock = json['is_unlimited_stock']?.toString();
    totalAllowedQuantity = json['total_allowed_quantity']?.toString();
    taxIncludedInPrice = json['tax_included_in_price']?.toString();
    taxPercentage = json['tax']?.toString();
    fssaiLicNo = json['fssai_lic_no']?.toString() ?? json['fssai_number']?.toString();
    returnStatus = json['return_status']?.toString();
    returnDays = json['return_days']?.toString();
    cancelableStatus = json['cancelable_status']?.toString();
    tillStatus = json['till_status']?.toString();
    description = json['description']?.toString();
    tags = json['tags']?.toString();
    otherInfo = json['other_info']?.toString();
    if (json['variants'] != null) {
      variants = <Variants>[];
      json['variants'].forEach((v) {
        variants!.add(new Variants.fromJson(v));
      });
    }
    imageUrl = json['image_url']?.toString();

    // Parse rating fields if they exist
    if (json['avg_rating'] != null) {
      avgRating = double.tryParse(json['avg_rating'].toString());
    }
    if (json['rating_count'] != null) {
      ratingCount = int.tryParse(json['rating_count'].toString());
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['tax_id'] = this.taxId;
    data['brand_id'] = this.brandId;
    data['slug'] = this.slug;
    data['category_id'] = this.categoryId;
    data['category_group_id'] = this.categoryGroupId;
    data['sub_category_group_id'] = this.subCategoryGroupId;
    data['category_group_name'] = this.categoryGroupName;
    data['sub_category_group_name'] = this.subCategoryGroupName;
    data['category_name'] = this.categoryName;
    data['brand_name'] = this.brandName;
    data['item_type_id'] = this.itemTypeId;
    data['item_type_name'] = this.itemTypeName;
    data['indicator'] = this.indicator;
    data['is_approved'] = this.isApproved;
    data['manufacturer'] = this.manufacturer;
    data['made_in'] = this.madeIn;
    data['type'] = this.type;
    data['is_unlimited_stock'] = this.isUnlimitedStock;
    data['total_allowed_quantity'] = this.totalAllowedQuantity;
    data['tax_included_in_price'] = this.taxIncludedInPrice;
    data['tax_percentage'] = this.taxPercentage;
    data['fssai_number'] = this.fssaiLicNo;
    data['return_status'] = this.returnStatus;
    data['return_days'] = this.returnDays;
    data['cancelable_status'] = this.cancelableStatus;
    data['till_status'] = this.tillStatus;
    data['description'] = this.description;
    data['tags'] = this.tags;
    data['other_info'] = this.otherInfo;
    if (this.variants != null) {
      data['variants'] = this.variants!.map((v) => v.toJson()).toList();
    }
    data['image_url'] = this.imageUrl;
    data['avg_rating'] = this.avgRating;
    data['rating_count'] = this.ratingCount;
    return data;
  }
}

class VariantImage {
  String? id;
  String? productId;
  String? productVariantId;
  String? image;
  String? imageUrl;

  VariantImage({
    this.id,
    this.productId,
    this.productVariantId,
    this.image,
    this.imageUrl,
  });

  VariantImage.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    productId = json['product_id']?.toString();
    productVariantId = json['product_variant_id']?.toString();
    image = json['image']?.toString();
    imageUrl = json['image_url']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['product_id'] = productId;
    data['product_variant_id'] = productVariantId;
    data['image'] = image;
    data['image_url'] = imageUrl;
    return data;
  }
}

class Variants {
  String? id;
  String? type;
  String? status;
  String? measurement;
  String? price;
  String? discountedPrice;
  String? stock;
  String? stockUnitId;
  String? stockUnitName;
  String? stockUnitShortCode;
  String? isUnlimitedStock;
  String? cartCount;
  String? taxableAmount;
  List<VariantImage>? images;

  Variants(
      {this.id,
      this.type,
      this.status,
      this.measurement,
      this.price,
      this.discountedPrice,
      this.stock,
      this.stockUnitId,
      this.stockUnitName,
      this.stockUnitShortCode,
      this.isUnlimitedStock,
      this.cartCount,
      this.taxableAmount,
      this.images});

  Variants.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    type = json['type'].toString();
    status = json['status'].toString();
    measurement = json['measurement'].toString();
    price = json['price'].toString();
    discountedPrice = json['discounted_price'].toString();
    stock = json['stock'].toString();
    stockUnitId = json['stock_unit_id']?.toString();
    stockUnitName = json['stock_unit_name']?.toString();
    if (stockUnitName == null || stockUnitName == 'null') {
      if (json['stock_unit'] != null && json['stock_unit'] is Map) {
        stockUnitName = json['stock_unit']['name']?.toString();
        stockUnitShortCode = json['stock_unit']['short_code']?.toString();
      }
    } else {
      // If we have stock_unit object, get short_code from it
      if (json['stock_unit'] != null && json['stock_unit'] is Map) {
        stockUnitShortCode = json['stock_unit']['short_code']?.toString();
      }
    }
    isUnlimitedStock = json['is_unlimited_stock'].toString();
    cartCount = json['cart_count'].toString();
    taxableAmount = json['taxable_amount'].toString();

    // Parse images array
    if (json['images'] != null) {
      images = <VariantImage>[];
      json['images'].forEach((v) {
        images!.add(VariantImage.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['type'] = this.type;
    data['status'] = this.status;
    data['measurement'] = this.measurement;
    data['price'] = this.price;
    data['discounted_price'] = this.discountedPrice;
    data['stock'] = this.stock;
    data['stock_unit_id'] = this.stockUnitId;
    data['stock_unit_name'] = this.stockUnitName;
    data['is_unlimited_stock'] = this.isUnlimitedStock;
    data['cart_count'] = this.cartCount;
    data['taxable_amount'] = this.taxableAmount;
    return data;
  }
}
