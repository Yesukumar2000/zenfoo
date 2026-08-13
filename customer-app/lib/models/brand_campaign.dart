import 'package:project/models/productListItem.dart';

class BrandCampaign {
  int? status;
  String? message;
  BrandCampaignData? data;

  BrandCampaign({this.status, this.message, this.data});

  BrandCampaign.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data =
        json['data'] != null ? BrandCampaignData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }

  bool get isValid => status == 1 && data?.campaign != null;
}

class BrandCampaignData {
  Campaign? campaign;
  List<ProductListItem>? latestProducts;
  List<ProductListItem>? otherProducts;
  int? productsCount;
  int? daysUntilExpiry;

  BrandCampaignData({
    this.campaign,
    this.latestProducts,
    this.otherProducts,
    this.productsCount,
    this.daysUntilExpiry,
  });

  BrandCampaignData.fromJson(Map<String, dynamic> json) {
    campaign =
        json['campaign'] != null ? Campaign.fromJson(json['campaign']) : null;
    if (json['latest_products'] != null) {
      latestProducts = <ProductListItem>[];
      json['latest_products'].forEach((v) {
        latestProducts!.add(ProductListItem.fromJson(v));
      });
    } else if (json['products'] != null) {
      latestProducts = <ProductListItem>[];
      json['products'].forEach((v) {
        latestProducts!.add(ProductListItem.fromJson(v));
      });
    }
    if (json['other_products'] != null) {
      otherProducts = <ProductListItem>[];
      json['other_products'].forEach((v) {
        otherProducts!.add(ProductListItem.fromJson(v));
      });
    }
    productsCount = json['products_count'];
    daysUntilExpiry = json['days_until_expiry'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (campaign != null) {
      data['campaign'] = campaign!.toJson();
    }
    if (latestProducts != null) {
      data['latest_products'] =
          latestProducts!.map((v) => v.toJson()).toList();
    }
    if (otherProducts != null) {
      data['other_products'] =
          otherProducts!.map((v) => v.toJson()).toList();
    }
    data['products_count'] = productsCount;
    data['days_until_expiry'] = daysUntilExpiry;
    return data;
  }
}

class Campaign {
  int? id;
  String? name;
  String? description;
  String? tagline;
  String? primaryImageUrl;
  String? secondaryImageUrl;
  List<CampaignBanner>? banners;
  int? brandId;
  String? brandName;
  List<int>? productIds;
  List<int>? categoryIds;
  String? campaignType;
  String? startDate;
  String? endDate;
  String? expiredAt;
  bool? isActive;
  bool? isExpired;
  bool? isFeatured;
  int? displayOrder;
  int? daysUntilExpiry;
  String? themeColor;
  CampaignMetadata? metadata;

  Campaign({
    this.id,
    this.name,
    this.description,
    this.tagline,
    this.primaryImageUrl,
    this.secondaryImageUrl,
    this.banners,
    this.brandId,
    this.brandName,
    this.productIds,
    this.categoryIds,
    this.campaignType,
    this.startDate,
    this.endDate,
    this.expiredAt,
    this.isActive,
    this.isExpired,
    this.isFeatured,
    this.displayOrder,
    this.daysUntilExpiry,
    this.themeColor,
    this.metadata,
  });

