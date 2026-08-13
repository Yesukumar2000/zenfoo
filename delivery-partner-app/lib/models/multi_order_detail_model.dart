import 'package:zenfoo_partner/utils/safe_parser.dart';

class MultiOrderDetailResponse {
  final int orderId;
  final String ordersId;
  final String orderDate;
  final String? deliveredAt;
  final String activeStatus;
  final String paymentMethod;
  final String orderType;
  final MultiOrderCustomer customer;
  final List<String> storeNames;
  final List<int> storeSellers;
  final MultiOrderDriverStart driverStart;
  final double totalDistanceKm;
  final String totalTime;
  final MultiOrderRoute route;
  final MultiOrderEarningsDetail earnings;
  final bool isRainSurcharge;
  final double rainSurchargeAmount;

  MultiOrderDetailResponse({
    required this.orderId,
    required this.ordersId,
    required this.orderDate,
    this.deliveredAt,
    required this.activeStatus,
    required this.paymentMethod,
    required this.orderType,
    required this.customer,
    required this.storeNames,
    required this.storeSellers,
    required this.driverStart,
    required this.totalDistanceKm,
    required this.totalTime,
    required this.route,
    required this.earnings,
    required this.isRainSurcharge,
    required this.rainSurchargeAmount,
  });

  factory MultiOrderDetailResponse.fromJson(Map<String, dynamic> json) {
    return MultiOrderDetailResponse(
      orderId: SafeParser.parseInt(json['order_id']),
      ordersId: SafeParser.parseString(json['orders_id']),
      orderDate: SafeParser.parseString(json['order_date']),
      deliveredAt: SafeParser.parseStringNullable(json['delivered_at']),
      activeStatus: SafeParser.parseString(json['active_status']),
      paymentMethod: SafeParser.parseString(json['payment_method']),
      orderType: SafeParser.parseString(json['order_type']),
      customer: MultiOrderCustomer.fromJson(
          SafeParser.parseMap(json['customer'])),
      storeNames: SafeParser.parseList<dynamic>(json['store_names'])
          .map((e) => e.toString())
          .toList(),
      storeSellers: SafeParser.parseList<dynamic>(json['store_sellers'])
          .map((e) => SafeParser.parseInt(e))
          .toList(),
      driverStart: MultiOrderDriverStart.fromJson(
          SafeParser.parseMap(json['driver_start'])),
      totalDistanceKm: SafeParser.parseDouble(json['total_distance_km']),
      totalTime: SafeParser.parseString(json['total_time']),
      route: MultiOrderRoute.fromJson(SafeParser.parseMap(json['route'])),
      earnings: MultiOrderEarningsDetail.fromJson(
          SafeParser.parseMap(json['earnings'])),
      isRainSurcharge: SafeParser.parseBool(json['is_rain_surcharge']),
      rainSurchargeAmount:
          SafeParser.parseDouble(json['rain_surcharge_amount']),
    );
  }
}

class MultiOrderCustomer {
  final int? id;
  final String name;
  final String? mobile;
  final String? deliveryAddress;
  final double? latitude;
  final double? longitude;

  MultiOrderCustomer({
    this.id,
    required this.name,
    this.mobile,
    this.deliveryAddress,
    this.latitude,
    this.longitude,
  });

  factory MultiOrderCustomer.fromJson(Map<String, dynamic> json) {
    return MultiOrderCustomer(
      id: SafeParser.parseIntNullable(json['id']),
      name: SafeParser.parseString(json['name']),
      mobile: SafeParser.parseStringNullable(json['mobile']),
      deliveryAddress: SafeParser.parseStringNullable(json['delivery_address']),
      latitude: SafeParser.parseDoubleNullable(json['latitude']),
      longitude: SafeParser.parseDoubleNullable(json['longitude']),
    );
  }
}

class MultiOrderDriverStart {
  final double? latitude;
  final double? longitude;
  final String? acceptedAt;

  MultiOrderDriverStart({
    this.latitude,
    this.longitude,
    this.acceptedAt,
  });

  factory MultiOrderDriverStart.fromJson(Map<String, dynamic> json) {
    return MultiOrderDriverStart(
      latitude: SafeParser.parseDoubleNullable(json['latitude']),
      longitude: SafeParser.parseDoubleNullable(json['longitude']),
      acceptedAt: SafeParser.parseStringNullable(json['accepted_at']),
    );
  }
}

class MultiOrderRoute {
  final int totalStops;
  final double totalRouteDistanceKm;
  final List<MultiOrderRouteLeg> legs;

