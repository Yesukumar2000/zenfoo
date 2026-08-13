class CategoryProductsByAdmin {
  int? status;
  String? message;
  Data? data;

  CategoryProductsByAdmin({this.status, this.message, this.data});

  CategoryProductsByAdmin.fromJson(Map<String, dynamic> json) {
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
  Category? category;
  StoreInfo? storeInfo;
  List<Products>? products;
  Pagination? pagination;

  Data({this.category, this.storeInfo, this.products, this.pagination});

  Data.fromJson(Map<String, dynamic> json) {
    category = json['category'] != null
        ? new Category.fromJson(json['category'])
        : null;
    storeInfo = json['store_info'] != null
        ? new StoreInfo.fromJson(json['store_info'])
        : null;
    if (json['products'] != null) {
      products = <Products>[];
      json['products'].forEach((v) {
        products!.add(new Products.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.category != null) {
      data['category'] = this.category!.toJson();
    }
    if (this.storeInfo != null) {
      data['store_info'] = this.storeInfo!.toJson();
    }
    if (this.products != null) {
      data['products'] = this.products!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class Category {
  int? id;
  String? name;
  String? imageUrl;

  Category({this.id, this.name, this.imageUrl});

  Category.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    imageUrl = json['image_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['image_url'] = this.imageUrl;
    return data;
  }
}

class StoreInfo {
  int? id;
  String? name;
  bool? managedByAdmin;

  StoreInfo({this.id, this.name, this.managedByAdmin});

  StoreInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    managedByAdmin = json['managed_by_admin'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['managed_by_admin'] = this.managedByAdmin;
    return data;
  }
}

class Products {
  int? id;
  String? name;
  String? slug;
  int? sellerId;
  int? categoryId;
  int? status;
  int? taxId;
  String? image;
  String? imageUrl;
  Null indicator;
  int? isApproved;
  String? manufacturer;
  String? madeIn;
  String? type;
  String? description;
  String? createdAt;
  List<Variants>? variants;
  List<String>? images;
  String? tax;

  Products(
      {this.id,
      this.name,
      this.slug,
      this.sellerId,
      this.categoryId,
      this.status,
      this.taxId,
      this.image,
      this.imageUrl,
      this.indicator,
      this.isApproved,
      this.manufacturer,
      this.madeIn,
      this.type,
      this.description,
      this.createdAt,
      this.variants,
      this.images,
      this.tax});

  Products.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
    sellerId = json['seller_id'];
    categoryId = json['category_id'];
    status = json['status'];
    taxId = json['tax_id'];
    image = json['image'];
    imageUrl = json['image_url'];
    // indicator = json['indicator'];
    isApproved = json['is_approved'];
    manufacturer = json['manufacturer'];
    madeIn = json['made_in'];
    type = json['type'];
    description = json['description'];
    createdAt = json['created_at'];
    if (json['variants'] != null) {
      variants = <Variants>[];
      json['variants'].forEach((v) {
        variants!.add(new Variants.fromJson(v));
      });
    }
    // if (json['images'] != null) {
    //   images = <String>[];
    //   json['images'].forEach((v) {
    //     images!.add(v);
    //   });
    // }
    // tax = json['tax'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['slug'] = this.slug;
    data['seller_id'] = this.sellerId;
    data['category_id'] = this.categoryId;
    data['status'] = this.status;
    data['tax_id'] = this.taxId;
    data['image'] = this.image;
    data['image_url'] = this.imageUrl;
    data['indicator'] = this.indicator;
    data['is_approved'] = this.isApproved;
    data['manufacturer'] = this.manufacturer;
    data['made_in'] = this.madeIn;
    data['type'] = this.type;
    data['description'] = this.description;
    data['created_at'] = this.createdAt;
    if (this.variants != null) {
      data['variants'] = this.variants!.map((v) => v.toJson()).toList();
    }
    if (this.images != null) {
      data['images'] = this.images!.map((v) => v).toList();
    }
    data['tax'] = this.tax;
    return data;
  }
}

class Variants {
  int? id;
  int? productId;
  int? price;
  int? discountedPrice;
  int? measurement;
  int? stock;
  int? stockUnitId;
  String? stockUnitName;
  int? status;
  int? serveFor;

  Variants(
      {this.id,
      this.productId,
      this.price,
      this.discountedPrice,
      this.measurement,
      this.stock,
      this.stockUnitId,
      this.stockUnitName,
      this.status,
      this.serveFor});

  Variants.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    price = json['price'];
    discountedPrice = json['discounted_price'];
    measurement = json['measurement'];
    stock = json['stock'];
    stockUnitId = json['stock_unit_id'];
    stockUnitName = json['stock_unit_name'];
    status = json['status'];
    serveFor = json['serve_for'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['product_id'] = this.productId;
    data['price'] = this.price;
    data['discounted_price'] = this.discountedPrice;
    data['measurement'] = this.measurement;
    data['stock'] = this.stock;
    data['stock_unit_id'] = this.stockUnitId;
    data['stock_unit_name'] = this.stockUnitName;
    data['status'] = this.status;
    data['serve_for'] = this.serveFor;
    return data;
  }
}

class Pagination {
  int? total;
  int? perPage;
  int? currentPage;
  int? lastPage;
  int? from;
  int? to;

  Pagination(
      {this.total,
      this.perPage,
      this.currentPage,
      this.lastPage,
      this.from,
      this.to});

  Pagination.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    perPage = json['per_page'];
    currentPage = json['current_page'];
    lastPage = json['last_page'];
    from = json['from'];
    to = json['to'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total'] = this.total;
    data['per_page'] = this.perPage;
    data['current_page'] = this.currentPage;
    data['last_page'] = this.lastPage;
    data['from'] = this.from;
    data['to'] = this.to;
    return data;
  }
}