  Campaign.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    tagline = json['tagline'];
    primaryImageUrl = json['primary_image_url']?.toString() ??
        json['primary_image']?.toString();
    secondaryImageUrl = json['secondary_image_url']?.toString() ??
        json['secondary_image']?.toString();
    if (json['banners'] != null) {
      banners = <CampaignBanner>[];
      json['banners'].forEach((v) {
        banners!.add(CampaignBanner.fromJson(v));
      });
    }
    brandId = json['brand_id'];
    brandName = json['brand_name'];
    productIds = json['product_ids'] != null
        ? (json['product_ids'] as List)
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .toList()
        : null;
    categoryIds = json['category_ids'] != null
        ? (json['category_ids'] as List)
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .toList()
        : null;
    campaignType = json['campaign_type'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    expiredAt = json['expired_at'];
    isActive = json['is_active'];
    isExpired = json['is_expired'];
    isFeatured = json['is_featured'];
    displayOrder = json['display_order'];
    daysUntilExpiry = json['days_until_expiry'];
    themeColor = json['theme_color'];
    metadata = (json['metadata'] != null && json['metadata'] is Map)
        ? CampaignMetadata.fromJson(json['metadata'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['tagline'] = tagline;
    data['primary_image_url'] = primaryImageUrl;
    data['secondary_image_url'] = secondaryImageUrl;
    if (banners != null) {
      data['banners'] = banners!.map((v) => v.toJson()).toList();
    }
    data['brand_id'] = brandId;
    data['brand_name'] = brandName;
    data['product_ids'] = productIds;
    data['category_ids'] = categoryIds;
    data['campaign_type'] = campaignType;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['expired_at'] = expiredAt;
    data['is_active'] = isActive;
    data['is_expired'] = isExpired;
    data['is_featured'] = isFeatured;
    data['display_order'] = displayOrder;
    data['days_until_expiry'] = daysUntilExpiry;
    data['theme_color'] = themeColor;
    if (metadata != null) {
      data['metadata'] = metadata!.toJson();
    }
    return data;
  }

  bool get isAvailable => (isActive ?? false) && !(isExpired ?? false);
}

class CampaignBanner {
  String? type;
  String? url;
  String? title;
  String? description;

  CampaignBanner({this.type, this.url, this.title, this.description});

  CampaignBanner.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    url = json['url'];
    title = json['title'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['url'] = url;
    data['title'] = title;
    data['description'] = description;
    return data;
  }
}

class CampaignProduct {
  int? id;
  String? name;
  String? slug;
  String? description;
  String? image;
  double? price;
  double? cost;
  double? discountPercentage;
  double? discountPrice;
  int? quantity;
  String? unit;
  String? sku;
  double? rating;
  int? reviewsCount;
  ProductCategory? category;
  ProductSeller? seller;
  ProductStore? store;

  CampaignProduct({
    this.id,
    this.name,
    this.slug,
    this.description,
    this.image,
    this.price,
    this.cost,
    this.discountPercentage,
    this.discountPrice,
    this.quantity,
    this.unit,
    this.sku,
    this.rating,
    this.reviewsCount,
    this.category,
    this.seller,
    this.store,
  });

  CampaignProduct.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
    description = json['description'];
    image = json['image'];
    price = json['price'] != null
        ? double.tryParse(json['price'].toString())
        : null;
    cost =
        json['cost'] != null ? double.tryParse(json['cost'].toString()) : null;
    discountPercentage = json['discount_percentage'] != null
        ? double.tryParse(json['discount_percentage'].toString())
        : null;
    discountPrice = json['discount_price'] != null
        ? double.tryParse(json['discount_price'].toString())
        : null;
    quantity = json['quantity'];
    unit = json['unit'];
    sku = json['sku'];
    rating = json['rating'] != null
        ? double.tryParse(json['rating'].toString())
        : null;
    reviewsCount = json['reviews_count'];
    category = json['category'] != null
        ? ProductCategory.fromJson(json['category'])
        : null;
    seller =
        json['seller'] != null ? ProductSeller.fromJson(json['seller']) : null;
    store = json['store'] != null ? ProductStore.fromJson(json['store']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['description'] = description;
    data['image'] = image;
    data['price'] = price;
    data['cost'] = cost;
    data['discount_percentage'] = discountPercentage;
    data['discount_price'] = discountPrice;
    data['quantity'] = quantity;
    data['unit'] = unit;
    data['sku'] = sku;
    data['rating'] = rating;
    data['reviews_count'] = reviewsCount;
    if (category != null) {
      data['category'] = category!.toJson();
    }
    if (seller != null) {
      data['seller'] = seller!.toJson();
    }
    if (store != null) {
      data['store'] = store!.toJson();
    }
    return data;
  }
}

class ProductCategory {
  int? id;
  String? name;

  ProductCategory({this.id, this.name});

  ProductCategory.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class ProductSeller {
  int? id;
  String? name;

  ProductSeller({this.id, this.name});

  ProductSeller.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class ProductStore {
  int? id;
  String? name;

  ProductStore({this.id, this.name});

  ProductStore.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class CampaignMetadata {
  String? discountPercentage;
  bool? freeShipping;
  String? targetAudience;

  CampaignMetadata(
      {this.discountPercentage, this.freeShipping, this.targetAudience});

  CampaignMetadata.fromJson(Map<String, dynamic> json) {
    discountPercentage = json['discount_percentage']?.toString();
    freeShipping = json['free_shipping'];
    targetAudience = json['target_audience'];
  }

  Map<String, dynamic> toJson() {
    return {
      'discount_percentage': discountPercentage,
      'free_shipping': freeShipping,
      'target_audience': targetAudience,
    };
  }
}
