/// Three-Stage Category System Models
/// For non-sweet stores (is_sweet_house = 0)
///
/// Stage 1: Categories
/// Stage 2: Category Groups (collection of categories with name and image)
/// Stage 3: Category Groupings (collection of groups with name and image)

import 'dart:io';

/// Stage 1: Base Category Model
class ThreeStageCategoryModel {
  final String? id;
  final String name;
  final String? subtitle;
  final String? imageUrl;
  final String? image;
  final int? status;
  final int? sellerId;
  final String? createdAt;
  final String? updatedAt;

  ThreeStageCategoryModel({
    this.id,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.image,
    this.status,
    this.sellerId,
    this.createdAt,
    this.updatedAt,
  });

  factory ThreeStageCategoryModel.fromJson(Map<String, dynamic> json) =>
      ThreeStageCategoryModel(
        id: json["id"]?.toString(),
        name: json["name"] ?? "",
        subtitle: json["subtitle"] ?? "",
        imageUrl: json["image_url"],
        image: json["image"],
        status: json["status"],
        sellerId: json["seller_id"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        "name": name,
        if (subtitle != null) "subtitle": subtitle,
        if (imageUrl != null) "image_url": imageUrl,
        if (image != null) "image": image,
        if (status != null) "status": status,
        if (sellerId != null) "seller_id": sellerId,
        if (createdAt != null) "created_at": createdAt,
        if (updatedAt != null) "updated_at": updatedAt,
      };
}

/// Stage 2: Category Group Model
/// A group contains multiple categories with its own name and image
class CategoryGroupModel {
  final String? id;
  final String name;
  final String? imageUrl;
  final String? image;
  final int? status;
  final int? sellerId;
  final List<ThreeStageCategoryModel> categories;
  final List<String> categoryIds;
  final String? createdAt;
  final String? updatedAt;

  // Local properties (not from API)
  File? localImageFile;

  CategoryGroupModel({
    this.id,
    required this.name,
    this.imageUrl,
    this.image,
    this.status,
    this.sellerId,
    this.categories = const [],
    this.categoryIds = const [],
    this.createdAt,
    this.updatedAt,
    this.localImageFile,
  });

  factory CategoryGroupModel.fromJson(Map<String, dynamic> json) {
    // Parse category_ids - can be either a string "1,2,3" or a list
    List<String> parsedCategoryIds = [];
    if (json["subcategory_ids"] != null) {
      if (json["subcategory_ids"] is String) {
        // If it's a string, split by comma
        final String categoryIdsStr = json["subcategory_ids"];
        if (categoryIdsStr.isNotEmpty) {
          parsedCategoryIds = categoryIdsStr.split(',').map((e) => e.trim()).toList();
        }
      } else if (json["subcategory_ids"] is List) {
        // If it's already a list
        parsedCategoryIds = List<String>.from(json["subcategory_ids"]);
      }
    }

    return CategoryGroupModel(
      id: json["id"]?.toString(),
      name: json["name"] ?? "",
      imageUrl: json["image_url"],
      image: json["image"],
      status: json["status"],
      sellerId: json["seller_id"],
      categories: json["categories"] != null
          ? (json["categories"] as List)
              .map((cat) => ThreeStageCategoryModel.fromJson(cat))
              .toList()
          : [],
      categoryIds: parsedCategoryIds,
      createdAt: json["created_at"],
      updatedAt: json["updated_at"],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        "name": name,
        if (imageUrl != null) "image_url": imageUrl,
        if (image != null) "image": image,
        if (status != null) "status": status,
        if (sellerId != null) "seller_id": sellerId,
        "categories": categories.map((cat) => cat.toJson()).toList(),
        "category_ids": categoryIds,
        if (createdAt != null) "created_at": createdAt,
        if (updatedAt != null) "updated_at": updatedAt,
      };

  CategoryGroupModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? image,
    int? status,
    int? sellerId,
    List<ThreeStageCategoryModel>? categories,
    List<String>? categoryIds,
    String? createdAt,
    String? updatedAt,
    File? localImageFile,
  }) {
    return CategoryGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      image: image ?? this.image,
      status: status ?? this.status,
      sellerId: sellerId ?? this.sellerId,
      categories: categories ?? this.categories,
      categoryIds: categoryIds ?? this.categoryIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      localImageFile: localImageFile ?? this.localImageFile,
    );
  }
}

/// Stage 3: Category Grouping Model
/// A grouping contains multiple groups with its own name and image
class CategoryGroupingModel {
  final String? id;
  final String name;
  final String? imageUrl;
  final String? image;
  final int? status;
  final int? sellerId;
  final List<CategoryGroupModel> groups;
  final List<String> groupIds;
  final String? createdAt;
  final String? updatedAt;

  // Local properties (not from API)
  File? localImageFile;

  CategoryGroupingModel({
    this.id,
    required this.name,
    this.imageUrl,
    this.image,
    this.status,
    this.sellerId,
    this.groups = const [],
    this.groupIds = const [],
    this.createdAt,
    this.updatedAt,
    this.localImageFile,
  });

  factory CategoryGroupingModel.fromJson(Map<String, dynamic> json) =>
      CategoryGroupingModel(
        id: json["id"]?.toString(),
        name: json["name"] ?? "",
        imageUrl: json["image_url"],
        image: json["image"],
        status: json["status"],
        sellerId: json["seller_id"],
        groups: json["groups"] != null
            ? (json["groups"] as List)
                .map((group) => CategoryGroupModel.fromJson(group))
                .toList()
            : [],
        groupIds: json["group_ids"] != null
            ? List<String>.from(json["group_ids"])
            : [],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        "name": name,
        if (imageUrl != null) "image_url": imageUrl,
        if (image != null) "image": image,
        if (status != null) "status": status,
        if (sellerId != null) "seller_id": sellerId,
        "groups": groups.map((group) => group.toJson()).toList(),
        "group_ids": groupIds,
        if (createdAt != null) "created_at": createdAt,
        if (updatedAt != null) "updated_at": updatedAt,
      };

  CategoryGroupingModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? image,
    int? status,
    int? sellerId,
    List<CategoryGroupModel>? groups,
    List<String>? groupIds,
    String? createdAt,
    String? updatedAt,
    File? localImageFile,
  }) {
    return CategoryGroupingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      image: image ?? this.image,
      status: status ?? this.status,
      sellerId: sellerId ?? this.sellerId,
      groups: groups ?? this.groups,
      groupIds: groupIds ?? this.groupIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      localImageFile: localImageFile ?? this.localImageFile,
    );
  }
}
