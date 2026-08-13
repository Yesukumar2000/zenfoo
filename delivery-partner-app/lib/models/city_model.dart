class City {
  final int id;
  final String name;
  final String state;
  final String zone;
  final String latitude;
  final String longitude;
  final String formattedAddress;
  final double maxDeliverableDistance;
  final double? distanceKm;

  City({
    required this.id,
    required this.name,
    required this.state,
    required this.zone,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.maxDeliverableDistance,
    this.distanceKm,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      state: json['state'] ?? '',
      zone: json['zone'] ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      maxDeliverableDistance: (json['max_deliverable_distance'] ?? 0).toDouble(),
      distanceKm: json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'zone': zone,
      'latitude': latitude,
      'longitude': longitude,
      'formatted_address': formattedAddress,
      'max_deliverable_distance': maxDeliverableDistance,
      'distance_km': distanceKm,
    };
  }
}
