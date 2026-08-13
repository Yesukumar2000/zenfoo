// Category Group Model (Level 1)
class CategoryGroup {
  final int id;
  final String name;
  final String? icon;
  final String? image;
  final String? color;
  final String? imageUrl;

  CategoryGroup({
    required this.id,
    required this.name,
    this.icon,
    this.image,
    this.color,
    this.imageUrl,
  });

  factory CategoryGroup.fromJson(Map<String, dynamic> json) {
    return CategoryGroup(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'],
      image: json['image'],
      color: json['color'],
      imageUrl: json['image_url'],
    );
  }
}

// Category Model (Level 2)
class CategoryItem {
  final int id;
  final String name;
  final String? image;
  final String? subcategoryIds;
  final int? categoryGroupId;

  CategoryItem({
    required this.id,
    required this.name,
    this.image,
    this.subcategoryIds,
    this.categoryGroupId,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'],
      subcategoryIds: json['subcategory_ids']?.toString(),
      categoryGroupId: json['category_group_id'],
    );
  }
}

// Subcategory Model (Level 3 - Final selection)
class SubcategoryItem {
  final int id;
  final String name;
  final String? slug;
  final String? subtitle;
  final String? image;
  final String? imageUrl;

  SubcategoryItem({
    required this.id,
    required this.name,
    this.slug,
    this.subtitle,
    this.image,
    this.imageUrl,
  });

  factory SubcategoryItem.fromJson(Map<String, dynamic> json) {
    return SubcategoryItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'],
      subtitle: json['subtitle'],
      image: json['image'],
      imageUrl: json['image_url'],
    );
  }
}
