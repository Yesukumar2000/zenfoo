import 'package:flutter/foundation.dart';
import 'package:zenfoo_partner/utils/safe_parser.dart';

class IncomingOrderResponse {
  final int status;
  final String message;
  final List<IncomingOrder> data;

  IncomingOrderResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory IncomingOrderResponse.fromJson(Map<String, dynamic> json) {
    return IncomingOrderResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => IncomingOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class IncomingOrder {
  final int orderId;
  final DriverLocation driver;
  final CustomerInfo customer;
  final String orderType;
  final double deliveryTip;
  final double totalOrderValue;
  final double totalRouteDistanceKm;
  final double multiOrderBonus;
  final List<SellerVisit> sellersVisitOrder;
  final double deliveryCharge;
  final String? otp;
  final List<OrderItem> items;
  final String? prepTime;
  final String? sellerPhoneNumber;
  final String? paymentMethod;

  IncomingOrder({
    required this.orderId,
    required this.driver,
    required this.customer,
    required this.orderType,
    required this.deliveryTip,
    required this.totalOrderValue,
    required this.totalRouteDistanceKm,
    required this.multiOrderBonus,
    required this.sellersVisitOrder,
    required this.deliveryCharge,
    this.otp,
    this.items = const [],
    this.prepTime,
    this.sellerPhoneNumber,
    this.paymentMethod,
  });

  factory IncomingOrder.fromJson(Map<String, dynamic> json) {
    final orderId = SafeParser.parseInt(json['order_id']);
    final deliveryCharge = SafeParser.parseDouble(json['delivery_charge']);
    final deliveryTip = SafeParser.parseDouble(json['delivery_tip']);
    final multiOrderBonus = SafeParser.parseDouble(json['multi_order_bonus']);

    // Debug: Log earnings breakdown
    debugPrint('💰 Order #$orderId - delivery_charge: $deliveryCharge, tip: $deliveryTip, bonus: $multiOrderBonus');

    // Debug: Log sellers_visit_order structure
    final sellersData = SafeParser.parseList<Map<String, dynamic>>(json['sellers_visit_order']);
    debugPrint('📦 Order #$orderId has ${sellersData.length} seller(s)');
    for (int i = 0; i < sellersData.length; i++) {
      final seller = sellersData[i];
      debugPrint('  Seller $i: store_name=${seller['store_name']}, seller_id=${seller['seller_id']}, store_id=${seller['store_id']}');
      debugPrint('    All keys: ${seller.keys.toList()}');
    }

    return IncomingOrder(
      orderId: orderId,
      driver: DriverLocation.fromJson(SafeParser.parseMap(json['driver'])),
      customer: CustomerInfo.fromJson(SafeParser.parseMap(json['customer'])),
      orderType: SafeParser.parseString(json['order_type']),
      deliveryTip: deliveryTip,
      totalOrderValue: SafeParser.parseDouble(json['total_order_value']),
      totalRouteDistanceKm: SafeParser.parseDouble(json['total_route_distance_km']),
      multiOrderBonus: multiOrderBonus,
      sellersVisitOrder: sellersData
              .map((e) => SellerVisit.fromJson(e))
              .toList(),
      deliveryCharge: deliveryCharge,
      otp: SafeParser.parseStringNullable(json['otp']),
      items: SafeParser.parseList<Map<String, dynamic>>(json['items'])
              .map((e) => OrderItem.fromJson(e))
              .toList(),
      prepTime: SafeParser.parseStringNullable(json['prep_time']),
      sellerPhoneNumber: SafeParser.parseStringNullable(SafeParser.parseMap(json['seller'])['phone_number']),
      paymentMethod: SafeParser.parseStringNullable(json['payment_method']),
    );
  }

  /// Calculate total earnings for this order
  double get totalEarnings =>
      deliveryCharge + deliveryTip + multiOrderBonus;

  /// Check if this is a multi-order
  bool get isMultiOrder => sellersVisitOrder.length > 1;

  /// Whether this order includes a Zenfoo store pickup (store_id 12).
  /// Zenfoo-store orders are prioritized first when orders are offered to a driver.
  bool get hasZenfooStore =>
      sellersVisitOrder.any((s) => s.isZenfooStore || s.storeId == 12);

  /// Get first seller (pickup location)
  SellerVisit? get pickupLocation =>
      sellersVisitOrder.isNotEmpty ? sellersVisitOrder.first : null;
}

class DriverLocation {
  final double latitude;
  final double longitude;

  DriverLocation({
    required this.latitude,
    required this.longitude,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
}

class CustomerInfo {
  final int? id;
  final String name;
  final String mobile;
  final String address;
  final String latitude;
  final String longitude;

  CustomerInfo({
    this.id,
    required this.name,
    required this.mobile,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] ?? '0',
      longitude: json['longitude'] ?? '0',
    );
  }

  double get lat => double.tryParse(latitude) ?? 0.0;
  double get lng => double.tryParse(longitude) ?? 0.0;

  /// Name to show the driver. Older orders (and accounts with no profile name)
  /// come through with an empty name, which rendered as a blank card.
  String get displayName => name.trim().isEmpty ? 'Customer' : name.trim();
}

class SellerVisit {
  final int? sellerId;
  final int? storeId;
  final String storeName;
  final String sellerAddress;
  final double latitude;
  final double longitude;
  final double distanceFromPreviousKm;
  final bool isZenfooStore;
  final String? sellerPhoneNumber;

  /// True for the handoff stop added by an emergency driver change - the point
  /// where this driver collects already-picked items from the previous driver.
  final bool isHandoffPoint;

  SellerVisit({
    this.sellerId,
    this.storeId,
    required this.storeName,
    required this.sellerAddress,
    required this.latitude,
    required this.longitude,
    required this.distanceFromPreviousKm,
    this.isZenfooStore = false,
    this.sellerPhoneNumber,
    this.isHandoffPoint = false,
  });

  factory SellerVisit.fromJson(Map<String, dynamic> json) {
    final parsedSellerId = json['seller_id'] != null ? int.tryParse(json['seller_id'].toString()) : null;
    final parsedStoreId = json['store_id'] != null ? int.tryParse(json['store_id'].toString()) : null;

    // Debug: Log what we're parsing
    debugPrint('🏪 SellerVisit.fromJson()');
    debugPrint('  • all keys: ${json.keys.toList()}');
    debugPrint('  • storeName: ${json['store_name']}');
    debugPrint('  • seller_id raw: ${json['seller_id']} (type: ${json['seller_id'].runtimeType})');
    debugPrint('  • seller_id parsed: $parsedSellerId');
    debugPrint('  • storeId raw: ${json['store_id']} (type: ${json['store_id'].runtimeType})');
    debugPrint('  • storeId parsed: $parsedStoreId');
    debugPrint('  • seller_phone_number raw: ${json['seller_phone_number']}');
    debugPrint('  • seller_address: ${json['seller_address']}');
    debugPrint('  • is_zenfoo_store: ${json['is_zenfoo_store']}');

    // Coordinates must go through SafeParser: the handoff stop written by an
    // emergency driver change sends them as Strings, and a raw .toDouble() on a
    // String throws, which would drop the whole order silently.
    return SellerVisit(
      sellerId: parsedSellerId,
      storeId: parsedStoreId,
      // The handoff stop carries its label in seller_name, not store_name.
      storeName: SafeParser.parseString(
          json['store_name'] ?? json['seller_name']),
      sellerAddress: SafeParser.parseString(json['seller_address']),
      latitude: SafeParser.parseDouble(json['latitude']),
      longitude: SafeParser.parseDouble(json['longitude']),
      distanceFromPreviousKm:
          SafeParser.parseDouble(json['distance_from_previous_km']),
      isZenfooStore: SafeParser.parseBool(json['is_zenfoo_store']),
      sellerPhoneNumber: SafeParser.parseStringNullable(json['seller_phone_number']),
      isHandoffPoint: SafeParser.parseBool(json['is_handoff_point']),
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
