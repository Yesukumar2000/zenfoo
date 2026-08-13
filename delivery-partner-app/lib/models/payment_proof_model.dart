class PaymentProofResponse {
  final int status;
  final String message;
  final PaymentProofData? data;

  PaymentProofResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory PaymentProofResponse.fromJson(Map<String, dynamic> json) {
    return PaymentProofResponse(
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status'].toString()) ?? 0,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? PaymentProofData.fromJson(json['data'])
          : null,
    );
  }
}

class PaymentProofData {
  final int id;
  final int deliveryBoyId;
  final String transactionId;
  final String amount;
  final String proofImage;
  final String status;
  final String? adminNotes;
  final String createdAt;

  PaymentProofData({
    required this.id,
    required this.deliveryBoyId,
    required this.transactionId,
    required this.amount,
    required this.proofImage,
    required this.status,
    this.adminNotes,
    required this.createdAt,
  });

  factory PaymentProofData.fromJson(Map<String, dynamic> json) {
    return PaymentProofData(
      id: json['id'] ?? 0,
      deliveryBoyId: json['delivery_boy_id'] ?? 0,
      transactionId: json['transaction_id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      proofImage: json['proof_image']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      adminNotes: json['admin_notes']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
