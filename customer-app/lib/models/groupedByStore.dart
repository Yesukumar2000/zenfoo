/// Tolerantly parses a value that may arrive as bool, int (1/0) or string
/// ("true"/"1"). The orders API returns these flags inconsistently, so a
/// direct `as bool?` cast crashes with "int is not a subtype of bool?".
bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0' || v.isEmpty) return false;
  }
  return null;
}

class GroupedByStore {
  final int? storeId;
  final String? storeName;
  final String? storeIcon;
  final String? storeColor;
  final String? storeImage;
  final String? storeDescription;
  final bool? isSuperMart;
  final bool? managedByAdmin;
  final List<SellerInfo>? sellers;
  final List<dynamic>? items;

  GroupedByStore({
    this.storeId,
    this.storeName,
    this.storeIcon,
    this.storeColor,
    this.storeImage,
    this.storeDescription,
    this.isSuperMart,
    this.managedByAdmin,
    this.sellers,
    this.items,
  });

  factory GroupedByStore.fromJson(Map<String, dynamic> json) {
    return GroupedByStore(
      storeId: json['store_id'] as int?,
      storeName: json['store_name']?.toString(),
      storeIcon: json['store_icon']?.toString(),
      storeColor: json['store_color']?.toString(),
      storeImage: json['store_image']?.toString(),
      storeDescription: json['store_description']?.toString(),
      isSuperMart: json['is_super_mart'] == 1 ||
          json['is_super_mart'] == '1' ||
          json['is_super_mart'] == true,
      managedByAdmin: json['managed_by_admin'] == 1 ||
          json['managed_by_admin'] == '1' ||
          json['managed_by_admin'] == true,
      sellers: (json['sellers'] as List<dynamic>?)
          ?.map((e) => SellerInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: json['items'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'store_name': storeName,
      'store_icon': storeIcon,
      'store_color': storeColor,
      'store_image': storeImage,
      'store_description': storeDescription,
      'is_super_mart': isSuperMart,
      'managed_by_admin': managedByAdmin,
      'sellers': sellers?.map((e) => e.toJson()).toList(),
      'items': items,
    };
  }
}

class SellerInfo {
  final int? sellerId;
  final String? sellerName;
  final String? sellerImage;
  final String? sellerAddress;
  final String? sellerPlaceName;
  final String? sellerLatitude;
  final String? sellerLongitude;
  final String? sellerLatLong;
  final String? prepTime;
  final List<dynamic>? items;

  SellerInfo({
    this.sellerId,
    this.sellerName,
    this.sellerImage,
    this.sellerAddress,
    this.sellerPlaceName,
    this.sellerLatitude,
    this.sellerLongitude,
    this.sellerLatLong,
    this.prepTime,
    this.items,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    String? sellerLat = json['seller_latitude']?.toString();
    String? sellerLng = json['seller_longitude']?.toString();
    String? sellerLatLng = json['seller_lat_long']?.toString();

    // If seller_latitude/longitude are empty but seller_lat_long has data, split it
    if ((sellerLat == null || sellerLat.isEmpty || sellerLat == 'null') &&
        (sellerLng == null || sellerLng.isEmpty || sellerLng == 'null') &&
        sellerLatLng != null && sellerLatLng.isNotEmpty && sellerLatLng != 'null') {
      List<String> latLong = sellerLatLng.split(',');
      if (latLong.length == 2) {
        sellerLat = latLong[0].trim();
        sellerLng = latLong[1].trim();
      }
    }

    return SellerInfo(
      sellerId: json['seller_id'] as int?,
      sellerName: json['seller_name']?.toString(),
      sellerImage: json['seller_image']?.toString(),
      sellerAddress: json['seller_address']?.toString(),
      sellerPlaceName: json['seller_place_name']?.toString(),
      sellerLatitude: sellerLat,
      sellerLongitude: sellerLng,
      sellerLatLong: sellerLatLng,
      prepTime: json['prep_time']?.toString(),
      items: json['items'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'seller_name': sellerName,
      'seller_image': sellerImage,
      'seller_address': sellerAddress,
      'seller_place_name': sellerPlaceName,
      'seller_latitude': sellerLatitude,
      'seller_longitude': sellerLongitude,
      'seller_lat_long': sellerLatLong,
      'prep_time': prepTime,
      'items': items,
    };
  }

  // Helper method to get parsed latitude
  double? getLatitude() {
    if (sellerLatitude != null && sellerLatitude!.isNotEmpty && sellerLatitude != 'null') {
      return double.tryParse(sellerLatitude!);
    }
    return null;
  }

  // Helper method to get parsed longitude
  double? getLongitude() {
    if (sellerLongitude != null && sellerLongitude!.isNotEmpty && sellerLongitude != 'null') {
      return double.tryParse(sellerLongitude!);
    }
    return null;
  }

  // Helper method to check if seller has valid location
  bool hasValidLocation() {
    double? lat = getLatitude();
    double? lng = getLongitude();
    return lat != null && lng != null && lat != 0.0 && lng != 0.0;
  }
}
