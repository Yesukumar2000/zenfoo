class CategoryTypeModel {
  final String id;
  final String name;

  CategoryTypeModel({
    required this.id,
    required this.name,
  });

  factory CategoryTypeModel.fromJson(Map<String, dynamic> json) =>
      CategoryTypeModel(
        id: json["id"]?.toString() ?? "",
        name: json["name"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

class CategoryModel {
  final String? id;
  final String name;
  final String subtitle;
  final String? imageUrl;
  final int? isAddedBySeller;
  final int? isSweetHouseStore;
  final int? sellerId;
  final int? isSuperMart;
  final int? rowOrder;
  final String? slug;
  final String? image;
  final int? status;
  final List<CategoryTypeModel> types;

  CategoryModel({
    this.id,
    required this.name,
    required this.subtitle,
    this.imageUrl,
    this.isAddedBySeller,
    this.isSweetHouseStore,
    this.sellerId,
    this.isSuperMart,
    this.rowOrder,
    this.slug,
    this.image,
    this.status,
    this.types = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json["id"]?.toString(),
        name: json["name"] ?? "",
        subtitle: json["subtitle"] ?? "",
        imageUrl: json["image_url"],
        isAddedBySeller: json["is_added_by_seller"],
        isSweetHouseStore: json["is_sweet_house_store"],
        sellerId: json["seller_id"],
        isSuperMart: json["is_super_mart"],
        rowOrder: json["row_order"],
        slug: json["slug"],
        image: json["image"],
        status: json["status"],
        types: json["types"] != null
            ? (json["types"] as List)
                .map((type) => CategoryTypeModel.fromJson(type))
                .toList()
            : [],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        "name": name,
        "subtitle": subtitle,
        if (imageUrl != null) "image_url": imageUrl,
        if (isAddedBySeller != null) "is_added_by_seller": isAddedBySeller,
        if (isSweetHouseStore != null) "is_sweet_house_store": isSweetHouseStore,
        if (sellerId != null) "seller_id": sellerId,
        if (isSuperMart != null) "is_super_mart": isSuperMart,
        if (rowOrder != null) "row_order": rowOrder,
        if (slug != null) "slug": slug,
        if (image != null) "image": image,
        if (status != null) "status": status,
        "types": types.map((type) => type.toJson()).toList(),
      };
}
