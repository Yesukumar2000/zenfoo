class StatisticsResponse {
  int? status;
  String? message;
  StatisticsData? data;

  StatisticsResponse({this.status, this.message, this.data});

  factory StatisticsResponse.fromJson(Map<String, dynamic> json) {
    return StatisticsResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? StatisticsData.fromJson(json['data']) : null,
    );
  }
}

class StatisticsData {
  SellerInfo? sellerInfo;
  Overview? overview;
  List<OrderStatusCount>? orderStatusCounts;
  List<CategoryWiseProduct>? categoryWiseProducts;

  StatisticsData({
    this.sellerInfo,
    this.overview,
    this.orderStatusCounts,
    this.categoryWiseProducts,
  });

  factory StatisticsData.fromJson(Map<String, dynamic> json) {
    return StatisticsData(
      sellerInfo: json['seller_info'] != null
          ? SellerInfo.fromJson(json['seller_info'])
          : null,
      overview: json['overview'] != null
          ? Overview.fromJson(json['overview'])
          : null,
      orderStatusCounts: json['order_status_counts'] != null
          ? (json['order_status_counts'] as List)
              .map((e) => OrderStatusCount.fromJson(e))
              .toList()
          : null,
      categoryWiseProducts: json['category_wise_products'] != null
          ? (json['category_wise_products'] as List)
              .map((e) => CategoryWiseProduct.fromJson(e))
              .toList()
          : null,
    );
  }
}

class SellerInfo {
  int? id;
  String? name;
  int? storeId;
  num? balance;

  SellerInfo({this.id, this.name, this.storeId, this.balance});

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      id: json['id'],
      name: json['name'],
      storeId: json['store_id'],
      balance: json['balance'],
    );
  }
}

class Overview {
  int? totalProducts;
  int? totalOrders;
  int? completedOrders;
  int? cancelledOrders;
  int? returnedOrders;
  int? todayOrders;
  int? pendingOrders;
  num? earnings;
  num? totalRevenue;
  int? soldOutProducts;
  int? lowStockProducts;

  Overview({
    this.totalProducts,
    this.totalOrders,
    this.completedOrders,
    this.cancelledOrders,
    this.returnedOrders,
    this.todayOrders,
    this.pendingOrders,
    this.earnings,
    this.totalRevenue,
    this.soldOutProducts,
    this.lowStockProducts,
  });

  factory Overview.fromJson(Map<String, dynamic> json) {
    return Overview(
      totalProducts: json['total_products'],
      totalOrders: json['total_orders'],
      completedOrders: json['completed_orders'],
      cancelledOrders: json['cancelled_orders'],
      returnedOrders: json['returned_orders'],
      todayOrders: json['today_orders'],
      pendingOrders: json['pending_orders'],
      earnings: json['earnings'],
      totalRevenue: json['total_revenue'],
      soldOutProducts: json['sold_out_products'],
      lowStockProducts: json['low_stock_products'],
    );
  }
}

class OrderStatusCount {
  int? id;
  String? status;
  String? statusName;
  int? count;

  OrderStatusCount({this.id, this.status, this.statusName, this.count});

  factory OrderStatusCount.fromJson(Map<String, dynamic> json) {
    return OrderStatusCount(
      id: json['id'],
      status: json['status'],
      statusName: json['status_name'],
      count: json['count'],
    );
  }
}

class CategoryWiseProduct {
  int? categoryId;
  String? categoryName;
  String? categoryImageUrl;
  int? productCount;

  CategoryWiseProduct({
    this.categoryId,
    this.categoryName,
    this.categoryImageUrl,
    this.productCount,
  });

  factory CategoryWiseProduct.fromJson(Map<String, dynamic> json) {
    return CategoryWiseProduct(
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      categoryImageUrl: json['category_image_url'],
      productCount: json['product_count'],
    );
  }
}
