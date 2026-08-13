class ProductListItem {
  String? id;
  String? sellerId;
  String? sellerName;
  String? name;
  String? averageRating;
  int? ratingCount;
  String? taxId;
  String? brandId;
  String? brandName;
  String? slug;
  String? categoryId;
  String? categoryName;
  String? itemTypeId;
  String? indicator;
  String? manufacturer;
  String? madeIn;
  String? madeInId;
  String? status;
  String? isApproved;
  String? isUnlimitedStock;
  String? codAllowed;
  String? totalAllowedQuantity;
  String? taxIncludedInPrice;
  String? longitude;
  String? latitude;
  String? maxDeliverableDistance;
  String? type;
  String? dType;
  String? description;
  String? returnStatus;
  String? cancelableStatus;
  String? tillStatus;
  String? returnDays;
  String? fssaiLicNo;
  String? tagNames;
  String? barcode;
  String? metaTitle;
  String? metaKeywords;
  String? schemaMarkup;
  String? metaDescription;
  String? boundaryPoints;
  String? countryMadeIn;
  int? isPreOrderItem;
  int? storeId;
  bool? isMeatProduct;
  bool? isSuperMart;
  bool? isCleaned;
  String? beforeCleaningWeight;
  String? afterCleaningWeight;
  String? pieces;

  int? calDiscountPercentage;
  int? calDiscount;
  int? price;
  int? discountedPrice;
  int? orderCounter;
  int? taxPercentage;
  int? minPrice;
  int? maxPrice;
  num? averageRatingNum;

  bool? isDeliverable;
  bool? isFavorite;
  bool? isBookmarked;

  List<Variants>? variants;
  String? imageUrl;
  List<String>? images;
  List<dynamic>? ratings;

  ProductListItem({
    this.id,
    this.sellerId,
    this.sellerName,
    this.name,
    this.averageRating,
    this.averageRatingNum,
    this.ratingCount,
    this.taxId,
    this.brandId,
    this.brandName,
    this.slug,
    this.categoryId,
    this.categoryName,
    this.itemTypeId,
    this.indicator,
    this.manufacturer,
    this.madeIn,
    this.madeInId,
    this.status,
    this.isApproved,
    this.isUnlimitedStock,
    this.codAllowed,
    this.totalAllowedQuantity,
    this.taxIncludedInPrice,
    this.longitude,
    this.latitude,
    this.maxDeliverableDistance,
    this.type,
    this.dType,
    this.description,
    this.returnStatus,
    this.cancelableStatus,
    this.tillStatus,
    this.returnDays,
    this.fssaiLicNo,
    this.tagNames,
    this.barcode,
    this.metaTitle,
    this.metaKeywords,
    this.schemaMarkup,
    this.metaDescription,
    this.boundaryPoints,
    this.countryMadeIn,
    this.calDiscountPercentage,
    this.calDiscount,
    this.price,
    this.discountedPrice,
    this.orderCounter,
    this.taxPercentage,
    this.minPrice,
    this.maxPrice,
    this.isDeliverable,
    this.isFavorite,
    this.isBookmarked,
    this.variants,
    this.imageUrl,
    this.images,
    this.ratings,
    this.storeId,
    this.isMeatProduct,
    this.isSuperMart,
    this.isCleaned,
    this.beforeCleaningWeight,
    this.afterCleaningWeight,
    this.pieces,
  });

  ProductListItem.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    sellerId = json['seller_id']?.toString();
    sellerName = json['seller_name']?.toString();
    name = json['name']?.toString();
    averageRating = json['average_rating']?.toString();
    averageRatingNum = (json['average_rating'] is num)
        ? json['average_rating']
        : num.tryParse(json['average_rating']?.toString() ?? "");
    ratingCount = json['rating_count'] is int
        ? json['rating_count']
        : int.tryParse(json['rating_count']?.toString() ?? '');
    taxId = json['tax_id']?.toString();
    brandId = json['brand_id']?.toString();
    brandName = json['brand_name']?.toString();
    slug = json['slug']?.toString();
    categoryId = json['category_id']?.toString();
    categoryName = json['category_name']?.toString();
    itemTypeId = json['item_type_id']?.toString();
    indicator = json['indicator']?.toString();
    manufacturer = json['manufacturer']?.toString();
    madeIn = json['made_in']?.toString();
    madeInId = json['made_in_id']?.toString();
    status = json['status']?.toString();
    isApproved = json['is_approved']?.toString();
    isUnlimitedStock = json['is_unlimited_stock']?.toString();
    codAllowed = json['cod_allowed']?.toString();
    totalAllowedQuantity = json['total_allowed_quantity']?.toString();
    taxIncludedInPrice = json['tax_included_in_price']?.toString();
    longitude = json['longitude']?.toString();
    latitude = json['latitude']?.toString();
    maxDeliverableDistance = json['max_deliverable_distance']?.toString();
    type = json['type']?.toString();
    dType = json['d_type']?.toString();
    description = json['description']?.toString();
    returnStatus = json['return_status']?.toString();
    cancelableStatus = json['cancelable_status']?.toString();
    tillStatus = json['till_status']?.toString();
    returnDays = json['return_days']?.toString();
    fssaiLicNo = json['fssai_lic_no']?.toString();
    tagNames = json['tag_names']?.toString();
    barcode = json['barcode']?.toString();
    metaTitle = json['meta_title']?.toString();
    metaKeywords = json['meta_keywords']?.toString();
    schemaMarkup = json['schema_markup']?.toString();
    metaDescription = json['meta_description']?.toString();
    boundaryPoints = json['boundary_points']?.toString();
    countryMadeIn = json['country_made_in']?.toString();
    isPreOrderItem =
        int.tryParse(json['is_pre_order_item']?.toString() ?? '0') ?? 0;
    storeId = int.tryParse(json['store_id']?.toString() ?? '');
    isMeatProduct = json['is_meat'] == true || json['is_meat'] == 1 ||
        json['is_meat_product'] == true || json['is_meat_product'] == 1;
    isSuperMart = json['is_super_mart'] == true || json['is_super_mart'] == 1;
    isCleaned = json['is_cleaned'] == true ||
        json['is_cleaned'] == 1 ||
        json['is_cleaned'] == '1';
    beforeCleaningWeight = json['before_cleaning_weight']?.toString() ?? '';
    afterCleaningWeight = json['after_cleaning_weight']?.toString() ?? '';
    pieces = json['pieces']?.toString() ?? '';

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
    taxPercentage = json['tax_percentage'] is num
        ? (json['tax_percentage'] as num?)?.toInt()
        : int.tryParse(json['tax_percentage']?.toString() ?? '');
    minPrice = json['min_price'] is num
        ? (json['min_price'] as num?)?.toInt()
        : int.tryParse(json['min_price']?.toString() ?? '');
    maxPrice = json['max_price'] is num
        ? (json['max_price'] as num?)?.toInt()
        : int.tryParse(json['max_price']?.toString() ?? '');

    isDeliverable =
        json['is_deliverable'] == true || json['is_deliverable'] == 1;
    isFavorite = json['is_favorite'] == true || json['is_favorite'] == 1;
    isBookmarked = json['is_bookmarked'] == true || json['is_bookmarked'] == 1;

    if (json['variants'] != null) {
      variants = <Variants>[];
      json['variants'].forEach((v) {
        variants!.add(Variants.fromJson(v));
      });
      variants = [
        ...variants!.where((v) => v.status != "0"),
        ...variants!.where((v) => v.status == "0"),
      ];
    }
    imageUrl = json['image_url']?.toString();
    images = (json['images'] is List) && (json['images'] != [])
        ? (json['images'] as List).map((img) {
            if (img is Map<String, dynamic>) {
              return img['image']?.toString() ?? '';
            }
            return img.toString();
          }).toList()
        : [];
    ratings = json['ratings'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['seller_id'] = sellerId;
    data['seller_name'] = sellerName;
    data['name'] = name;
    data['average_rating'] = averageRating;
    data['rating_count'] = ratingCount;
    data['tax_id'] = taxId;
    data['brand_id'] = brandId;
    data['brand_name'] = brandName;
    data['slug'] = slug;
    data['category_id'] = categoryId;
    data['category_name'] = categoryName;
    data['item_type_id'] = itemTypeId;
    data['indicator'] = indicator;
    data['manufacturer'] = manufacturer;
    data['made_in'] = madeIn;
    data['made_in_id'] = madeInId;
    data['status'] = status;
    data['is_approved'] = isApproved;
    data['is_unlimited_stock'] = isUnlimitedStock;
    data['cod_allowed'] = codAllowed;
    data['total_allowed_quantity'] = totalAllowedQuantity;
    data['tax_included_in_price'] = taxIncludedInPrice;
    data['longitude'] = longitude;
    data['latitude'] = latitude;
    data['max_deliverable_distance'] = maxDeliverableDistance;
    data['type'] = type;
    data['d_type'] = dType;
    data['description'] = description;
    data['return_status'] = returnStatus;
    data['cancelable_status'] = cancelableStatus;
    data['till_status'] = tillStatus;
    data['return_days'] = returnDays;
    data['fssai_lic_no'] = fssaiLicNo;
    data['tag_names'] = tagNames;
    data['barcode'] = barcode;
    data['meta_title'] = metaTitle;
    data['meta_keywords'] = metaKeywords;
    data['schema_markup'] = schemaMarkup;
    data['meta_description'] = metaDescription;
    data['boundary_points'] = boundaryPoints;
    data['country_made_in'] = countryMadeIn;
    data['is_pre_order_item'] = isPreOrderItem;
    data['cal_discount_percentage'] = calDiscountPercentage;
    data['cal_discount'] = calDiscount;
    data['price'] = price;
    data['discounted_price'] = discountedPrice;
    data['order_counter'] = orderCounter;
    data['tax_percentage'] = taxPercentage;
    data['min_price'] = minPrice;
    data['max_price'] = maxPrice;
    data['is_deliverable'] = isDeliverable;
    data['is_favorite'] = isFavorite;
    data['is_bookmarked'] = isBookmarked;
    if (variants != null) {
      data['variants'] = variants!.map((v) => v.toJson()).toList();
    }
    data['image_url'] = imageUrl;
    data['images'] = images;
    data['ratings'] = ratings;
    data['is_cleaned'] = isCleaned;
    data['before_cleaning_weight'] = beforeCleaningWeight;
    data['after_cleaning_weight'] = afterCleaningWeight;
    data['pieces'] = pieces;
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
  String? stockUnitName;
  String? isUnlimitedStock;
  String? cartCount;
  String? taxableAmount;

  List<String>? images;

  Variants({
    this.id,
    this.type,
    this.status,
    this.measurement,
    this.price,
    this.discountedPrice,
    this.stock,
    this.stockUnitName,
    this.isUnlimitedStock,
    this.cartCount,
    this.taxableAmount,
    this.images,
  });

  Variants.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    type = json['type'].toString();
    status = json['status'].toString();
    measurement = json['measurement'].toString();
    price = json['price'].toString();
    discountedPrice = json['discounted_price'].toString();
    stock = json['stock'].toString();
    stockUnitName = json['stock_unit_name'].toString();
    isUnlimitedStock = json['is_unlimited_stock'].toString();
    cartCount = json['cart_count'].toString();
    taxableAmount = json['taxable_amount'].toString();
    images = (json['images'] != null && json['images'] is List)
        ? (json['images'] as List).map((img) {
            if (img is Map<String, dynamic>) {
              return img['image']?.toString() ?? '';
            }
            return img.toString();
          }).toList()
        : [];
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
    data['stock_unit_name'] = this.stockUnitName;
    data['is_unlimited_stock'] = this.isUnlimitedStock;
    data['cart_count'] = this.cartCount;
    data['taxable_amount'] = this.taxableAmount;
    data['images'] = this.images;
    return data;
  }
}
