import 'dart:convert';

OrderHistoryModel orderHistoryModelFromJson(String str) =>
    OrderHistoryModel.fromJson(json.decode(str));

String orderHistoryModelToJson(OrderHistoryModel data) =>
    json.encode(data.toJson());

class OrderHistoryModel {
  final int? status;
  final String? message;
  final Data? data;

  OrderHistoryModel({
    this.status,
    this.message,
    this.data,
  });

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) =>
      OrderHistoryModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data?.toJson(),
      };
}

class Data {
  final List<OrdersByDate>? ordersByDate;
  final Pagination? pagination;

  Data({
    this.ordersByDate,
    this.pagination,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        ordersByDate: json["orders_by_date"] == null
            ? []
            : List<OrdersByDate>.from(
                json["orders_by_date"]!.map((x) => OrdersByDate.fromJson(x))),
        pagination: json["pagination"] == null
            ? null
            : Pagination.fromJson(json["pagination"]),
      );

  Map<String, dynamic> toJson() => {
        "orders_by_date": ordersByDate == null
            ? []
            : List<dynamic>.from(ordersByDate!.map((x) => x.toJson())),
        "pagination": pagination?.toJson(),
      };
}

class OrdersByDate {
  final String? date;
  final String? dateHeader;
  final List<Order>? orders;
  final int? orderCount;

  OrdersByDate({
    this.date,
    this.dateHeader,
    this.orders,
    this.orderCount,
  });

  factory OrdersByDate.fromJson(Map<String, dynamic> json) => OrdersByDate(
        date: json["date"],
        dateHeader: json["date_header"],
        orders: json["orders"] == null
            ? []
            : List<Order>.from(json["orders"]!.map((x) => Order.fromJson(x))),
        orderCount: json["order_count"],
      );

  Map<String, dynamic> toJson() => {
        "date": date,
        "date_header": dateHeader,
        "orders": orders == null
            ? []
            : List<dynamic>.from(orders!.map((x) => x.toJson())),
        "order_count": orderCount,
      };
}

class Order {
  final int? orderId;
  final int? itemCount;
  final List<Item>? items;
  final String? deliveryTime;
  final num? totalAmountPaid;
  final num? deliveryCharges;
  final bool? isRainSurcharge;
  final num? rainSurchargeAmount;
  final num? rainSurcharge;
  final num? tip;
  final num? multiOrderBonus;

  Order({
    this.orderId,
    this.itemCount,
    this.items,
    this.deliveryTime,
    this.totalAmountPaid,
    this.deliveryCharges,
    this.isRainSurcharge,
    this.rainSurchargeAmount,
    this.rainSurcharge,
    this.tip,
    this.multiOrderBonus,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderId: json["order_id"],
        itemCount: json["item_count"],
        items: json["items"] == null
            ? []
            : List<Item>.from(json["items"]!.map((x) => Item.fromJson(x))),
        deliveryTime: json["delivery_time"],
        totalAmountPaid: json["total_amount_paid"],
        deliveryCharges: json["delivery_charges"],
        isRainSurcharge: json["is_rain_surcharge"],
        rainSurchargeAmount: json["rain_surcharge_amount"],
        rainSurcharge: json["rain_surcharge"],
        tip: json["tip"],
        multiOrderBonus: json["multi_order_bonus"],
      );

  Map<String, dynamic> toJson() => {
        "order_id": orderId,
        "item_count": itemCount,
        "items": items == null
            ? []
            : List<dynamic>.from(items!.map((x) => x.toJson())),
        "delivery_time": deliveryTime,
        "total_amount_paid": totalAmountPaid,
        "delivery_charges": deliveryCharges,
        "is_rain_surcharge": isRainSurcharge,
        "rain_surcharge_amount": rainSurchargeAmount,
        "rain_surcharge": rainSurcharge,
        "tip": tip,
        "multi_order_bonus": multiOrderBonus,
      };
}

class Item {
  final String? itemName;
  final num? quantity;
  final String? measurement;

  Item({
    this.itemName,
    this.quantity,
    this.measurement,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        itemName: json["item_name"],
        quantity: json["quantity"],
        measurement: json["measurement"],
      );

  Map<String, dynamic> toJson() => {
        "item_name": itemName,
        "quantity": quantity,
        "measurement": measurement,
      };
}

class Pagination {
  final int? currentPage;
  final int? perPage;
  final bool? hasMore;
  final int? totalPages;

  Pagination({
    this.currentPage,
    this.perPage,
    this.hasMore,
    this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        currentPage: json["current_page"],
        perPage: json["per_page"],
        hasMore: json["has_more"],
        totalPages: json["total_pages"],
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "per_page": perPage,
        "has_more": hasMore,
        "total_pages": totalPages,
      };
}
