class CategoryType {
  final int id;
  final String name;
  final int categoryId;
  final String createdAt;
  final String updatedAt;

  CategoryType({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryType.fromJson(Map<String, dynamic> json) {
    return CategoryType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      categoryId: json['category_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class Brand {
  final int id;
  final String name;
  final String image;
  final String categoryIds;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String imageUrl;

  Brand({
    required this.id,
    required this.name,
    required this.image,
    required this.categoryIds,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.imageUrl,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      categoryIds: json['category_ids'] ?? '',
      status: json['status'] ?? '1',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'category_ids': categoryIds,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'image_url': imageUrl,
    };
  }
}

class BannerItem {
  final int id;
  final int? storeId;
  final String type;
  final String typeId;
  final String image;
  final String sliderUrl;
  final int status;
  final String createdAt;
  final String updatedAt;
  final String typeName;
  final String imageUrl;

  BannerItem({
    required this.id,
    this.storeId,
    required this.type,
    required this.typeId,
    required this.image,
    required this.sliderUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.typeName,
    required this.imageUrl,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] ?? 0,
      storeId: json['store_id'],
      type: json['type'] ?? '',
      typeId: json['type_id'] ?? '',
      image: json['image'] ?? '',
      sliderUrl: json['slider_url'] ?? 'null',
      status: json['status'] ?? 1,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      typeName: json['type_name'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'type': type,
      'type_id': typeId,
      'image': image,
      'slider_url': sliderUrl,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'type_name': typeName,
      'image_url': imageUrl,
    };
  }
}
