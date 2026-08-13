class ThinkingItem {
  int? id;
  String? name;
  String? imgUrl;
  int? status;
  int? categoryId;
  ThinkingItemCategory? category;

  ThinkingItem({
    this.id,
    this.name,
    this.imgUrl,
    this.status,
    this.categoryId,
    this.category,
  });

  ThinkingItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    imgUrl = json['img_url'];
    status = json['status'];
    categoryId = json['category_id'];
    category = json['category'] != null
        ? ThinkingItemCategory.fromJson(json['category'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['img_url'] = imgUrl;
    data['status'] = status;
    data['category_id'] = categoryId;
    if (category != null) {
      data['category'] = category!.toJson();
    }
    return data;
  }
}

class ThinkingItemCategory {
  int? id;
  String? name;
  String? image;
  String? imageUrl;

  ThinkingItemCategory({this.id, this.name, this.image, this.imageUrl});

  ThinkingItemCategory.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    image = json['image'];
    imageUrl = json['image_url'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'image_url': imageUrl,
    };
  }
}
