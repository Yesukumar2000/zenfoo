import 'package:zenfoo_partner/utils/safe_parser.dart';

class TipsResponse {
  final DeliveryBoyInfo deliveryBoy;
  final WeekSummary weekSummary;
  final List<TipItem> tipsList;
  final NavigationInfo navigation;

  TipsResponse({
    required this.deliveryBoy,
    required this.weekSummary,
    required this.tipsList,
    required this.navigation,
  });

  factory TipsResponse.fromJson(Map<String, dynamic> json) {
    return TipsResponse(
      deliveryBoy: DeliveryBoyInfo.fromJson(
          SafeParser.parseMap(json['delivery_boy'])),
      weekSummary:
          WeekSummary.fromJson(SafeParser.parseMap(json['week_summary'])),
      tipsList: SafeParser.parseList<dynamic>(json['tips_list'])
          .map((item) => TipItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      navigation:
          NavigationInfo.fromJson(SafeParser.parseMap(json['navigation'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'delivery_boy': deliveryBoy.toJson(),
      'week_summary': weekSummary.toJson(),
      'tips_list': tipsList.map((item) => item.toJson()).toList(),
      'navigation': navigation.toJson(),
    };
  }
}

class DeliveryBoyInfo {
  final int id;
  final String name;
  final String? phone;
  final double currentBalance;

  DeliveryBoyInfo({
    required this.id,
    required this.name,
    this.phone,
    required this.currentBalance,
  });

  factory DeliveryBoyInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryBoyInfo(
      id: SafeParser.parseInt(json['id']),
      name: SafeParser.parseString(json['name']),
      phone: SafeParser.parseStringNullable(json['phone']),
      currentBalance: SafeParser.parseDouble(json['current_balance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'current_balance': currentBalance,
    };
  }
}

class WeekSummary {
  final String weekStart;
  final String weekEnd;
  final String weekRange;
  final double totalTips;
  final int totalOrdersWithTips;
  final double averageTipPerOrder;
  final double maxTip;
  final double minTip;
  final int totalOrdersCount;
  final Map<String, dynamic> daysWithTips;

  WeekSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.weekRange,
    required this.totalTips,
    required this.totalOrdersWithTips,
    required this.averageTipPerOrder,
    required this.maxTip,
    required this.minTip,
    required this.totalOrdersCount,
    required this.daysWithTips,
  });

  factory WeekSummary.fromJson(Map<String, dynamic> json) {
    return WeekSummary(
      weekStart: SafeParser.parseString(json['week_start']),
      weekEnd: SafeParser.parseString(json['week_end']),
      weekRange: SafeParser.parseString(json['week_range']),
      totalTips: SafeParser.parseDouble(json['total_tips']),
      totalOrdersWithTips: SafeParser.parseInt(json['total_orders_with_tips']),
      averageTipPerOrder: SafeParser.parseDouble(json['average_tip_per_order']),
      maxTip: SafeParser.parseDouble(json['max_tip']),
      minTip: SafeParser.parseDouble(json['min_tip']),
      totalOrdersCount: SafeParser.parseInt(json['total_orders_count']),
      daysWithTips: SafeParser.parseMap(json['days_with_tips']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week_start': weekStart,
      'week_end': weekEnd,
      'week_range': weekRange,
      'total_tips': totalTips,
      'total_orders_with_tips': totalOrdersWithTips,
      'average_tip_per_order': averageTipPerOrder,
      'max_tip': maxTip,
      'min_tip': minTip,
      'total_orders_count': totalOrdersCount,
      'days_with_tips': daysWithTips,
    };
  }
}

class TipItem {
  final int orderId;
  final double tipAmount;
  final double orderAmount;
  final double deliveryCharge;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final int orderItemsCount;
  final String paymentMethod;
  final String orderStatus;
  final String orderDate;
  final String orderTime;
  final String deliveryTime;
  final String restaurantName;
  final String restaurantAddress;
  final double deliveryDistanceKm;
  final DateTime createdAt;
  final DateTime updatedAt;

  TipItem({
    required this.orderId,
    required this.tipAmount,
    required this.orderAmount,
    required this.deliveryCharge,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.orderItemsCount,
    required this.paymentMethod,
    required this.orderStatus,
    required this.orderDate,
    required this.orderTime,
    required this.deliveryTime,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.deliveryDistanceKm,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TipItem.fromJson(Map<String, dynamic> json) {
    return TipItem(
      orderId: SafeParser.parseInt(json['order_id']),
      tipAmount: SafeParser.parseDouble(json['tip_amount']),
      orderAmount: SafeParser.parseDouble(json['order_amount']),
      deliveryCharge: SafeParser.parseDouble(json['delivery_charge']),
      customerName: SafeParser.parseString(json['customer_name']),
      customerPhone: SafeParser.parseString(json['customer_phone']),
      deliveryAddress: SafeParser.parseString(json['delivery_address']),
      orderItemsCount: SafeParser.parseInt(json['order_items_count']),
      paymentMethod: SafeParser.parseString(json['payment_method']),
      orderStatus: SafeParser.parseString(json['order_status']),
      orderDate: SafeParser.parseString(json['order_date']),
      orderTime: SafeParser.parseString(json['order_time']),
      deliveryTime: SafeParser.parseString(json['delivery_time']),
      restaurantName: SafeParser.parseString(json['restaurant_name']),
      restaurantAddress: SafeParser.parseString(json['restaurant_address']),
      deliveryDistanceKm: SafeParser.parseDouble(json['delivery_distance_km']),
      createdAt: SafeParser.parseDateTime(json['created_at']),
      updatedAt: SafeParser.parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'tip_amount': tipAmount,
      'order_amount': orderAmount,
      'delivery_charge': deliveryCharge,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'order_items_count': orderItemsCount,
      'payment_method': paymentMethod,
      'order_status': orderStatus,
      'order_date': orderDate,
      'order_time': orderTime,
      'delivery_time': deliveryTime,
      'restaurant_name': restaurantName,
      'restaurant_address': restaurantAddress,
      'delivery_distance_km': deliveryDistanceKm,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class NavigationInfo {
  final WeekNavigation current;
  final WeekNavigation previous;
  final WeekNavigation next;

  NavigationInfo({
    required this.current,
    required this.previous,
    required this.next,
  });

  factory NavigationInfo.fromJson(Map<String, dynamic> json) {
    return NavigationInfo(
      current: WeekNavigation.fromJson(SafeParser.parseMap(json['current'])),
      previous:
          WeekNavigation.fromJson(SafeParser.parseMap(json['previous'])),
      next: WeekNavigation.fromJson(SafeParser.parseMap(json['next'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current.toJson(),
      'previous': previous.toJson(),
      'next': next.toJson(),
    };
  }
}

class WeekNavigation {
  final String weekStart;
  final String weekEnd;
  final int offset;

  WeekNavigation({
    required this.weekStart,
    required this.weekEnd,
    required this.offset,
  });

  factory WeekNavigation.fromJson(Map<String, dynamic> json) {
    return WeekNavigation(
      weekStart: SafeParser.parseString(json['week_start']),
      weekEnd: SafeParser.parseString(json['week_end']),
      offset: SafeParser.parseInt(json['offset']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week_start': weekStart,
      'week_end': weekEnd,
      'offset': offset,
    };
  }
}
