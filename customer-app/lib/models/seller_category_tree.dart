class SellerSubCategoryGroup {
  final int id;
  final String name;
  final String? imageUrl;
  final int categoryGroupId;
  final String subcategoryIds;
  final int isGroup;
  final int isChildrenAllowed;

  SellerSubCategoryGroup({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.categoryGroupId,
    required this.subcategoryIds,
    required this.isGroup,
    required this.isChildrenAllowed,
  });

  factory SellerSubCategoryGroup.fromJson(Map<String, dynamic> json) {
    return SellerSubCategoryGroup(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      categoryGroupId: int.tryParse(json['category_group_id']?.toString() ?? '0') ?? 0,
      subcategoryIds: json['subcategory_ids']?.toString() ?? '',
      isGroup: int.tryParse(json['is_group']?.toString() ?? '0') ?? 0,
      isChildrenAllowed: int.tryParse(json['is_children_allowed']?.toString() ?? '1') ?? 1,
    );
  }
}

class SellerCategoryGroup {
  final int id;
  final String name;
  final String? imageUrl;
  final List<SellerSubCategoryGroup> subCategoryGroups;

  SellerCategoryGroup({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.subCategoryGroups,
  });

  factory SellerCategoryGroup.fromJson(Map<String, dynamic> json) {
    return SellerCategoryGroup(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      subCategoryGroups: (json['sub_category_groups'] is List
              ? (json['sub_category_groups'] as List)
                  .map((e) {
                    try {
                      return SellerSubCategoryGroup.fromJson(e as Map<String, dynamic>);
                    } catch (_) {
                      return null;
                    }
                  })
                  .whereType<SellerSubCategoryGroup>()
                  .toList()
              : null) ??
          [],
    );
  }
}

class SellerFlatCategory {
  final int id;
  final String name;
  final String? subtitle;
  final String? imageUrl;
  final bool hasChild;

  SellerFlatCategory({
    required this.id,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.hasChild = false,
  });

  factory SellerFlatCategory.fromJson(Map<String, dynamic> json) {
    return SellerFlatCategory(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      imageUrl: json['image_url']?.toString(),
      hasChild: json['has_child'] == true || json['has_child'] == 1,
    );
  }
}

class SellerCategoryTree {
  final int sellerId;
  final List<SellerCategoryGroup> categoryGroups;
  final List<SellerFlatCategory> categories;

  SellerCategoryTree({
    required this.sellerId,
    required this.categoryGroups,
    required this.categories,
  });

  factory SellerCategoryTree.fromJson(Map<String, dynamic> json) {
    return SellerCategoryTree(
      sellerId: int.tryParse(json['seller_id']?.toString() ?? '0') ?? 0,
      categoryGroups: (json['category_groups'] is List
              ? (json['category_groups'] as List)
                  .map((e) {
                    try {
                      return SellerCategoryGroup.fromJson(e as Map<String, dynamic>);
                    } catch (_) {
                      return null;
                    }
                  })
                  .whereType<SellerCategoryGroup>()
                  .toList()
              : null) ??
          [],
      categories: (json['categories'] is List
              ? (json['categories'] as List)
                  .map((e) {
                    try {
                      return SellerFlatCategory.fromJson(e as Map<String, dynamic>);
                    } catch (_) {
                      return null;
                    }
                  })
                  .whereType<SellerFlatCategory>()
                  .toList()
              : null) ??
          [],
    );
  }
}
