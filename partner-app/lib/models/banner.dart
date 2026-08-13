class BannerResponse {
  int? status;
  String? message;
  BannerData? data;

  BannerResponse({this.status, this.message, this.data});

  factory BannerResponse.fromJson(Map<String, dynamic> json) {
    return BannerResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? BannerData.fromJson(json['data'] as dynamic) : null,
    );
  }
}

class BannerData {
  StoreInfo? storeInfo;
  List<BannerItem>? banners;

  BannerData({this.storeInfo, this.banners});

  factory BannerData.fromJson(dynamic json) {
    // Handle both cases: data as list directly or data as object with banners
    if (json is List) {
      // Case where data is directly a list of banners
      return BannerData(
        storeInfo: null,
        banners: json
            .map((e) => BannerItem.fromJson(e))
            .toList(),
      );
    } else if (json is Map<String, dynamic>) {
      // Case where data is an object with banners property
      return BannerData(
        storeInfo: json['store_info'] != null
            ? StoreInfo.fromJson(json['store_info'])
            : null,
        banners: json['banners'] != null
            ? (json['banners'] as List)
                .map((e) => BannerItem.fromJson(e))
                .toList()
            : null,
      );
    } else {
      // Handle case where data is the banners list directly
      return BannerData(
        storeInfo: null,
        banners: null,
      );
    }
  }
}

class StoreInfo {
  int? id;
  String? name;
  bool? managedByAdmin;

  StoreInfo({this.id, this.name, this.managedByAdmin});

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      id: json['id'],
      name: json['name'],
      managedByAdmin: json['managed_by_admin'],
    );
  }
}

class BannerItem {
  int? id;
  String? type; // 'category', 'product', 'offer_url', 'default'
  int? typeId;
  String? typeName;
  String? image;
  String? imageUrl;
  String? offerUrl;
  int? storeId;
  String? createdAt;
  String? updatedAt;

  BannerItem({
    this.id,
    this.type,
    this.typeId,
    this.typeName,
    this.image,
    this.imageUrl,
    this.offerUrl,
    this.storeId,
    this.createdAt,
    this.updatedAt,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    // Safe parsing for type_id - can be string or int
    int? parsedTypeId;
    if (json['type_id'] != null && json['type_id'] != 'null') {
      if (json['type_id'] is int) {
        parsedTypeId = json['type_id'];
      } else if (json['type_id'] is String) {
        parsedTypeId = int.tryParse(json['type_id']);
      }
    }

    // Safe parsing for offer_url/slider_url - can be null or "null" string
    String? parsedOfferUrl;
    final sliderUrl = json['slider_url'] ?? json['offer_url'];
    if (sliderUrl != null && sliderUrl != 'null' && sliderUrl.toString().isNotEmpty) {
      parsedOfferUrl = sliderUrl.toString();
    }

    // Safe parsing for type_name - handle null or "null" string
    String? parsedTypeName;
    if (json['type_name'] != null && json['type_name'] != 'null') {
      parsedTypeName = json['type_name']?.toString();
    }

    return BannerItem(
      id: json['id'],
      type: json['type']?.toString(),
      typeId: parsedTypeId,
      typeName: parsedTypeName,
      image: json['image']?.toString(),
      imageUrl: json['image_url']?.toString(),
      offerUrl: parsedOfferUrl,
      storeId: json['store_id'],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}
