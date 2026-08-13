import 'package:project/models/productListItem.dart';

class HomeSection {
  int? id;
  String? name;
  int? order;
  List<ProductListItem>? products;
  int? productsCount;

  HomeSection({
    this.id,
    this.name,
    this.order,
    this.products,
    this.productsCount,
  });

  HomeSection.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    order = json['order'];
    productsCount = json['products_count'];
    if (json['products'] != null) {
      products = <ProductListItem>[];
      json['products'].forEach((v) {
        products!.add(ProductListItem.fromJson(v));
      });
    }
  }
}
