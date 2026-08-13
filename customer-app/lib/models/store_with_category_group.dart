import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_groups.dart';

/// Category data for slider when type is "category"
class SliderCategory {
  final int id;
  final String? name;
  final String? imageUrl;
  final bool hasChild;
  final bool hasActiveChild;

  SliderCategory({
    required this.id,
    this.name,
    this.imageUrl,
    this.hasChild = false,
    this.hasActiveChild = false,
  });

  factory SliderCategory.fromJson(Map<String, dynamic> json) {
    return SliderCategory(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString(),
      imageUrl: json['image_url']?.toString(),
      hasChild: json['has_child'] == true || json['has_child'] == 1,
      hasActiveChild: json['has_active_child'] == true || json['has_active_child'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name ?? '',
      'image_url': imageUrl ?? '',
      'has_child': hasChild,
      'has_active_child': hasActiveChild,
    };
  }
}

class StoreSlider {
  final int id;
  final int? storeId;
  final int? categoryGroupId;
  final int? subCategoryGroupId;
  final String? subCategoryName; // Name of the sub-category for title
  final String? type;
  final String? typeId;
  final String? image;
  final String? sliderUrl;
  final int status;
  final String? typeName;
  final String? imageUrl;
  final SliderCategory? category; // Category data when type is "category"

  StoreSlider({
    required this.id,
    this.storeId,
    this.categoryGroupId,
    this.subCategoryGroupId,
    this.subCategoryName,
    this.type,
    this.typeId,
    this.image,
    this.sliderUrl,
    this.status = 1,
    this.typeName,
    this.imageUrl,
    this.category,
  });

  factory StoreSlider.fromJson(Map<String, dynamic> json) {
    debugPrint('++++++++store sliders+++++++');
    print(json);
    debugPrint('sub_category_name_field from API: ${json['sub_category_name_field']}');
    return StoreSlider(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      storeId: json['store_id'] != null
          ? int.tryParse(json['store_id'].toString())
          : null,
      categoryGroupId: json['category_group_id'] != null
          ? int.tryParse(json['category_group_id'].toString())
          : null,
      subCategoryGroupId: json['sub_category_group_id'] != null
          ? int.tryParse(json['sub_category_group_id'].toString())
          : null,
      subCategoryName: json['sub_category_name_field']?.toString(),
      type: json['type']?.toString(),
      typeId: json['type_id']?.toString(),
      image: json['image']?.toString(),
      sliderUrl: json['slider_url']?.toString(),
      status: int.tryParse(json['status']?.toString() ?? '1') ?? 1,
      typeName: json['type_name']?.toString(),
      imageUrl: json['image_url']?.toString(),
      category: json['category'] != null
          ? SliderCategory.fromJson(json['category'])
          : null,
    );
  }

  // Convert StoreSlider to Sliders format for compatibility with SliderImageWidget
  Map<String, dynamic> toSlidersJson() {
    return {
      'id': id.toString(),
      'store_id': storeId.toString(),
      'category_group_id': categoryGroupId?.toString() ?? '',
      'sub_category_group_id': subCategoryGroupId?.toString() ?? '',
      'sub_category_name_field': subCategoryName ?? '',
      'type': type ?? '',
      'type_id': typeId ?? '',
      'slider_url': sliderUrl ?? '',
      'type_name': typeName ?? '',
      'image_url': imageUrl ?? '',
      'category_data': category?.toJson()
    };
  } 
}

class StoreCategory {
  final int id;
  final String name;
  final String? subtitle;
  final String? imageUrl;
  final String? image;
  final int? parentId;
  final bool hasChild;
  final int? sellerId;
  final int? isChildrenAllowed;
  final int? isSuperMart;
  final String? subcategoryIds;
  final int? categoryGroupId;
  final int? isGroup;
  final int? rowOrder;
  final String? createdAt;
  final String? updatedAt;

