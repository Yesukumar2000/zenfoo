class ProductDetail {
  ProductDetail({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  late final String status;
  late final String message;
  late final String total;
  late final ProductData data;

  ProductDetail.fromJson(Map<String, dynamic> json) {
    status = json['status'].toString();
    message = json['message'].toString();
    total = json['total'].toString();
    if (json['data'] is List) {
      if ((json['data'] as List).isNotEmpty) {
        data = ProductData.fromJson(json['data'][0]);
      } else {
        // Handle empty list case if necessary, or let it throw if data is required
        data = ProductData.fromJson({});
      }
    } else {
      data = ProductData.fromJson(json['data'] ?? {});
    }
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['status'] = status;
    itemData['message'] = message;
    itemData['total'] = total;
    itemData['data'] = data.toJson();
    return itemData;
  }
}

class ProductData {
  ProductData({
    required this.id,
    required this.name,
    required this.taxId,
    required this.brandId,
    required this.brandName,
    required this.slug,
    required this.categoryId,
    required this.indicator,
    required this.manufacturer,
    required this.madeIn,
    required this.madeInId,
    required this.returnStatus,
    required this.cancelableStatus,
    required this.tillStatus,
    required this.description,
    required this.status,
    required this.isApproved,
    required this.returnDays,
    required this.type,
    required this.isUnlimitedStock,
    required this.isPreOrderItem,
    required this.codAllowed,
    required this.totalAllowedQuantity,
    required this.taxIncludedInPrice,
    required this.isSkinnedOne,
    required this.isMeatProduct,
    required this.beforeCleaningWeight,
    required this.pieces,
    required this.fssaiLicNo,
    required this.categoryName,
    required this.dType,
    required this.sellerName,
    required this.sellerId,
    required this.images,
    required this.isFavorite,
    required this.variants,
    required this.imageUrl,
  });

  late final String barcode;
  late final String metaTitle;
  late final String metaKeywords;
  late final String schemaMarkup;
  late final String metaDescription;

  int? calDiscountPercentage;
  int? calDiscount;
  int? price;
  int? discountedPrice;
  int? orderCounter;
  String? countryMadeIn;
  String? longitude;
  String? latitude;
  int? maxDeliverableDistance;
  int? taxPercentage;
  int? minPrice;
  int? maxPrice;
  int? ratingCount;
  num? averageRating;
  List<dynamic>? ratings;
  String? boundaryPoints;

  late final String id;
  late final String name;
  late final String taxId;
  late final String brandId;
  late final String brandName;
  late final String slug;
  late final String categoryId;
  late final String indicator;
  late final String manufacturer;
  late final String madeIn;
  late final String madeInId;
  late final String returnStatus;
  late final String cancelableStatus;
  late final String tillStatus;
  late final String description;
  late final String status;
  late final String isApproved;
  late final String returnDays;
  late final String type;
  late final String isUnlimitedStock;
  late final int isPreOrderItem;
  late final String codAllowed;
  late final String totalAllowedQuantity;
  late final String taxIncludedInPrice;
  late final String isSkinnedOne;
  late final String isMeatProduct;
  late final String fssaiLicNo;
  late final String categoryName;
  late final String dType;
  late final String sellerName;
  late final String sellerId;
  late final List<String> images;
  late final bool isFavorite;
  late final List<ProductDetailVariants> variants;
  late final String imageUrl;
  late final String tagNames;
  late final String videoUrl;
  late final bool isCleaned;
  late final String otherInfo;
  late final String
      afterCleaningWeight; // stored as String, parsed from dynamic
  late final String beforeCleaningWeight;
  late final String pieces;

  ProductData.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    name = json['name'].toString();
    taxId = json['tax_id'].toString();
    brandId = json['brand_id'].toString();
    brandName = json['brand_name'].toString();
    slug = json['slug'].toString();
    categoryId = json['category_id'].toString();
    indicator = json['indicator'].toString();
    manufacturer = json['manufacturer'].toString();
    madeIn = json['made_in'].toString();
    madeInId = json['made_in_id'].toString();
    returnStatus = json['return_status'].toString();
    cancelableStatus = json['cancelable_status'].toString();
    tillStatus = json['till_status'].toString();
    description = json['description'].toString();
    status = json['status'].toString();
    isApproved = json['is_approved'].toString();
    returnDays = json['return_days'].toString(); /////////
    type = json['type'].toString();
    isUnlimitedStock = json['is_unlimited_stock'].toString();
    isPreOrderItem = int.tryParse(json['is_pre_order_item'].toString()) ?? 0;
    codAllowed = json['cod_allowed'].toString();
    totalAllowedQuantity = json['total_allowed_quantity'].toString();
    taxIncludedInPrice = json['tax_included_in_price'].toString();
    isSkinnedOne = json['is_skinned_one'].toString();
    isMeatProduct = json['is_meat_product'].toString();
    fssaiLicNo = json['fssai_lic_no'].toString();
    categoryName = json['category_name'].toString();
    dType = json['d_type'].toString();
    sellerName = json['seller_name'].toString();
    sellerId = json['seller_id'].toString();
    images = List.castFrom<dynamic, String>(json['images'] ?? []);
    isFavorite = json['is_favorite'] ?? false;
    variants = List.from(json['variants'])
        .map((e) => ProductDetailVariants.fromJson(e))
        .toList();
    imageUrl = json['image_url'].toString();
    tagNames = json['tag_names'].toString();
    videoUrl = json['video_url']?.toString() ?? '';
    otherInfo = json['other_info']?.toString() ?? '';
    isCleaned = json['is_cleaned'] == 1 ||
        json['is_cleaned'] == true ||
        json['is_cleaned'] == '1';
    try {
      final raw = json['after_cleaning_weight'];
      if (raw == null) {
        afterCleaningWeight = '';
      } else if (raw is int) {
        afterCleaningWeight = raw.toString();
      } else if (raw is double) {
        afterCleaningWeight =
            raw % 1 == 0 ? raw.toInt().toString() : raw.toString();
      } else {
        afterCleaningWeight = raw.toString();
      }
    } catch (_) {
      afterCleaningWeight = '';
    }
    beforeCleaningWeight = json['before_cleaning_weight']?.toString() ?? '';
    pieces = json['pieces']?.toString() ?? '';

    barcode = json['barcode']?.toString() ?? "";
    metaTitle = json['meta_title']?.toString() ?? "";
    metaKeywords = json['meta_keywords']?.toString() ?? "";
    schemaMarkup = json['schema_markup']?.toString() ?? "";
    metaDescription = json['meta_description']?.toString() ?? "";

    calDiscountPercentage = json['cal_discount_percentage'] is num
        ? (json['cal_discount_percentage'] as num?)?.toInt()
        : int.tryParse(json['cal_discount_percentage']?.toString() ?? '');
    calDiscount = json['cal_discount'] is num
        ? (json['cal_discount'] as num?)?.toInt()
        : int.tryParse(json['cal_discount']?.toString() ?? '');
    price = json['price'] is num
        ? (json['price'] as num?)?.toInt()
        : int.tryParse(json['price']?.toString() ?? '');
    discountedPrice = json['discounted_price'] is num
        ? (json['discounted_price'] as num?)?.toInt()
        : int.tryParse(json['discounted_price']?.toString() ?? '');
    orderCounter = json['order_counter'] is num
        ? (json['order_counter'] as num?)?.toInt()
        : int.tryParse(json['order_counter']?.toString() ?? '');
    countryMadeIn = json['country_made_in']?.toString();
    longitude = json['longitude']?.toString();
    latitude = json['latitude']?.toString();
    maxDeliverableDistance = json['max_deliverable_distance'] is num
        ? (json['max_deliverable_distance'] as num?)?.toInt()
        : int.tryParse(json['max_deliverable_distance']?.toString() ?? '');
    taxPercentage = json['tax_percentage'] is num
        ? (json['tax_percentage'] as num?)?.toInt()
        : int.tryParse(json['tax_percentage']?.toString() ?? '');
    minPrice = json['min_price'] is num
        ? (json['min_price'] as num?)?.toInt()
        : int.tryParse(json['min_price']?.toString() ?? '');
    maxPrice = json['max_price'] is num
        ? (json['max_price'] as num?)?.toInt()
        : int.tryParse(json['max_price']?.toString() ?? '');
    ratingCount = json['rating_count'] is num
        ? (json['rating_count'] as num?)?.toInt()
        : int.tryParse(json['rating_count']?.toString() ?? '');
    averageRating = json['average_rating'] is num
        ? json['average_rating']
        : num.tryParse(json['average_rating']?.toString() ?? '0');
    ratings = json['ratings'] ?? [];
    boundaryPoints = json['boundary_points']?.toString();
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['id'] = id;
    itemData['name'] = name;
    itemData['tax_id'] = taxId;
    itemData['brand_id'] = brandId;
    itemData['brand_name'] = brandName;
    itemData['slug'] = slug;
    itemData['category_id'] = categoryId;
    itemData['indicator'] = indicator;
    itemData['manufacturer'] = manufacturer;
    itemData['made_in'] = madeIn;
    itemData['made_in_id'] = madeInId;
    itemData['return_status'] = returnStatus;
    itemData['cancelable_status'] = cancelableStatus;
    itemData['till_status'] = tillStatus;
    itemData['description'] = description;
    itemData['status'] = status;
    itemData['is_approved'] = isApproved;
    itemData['return_days'] = returnDays;
    itemData['type'] = type;
    itemData['is_unlimited_stock'] = isUnlimitedStock;
    itemData['is_pre_order_item'] = isPreOrderItem;
    itemData['cod_allowed'] = codAllowed;
    itemData['total_allowed_quantity'] = totalAllowedQuantity;
    itemData['tax_included_in_price'] = taxIncludedInPrice;
    itemData['is_skinned_one'] = isSkinnedOne;
    itemData['is_meat_product'] = isMeatProduct;
    itemData['fssai_lic_no'] = fssaiLicNo;
    itemData['category_name'] = categoryName;
    itemData['d_type'] = dType;
    itemData['seller_name'] = sellerName;
    itemData['seller_id'] = sellerId;
    itemData['`images`'] = images;
    itemData['is_favorite'] = isFavorite;
    itemData['variants'] = variants.map((e) => e.toJson()).toList();
    itemData['image_url'] = imageUrl;
    itemData['tag_names'] = tagNames;
    itemData['video_url'] = videoUrl;
    itemData['other_info'] = otherInfo;
    itemData['is_cleaned'] = isCleaned;
    itemData['before_cleaning_weight'] = beforeCleaningWeight;
    itemData['after_cleaning_weight'] = afterCleaningWeight;
    itemData['pieces'] = pieces;

    itemData['barcode'] = barcode;
    itemData['meta_title'] = metaTitle;
    itemData['meta_keywords'] = metaKeywords;
    itemData['schema_markup'] = schemaMarkup;
    itemData['meta_description'] = metaDescription;
    itemData['cal_discount_percentage'] = calDiscountPercentage;
    itemData['cal_discount'] = calDiscount;
    itemData['price'] = price;
    itemData['discounted_price'] = discountedPrice;
    itemData['order_counter'] = orderCounter;
    itemData['country_made_in'] = countryMadeIn;
    itemData['longitude'] = longitude;
    itemData['latitude'] = latitude;
    itemData['max_deliverable_distance'] = maxDeliverableDistance;
    itemData['tax_percentage'] = taxPercentage;
    itemData['min_price'] = minPrice;
    itemData['max_price'] = maxPrice;
    itemData['rating_count'] = ratingCount;
    itemData['average_rating'] = averageRating;
    itemData['ratings'] = ratings;
    itemData['boundary_points'] = boundaryPoints;
    return itemData;
  }
}

class ProductDetailVariants {
  ProductDetailVariants({
    required this.id,
    required this.type,
    required this.measurement,
    required this.price,
    required this.discountedPrice,
    required this.stock,
    required this.stockUnitName,
    required this.cartCount,
    required this.status,
    required this.images,
    this.isUnlimitedStock,
    this.taxableAmount,
    this.calcDiscountPercentage,
    this.finalPriceWithTax,
    this.product,
  });

  late final String id;
  late final String type;
  late final String measurement;
  late final String price;
  late final String discountedPrice;
  late final String stock;
  late final String stockUnitName;
  late final String cartCount;
  late final String status;
  late final List<String> images;

  // New/extra fields
  String? isUnlimitedStock;
  int? taxableAmount;
  num? calcDiscountPercentage;
  int? finalPriceWithTax;
  Map<String, dynamic>? product;

  ProductDetailVariants.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    type = json['type'].toString();
    measurement = json['measurement'].toString();
    price = json['price'].toString();
    discountedPrice = json['discounted_price'].toString();
    stock = json['stock'].toString();
    stockUnitName = json['stock_unit_name'].toString();
    cartCount = json['cart_count'].toString();
    status = json['status'].toString();
    images = List.castFrom<dynamic, String>(json['images'] ?? []);
    isUnlimitedStock = json['is_unlimited_stock']?.toString();
    taxableAmount = json['taxable_amount'] is num
        ? (json['taxable_amount'] as num?)?.toInt()
        : int.tryParse(json['taxable_amount']?.toString() ?? '');
    calcDiscountPercentage = json['calc_discount_percentage'] is num
        ? (json['calc_discount_percentage'] as num)
        : num.tryParse(json['calc_discount_percentage']?.toString() ?? '');
    finalPriceWithTax = json['final_price_with_tax'] is num
        ? (json['final_price_with_tax'] as num?)?.toInt()
        : int.tryParse(json['final_price_with_tax']?.toString() ?? '');
    product = json['product'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['type'] = type;
    data['measurement'] = measurement;
    data['price'] = price;
    data['discounted_price'] = discountedPrice;
    data['stock'] = stock;
    data['stock_unit_name'] = stockUnitName;
    data['cart_count'] = cartCount;
    data['status'] = status;
    data['images'] = images;
    data['is_unlimited_stock'] = isUnlimitedStock;
    data['taxable_amount'] = taxableAmount;
    data['calc_discount_percentage'] = calcDiscountPercentage;
    data['final_price_with_tax'] = finalPriceWithTax;
    data['product'] = product;
    return data;
  }
}
