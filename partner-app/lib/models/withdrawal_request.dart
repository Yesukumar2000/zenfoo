class WithdrawalRequest {
  final int id;
  final int sellerId;
  final double amount;
  final double balanceBefore;
  final double? balanceAfter;
  final String accountNumber;
  final String bankIfscCode;
  final String accountName;
  final String bankName;
  final String? branchName;
  final String status; // 'pending', 'approved', 'rejected', 'processing', 'completed'
  final String? sellerNote;
  final String? adminNote;
  final int? processedBy;
  final String? processedAt;
  final String? paymentMethod;
  final String? transactionReference;
  final String createdAt;
  final String updatedAt;

  WithdrawalRequest({
    required this.id,
    required this.sellerId,
    required this.amount,
    required this.balanceBefore,
    this.balanceAfter,
    required this.accountNumber,
    required this.bankIfscCode,
    required this.accountName,
    required this.bankName,
    this.branchName,
    required this.status,
    this.sellerNote,
    this.adminNote,
    this.processedBy,
    this.processedAt,
    this.paymentMethod,
    this.transactionReference,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      balanceBefore: double.tryParse(json['balance_before'].toString()) ?? 0.0,
      balanceAfter: json['balance_after'] != null
          ? double.tryParse(json['balance_after'].toString())
          : null,
      accountNumber: json['account_number'] ?? '',
      bankIfscCode: json['bank_ifsc_code'] ?? '',
      accountName: json['account_name'] ?? '',
      bankName: json['bank_name'] ?? '',
      branchName: json['branch_name'],
      status: json['status'] ?? 'pending',
      sellerNote: json['seller_note'],
      adminNote: json['admin_note'],
      processedBy: json['processed_by'],
      processedAt: json['processed_at'],
      paymentMethod: json['payment_method'],
      transactionReference: json['transaction_reference'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isCompleted => status.toLowerCase() == 'completed';

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return '0xFF10B981'; // Green
      case 'rejected':
        return '0xFFEF4444'; // Red
      case 'processing':
        return '0xFF3B82F6'; // Blue
      case 'pending':
      default:
        return '0xFFF59E0B'; // Orange
    }
  }
}
