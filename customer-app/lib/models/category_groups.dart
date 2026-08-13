class CategoryGroup {
  final int id;
  final String name;
  final String? icon;
  final String? iconUrl;
  final String? image;
  final String? imageUrl;
  final String? color;
  final String? createdAt;
  final String? updatedAt;
  final List<SubCategoryGroup> subCategoryGroups;
  final int? storeId; // Parent store ID for matching sliders

  CategoryGroup({
    required this.id,
    required this.name,
    this.icon,
    this.iconUrl,
    this.image,
    this.imageUrl,
    this.color,
    this.createdAt,
    this.updatedAt,
    this.subCategoryGroups = const [],
    this.storeId,
  });

  factory CategoryGroup.fromJson(Map<String, dynamic> json) {
    // Get storeId from pivot if available
    int? storeId;
    if (json['pivot'] != null && json['pivot']['store_id'] != null) {
      storeId = json['pivot']['store_id'] is int
          ? json['pivot']['store_id']
          : int.tryParse(json['pivot']['store_id'].toString());
    }

    return CategoryGroup(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'],
      iconUrl: json['icon_url'],
      image: json['image'],
      imageUrl: json['image_url'],
      color: json['color'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      subCategoryGroups: (json['sub_category_groups'] is List)
          ? (json['sub_category_groups'] as List)
              .map((e) => SubCategoryGroup.fromJson(e))
              .toList()
          : [],
      storeId: storeId,
    );
  }

  /// Create a copy with a different storeId
  CategoryGroup copyWithStoreId(int storeId) {
    return CategoryGroup(
      id: id,
      name: name,
      icon: icon,
      iconUrl: iconUrl,
      image: image,
      imageUrl: imageUrl,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
      subCategoryGroups: subCategoryGroups,
      storeId: storeId,
    );
  }
}

class SubCategoryGroup {
  final int id;
  final String name;
  final String? image;
  final String? imageUrl;
  final String? subcategoryIds;
  final int? categoryGroupId;
  final int? isGroup;
  final String? createdAt;
  final String? updatedAt;

  /// The real categories this tile bundles, resolved server-side from
  /// [subcategoryIds]. Lets the grid show what sits inside a tile — e.g.
  /// "Oils,Ghee & Massala" is Massala, Oils and Ghee — without opening it.
  /// Empty when the API predates this field.
  final List<TileSubcategory> subcategories;

  SubCategoryGroup({
    required this.id,
    required this.name,
    this.image,
    this.imageUrl,
    this.subcategoryIds,
    this.categoryGroupId,
    this.isGroup,
    this.createdAt,
    this.updatedAt,
    this.subcategories = const [],
  });

  factory SubCategoryGroup.fromJson(Map<String, dynamic> json) {
    return SubCategoryGroup(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      image: json['image'],
      imageUrl: json['image_url'],
      subcategoryIds: json['subcategory_ids'],
      categoryGroupId: json['category_group_id'] is int
          ? json['category_group_id']
          : int.tryParse(json['category_group_id']?.toString() ?? ''),
      isGroup: json['is_group'] is int
          ? json['is_group']
          : int.tryParse(json['is_group']?.toString() ?? ''),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      subcategories: (json['subcategories'] is List)
          ? (json['subcategories'] as List)
              .map((e) => TileSubcategory.fromJson(e))
              .toList()
          : const [],
    );
  }

  /// The categories bundled inside this tile as one line — the tile
  /// "Atta rice & Dal" reads "Atta · Besan, Sooji & Maida · Dal · Rice".
  ///
  /// Null when there is nothing worth printing: no resolved subcategories,
  /// or ones that only echo the tile label back. "Chips & Namkeen" over
  /// "Chips · Namkeen" says nothing the title didn't, and it costs a row of
  /// grid height to say it — see [_echoesTitle].
  String? get bundledLabel {
    final names = subcategories
        .map((s) => s.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (names.isEmpty) return null;
    if (_echoesTitle(names)) return null;
    return names.join(' · ');
  }

  /// True when every word the caption would print already appears in the tile
  /// name, so the line adds nothing. Plurals are folded ("cup" matches
  /// "cups") because the catalogue is inconsistent about them.
  bool _echoesTitle(List<String> names) {
    final titleWords = _words(name);
    if (titleWords.isEmpty) return false;
    return names.every(
      (n) => _words(n).every(titleWords.contains),
    );
  }

  /// Lowercased, de-pluralised words of [text], with separators ("&", ",")
  /// and joining words dropped.
  static Set<String> _words(String text) {
    const skip = {'and', 'the', 'of', 'with'};
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.isNotEmpty && !skip.contains(w))
        .map((w) => w.endsWith('s') && w.length > 3
            ? w.substring(0, w.length - 1)
            : w)
        .toSet();
  }
}

/// One real category sitting inside a [SubCategoryGroup] tile.
class TileSubcategory {
  final int id;
  final String name;
  final String? imageUrl;

  TileSubcategory({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory TileSubcategory.fromJson(Map<String, dynamic> json) {
    return TileSubcategory(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}
