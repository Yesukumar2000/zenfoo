class StoreModel {
  final int id;
  final String name;
  final String icon, image, color, iconUrl, imageUrl, VendorImgUrl;
  final String? description;
  final String? stores; // String ID of stores (e.g., "12")
  final List<String>? categories; // Categories array from new API

  StoreModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.image,
    required this.color,
    required this.iconUrl,
    required this.imageUrl,
    required this.VendorImgUrl,
    this.description,
    this.stores,
    this.categories,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) => StoreModel(
        id: json["id"],
        name: json["name"] ?? "",
        icon: json["icon"] ?? "",
        image: json["image"] ?? "",
        color: json["color"] ?? "",
        iconUrl: json["icon_url"] ?? "",
        imageUrl: json["image_url"] ?? "",
        VendorImgUrl: json["vendor_img_url"] ?? json["image_url"] ?? "",
        description: json["description"] ?? "",
        stores: json["stores"]?.toString(),
        categories: json["categories"] != null
            ? List<String>.from(json["categories"])
            : null,
      );
}