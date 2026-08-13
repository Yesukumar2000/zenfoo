import 'package:project/models/productListItem.dart';

class NoteProductsResponse {
  String? status;
  String? message;
  String? total;
  List<NoteProductGroup>? data;

  NoteProductsResponse({this.status, this.message, this.total, this.data});

  NoteProductsResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'].toString();
    message = json['message'].toString();
    total = json['total'].toString();

    if (json['data'] != null) {
      data = <NoteProductGroup>[];
      if (json['data'] is List) {
        json['data'].forEach((v) {
          data!.add(NoteProductGroup.fromJson(v));
        });
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonData = <String, dynamic>{};
    jsonData['status'] = status;
    jsonData['message'] = message;
    jsonData['total'] = total;
    if (data != null) {
      jsonData['data'] = data!.map((v) => v.toJson()).toList();
    }
    return jsonData;
  }
}

class NoteProductGroup {
  int? noteId;
  String? noteText;
  int? orderIndex;
  List<ProductListItem>? products;
  int? productsCount;

  NoteProductGroup({
    this.noteId,
    this.noteText,
    this.orderIndex,
    this.products,
    this.productsCount,
  });

  NoteProductGroup.fromJson(Map<String, dynamic> json) {
    noteId = json['note_id'] is int
        ? json['note_id']
        : int.tryParse(json['note_id']?.toString() ?? '0');
    noteText = json['note_text']?.toString();
    orderIndex = json['order_index'] is int
        ? json['order_index']
        : int.tryParse(json['order_index']?.toString() ?? '0');
    productsCount = json['products_count'] is int
        ? json['products_count']
        : int.tryParse(json['products_count']?.toString() ?? '0');

    if (json['products'] != null) {
      products = <ProductListItem>[];
      if (json['products'] is List) {
        json['products'].forEach((v) {
          products!.add(ProductListItem.fromJson(v));
        });
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['note_id'] = noteId;
    data['note_text'] = noteText;
    data['order_index'] = orderIndex;
    data['products_count'] = productsCount;
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
