import 'package:zenfoo_partner/models/delivery_boy_model.dart';
import 'package:zenfoo_partner/models/user_model.dart';

class AuthResponseModel {
  final int status;
  final String message;
  final int total;
  final AuthData data;

  AuthResponseModel({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      total: json['total'] ?? 0,
      data: AuthData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'total': total,
      'data': data.toJson(),
    };
  }

  bool get isSuccess {
    return status == 1 || status.toString() == '1';
  }
}

class AuthData {
  final User user;
  final DeliveryBoy deliveryBoy;
  final String accessToken;
  final String tokenType;
  final String message;

  AuthData({
    required this.user,
    required this.deliveryBoy,
    required this.accessToken,
    required this.tokenType,
    required this.message,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      user: User.fromJson(json['user'] ?? {}),
      deliveryBoy: DeliveryBoy.fromJson(json['delivery_boy'] ?? {}),
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'delivery_boy': deliveryBoy.toJson(),
      'access_token': accessToken,
      'token_type': tokenType,
      'message': message,
    };
  }
}
