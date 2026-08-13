import 'package:zenfoo_partner/utils/safe_parser.dart';

class SellerOrderDetailsResponse {
  final int status;
  final String message;
  final SellerOrderDetails data;

  SellerOrderDetailsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SellerOrderDetailsResponse.fromJson(Map<String, dynamic> json) {
    return SellerOrderDetailsResponse(
      status: SafeParser.parseInt(json['status']),
      message: SafeParser.parseString(json['message']),
      data: SellerOrderDetails.fromJson(SafeParser.parseMap(json['data'])),
    );
  }
}

class SellerOrderDetails {
  final int orderId;
  final int sellerId;
  final bool isZenfooStore;
  final int itemsCount;
  final List<OrderItem> items;
  final String otp;
  final String status;
  final String prepTime;
  final SellerInfo seller;
  final String? firstPrepTimeSetAt;
  final int? firstPrepTimeMinutes;
  final String? driverArrivedAtSeller;
  final WaitChargeSettings? waitChargeSettings;

  SellerOrderDetails({
    required this.orderId,
    required this.sellerId,
    required this.isZenfooStore,
    required this.itemsCount,
    required this.items,
    required this.otp,
    required this.status,
    required this.prepTime,
    required this.seller,
    this.firstPrepTimeSetAt,
    this.firstPrepTimeMinutes,
    this.driverArrivedAtSeller,
    this.waitChargeSettings,
  });

  factory SellerOrderDetails.fromJson(Map<String, dynamic> json) {
    return SellerOrderDetails(
      orderId: SafeParser.parseInt(json['order_id']),
      sellerId: SafeParser.parseInt(json['seller_id']),
      isZenfooStore: SafeParser.parseBool(json['is_zenfoo_store']),
      itemsCount: SafeParser.parseInt(json['items_count']),
      items: SafeParser.parseList<Map<String, dynamic>>(json['items'])
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      otp: SafeParser.parseString(json['otp']),
      status: SafeParser.parseString(json['status']),
      prepTime: SafeParser.parseString(json['prep_time']),
      seller: SellerInfo.fromJson(SafeParser.parseMap(json['seller'])),
      firstPrepTimeSetAt: json['first_prep_time_set_at']?.toString(),
      firstPrepTimeMinutes: json['first_prep_time_minutes'] == null
          ? null
          : SafeParser.parseInt(json['first_prep_time_minutes']),
      driverArrivedAtSeller: json['driver_arrived_at_seller']?.toString(),
      waitChargeSettings: json['wait_charge_settings'] == null
          ? null
          : WaitChargeSettings.fromJson(
              SafeParser.parseMap(json['wait_charge_settings'])),
    );
  }
}

class WaitChargeSettings {
  final int graceMinutes;
  final double chargePerMinute;
  final double cap;

  WaitChargeSettings({
    required this.graceMinutes,
    required this.chargePerMinute,
    required this.cap,
  });

  factory WaitChargeSettings.fromJson(Map<String, dynamic> json) {
    return WaitChargeSettings(
      graceMinutes: SafeParser.parseInt(json['grace_minutes']),
      chargePerMinute: SafeParser.parseDouble(json['charge_per_minute']),
      cap: SafeParser.parseDouble(json['cap']),
    );
  }
}

class OrderItem {
  final int quantity;
  final String itemName;
  final String measurement;
  final String source;

  OrderItem({
    required this.quantity,
    required this.itemName,
    required this.measurement,
    required this.source,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      quantity: SafeParser.parseInt(json['quantity']),
      itemName: SafeParser.parseString(json['item_name']),
      measurement: SafeParser.parseString(json['measurement']),
      source: SafeParser.parseString(json['source']),
    );
  }
}

class SellerInfo {
  final String storeName;
  final String phoneNumber;
  final String address;
  final double latitude;
  final double longitude;

  SellerInfo({
    required this.storeName,
    required this.phoneNumber,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      storeName: SafeParser.parseString(json['store_name']),
      phoneNumber: SafeParser.parseString(json['phone_number']),
      address: SafeParser.parseString(json['address']),
      latitude: SafeParser.parseDouble(json['latitude']),
      longitude: SafeParser.parseDouble(json['longitude']),
    );
  }
}
