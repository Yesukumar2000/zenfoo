class CategoryByAdmin {
  int? status;
  String? message;
  Data? data;

  CategoryByAdmin({this.status, this.message, this.data});

  CategoryByAdmin.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  Store? store;
  List<CategoryGroups>? categoryGroups;

  Data({this.store, this.categoryGroups});

  Data.fromJson(Map<String, dynamic> json) {
    store = json['store'] != null ? new Store.fromJson(json['store']) : null;
    if (json['category_groups'] != null) {
      categoryGroups = <CategoryGroups>[];
      json['category_groups'].forEach((v) {
        categoryGroups!.add(new CategoryGroups.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.store != null) {
      data['store'] = this.store!.toJson();
    }
    if (this.categoryGroups != null) {
      data['category_groups'] =
          this.categoryGroups!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Store {
  int? id;
  String? name;
  String? description;
  String? iconUrl;
  String? imageUrl;
  String? vendorImgUrl;
  bool? managedByAdmin;
  bool? isSuperMart;
  bool? isActive;

  Store(
      {this.id,
      this.name,
      this.description,
      this.iconUrl,
      this.imageUrl,
      this.vendorImgUrl,
      this.managedByAdmin,
      this.isSuperMart,
      this.isActive});

  Store.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    iconUrl = json['icon_url'];
    imageUrl = json['image_url'];
    vendorImgUrl = json['vendor_img_url'];
    managedByAdmin = json['managed_by_admin'];
    isSuperMart = json['is_super_mart'];
    isActive = json['is_active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['icon_url'] = this.iconUrl;
    data['image_url'] = this.imageUrl;
    data['vendor_img_url'] = this.vendorImgUrl;
    data['managed_by_admin'] = this.managedByAdmin;
    data['is_super_mart'] = this.isSuperMart;
    data['is_active'] = this.isActive;
    return data;
  }
}

class CategoryGroups {
  int? id;
  String? name;
  String? imageUrl;
  int? status;
  List<SubCategoryGroups>? subCategoryGroups;

  CategoryGroups(
      {this.id, this.name, this.imageUrl, this.status, this.subCategoryGroups});

  CategoryGroups.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    imageUrl = json['image_url'];
    status = json['status'];
    if (json['sub_category_groups'] != null) {
      subCategoryGroups = <SubCategoryGroups>[];
      json['sub_category_groups'].forEach((v) {
        subCategoryGroups!.add(new SubCategoryGroups.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['image_url'] = this.imageUrl;
    data['status'] = this.status;
    if (this.subCategoryGroups != null) {
      data['sub_category_groups'] =
          this.subCategoryGroups!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SubCategoryGroups {
  int? id;
  String? name;
  String? imageUrl;
  List<Categories>? categories;

  SubCategoryGroups({this.id, this.name, this.imageUrl, this.categories});

  SubCategoryGroups.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    imageUrl = json['image_url'];
    if (json['categories'] != null) {
      categories = <Categories>[];
      json['categories'].forEach((v) {
        categories!.add(new Categories.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['image_url'] = this.imageUrl;
    if (this.categories != null) {
      data['categories'] = this.categories!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Categories {
  int? id;
  String? name;
  String? imageUrl;
  int? parentId;

  Categories({this.id, this.name, this.imageUrl, this.parentId});

  Categories.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    imageUrl = json['image_url'];
    parentId = json['parent_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['image_url'] = this.imageUrl;
    data['parent_id'] = this.parentId;
    return data;
  }
}
