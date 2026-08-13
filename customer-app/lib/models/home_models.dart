class HomeCategories {
  int? id;
  String? name;
  String? subtitle;
  String? slug;
  String? imageUrl;
  bool? hasChild;
  bool? hasActiveChild;
  List<CatActiveChilds>? catActiveChilds;

  HomeCategories(
      {this.id,
      this.name,
      this.subtitle,
      this.slug,
      this.imageUrl,
      this.hasChild,
      this.hasActiveChild,
      this.catActiveChilds});

  HomeCategories.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    subtitle = json['subtitle'];
    slug = json['slug'];
    imageUrl = json['image_url'];
    hasChild = json['has_child'];
    hasActiveChild = json['has_active_child'];
    if (json['cat_active_childs'] != null) {
      catActiveChilds = <CatActiveChilds>[];
      json['cat_active_childs'].forEach((v) {
        catActiveChilds!.add(new CatActiveChilds.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['subtitle'] = this.subtitle;
    data['slug'] = this.slug;
    data['image_url'] = this.imageUrl;
    data['has_child'] = this.hasChild;
    data['has_active_child'] = this.hasActiveChild;
    if (this.catActiveChilds != null) {
      data['cat_active_childs'] =
          this.catActiveChilds!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CatActiveChilds {
  int? id;
  int? rowOrder;
  String? name;
  String? slug;
  String? subtitle;
  String? image;
  int? status;
  int? productRating;
  String? webImage;
  int? parentId;
  String? metaTitle;
  String? metaKeywords;
  String? schemaMarkup;
  String? metaDescription;
  String? parentName;
  String? imageUrl;
  bool? hasChild;
  bool? hasActiveChild;
  List<CatActiveChilds>? catActiveChilds;

  CatActiveChilds(
      {this.id,
      this.rowOrder,
      this.name,
      this.slug,
      this.subtitle,
      this.image,
      this.status,
      this.productRating,
      this.webImage,
      this.parentId,
      this.metaTitle,
      this.metaKeywords,
      this.schemaMarkup,
      this.metaDescription,
      this.parentName,
      this.imageUrl,
      this.hasChild,
      this.hasActiveChild,
      this.catActiveChilds});

  CatActiveChilds.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    rowOrder = json['row_order'];
    name = json['name'];
    slug = json['slug'];
    subtitle = json['subtitle'];
    image = json['image'];
    status = json['status'];
    productRating = json['product_rating'];
    webImage = json['web_image'];
    parentId = json['parent_id'];
    metaTitle = json['meta_title'];
    metaKeywords = json['meta_keywords'];
    schemaMarkup = json['schema_markup'];
    metaDescription = json['meta_description'];
    parentName = json['parent_name'];
    imageUrl = json['image_url'];
    hasChild = json['has_child'];
    hasActiveChild = json['has_active_child'];
    if (json['cat_active_childs'] != null) {
      catActiveChilds = <CatActiveChilds>[];
      json['cat_active_childs'].forEach((v) {
        catActiveChilds!.add(new CatActiveChilds.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['row_order'] = this.rowOrder;
    data['name'] = this.name;
    data['slug'] = this.slug;
    data['subtitle'] = this.subtitle;
    data['image'] = this.image;
    data['status'] = this.status;
    data['product_rating'] = this.productRating;
    data['web_image'] = this.webImage;
    data['parent_id'] = this.parentId;
    data['meta_title'] = this.metaTitle;
    data['meta_keywords'] = this.metaKeywords;
    data['schema_markup'] = this.schemaMarkup;
    data['meta_description'] = this.metaDescription;
    data['parent_name'] = this.parentName;
    data['image_url'] = this.imageUrl;
    data['has_child'] = this.hasChild;
    data['has_active_child'] = this.hasActiveChild;
    if (this.catActiveChilds != null) {
      data['cat_active_childs'] =
          this.catActiveChilds!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
