// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

RatingModel ratingModelFromJson(String str) =>
    RatingModel.fromJson(json.decode(str));

String ratingModelToJson(RatingModel data) => json.encode(data.toJson());

class RatingModel {
  final int? status;
  final String? message;
  final RatingData? data;

  RatingModel({
    this.status,
    this.message,
    this.data,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) => RatingModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null ? null : RatingData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data?.toJson(),
      };
}

class RatingData {
  final int? orderId;
  final DeliveryBoy? deliveryBoy;
  final int? sellerCount;
  final List<Seller>? sellers;

  RatingData({
    this.orderId,
    this.deliveryBoy,
    this.sellerCount,
    this.sellers,
  });

  factory RatingData.fromJson(Map<String, dynamic> json) => RatingData(
        orderId: json["order_id"],
        deliveryBoy: json["delivery_boy"] == null
            ? null
            : DeliveryBoy.fromJson(json["delivery_boy"]),
        sellerCount: json["seller_count"],
        sellers: json["sellers"] == null
            ? []
            : List<Seller>.from(
                json["sellers"]!.map((x) => Seller.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "order_id": orderId,
        "delivery_boy": deliveryBoy?.toJson(),
        "seller_count": sellerCount,
        "sellers": sellers == null
            ? []
            : List<dynamic>.from(sellers!.map((x) => x.toJson())),
      };
}

class DeliveryBoy {
  final dynamic id;
  final dynamic name;
  final String? profileImage;
  final dynamic rating;
  final dynamic review;

  DeliveryBoy({
    this.id,
    this.name,
    this.profileImage,
    this.rating,
    this.review,
  });

  factory DeliveryBoy.fromJson(Map<String, dynamic> json) => DeliveryBoy(
        id: json["id"],
        name: json["name"],
        profileImage: json["profile_image"]?.toString(),
        rating: json["rating"],
        review: json["review"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "profile_image": profileImage,
        "rating": rating,
        "review": review,
      };
}

class Seller {
  final int? sellerId;
  final int? storeId;
  final String? storeName;
  final String? sellerName;
  final String? sellerLogo;
  final bool? isZenfooStore;
  final dynamic review;
  final List<Item>? items;
  final int? itemCount;

  Seller({
    this.sellerId,
    this.storeId,
    this.storeName,
    this.sellerName,
    this.sellerLogo,
    this.isZenfooStore,
    this.review,
    this.items,
    this.itemCount,
  });

  factory Seller.fromJson(Map<String, dynamic> json) => Seller(
        sellerId: json["seller_id"],
        storeId: json["store_id"],
        storeName: json["store_name"],
        sellerName: json["seller_name"]?.toString(),
        sellerLogo: json["seller_logo"]?.toString(),
        isZenfooStore: json["is_zenfoo_store"] == 1 ||
            json["is_zenfoo_store"] == "1" ||
            json["is_zenfoo_store"] == true,
        review: json["review"],
        items: json["items"] == null
            ? []
            : List<Item>.from(json["items"]!.map((x) => Item.fromJson(x))),
        itemCount: json["item_count"],
      );

  Map<String, dynamic> toJson() => {
        "seller_id": sellerId,
        "store_id": storeId,
        "store_name": storeName,
        "seller_name": sellerName,
        "seller_logo": sellerLogo,
        "is_zenfoo_store": isZenfooStore,
        "review": review,
        "items": items == null
            ? []
            : List<dynamic>.from(items!.map((x) => x.toJson())),
        "item_count": itemCount,
      };
}

class Item {
  final int? productId;
  final String? itemName;
  final int? quantity;
  final String? measurement;
  final dynamic rating;

  Item({
    this.productId,
    this.itemName,
    this.quantity,
    this.measurement,
    this.rating,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        productId: json["product_id"],
        itemName: json["item_name"],
        quantity: json["quantity"],
        measurement: json["measurement"],
        rating: json["rating"],
      );

  Map<String, dynamic> toJson() => {
        "product_id": productId,
        "item_name": itemName,
        "quantity": quantity,
        "measurement": measurement,
        "rating": rating,
      };
}