  MultiOrderRoute({
    required this.totalStops,
    required this.totalRouteDistanceKm,
    required this.legs,
  });

  factory MultiOrderRoute.fromJson(Map<String, dynamic> json) {
    return MultiOrderRoute(
      totalStops: SafeParser.parseInt(json['total_stops']),
      totalRouteDistanceKm:
          SafeParser.parseDouble(json['total_route_distance_km']),
      legs: SafeParser.parseList<dynamic>(json['legs'])
          .map((e) => MultiOrderRouteLeg.fromJson(
              SafeParser.parseMap(e as Map<String, dynamic>)))
          .toList(),
    );
  }
}

class MultiOrderRouteLeg {
  final int? trackingId;
  final int? sellerId;
  final int? storeId;
  final bool isZenfooStore;
  final String? storeName;
  final String? sellerAddress;
  final String? sellerMobile;
  final String? customerName;
  final String? deliveryAddress;
  final double? latitude;
  final double? longitude;
  final String? status;
  final String? driverArrivedAt;
  final int leg;
  final String legType;
  final double distanceFromPreviousKm;
  final String timeTaken;

  MultiOrderRouteLeg({
    this.trackingId,
    this.sellerId,
    this.storeId,
    required this.isZenfooStore,
    this.storeName,
    this.sellerAddress,
    this.sellerMobile,
    this.customerName,
    this.deliveryAddress,
    this.latitude,
    this.longitude,
    this.status,
    this.driverArrivedAt,
    required this.leg,
    required this.legType,
    required this.distanceFromPreviousKm,
    required this.timeTaken,
  });

  factory MultiOrderRouteLeg.fromJson(Map<String, dynamic> json) {
    return MultiOrderRouteLeg(
      trackingId: SafeParser.parseIntNullable(json['tracking_id']),
      sellerId: SafeParser.parseIntNullable(json['seller_id']),
      storeId: SafeParser.parseIntNullable(json['store_id']),
      isZenfooStore: SafeParser.parseBool(json['is_zenfoo_store']),
      storeName: SafeParser.parseStringNullable(json['store_name']),
      sellerAddress: SafeParser.parseStringNullable(json['seller_address']),
      sellerMobile: SafeParser.parseStringNullable(json['seller_mobile']),
      customerName: SafeParser.parseStringNullable(json['customer_name']),
      deliveryAddress: SafeParser.parseStringNullable(json['delivery_address']),
      latitude: SafeParser.parseDoubleNullable(json['latitude']),
      longitude: SafeParser.parseDoubleNullable(json['longitude']),
      status: SafeParser.parseStringNullable(json['status']),
      driverArrivedAt: SafeParser.parseStringNullable(json['driver_arrived_at']),
      leg: SafeParser.parseInt(json['leg']),
      legType: SafeParser.parseString(json['leg_type']),
      distanceFromPreviousKm:
          SafeParser.parseDouble(json['distance_from_previous_km']),
      timeTaken: SafeParser.parseString(json['time_taken']),
    );
  }
}

class MultiOrderEarningsDetail {
  final double deliveryCharge;
  final double deliveryTip;
  final double multiOrderBonus;
  final double rainSurcharge;
  final double returnCharge;
  final double vendorWaitCharge;
  final double driverEarnings;
  final double adminCash;
  final double totalOrderValue;

  MultiOrderEarningsDetail({
    required this.deliveryCharge,
    required this.deliveryTip,
    required this.multiOrderBonus,
    required this.rainSurcharge,
    required this.returnCharge,
    this.vendorWaitCharge = 0.0,
    required this.driverEarnings,
    required this.adminCash,
    required this.totalOrderValue,
  });

  factory MultiOrderEarningsDetail.fromJson(Map<String, dynamic> json) {
    return MultiOrderEarningsDetail(
      deliveryCharge: SafeParser.parseDouble(json['delivery_charge']),
      deliveryTip: SafeParser.parseDouble(json['delivery_tip']),
      multiOrderBonus: SafeParser.parseDouble(json['multi_order_bonus']),
      rainSurcharge: SafeParser.parseDouble(json['rain_surcharge']),
      returnCharge: SafeParser.parseDouble(json['return_charge']),
      vendorWaitCharge: SafeParser.parseDouble(json['vendor_wait_charge']),
      driverEarnings: SafeParser.parseDouble(json['driver_earnings']),
      adminCash: SafeParser.parseDouble(json['admin_cash']),
      totalOrderValue: SafeParser.parseDouble(json['total_order_value']),
    );
  }
}
