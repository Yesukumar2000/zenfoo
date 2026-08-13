import 'dart:developer' as dev;

import 'package:zenfoo_partner/utils/safe_parser.dart';

class MultiOrderEarningsResponse {
  final String period;
  final String periodName;
  final String? startDate;
  final String? endDate;
  final MultiOrderSummary summary;
  final List<MultiOrderItem> orders;

  MultiOrderEarningsResponse({
    required this.period,
    required this.periodName,
    this.startDate,
    this.endDate,
    required this.summary,
    required this.orders,
  });

  factory MultiOrderEarningsResponse.fromJson(Map<String, dynamic> json) {
    dev.log('🔵 Parsing MultiOrderEarningsResponse',
        name: 'MultiOrderEarningsModel');

    final data = SafeParser.parseMap(json['data']);

    return MultiOrderEarningsResponse(
      period: SafeParser.parseString(data['period']),
      periodName: SafeParser.parseString(data['period_name']),
      startDate: SafeParser.parseStringNullable(data['start_date']),
      endDate: SafeParser.parseStringNullable(data['end_date']),
      summary: MultiOrderSummary.fromJson(SafeParser.parseMap(data['summary'])),
      orders: SafeParser.parseList<dynamic>(data['orders'])
          .map((item) => MultiOrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'period_name': periodName,
      'start_date': startDate,
      'end_date': endDate,
      'summary': summary.toJson(),
      'orders': orders.map((item) => item.toJson()).toList(),
    };
  }
}

class MultiOrderSummary {
  final int totalMultiOrderBonus;
  final int totalOrdersWithBonus;
  final int averageBonusPerOrder;
  final int maxBonus;
  final int minBonus;

  MultiOrderSummary({
    required this.totalMultiOrderBonus,
    required this.totalOrdersWithBonus,
    required this.averageBonusPerOrder,
    required this.maxBonus,
    required this.minBonus,
  });

  factory MultiOrderSummary.fromJson(Map<String, dynamic> json) {
    return MultiOrderSummary(
      totalMultiOrderBonus: SafeParser.parseInt(json['total_multi_order_bonus']),
      totalOrdersWithBonus: SafeParser.parseInt(json['total_orders_with_bonus']),
      averageBonusPerOrder: SafeParser.parseInt(json['average_bonus_per_order']),
      maxBonus: SafeParser.parseInt(json['max_bonus']),
      minBonus: SafeParser.parseInt(json['min_bonus']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_multi_order_bonus': totalMultiOrderBonus,
      'total_orders_with_bonus': totalOrdersWithBonus,
      'average_bonus_per_order': averageBonusPerOrder,
      'max_bonus': maxBonus,
      'min_bonus': minBonus,
    };
  }
}

class MultiOrderItem {
  final int orderId;
  final String? orderNumber;
  final String orderDate;
  final String? customerName;
  final List<String> storeNames;
  final List<int> storeSellers;
  final String? deliveryAddress;
  final int bonusAmount;
  final String orderStatus;

  MultiOrderItem({
    required this.orderId,
    this.orderNumber,
    required this.orderDate,
    this.customerName,
    required this.storeNames,
    required this.storeSellers,
    this.deliveryAddress,
    required this.bonusAmount,
    required this.orderStatus,
  });

  factory MultiOrderItem.fromJson(Map<String, dynamic> json) {
    return MultiOrderItem(
      orderId: SafeParser.parseInt(json['order_id']),
      orderNumber: SafeParser.parseStringNullable(json['order_number']),
      orderDate: SafeParser.parseString(json['order_date']),
      customerName: SafeParser.parseStringNullable(json['customer_name']),
      storeNames: SafeParser.parseList<dynamic>(json['store_names'])
          .map((e) => e.toString())
          .toList(),
      storeSellers: SafeParser.parseList<dynamic>(json['store_sellers'])
          .map((e) => SafeParser.parseInt(e))
          .toList(),
      deliveryAddress: SafeParser.parseStringNullable(json['delivery_address']),
      bonusAmount: SafeParser.parseInt(json['bonus_amount']),
      orderStatus: SafeParser.parseString(json['order_status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'order_number': orderNumber,
      'order_date': orderDate,
      'customer_name': customerName,
      'store_names': storeNames,
      'store_sellers': storeSellers,
      'delivery_address': deliveryAddress,
      'bonus_amount': bonusAmount,
      'order_status': orderStatus,
    };
  }
}
