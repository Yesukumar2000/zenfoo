import 'package:zenfoo_partner/models/store_location_model.dart';

class DeliveryBoy {
  final int id;
  final String name;
  final String mobile;
  final String? email;
  final String? dob;
  final String address;
  final String? latitude;
  final String? longitude;
  final int bonusType;
  final dynamic bonus;
  final double balance;
  final int? cityId;
  final String cityName;
  final int? vehicleId;
  final String? vehicleName;
  final String? vehicleImageUrl;
  final List<StoreLocation>? storeLocations;
  final int? storeLocationsCount;
  final String? profileImage;
  final String? profileImageUrl;
  final int status;
  final String statusName;
  final String remark;
  final String? drivingLicenseUrl;
  final String? nationalIdentityCardUrl;
  final int pendingOrderCount;
  final int ordersPriority;
  final String ordersPriorityName;
  final int isDetailsGiven;
  final String createdAt;

  DeliveryBoy({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.dob,
    required this.address,
    this.latitude,
    this.longitude,
    required this.bonusType,
    this.bonus,
    required this.balance,
    this.cityId,
    required this.cityName,
    this.vehicleId,
    this.vehicleName,
    this.vehicleImageUrl,
    this.storeLocations,
    this.storeLocationsCount,
    this.profileImage,
    this.profileImageUrl,
    required this.status,
    required this.statusName,
    required this.remark,
    this.drivingLicenseUrl,
    this.nationalIdentityCardUrl,
    required this.pendingOrderCount,
    required this.ordersPriority,
    required this.ordersPriorityName,
    required this.isDetailsGiven,
    required this.createdAt,
  });

  factory DeliveryBoy.fromJson(Map<String, dynamic> json) {
    return DeliveryBoy(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'],
      dob: json['dob'],
      address: json['address'] ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      bonusType: json['bonus_type'] ?? 0,
      bonus: json['bonus'],
      balance: (json['balance'] ?? 0).toDouble(),
      cityId: json['city_id'],
      cityName: json['city_name'] ?? '',
      vehicleId: json['vehicle_id'],
      vehicleName: json['vehicle_name'],
      vehicleImageUrl: json['vehicle_image_url'],
      storeLocations: json['store_locations'] != null
          ? (json['store_locations'] as List)
              .map((store) => StoreLocation.fromJson(store))
              .toList()
          : null,
      storeLocationsCount: json['store_locations_count'],
      profileImage: json['profile_image'],
      profileImageUrl: json['profile_image_url'],
      status: json['status'] ?? 0,
      statusName: json['status_name'] ?? '',
      remark: json['remark'] ?? '',
      drivingLicenseUrl: json['driving_license_url'],
      nationalIdentityCardUrl: json['national_identity_card_url'],
      pendingOrderCount: json['pending_order_count'] ?? 0,
      ordersPriority: json['orders_priority'] ?? 0,
      ordersPriorityName: json['orders_priority_name'] ?? 'Both',
      isDetailsGiven: json['is_details_given'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'dob': dob,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'bonus_type': bonusType,
      'bonus': bonus,
      'balance': balance,
      'city_id': cityId,
      'city_name': cityName,
      'vehicle_id': vehicleId,
      'vehicle_name': vehicleName,
      'vehicle_image_url': vehicleImageUrl,
      'store_locations':
          storeLocations?.map((store) => store.toJson()).toList(),
      'store_locations_count': storeLocationsCount,
      'profile_image': profileImage,
      'profile_image_url': profileImageUrl,
      'status': status,
      'status_name': statusName,
      'remark': remark,
      'driving_license_url': drivingLicenseUrl,
      'national_identity_card_url': nationalIdentityCardUrl,
      'pending_order_count': pendingOrderCount,
      'orders_priority': ordersPriority,
      'orders_priority_name': ordersPriorityName,
      'is_details_given': isDetailsGiven,
      'created_at': createdAt,
    };
  }

  /// Check if delivery boy needs to complete registration
  bool get needsRegistration {
    return isDetailsGiven == 0;
  }

  /// Check if personal details are complete
  bool get hasCompletePersonalDetails {
    return name.isNotEmpty &&
        name != mobile &&
        address.isNotEmpty &&
        latitude != null &&
        longitude != null;
  }

  /// Check if vehicle is selected
  bool get hasVehicleSelected {
    return vehicleId != null;
  }

  /// Check if city is selected
  bool get hasCitySelected {
    return cityId != null;
  }

  /// Check if store locations are selected
  bool get hasStoreLocationsSelected {
    return storeLocations != null && storeLocations!.isNotEmpty;
  }

  /// Check if profile image is uploaded
  bool get hasProfileImage {
    return profileImage != null && profileImage!.isNotEmpty;
  }

  /// Check if delivery boy is approved
  bool get isApproved {
    return status != 0;
  }

  /// Check if delivery boy is registered but pending approval
  bool get isPendingApproval {
    return status == 0;
  }
}