  StoreCategory({
    required this.id,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.image,
    this.parentId,
    this.hasChild = false,
    this.sellerId,
    this.isChildrenAllowed,
    this.isSuperMart,
    this.subcategoryIds,
    this.categoryGroupId,
    this.isGroup,
    this.rowOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreCategory.fromJson(Map<String, dynamic> json) {
    return StoreCategory(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      imageUrl: json['image_url']?.toString(),
      image: json['image']?.toString(),
      parentId: json['parent_id'] != null
          ? int.tryParse(json['parent_id'].toString())
          : null,
      hasChild: json['has_child'] == true ||
          json['has_child']?.toString().toLowerCase() == 'true' ||
          json['has_child'] == 1,
      sellerId: json['seller_id'] != null
          ? int.tryParse(json['seller_id'].toString())
          : null,
      isChildrenAllowed: json['is_children_allowed'] != null
          ? int.tryParse(json['is_children_allowed'].toString())
          : null,
      isSuperMart: json['is_super_mart'] != null
          ? int.tryParse(json['is_super_mart'].toString())
          : null,
      subcategoryIds: json['subcategory_ids']?.toString(),
      categoryGroupId: json['category_group_id'] != null
          ? int.tryParse(json['category_group_id'].toString())
          : null,
      isGroup: json['is_group'] != null
          ? int.tryParse(json['is_group'].toString())
          : null,
      rowOrder: json['row_order'] != null
          ? int.tryParse(json['row_order'].toString())
          : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  StoreCategory copyWith({
    int? id,
    String? name,
    String? subtitle,
    String? imageUrl,
    String? image,
    int? parentId,
    bool? hasChild,
    int? sellerId,
    int? isChildrenAllowed,
    int? isSuperMart,
    String? subcategoryIds,
    int? categoryGroupId,
    int? isGroup,
    int? rowOrder,
    String? createdAt,
    String? updatedAt,
  }) {
    return StoreCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      image: image ?? this.image,
      parentId: parentId ?? this.parentId,
      hasChild: hasChild ?? this.hasChild,
      sellerId: sellerId ?? this.sellerId,
      isChildrenAllowed: isChildrenAllowed ?? this.isChildrenAllowed,
      isSuperMart: isSuperMart ?? this.isSuperMart,
      subcategoryIds: subcategoryIds ?? this.subcategoryIds,
      categoryGroupId: categoryGroupId ?? this.categoryGroupId,
      isGroup: isGroup ?? this.isGroup,
      rowOrder: rowOrder ?? this.rowOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class StoreSeller {
  int? id;
  String? categoryName;
  String? aadharNumber;
  String? fssaiNumber;
  int? storeId;
  int? shopStatus;
  int? adminId;
  String? name;
  String? storeName;
  String? slug;
  String? email;
  String? mobile;
  Null otpLogin;
  int? balance;
  String? storeUrl;
  String? logo;
  String? storeDescription;
  String? street;
  String? pincodeId;
  String? cityId;
  String? storeLocation;
  String? storeCity;
  String? latLong;
  int? status;
  int? requireProductsApproval;
  Null fcmId;
  String? nationalIdentityCard;
  Null addressProof;
  String? panNumber;
  String? taxName;
  String? taxNumber;
  String? panImg;
  String? fssaiImg;
  List<String>? storeImages;
  int? customerPrivacy;
  int? viewOrderOtp;
  int? assignDeliveryBoy;
  int? selfPickupMode;
  String? createdAt;
  String? updatedAt;
  StoreDetails? storeDetails;
  String? distanceKm;
  String? travelTimeMin;
  String? logoUrl;
  String? nationalIdentityCardUrl;
  Null addressProofUrl;
  String? categoriesArray;
  List<Null>? pickupStoreTimingsArray;
  double? rating;
  int? ratingCount;
  bool? isBookmarked;
  String? foodType;
  bool? isShopOpen;
  String? shopStatusMessage;

  StoreSeller({
    this.id,
    this.categoryName,
    this.aadharNumber,
    this.fssaiNumber,
    this.storeId,
    this.shopStatus,
    this.adminId,
    this.name,
    this.storeName,
    this.slug,
    this.email,
    this.mobile,
    this.otpLogin,
    this.balance,
    this.storeUrl,
    this.logo,
    this.storeDescription,
    this.street,
    this.pincodeId,
    this.cityId,
    this.storeLocation,
    this.storeCity,
    this.latLong,
    this.status,
    this.requireProductsApproval,
    this.fcmId,
    this.nationalIdentityCard,
    this.addressProof,
    this.panNumber,
    this.taxName,
    this.taxNumber,
    this.panImg,
    this.fssaiImg,
    this.storeImages,
    this.customerPrivacy,
    this.viewOrderOtp,
    this.assignDeliveryBoy,
    this.selfPickupMode,
    this.createdAt,
    this.updatedAt,
    this.storeDetails,
    this.distanceKm,
    this.travelTimeMin,
    this.logoUrl,
    this.nationalIdentityCardUrl,
    this.addressProofUrl,
    this.categoriesArray,
    this.pickupStoreTimingsArray,
    this.rating,
    this.ratingCount,
    this.isBookmarked,
    this.foodType,
    this.isShopOpen,
    this.shopStatusMessage,
  });

  StoreSeller.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    categoryName = json['category_name']?.toString();
    aadharNumber = json['aadhar_number']?.toString();
    fssaiNumber = json['fssai_number']?.toString();
    storeId = json['store_id'] != null
        ? int.tryParse(json['store_id'].toString())
        : null;
    shopStatus = json['shop_status'] != null
        ? int.tryParse(json['shop_status'].toString())
        : null;
    adminId = json['admin_id'] != null
        ? int.tryParse(json['admin_id'].toString())
        : null;
    name = json['name']?.toString();
    storeName = json['store_name']?.toString();
    slug = json['slug']?.toString();
    email = json['email']?.toString();
    mobile = json['mobile']?.toString();
    otpLogin = json['otp_login'];
    balance = json['balance'] != null
        ? int.tryParse(json['balance'].toString())
        : null;
    storeUrl = json['store_url']?.toString();
    logo = json['logo']?.toString();
    storeDescription = json['store_description']?.toString();
    street = json['street']?.toString();
    pincodeId = json['pincode_id']?.toString();
    cityId = json['city_id']?.toString();
    storeLocation = json['store_location']?.toString();
    storeCity = json['store_city']?.toString();
    latLong = json['lat_long']?.toString();
    status =
        json['status'] != null ? int.tryParse(json['status'].toString()) : null;
    requireProductsApproval = json['require_products_approval'] != null
        ? int.tryParse(json['require_products_approval'].toString())
        : null;
    fcmId = json['fcm_id'];
    nationalIdentityCard = json['national_identity_card']?.toString();
    addressProof = json['address_proof'];
    panNumber = json['pan_number']?.toString();
    taxName = json['tax_name']?.toString();
    taxNumber = json['tax_number']?.toString();
    panImg = json['pan_img']?.toString();
    fssaiImg = json['fssai_img']?.toString();
    storeImages = json['store_images_urls'] != null
        ? (json['store_images_urls'] is List
            ? List<String>.from((json['store_images_urls'] as List)
                .map((e) => e?.toString() ?? '')
                .where((e) => e.isNotEmpty))
            : null)
        : null;
    customerPrivacy = json['customer_privacy'] != null
        ? int.tryParse(json['customer_privacy'].toString())
        : null;
    viewOrderOtp = json['view_order_otp'] != null
        ? int.tryParse(json['view_order_otp'].toString())
        : null;
    assignDeliveryBoy = json['assign_delivery_boy'] != null
        ? int.tryParse(json['assign_delivery_boy'].toString())
        : null;
    selfPickupMode = json['self_pickup_mode'] != null
        ? int.tryParse(json['self_pickup_mode'].toString())
        : null;
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    storeDetails = json['store_details'] != null
        ? StoreDetails.fromJson(json['store_details'])
        : null;
    distanceKm = json['distance_km']?.toString();
    travelTimeMin = json['travel_time_min']?.toString();
    logoUrl = json['logo_url']?.toString();
    nationalIdentityCardUrl = json['national_identity_card_url']?.toString();
    addressProofUrl = json['address_proof_url'];
    categoriesArray = json['categories_array']?.toString();
    rating = json['rating'] != null
        ? double.tryParse(json['rating'].toString())
        : null;
    ratingCount = json['rating_count'] != null
        ? int.tryParse(json['rating_count'].toString())
        : null;
    isBookmarked = json['is_bookmarked'] == true || json['is_bookmarked'] == 1;
    foodType = json['food_type']?.toString();
    isShopOpen = json['is_shop_open'] == true || json['is_shop_open'] == 1;
    shopStatusMessage = json['shop_status_message']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['category_name'] = this.categoryName;
    data['aadhar_number'] = this.aadharNumber;
    data['fssai_number'] = this.fssaiNumber;
    data['store_id'] = this.storeId;
    data['shop_status'] = this.shopStatus;
    data['admin_id'] = this.adminId;
    data['name'] = this.name;
    data['store_name'] = this.storeName;
    data['slug'] = this.slug;
    data['email'] = this.email;
    data['mobile'] = this.mobile;
    data['otp_login'] = this.otpLogin;
    data['balance'] = this.balance;
    data['store_url'] = this.storeUrl;
    data['logo'] = this.logo;
    data['store_description'] = this.storeDescription;
    data['street'] = this.street;
    data['pincode_id'] = this.pincodeId;
    data['city_id'] = this.cityId;
    data['store_location'] = this.storeLocation;
    data['store_city'] = this.storeCity;
    data['lat_long'] = this.latLong;
    data['status'] = this.status;
    data['require_products_approval'] = this.requireProductsApproval;
    data['fcm_id'] = this.fcmId;
    data['national_identity_card'] = this.nationalIdentityCard;
    data['address_proof'] = this.addressProof;
    data['pan_number'] = this.panNumber;
    data['tax_name'] = this.taxName;
    data['tax_number'] = this.taxNumber;
    data['pan_img'] = this.panImg;
    data['fssai_img'] = this.fssaiImg;
    data['store_images'] = this.storeImages;
    data['customer_privacy'] = this.customerPrivacy;
    data['view_order_otp'] = this.viewOrderOtp;
    data['assign_delivery_boy'] = this.assignDeliveryBoy;
    data['self_pickup_mode'] = this.selfPickupMode;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (this.storeDetails != null) {
      data['store_details'] = this.storeDetails!.toJson();
    }
    data['distance_km'] = this.distanceKm;
    data['travel_time_min'] = this.travelTimeMin;
    data['logo_url'] = this.logoUrl;
    data['national_identity_card_url'] = this.nationalIdentityCardUrl;
    data['address_proof_url'] = this.addressProofUrl;
    data['categories_array'] = this.categoriesArray;
    data['rating'] = this.rating;
    data['rating_count'] = this.ratingCount;
    data['is_bookmarked'] = this.isBookmarked;
    data['food_type'] = this.foodType;
    data['is_shop_open'] = this.isShopOpen;
    data['shop_status_message'] = this.shopStatusMessage;
    return data;
  }
}

class StoreDetails {
  int? id;
  String? name;
  String? icon;
  String? color;
  String? image;
  String? description;
  int? managedByAdmin;
  int? isSuperMart;
  bool? isSweetHouse;

  StoreDetails(
      {this.id,
      this.name,
      this.icon,
      this.color,
      this.image,
      this.description,
      this.managedByAdmin,
      this.isSuperMart,
      this.isSweetHouse});

  StoreDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name']?.toString();
    icon = json['icon']?.toString();
    color = json['color']?.toString();
    image = json['image']?.toString();
    description = json['description']?.toString();
    managedByAdmin = json['managed_by_admin'] != null
        ? int.tryParse(json['managed_by_admin'].toString())
        : null;
    isSuperMart = json['is_super_mart'] != null
        ? int.tryParse(json['is_super_mart'].toString())
        : null;
    isSweetHouse = json['is_sweet_house'] == true ||
        json['is_sweet_house']?.toString().toLowerCase() == 'true' ||
        json['is_sweet_house'] == 1;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['icon'] = this.icon;
    data['color'] = this.color;
    data['image'] = this.image;
    data['description'] = this.description;
    data['managed_by_admin'] = this.managedByAdmin;
    data['is_super_mart'] = this.isSuperMart;
    data['is_sweet_house'] = this.isSweetHouse;
    return data;
  }
}

// class StoreSeller {
//   final int id;
//   final String name;
//   final String? storeName;
//   final String? logoUrl;
//   final String? storeDescription;
//   final String? storeLocation;
//   final String? storeCity;
//   final String? latLong;
//   final String? categoriesArray;
//   final int status;
//   final String? distanceKm;
//   final String? travelTimeMin;
//   final int? isSweetHouse;
//   final List<String>? tags;
//   final num? rating;
//   final String? deliveryTime;
//   final String? licenseNumber;

//   StoreSeller({
//     required this.id,
//     required this.name,
//     this.storeName,
//     this.logoUrl,
//     this.storeDescription,
//     this.storeLocation,
//     this.storeCity,
//     this.latLong,
//     this.categoriesArray,
//     this.status = 1,
//     this.distanceKm,
//     this.travelTimeMin,
//     this.isSweetHouse,
//     this.tags,
//     this.rating,
//     this.deliveryTime,
//     this.licenseNumber,
//   });

//   factory StoreSeller.fromJson(Map<String, dynamic> json) {
//     return StoreSeller(
//       id: json['id'],
//       name: json['name'] ?? '',
//       storeName: json['store_name'],
//       logoUrl: json['logo_url'],
//       storeDescription: json['store_description'],
//       storeLocation: json['store_location'],
//       storeCity: json['store_city'],
//       latLong: json['lat_long'],
//       categoriesArray: json['categories_array'],
//       status: json['status'] ?? 1,
//       distanceKm: json['distance_km'],
//       travelTimeMin: json['travel_time_min'],
//       isSweetHouse: json['is_sweet_house'],
//       tags: json['tags'] != null
//           ? (json['tags'] is List
//               ? List<String>.from(json['tags'])
//               : (json['tags'] as String).split(',').map((e) => e.trim()).toList())
//           : null,
//       rating: json['rating'] != null ? num.tryParse(json['rating'].toString()) : null,
//       deliveryTime: json['delivery_time'],
//       licenseNumber: json['license_number'] ?? json['fssai_license'],
//     );
//   }
// }

class SellersPagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final List<StoreSeller> data;

  SellersPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.data,
  });

  factory SellersPagination.fromJson(Map<String, dynamic> json) {
    return SellersPagination(
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      perPage: int.tryParse(json['per_page']?.toString() ?? '0') ?? 0,
      currentPage: int.tryParse(json['current_page']?.toString() ?? '1') ?? 1,
      lastPage: int.tryParse(json['last_page']?.toString() ?? '1') ?? 1,
      data: (json['data'] is List
              ? (json['data'] as List)
                  .map((e) {
                    try {
                      return StoreSeller.fromJson(e as Map<String, dynamic>);
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<StoreSeller>()
                  .toList()
              : null) ??
          [],
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}

// Supermart sellers response model
class SupermartSellersResponse {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final List<StoreSeller> data;
  final List<StoreSlider> banners;

  SupermartSellersResponse({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.data,
    this.banners = const [],
  });

  factory SupermartSellersResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested data structure from API
    final paginationData = json['data'] is Map ? json['data'] : json;

    return SupermartSellersResponse(
      total: int.tryParse(paginationData['total']?.toString() ?? '0') ?? 0,
      perPage: int.tryParse(paginationData['per_page']?.toString() ?? '0') ?? 0,
      currentPage:
          int.tryParse(paginationData['current_page']?.toString() ?? '1') ?? 1,
      lastPage:
          int.tryParse(paginationData['last_page']?.toString() ?? '1') ?? 1,
      data: (paginationData['data'] is List
              ? (paginationData['data'] as List)
                  .map((e) {
                    try {
                      return StoreSeller.fromJson(e as Map<String, dynamic>);
                    } catch (error) {
                      return null;
                    }
                  })
                  .whereType<StoreSeller>()
                  .toList()
              : null) ??
          [],
      banners: (paginationData['banners'] is List
              ? (paginationData['banners'] as List)
                  .map((e) {
                    try {
                      return StoreSlider.fromJson(e as Map<String, dynamic>);
                    } catch (error) {
                      return null;
                    }
                  })
                  .whereType<StoreSlider>()
                  .toList()
              : null) ??
          [],
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}

class StoreWithCategoryGroups {
  final int id;
  final String name;
  final String? icon;
  final String? iconUrl;
  final String? color;
  final List<CategoryGroup> categoryGroups;
  final List<StoreCategory> categories;
  final List<StoreSeller> sellers;
  final List<StoreSeller> topRatedSellers;
  final List<StoreSlider> sliders;
  final SellersPagination? sellersPagination;
  final bool isMeat;

  StoreWithCategoryGroups({
    required this.id,
    required this.name,
    this.icon,
    this.iconUrl,
    this.color,
    required this.categoryGroups,
    this.categories = const [],
    this.sellers = const [],
    this.topRatedSellers = const [],
    this.sliders = const [],
    this.sellersPagination,
    this.isMeat = false,
  });

  factory StoreWithCategoryGroups.fromJson(Map<String, dynamic> json) {
    return StoreWithCategoryGroups(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString(),
      iconUrl: json['icon_url']?.toString(),
      color: json['color']?.toString(),
      categoryGroups: (json['category_groups'] is List
              ? (json['category_groups'] as List)
                  .map((e) {
                    try {
                      return CategoryGroup.fromJson(e as Map<String, dynamic>);
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<CategoryGroup>()
                  .toList()
              : null) ??
          [],
      categories: (json['categories'] is List
              ? (json['categories'] as List)
                  .map((e) {
                    try {
                      return StoreCategory.fromJson(e as Map<String, dynamic>);
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<StoreCategory>()
                  .toList()
              : null) ??
          [],
      sellers: (json['sellers'] is List
              ? (json['sellers'] as List)
                  .map((e) {
                    try {
                      return StoreSeller.fromJson(e as Map<String, dynamic>);
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<StoreSeller>()
                  .toList()
              : null) ??
          [],
      topRatedSellers: (json['top_rated_sellers'] is List
              ? (json['top_rated_sellers'] as List)
                  .map((e) {
                    try {
                      return StoreSeller.fromJson(e as Map<String, dynamic>);
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<StoreSeller>()
                  .toList()
              : null) ??
          [],
      sliders: (json['sliders'] is List
              ? (json['sliders'] as List)
                  .map((e) {
                    try {
                      return StoreSlider.fromJson(e as Map<String, dynamic>);
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<StoreSlider>()
                  .toList()
              : null) ??
          [],
      sellersPagination: json['sellers_pagination'] != null
          ? SellersPagination.fromJson(
              json['sellers_pagination'] as Map<String, dynamic>)
          : null,
      isMeat: json['is_meat'] == true || json['is_meat'] == 1,
    );
  }
}
