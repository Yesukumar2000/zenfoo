class InvoiceModel {
  final int status;
  final String message;
  final InvoiceData? invoice;

  InvoiceModel({
    required this.status,
    required this.message,
    this.invoice,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      invoice: json['invoice'] != null
          ? InvoiceData.fromJson(json['invoice'])
          : null,
    );
  }
}

class InvoiceData {
  final StoreInfo store;
  final OrderInfo orderInfo;
  final CustomerInfo customer;
  final List<InvoiceItem> items;
  final PricingInfo pricing;
  final NotesInfo notes;
  final FooterInfo footer;

  InvoiceData({
    required this.store,
    required this.orderInfo,
    required this.customer,
    required this.items,
    required this.pricing,
    required this.notes,
    required this.footer,
  });

  factory InvoiceData.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((item) => InvoiceItem.fromJson(item))
            .toList() ??
        [];
    return InvoiceData(
      store: StoreInfo.fromJson(json['store'] ?? {}),
      orderInfo: OrderInfo.fromJson(json['order_info'] ?? {}),
      customer: CustomerInfo.fromJson(json['customer'] ?? {}),
      items: items,
      pricing: PricingInfo.fromJson(json['pricing'] ?? {}, items: items),
      notes: NotesInfo.fromJson(json['notes'] ?? {}),
      footer: FooterInfo.fromJson(json['footer'] ?? {}),
    );
  }
}

class StoreInfo {
  final String storeName;
  final String sellerName;
  final String sellerMobile;
  final String sellerEmail;
  final String address;
  final String panNumber;
  final String appName;

  StoreInfo({
    required this.storeName,
    required this.sellerName,
    required this.sellerMobile,
    required this.sellerEmail,
    required this.address,
    required this.panNumber,
    required this.appName,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      storeName: json['store_name'] ?? '',
      sellerName: json['seller_name'] ?? '',
      sellerMobile: json['seller_mobile'] ?? '',
      sellerEmail: json['seller_email'] ?? '',
      address: json['address'] ?? '',
      panNumber: json['pan_number'] ?? '',
      appName: json['app_name'] ?? '',
    );
  }
}

class OrderInfo {
  final int orderId;
  final String orderNumber;
  final String orderDate;
  final String orderType;
  final String orderStatus;
  final String paymentMethod;

  OrderInfo({
    required this.orderId,
    required this.orderNumber,
    required this.orderDate,
    required this.orderType,
    required this.orderStatus,
    required this.paymentMethod,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      orderId: json['order_id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      orderDate: json['order_date'] ?? '',
      orderType: json['order_type'] ?? '',
      orderStatus: json['order_status'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
    );
  }
}

class CustomerInfo {
  final String name;
  final String mobile;
  final String email;
  final String address;

  CustomerInfo({
    required this.name,
    required this.mobile,
    required this.email,
    required this.address,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class InvoiceItem {
  final String productName;
  final String variantName;
  final int quantity;
  final double price;
  final double discountedPrice;
  final double taxAmount;
  final double taxPercentage;
  final double subTotal;
  final String itemType;

  InvoiceItem({
    required this.productName,
    required this.variantName,
    required this.quantity,
    required this.price,
    required this.discountedPrice,
    required this.taxAmount,
    required this.taxPercentage,
    required this.subTotal,
    required this.itemType,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      productName: json['product_name'] ?? '',
      variantName: json['variant_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      discountedPrice: (json['discounted_price'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      taxPercentage: (json['tax_percentage'] ?? 0).toDouble(),
      subTotal: (json['sub_total'] ?? 0).toDouble(),
      itemType: json['item_type'] ?? 'regular',
    );
  }
}

class PricingLineItem {
  final String label;
  final dynamic value;

  PricingLineItem({required this.label, required this.value});

  factory PricingLineItem.fromJson(Map<String, dynamic> json) {
    return PricingLineItem(
      label: json['label'] ?? '',
      value: json['value'],
    );
  }
}

class PricingInfo {
  final List<PricingLineItem> lineItems;

  PricingInfo({required this.lineItems});

  factory PricingInfo.fromJson(dynamic json, {List<InvoiceItem>? items}) {
    if (json is List) {
      return PricingInfo(
        lineItems:
            json.map((e) => PricingLineItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    // Fallback: compute total from items
    double total = 0;
    if (items != null) {
      for (final item in items) {
        total += item.subTotal;
      }
    }
    return PricingInfo(lineItems: [
      PricingLineItem(label: 'Total', value: total),
    ]);
  }
}

class NotesInfo {
  final String orderNote;
  final String deliveryTime;

  NotesInfo({
    required this.orderNote,
    required this.deliveryTime,
  });

  factory NotesInfo.fromJson(Map<String, dynamic> json) {
    return NotesInfo(
      orderNote: json['order_note'] ?? '',
      deliveryTime: json['delivery_time'] ?? '',
    );
  }
}

class FooterInfo {
  final String message;
  final String tagline;

  FooterInfo({
    required this.message,
    required this.tagline,
  });

  factory FooterInfo.fromJson(Map<String, dynamic> json) {
    return FooterInfo(
      message: json['message'] ?? '',
      tagline: json['tagline'] ?? '',
    );
  }
}
