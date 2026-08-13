import 'package:flutter/services.dart';

/// Real-world validators for the seller (vendor) forms.
///
/// Every message is written for the vendor, not the developer: it says what
/// is wrong AND shows an example of the correct format, e.g.
/// "PAN must look like ABCDE1234F (5 letters, 4 digits, 1 letter)".
///
/// The document rules implemented here are the actual government rules:
///  * Aadhaar  - 12 digits, never starts with 0/1, Verhoeff checksum
///  * PAN      - AAAAA9999A, 4th char is the holder type, 5th is surname initial
///  * FSSAI    - 14 digits, starts with 1 (licence) or 2 (registration)
///  * GSTIN    - 15 chars, state code + PAN + entity + 'Z' + mod-36 checksum
class AppValidators {
  AppValidators._();

  // ---------------------------------------------------------------- examples
  // Shown in hints/helper text so the vendor knows the expected shape.
  // These samples are deliberately checksum-valid dummies.
  // The PAN sample is also the PAN embedded in the GSTIN sample, which is how
  // a real GSTIN is built (state code + PAN + entity + Z + checksum).
  static const String aadhaarExample = '2345 6789 0124';
  static const String panExample = 'ABCPK1234F';
  static const String fssaiExample = '10012345000123';
  static const String gstinExample = '36ABCPK1234F1Z6';
  static const String emailExample = 'name@example.com';
  static const String mobileExample = '9876543210';

  // -------------------------------------------------------------------- name

