class WrongItemReportModel {
  final String orderId;
  final List<WrongItemStore> storeList;
  final List<WrongItemCombo> comboList;

  WrongItemReportModel({
    required this.orderId,
    required this.storeList,
    required this.comboList,
  });

  factory WrongItemReportModel.fromJson(Map<String, dynamic> json) {
    return WrongItemReportModel(
      orderId: json['order_id']?.toString() ?? '',
      storeList: _parseList<WrongItemStore>(
        json['store_list'],
        (item) => WrongItemStore.fromJson(item as Map<String, dynamic>),
      ),
      comboList: _parseList<WrongItemCombo>(
        json['combo_list'],
        (item) => WrongItemCombo.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  static List<T> _parseList<T>(dynamic value, T Function(dynamic) mapper) {
    if (value == null) return [];
    if (value is! List) return [];
    try {
      return value.map(mapper).toList();
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'store_list': storeList.map((item) => item.toJson()).toList(),
      'combo_list': comboList.map((item) => item.toJson()).toList(),
    };
  }
}

class WrongItemStore {
  final int storeId;
  final String storeName;

  WrongItemStore({
    required this.storeId,
    required this.storeName,
  });

  factory WrongItemStore.fromJson(Map<String, dynamic> json) {
    return WrongItemStore(
      storeId: _parseInt(json['store_id']),
      storeName: json['store_name']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'store_name': storeName,
    };
  }
}

class WrongItemCombo {
  final int comboId;
  final String comboName;

  WrongItemCombo({
    required this.comboId,
    required this.comboName,
  });

  factory WrongItemCombo.fromJson(Map<String, dynamic> json) {
    return WrongItemCombo(
      comboId: _parseInt(json['combo_id']),
      comboName: json['combo_name']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'combo_id': comboId,
      'combo_name': comboName,
    };
  }
}
