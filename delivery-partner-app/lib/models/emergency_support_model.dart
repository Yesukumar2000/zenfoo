class EmergencySupportContact {
  final String id;
  final String name;
  final String? type; // support, emergency, etc.
  final String phone;
  final String? email;
  final String? icon;
  final String? description;
  final String? actionType; // CONTACT_SUPPORT, CALL_EMERGENCY, etc.
  final bool isActive;

  EmergencySupportContact({
    required this.id,
    required this.name,
    this.type,
    required this.phone,
    this.email,
    this.icon,
    this.description,
    this.actionType,
    required this.isActive,
  });

  factory EmergencySupportContact.fromJson(Map<String, dynamic> json) {
    return EmergencySupportContact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'],
      phone: json['phone'] ?? '',
      email: json['email'],
      icon: json['icon'],
      description: json['description'],
      actionType: json['action_type'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'phone': phone,
      'email': email,
      'icon': icon,
      'description': description,
      'action_type': actionType,
      'is_active': isActive,
    };
  }
}

class EmergencySupportResponse {
  final int status;
  final String message;
  final int total;
  final List<EmergencySupportContact> emergencyContacts;

  EmergencySupportResponse({
    required this.status,
    required this.message,
    required this.total,
    required this.emergencyContacts,
  });

  factory EmergencySupportResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final contacts = <EmergencySupportContact>[];

    if (data != null && data['emergency_contacts'] != null) {
      final contactsList = data['emergency_contacts'] as List<dynamic>;
      contacts.addAll(
        contactsList
            .map((c) => EmergencySupportContact.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
    }

    return EmergencySupportResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      total: data?['total_contacts'] ?? 0,
      emergencyContacts: contacts,
    );
  }
}
