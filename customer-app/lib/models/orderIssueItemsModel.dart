class OrderIssueItemsModel {
  final int orderId;
  final List<StoreWiseItems> storeWiseItems;
  final List<ComboItem> comboItems;

  OrderIssueItemsModel({
    required this.orderId,
    required this.storeWiseItems,
    required this.comboItems,
  });

  factory OrderIssueItemsModel.fromJson(Map<String, dynamic> json) {
    return OrderIssueItemsModel(
      orderId: _parseInt(json['order_id']),
      storeWiseItems: _parseList<StoreWiseItems>(
        json['store_wise_items'],
        (item) => StoreWiseItems.fromJson(item as Map<String, dynamic>),
      ),
      comboItems: _parseList<ComboItem>(
        json['combo_items'],
        (item) => ComboItem.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static List<T> _parseList<T>(dynamic value, T Function(dynamic) mapper) {
    if (value == null) return [];
    if (value is! List) return [];
    try {
      return value.map(mapper).toList();
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'store_wise_items': storeWiseItems.map((item) => item.toJson()).toList(),
      'combo_items': comboItems.map((item) => item.toJson()).toList(),
    };
  }
}

class StoreWiseItems {
  final int storeId;
  final String storeName;
  final List<OrderProduct> items;

  StoreWiseItems({
    required this.storeId,
    required this.storeName,
    required this.items,
  });

  factory StoreWiseItems.fromJson(Map<String, dynamic> json) {
    return StoreWiseItems(
      storeId: OrderIssueItemsModel._parseInt(json['store_id']),
      storeName: json['store_name']?.toString() ?? '',
      items: OrderIssueItemsModel._parseList<OrderProduct>(
        json['items'],
        (item) => OrderProduct.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'store_name': storeName,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class OrderProduct {
  final int productId;
  final String productName;
  final String variantMeasurement;
  final double price;
  final double actualPrice;
  final int quantity;
  final double subTotal;
  final bool isReturnable;
  final int returnDays;
  final int remainingReturnDays;
  final bool isStillReturnAvailable;

  OrderProduct({
    required this.productId,
    required this.productName,
    required this.variantMeasurement,
    required this.price,
    required this.actualPrice,
    required this.quantity,
    required this.subTotal,
    this.isReturnable = false,
    this.returnDays = 0,
    this.remainingReturnDays = 0,
    this.isStillReturnAvailable = false,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      productId: OrderIssueItemsModel._parseInt(json['product_id']),
      productName: json['product_name']?.toString() ?? '',
      variantMeasurement: json['variant_measurement']?.toString() ?? '',
      price: _parseDouble(json['price']),
      actualPrice: _parseDouble(json['actual_price']),
      quantity: OrderIssueItemsModel._parseInt(json['quantity']),
      subTotal: _parseDouble(json['sub_total']),
      isReturnable: json['is_returnable'] == true || json['is_returnable'] == 1,
      returnDays: OrderIssueItemsModel._parseInt(json['return_days']),
      remainingReturnDays: OrderIssueItemsModel._parseInt(json['remaining_return_days']),
      isStillReturnAvailable: json['is_still_return_available'] == true || json['is_still_return_available'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'variant_measurement': variantMeasurement,
      'price': price,
      'actual_price': actualPrice,
      'quantity': quantity,
      'sub_total': subTotal,
      'is_returnable': isReturnable,
      'return_days': returnDays,
      'remaining_return_days': remainingReturnDays,
      'is_still_return_available': isStillReturnAvailable,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class ComboItem {
  final int id;
  final String comboName;
  final int comboQuantity;
  final double subTotal;
  final double discountPercentage;
  final double totalActualPrice;
  final double totalProductsPrice;
  final List<OrderProduct> products;

  ComboItem({
    required this.id,
    required this.comboName,
    required this.comboQuantity,
    required this.subTotal,
    required this.discountPercentage,
    required this.totalActualPrice,
    required this.totalProductsPrice,
    required this.products,
  });

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    return ComboItem(
      id: OrderIssueItemsModel._parseInt(json['id']),
      comboName: json['combo_name']?.toString() ?? '',
      comboQuantity: OrderIssueItemsModel._parseInt(json['combo_quantity']),
      subTotal: OrderProduct._parseDouble(json['sub_total']),
      discountPercentage: OrderProduct._parseDouble(json['discount_percentage']),
      totalActualPrice: OrderProduct._parseDouble(json['total_actual_price']),
      totalProductsPrice: OrderProduct._parseDouble(json['total_products_price']),
      products: OrderIssueItemsModel._parseList<OrderProduct>(
        json['products'],
        (item) => OrderProduct.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'combo_name': comboName,
      'combo_quantity': comboQuantity,
      'sub_total': subTotal,
      'discount_percentage': discountPercentage,
      'total_actual_price': totalActualPrice,
      'total_products_price': totalProductsPrice,
      'products': products.map((item) => item.toJson()).toList(),
    };
  }
}
