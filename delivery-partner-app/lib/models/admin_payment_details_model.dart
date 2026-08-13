import 'package:zenfoo_partner/utils/safe_parser.dart';

class AdminPaymentDetailsModel {
  final String upiId;
  final AdminBankDetails bankDetails;
  final DepositMethods methods;
  final String qrImage;

  AdminPaymentDetailsModel({
    required this.upiId,
    required this.bankDetails,
    required this.methods,
    required this.qrImage,
  });

  factory AdminPaymentDetailsModel.fromJson(Map<String, dynamic> json) {
    return AdminPaymentDetailsModel(
      upiId: SafeParser.parseString(json['upi_id']),
      bankDetails: AdminBankDetails.fromJson(
        SafeParser.parseMap(json['bank_details']),
      ),
      methods: DepositMethods.fromJson(SafeParser.parseMap(json['methods'])),
      qrImage: SafeParser.parseString(json['qr_image']),
    );
  }
}

class DepositMethods {
  final bool bank;
  final bool upi;
  final bool qr;

  DepositMethods({
    required this.bank,
    required this.upi,
    required this.qr,
  });

  /// True when the admin has disabled every deposit method.
  bool get allDisabled => !bank && !upi && !qr;

  factory DepositMethods.fromJson(Map<String, dynamic> json) {
    // Default to bank + upi enabled when the API omits the field (older backend).
    if (json.isEmpty) {
      return DepositMethods(bank: true, upi: true, qr: false);
    }
    return DepositMethods(
      bank: SafeParser.parseInt(json['bank']) == 1,
      upi: SafeParser.parseInt(json['upi']) == 1,
      qr: SafeParser.parseInt(json['qr']) == 1,
    );
  }
}

class AdminBankDetails {
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String accountHolderName;

  AdminBankDetails({
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountHolderName,
  });

  factory AdminBankDetails.fromJson(Map<String, dynamic> json) {
    return AdminBankDetails(
      bankName: SafeParser.parseString(json['bank_name']),
      accountNumber: SafeParser.parseString(json['account_number']),
      ifscCode: SafeParser.parseString(json['ifsc_code']),
      accountHolderName: SafeParser.parseString(json['account_holder_name']),
    );
  }
}
