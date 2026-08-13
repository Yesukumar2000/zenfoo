class ReorderableOrdersResponse {
  String? status;
  String? message;
  String? total;
  List<ReorderableOrder>? data;

  ReorderableOrdersResponse({this.status, this.message, this.total, this.data});

  ReorderableOrdersResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'].toString();
    message = json['message'].toString();
    total = json['total'].toString();

    if (json['data'] != null) {
      data = <ReorderableOrder>[];
      if (json['data'] is List) {
        json['data'].forEach((v) {
          data!.add(ReorderableOrder.fromJson(v));
        });
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonData = <String, dynamic>{};
    jsonData['status'] = status;
    jsonData['message'] = message;
    jsonData['total'] = total;
    if (data != null) {
      jsonData['data'] = data!.map((v) => v.toJson()).toList();
    }
    return jsonData;
  }
}

class ReorderableOrder {
  int? orderId;
  String? orderDate;
  String? orderDateFormatted;
  String? finalTotal;
  String? orderStatus;
  String? orderType;
  int? totalItems;
  int? availableItemsCount;
  int? unavailableItemsCount;
  bool canReorderAll;
  List<ReorderableItem>? items;

  ReorderableOrder({
    this.orderId,
    this.orderDate,
    this.orderDateFormatted,
    this.finalTotal,
    this.orderStatus,
    this.orderType,
    this.totalItems,
    this.availableItemsCount,
    this.unavailableItemsCount,
    this.canReorderAll = false,
    this.items,
  });

  ReorderableOrder.fromJson(Map<String, dynamic> json)
      : canReorderAll = json['can_reorder_all'] == true ||
            json['can_reorder_all'].toString() == '1' {
    orderId = json['order_id'] is int
        ? json['order_id']
        : int.tryParse(json['order_id']?.toString() ?? '0');
    orderDate = json['order_date']?.toString();
    orderDateFormatted = json['order_date_formatted']?.toString();
    finalTotal = json['final_total']?.toString();
    orderStatus = json['order_status']?.toString();
    orderType = json['order_type']?.toString();
    totalItems = json['total_items'] is int
        ? json['total_items']
        : int.tryParse(json['total_items']?.toString() ?? '0');
    availableItemsCount = json['available_items_count'] is int
        ? json['available_items_count']
        : int.tryParse(json['available_items_count']?.toString() ?? '0');
    unavailableItemsCount = json['unavailable_items_count'] is int
        ? json['unavailable_items_count']
        : int.tryParse(json['unavailable_items_count']?.toString() ?? '0');

    if (json['items'] != null) {
      items = <ReorderableItem>[];
      if (json['items'] is List) {
        json['items'].forEach((v) {
          items!.add(ReorderableItem.fromJson(v));
        });
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_id'] = orderId;
    data['order_date'] = orderDate;
    data['order_date_formatted'] = orderDateFormatted;
    data['final_total'] = finalTotal;
    data['order_status'] = orderStatus;
    data['order_type'] = orderType;
    data['total_items'] = totalItems;
    data['available_items_count'] = availableItemsCount;
    data['unavailable_items_count'] = unavailableItemsCount;
    data['can_reorder_all'] = canReorderAll;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ReorderableItem {
  int? orderItemId;
  int? productId;
  String? productName;
  String? productImage;
  int? variantId;
  String? variantType;
  int? measurement;
  String? unit;
  int? orderedQuantity;
  String? orderedPrice;
  String? orderedSubTotal;
  String? currentPrice;
  int? currentStock;
  String? priceDifference;
  String? priceChangePercentage;
  bool isAvailable;
  String? availabilityReason;
  int? sellerId;
  String? sellerName;
  int? storeId;
  String? storeName;
  String? storeIcon;

  ReorderableItem({
    this.orderItemId,
    this.productId,
    this.productName,
    this.productImage,
    this.variantId,
    this.variantType,
    this.measurement,
    this.unit,
    this.orderedQuantity,
    this.orderedPrice,
    this.orderedSubTotal,
    this.currentPrice,
    this.currentStock,
    this.priceDifference,
    this.priceChangePercentage,
    this.isAvailable = false,
    this.availabilityReason,
    this.sellerId,
    this.sellerName,
    this.storeId,
    this.storeName,
    this.storeIcon,
  });

  ReorderableItem.fromJson(Map<String, dynamic> json)
      : isAvailable = json['is_available'] == true ||
            json['is_available'].toString() == '1' {
    orderItemId = json['order_item_id'] is int
        ? json['order_item_id']
        : int.tryParse(json['order_item_id']?.toString() ?? '0');
    productId = json['product_id'] is int
        ? json['product_id']
        : int.tryParse(json['product_id']?.toString() ?? '0');
    productName = json['product_name']?.toString();
    productImage = json['product_image']?.toString();
    variantId = json['variant_id'] is int
        ? json['variant_id']
        : int.tryParse(json['variant_id']?.toString() ?? '0');
    variantType = json['variant_type']?.toString();
    measurement = json['measurement'] is int
        ? json['measurement']
        : int.tryParse(json['measurement']?.toString() ?? '0');
    unit = json['unit']?.toString();
    orderedQuantity = json['ordered_quantity'] is int
        ? json['ordered_quantity']
        : int.tryParse(json['ordered_quantity']?.toString() ?? '0');
    orderedPrice = json['ordered_price']?.toString();
    orderedSubTotal = json['ordered_sub_total']?.toString();
    currentPrice = json['current_price']?.toString();
    currentStock = json['current_stock'] is int
        ? json['current_stock']
        : int.tryParse(json['current_stock']?.toString() ?? '0');
    priceDifference = json['price_difference']?.toString();
    priceChangePercentage = json['price_change_percentage']?.toString();
    availabilityReason = json['availability_reason']?.toString();
    sellerId = json['seller_id'] is int
        ? json['seller_id']
        : int.tryParse(json['seller_id']?.toString() ?? '0');
    sellerName = json['seller_name']?.toString();
    storeId = json['store_id'] is int
        ? json['store_id']
        : int.tryParse(json['store_id']?.toString() ?? '0');
    storeName = json['store_name']?.toString();
    storeIcon = json['store_icon']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_item_id'] = orderItemId;
    data['product_id'] = productId;
    data['product_name'] = productName;
    data['product_image'] = productImage;
    data['variant_id'] = variantId;
    data['variant_type'] = variantType;
    data['measurement'] = measurement;
    data['unit'] = unit;
    data['ordered_quantity'] = orderedQuantity;
    data['ordered_price'] = orderedPrice;
    data['ordered_sub_total'] = orderedSubTotal;
    data['current_price'] = currentPrice;
    data['current_stock'] = currentStock;
    data['price_difference'] = priceDifference;
    data['price_change_percentage'] = priceChangePercentage;
    data['is_available'] = isAvailable;
    data['availability_reason'] = availabilityReason;
    data['seller_id'] = sellerId;
    data['seller_name'] = sellerName;
    data['store_id'] = storeId;
    data['store_name'] = storeName;
    data['store_icon'] = storeIcon;
    return data;
  }

  String get displayMeasurement => '$measurement $unit';
}
