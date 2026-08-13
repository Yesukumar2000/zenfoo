class BankModel {
  final String? id;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String accountHolderName;
  final String? documentUrl;
  final String? documentType; // 'passbook', 'statement', 'cheque'
  final bool isDefault;

  BankModel({
    this.id,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountHolderName,
    this.documentUrl,
    this.documentType,
    this.isDefault = false,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['id']?.toString(),
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      documentUrl: json['document_url'],
      documentType: json['document_type'],
      isDefault: json['is_default'] == true || json['is_default'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'bank_name': bankName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'account_holder_name': accountHolderName,
      if (documentUrl != null) 'document_url': documentUrl,
      if (documentType != null) 'document_type': documentType,
      'is_default': isDefault ? 1 : 0,
    };
  }

  BankModel copyWith({
    String? id,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? accountHolderName,
    String? documentUrl,
    String? documentType,
    bool? isDefault,
  }) {
    return BankModel(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      documentUrl: documentUrl ?? this.documentUrl,
      documentType: documentType ?? this.documentType,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
