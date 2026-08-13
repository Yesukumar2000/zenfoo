/// Super Mart Category Models
/// Response structure from seller-category-groups API

class SuperMartCategoryResponse {
  final int status;
  final String message;
  final int total;
  final SuperMartData? data;

  SuperMartCategoryResponse({
    required this.status,
    required this.message,
    required this.total,
    this.data,
  });

  factory SuperMartCategoryResponse.fromJson(Map<String, dynamic> json) =>
      SuperMartCategoryResponse(
        status: json["status"] ?? 0,
        message: json["message"] ?? "",
        total: json["total"] ?? 0,
        data: json["data"] != null
            ? SuperMartData.fromJson(json["data"])
            : null,
      );
}

class SuperMartData {
  final String sellerId;
  final int storeId;
  final String storeName;
  final List<CategoryGrouping> categoryGroups;
  final List<dynamic> categories;

  SuperMartData({
    required this.sellerId,
    required this.storeId,
    required this.storeName,
    required this.categoryGroups,
    required this.categories,
  });

  factory SuperMartData.fromJson(Map<String, dynamic> json) => SuperMartData(
        sellerId: json["seller_id"]?.toString() ?? "",
        storeId: json["store_id"] ?? 0,
        storeName: json["store_name"] ?? "",
        categoryGroups: json["category_groups"] != null
            ? (json["category_groups"] as List)
                .map((x) => CategoryGrouping.fromJson(x))
                .toList()
            : [],
        categories: json["categories"] ?? [],
      );
}

/// Main Category Grouping (Top Level)
class CategoryGrouping {
  final int id;
  final int sellerId;
  final String name;
  final String? icon;
  final String? image;
  final String? color;
  final String? categoryIds;
  final int status;
  final int isSuperMart;
  final String createdAt;
  final String updatedAt;
  final String? imageUrl;
  final List<SubCategoryGroup> subCategoryGroups;

  CategoryGrouping({
    required this.id,
    required this.sellerId,
    required this.name,
    this.icon,
    this.image,
    this.color,
    this.categoryIds,
    required this.status,
    required this.isSuperMart,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    required this.subCategoryGroups,
  });

  factory CategoryGrouping.fromJson(Map<String, dynamic> json) =>
      CategoryGrouping(
        id: json["id"] ?? 0,
        sellerId: json["seller_id"] ?? 0,
        name: json["name"] ?? "",
        icon: json["icon"],
        image: json["image"],
        color: json["color"],
        categoryIds: json["category_ids"]?.toString(),
        status: json["status"] ?? 0,
        isSuperMart: json["is_super_mart"] ?? 0,
        createdAt: json["created_at"] ?? "",
        updatedAt: json["updated_at"] ?? "",
        imageUrl: json["image_url"],
        subCategoryGroups: json["sub_category_groups"] != null
            ? (json["sub_category_groups"] as List)
                .map((x) => SubCategoryGroup.fromJson(x))
                .toList()
            : [],
      );
}

/// Sub Category Group (Second Level)
class SubCategoryGroup {
  final int id;
  final int sellerId;
  final int isSuperMart;
  final String name;
  final String? image;
  final String? subcategoryIds;
  final int categoryGroupId;
  final int isGroup;
  final String createdAt;
  final String updatedAt;
  final String? imageUrl;

  SubCategoryGroup({
    required this.id,
    required this.sellerId,
    required this.isSuperMart,
    required this.name,
    this.image,
    this.subcategoryIds,
    required this.categoryGroupId,
    required this.isGroup,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });

  factory SubCategoryGroup.fromJson(Map<String, dynamic> json) =>
      SubCategoryGroup(
        id: json["id"] ?? 0,
        sellerId: json["seller_id"] ?? 0,
        isSuperMart: json["is_super_mart"] ?? 0,
        name: json["name"] ?? "",
        image: json["image"],
        subcategoryIds: json["subcategory_ids"]?.toString(),
        categoryGroupId: json["category_group_id"] ?? 0,
        isGroup: json["is_group"] ?? 0,
        createdAt: json["created_at"] ?? "",
        updatedAt: json["updated_at"] ?? "",
        imageUrl: json["image_url"],
      );
}