  static String? fullName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Please enter your full name';
    if (name.length < 3) return 'Name is too short (e.g. Ravi Kumar)';
    if (name.length > 50) return 'Name cannot be longer than 50 characters';
    if (!RegExp(r"^[a-zA-Z][a-zA-Z .']*$").hasMatch(name)) {
      return 'Name can only contain letters (e.g. Ravi Kumar)';
    }
    return null;
  }

  // ------------------------------------------------------------------- email

  static String? email(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Please enter your email address';
    if (email.length > 100) return 'Email address is too long';
    if (email.contains('..')) {
      return 'Email address cannot contain two dots together (e.g. $emailExample)';
    }
    // Local part, single @, domain with a valid TLD of 2+ letters
    // (.in, .com, .online, .business ... all accepted).
    final regex = RegExp(
      r"^[a-zA-Z0-9]([a-zA-Z0-9._%+-]*[a-zA-Z0-9])?@[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$",
    );
    if (!regex.hasMatch(email)) {
      return 'Enter a valid email address (e.g. $emailExample)';
    }
    return null;
  }

  // ------------------------------------------------------------------ mobile

  static String? mobile(String? value, {bool required = true}) {
    final mobile = (value ?? '').trim().replaceAll(RegExp(r'[\s-]'), '');
    if (mobile.isEmpty) {
      return required ? 'Please enter your mobile number' : null;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
      return 'Mobile number must be 10 digits (e.g. $mobileExample)';
    }
    if (!RegExp(r'^[6-9]').hasMatch(mobile)) {
      return 'Indian mobile numbers start with 6, 7, 8 or 9 (e.g. $mobileExample)';
    }
    return null;
  }

  // ----------------------------------------------------------------- Aadhaar

  /// Aadhaar: exactly 12 digits, first digit 2-9, valid Verhoeff check digit.
  static String? aadhaar(String? value, {bool required = true}) {
    final aadhaar = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (aadhaar.isEmpty) {
      return required ? 'Please enter your Aadhar number' : null;
    }
    if (!RegExp(r'^\d+$').hasMatch(aadhaar)) {
      return 'Aadhar number can contain digits only (e.g. $aadhaarExample)';
    }
    if (aadhaar.length != 12) {
      return 'Aadhar number must be exactly 12 digits — you entered ${aadhaar.length} (e.g. $aadhaarExample)';
    }
    if (aadhaar[0] == '0' || aadhaar[0] == '1') {
      return 'Aadhar number cannot start with 0 or 1 (e.g. $aadhaarExample)';
    }
    if (RegExp(r'^(\d)\1{11}$').hasMatch(aadhaar)) {
      return 'Please enter your real Aadhar number (e.g. $aadhaarExample)';
    }
    if (!_verhoeffIsValid(aadhaar)) {
      return 'This Aadhar number is not valid. Please re-check the 12 digits on your card';
    }
    return null;
  }

  // --------------------------------------------------------------------- PAN

  /// PAN: AAAAA9999A. The 4th letter is the holder type and the 5th letter is
  /// the first letter of the surname / entity name.
  static String? pan(String? value, {bool required = true}) {
    final pan = (value ?? '').trim().toUpperCase();
    if (pan.isEmpty) {
      return required ? 'Please enter your PAN number' : null;
    }
    if (pan.length != 10) {
      return 'PAN must be exactly 10 characters — you entered ${pan.length} (e.g. $panExample)';
    }
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan)) {
      return 'PAN format is AAAAA9999A — 5 letters, 4 digits, 1 letter (e.g. $panExample)';
    }
    // 4th character = holder type. P-Individual, C-Company, H-HUF, F-Firm,
    // A-AOP, T-Trust, B-BOI, L-Local authority, J-Artificial juridical person,
    // G-Government.
    if (!'PCHFATBLJG'.contains(pan[3])) {
      return 'Invalid PAN: the 4th character must be P, C, H, F, A, T, B, L, J or G (e.g. $panExample)';
    }
    return null;
  }

  // ------------------------------------------------------------------- FSSAI

  /// FSSAI licence / registration number: 14 digits starting with 1 or 2.
  static String? fssai(String? value, {bool required = false}) {
    final fssai = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (fssai.isEmpty) {
      return required ? 'Please enter your FSSAI number' : null;
    }
    if (!RegExp(r'^\d+$').hasMatch(fssai)) {
      return 'FSSAI number can contain digits only (e.g. $fssaiExample)';
    }
    if (fssai.length != 14) {
      return 'FSSAI number must be exactly 14 digits — you entered ${fssai.length} (e.g. $fssaiExample)';
    }
    if (fssai[0] != '1' && fssai[0] != '2') {
      return 'FSSAI number starts with 1 (licence) or 2 (registration) (e.g. $fssaiExample)';
    }
    if (RegExp(r'^(\d)\1{13}$').hasMatch(fssai)) {
      return 'Please enter the FSSAI number printed on your certificate';
    }
    return null;
  }

  // ------------------------------------------------------------------- GSTIN

  /// GSTIN: 15 characters — 2 digit state code, 10 char PAN, 1 entity number,
  /// literal 'Z', 1 mod-36 checksum character.
  static String? gstin(String? value, {bool required = true}) {
    final gst = (value ?? '').trim().toUpperCase().replaceAll(RegExp(r'\s'), '');
    if (gst.isEmpty) {
      return required ? 'Please enter your GSTIN number' : null;
    }
    if (gst.length != 15) {
      return 'GSTIN must be exactly 15 characters — you entered ${gst.length} (e.g. $gstinExample)';
    }
    if (!RegExp(r'^[0-9A-Z]{15}$').hasMatch(gst)) {
      return 'GSTIN can contain only capital letters and digits (e.g. $gstinExample)';
    }
    final stateCode = int.tryParse(gst.substring(0, 2)) ?? 0;
    final isValidState =
        (stateCode >= 1 && stateCode <= 38) || stateCode == 97 || stateCode == 99;
    if (!isValidState) {
      return 'GSTIN must begin with a valid state code, 01 to 38 (e.g. $gstinExample)';
    }
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(gst.substring(2, 12))) {
      return 'Characters 3-12 of the GSTIN must be a valid PAN (e.g. $gstinExample)';
    }
    if (!RegExp(r'^[0-9A-Z]$').hasMatch(gst[12])) {
      return 'Invalid GSTIN entity code at position 13 (e.g. $gstinExample)';
    }
    if (gst[13] != 'Z') {
      return 'The 14th character of a GSTIN is always Z (e.g. $gstinExample)';
    }
    if (_gstinCheckDigit(gst.substring(0, 14)) != gst[14]) {
      return 'This GSTIN failed the checksum test. Please re-check it on your GST certificate';
    }
    return null;
  }

  /// The PAN embedded inside a GSTIN, or null if the GSTIN is not 15 chars.
  /// Used only for a soft "this does not match your PAN" hint.
  static String? panInsideGstin(String? gstin) {
    final gst = (gstin ?? '').trim().toUpperCase();
    if (gst.length != 15) return null;
    return gst.substring(2, 12);
  }

  // -------------------------------------------------------------- store info

  static String? storeName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Please enter your store name';
    if (name.length < 3) {
      return 'Store name must be at least 3 characters (e.g. Sri Sai Bakery)';
    }
    if (name.length > 60) return 'Store name cannot be longer than 60 characters';
    if (!RegExp(r"^[a-zA-Z0-9][a-zA-Z0-9 &.,'()-]*$").hasMatch(name)) {
      return "Store name can use letters, numbers and & . , ' ( ) - only";
    }
    return null;
  }

  static String? storeDescription(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Please write a short description of your store';
    if (text.length < 20) {
      return 'Please write at least 20 characters so customers know what you sell (currently ${text.length})';
    }
    if (text.length > 500) {
      return 'Description cannot be longer than 500 characters (currently ${text.length})';
    }
    return null;
  }

  /// Legal / trade name as printed on the GST certificate.
  static String? gstBusinessName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Please enter the business name on your GST certificate';
    if (name.length < 3) {
      return 'Business name must be at least 3 characters (e.g. Sri Sai Foods)';
    }
    if (name.length > 100) {
      return 'Business name cannot be longer than 100 characters';
    }
    if (!RegExp(r"^[a-zA-Z0-9][a-zA-Z0-9 &.,'()-]*$").hasMatch(name)) {
      return "Business name can use letters, numbers and & . , ' ( ) - only";
    }
    return null;
  }

  // ------------------------------------------------------------- check digits

  // Verhoeff tables (UIDAI uses the Verhoeff scheme for the 12th digit).
  static const List<List<int>> _verhoeffD = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
  ];

  static const List<List<int>> _verhoeffP = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
  ];

  static bool _verhoeffIsValid(String digits) {
    int c = 0;
    final reversed = digits.split('').reversed.toList();
    for (int i = 0; i < reversed.length; i++) {
      final digit = int.tryParse(reversed[i]);
      if (digit == null) return false;
      c = _verhoeffD[c][_verhoeffP[i % 8][digit]];
    }
    return c == 0;
  }

  /// Mod-36 checksum used by the GST portal for the 15th character.
  static String _gstinCheckDigit(String first14) {
    const codes = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    int sum = 0;
    for (int i = 0; i < first14.length; i++) {
      final value = codes.indexOf(first14[i]);
      if (value < 0) return '';
      final product = value * (i.isEven ? 1 : 2);
      sum += (product ~/ 36) + (product % 36);
    }
    return codes[(36 - (sum % 36)) % 36];
  }
}

/// Forces PAN / GSTIN input to capitals as the vendor types, so a lowercase
/// entry never fails validation for the wrong reason.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
