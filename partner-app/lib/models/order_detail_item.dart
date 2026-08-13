class OrderDetailItem {
  final String id;
  final String status;
  final String statusColor;
  final List<OrderProduct> products;
  final String totalAmount;

  OrderDetailItem({
    required this.id,
    required this.status,
    required this.statusColor,
    required this.products,
    required this.totalAmount,
  });

  factory OrderDetailItem.fromJson(Map<String, dynamic> json) {
    return OrderDetailItem(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusColor: json['status_color']?.toString() ?? 'gray',
      products: json['products'] != null
          ? (json['products'] as List)
              .map((e) => OrderProduct.fromJson(e))
              .toList()
          : [],
      totalAmount: json['total_amount']?.toString() ?? '0.00',
    );
  }
}

class OrderProduct {
  final String name;
  final String quantity;
  final String weight;
  final String price;
  final String? earnedAmount;

  OrderProduct({
    required this.name,
    required this.quantity,
    required this.weight,
    required this.price,
    this.earnedAmount,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      name: json['name']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '',
      weight: json['weight']?.toString() ?? '',
      price: json['price']?.toString() ?? '0.00',
      earnedAmount: json['earned_amount']?.toString(),
    );
  }
}
