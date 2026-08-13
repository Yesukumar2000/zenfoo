import 'package:zenfoo_partner/utils/safe_parser.dart';

class OrderSummaryResponse {
  final int status;
  final String message;
  final OrderSummary data;

  OrderSummaryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory OrderSummaryResponse.fromJson(Map<String, dynamic> json) {
    return OrderSummaryResponse(
      status: SafeParser.parseInt(json['status']),
      message: SafeParser.parseString(json['message']),
      data: OrderSummary.fromJson(SafeParser.parseMap(json['data'])),
    );
  }
}

class OrderSummary {
  final int orderId;
  final String orderType;
  final String paymentMode;
  final int totalPrice;
  final int itemCount;
  final List<SummaryItem> items;
  final CustomerDetails customer;
  final String? customerPin;

  OrderSummary({
    required this.orderId,
    required this.orderType,
    required this.paymentMode,
    required this.totalPrice,
    required this.itemCount,
    required this.items,
    required this.customer,
    this.customerPin,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      orderId: SafeParser.parseInt(json['order_id']),
      orderType: SafeParser.parseString(json['order_type']),
      paymentMode: SafeParser.parseString(json['payment_mode']),
      totalPrice: SafeParser.parseInt(json['total_price']),
      itemCount: SafeParser.parseInt(json['item_count']),
      items: SafeParser.parseList<Map<String, dynamic>>(json['items'])
          .map((e) => SummaryItem.fromJson(e))
          .toList(),
      customer: CustomerDetails.fromJson(SafeParser.parseMap(json['customer'])),
      customerPin: SafeParser.parseStringNullable(json['customer_pin']),
    );
  }
}

class SummaryItem {
  final String itemName;
  final int quantity;
  final String measurement;

  SummaryItem({
    required this.itemName,
    required this.quantity,
    required this.measurement,
  });

  factory SummaryItem.fromJson(Map<String, dynamic> json) {
    return SummaryItem(
      itemName: SafeParser.parseString(json['item_name']),
      quantity: SafeParser.parseInt(json['quantity']),
      measurement: SafeParser.parseString(json['measurement']),
    );
  }
}

class CustomerDetails {
  final int id;
  final String name;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;

  CustomerDetails({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      id: SafeParser.parseInt(json['id']),
      name: SafeParser.parseString(json['name']),
      phone: SafeParser.parseString(json['phone']),
      address: SafeParser.parseString(json['address']),
      latitude: SafeParser.parseDouble(json['latitude']),
      longitude: SafeParser.parseDouble(json['longitude']),
    );
  }
}
