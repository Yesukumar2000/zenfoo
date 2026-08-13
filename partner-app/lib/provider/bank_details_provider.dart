import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/bank_model.dart';
import 'package:http/http.dart' as http;

class BankDetailsProvider extends ChangeNotifier {
  List<BankModel> _bankAccounts = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Form controllers
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController ifscCodeController = TextEditingController();
  final TextEditingController accountHolderNameController =
      TextEditingController();

  File? _documentFile;
  String? _documentUrl;
  String? _documentType;

  // For debouncing IFSC auto-fetch
  Timer? _debounceTimer;
  bool _isAutoFetching = false;

  List<BankModel> get bankAccounts => _bankAccounts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  File? get documentFile => _documentFile;
  String? get documentUrl => _documentUrl;
  String? get documentType => _documentType;

  void setDocument(File? file, String? type) {
    _documentFile = file;
    _documentType = type;
    notifyListeners();
  }

  void clearDocument() {
    _documentFile = null;
    _documentUrl = null;
    _documentType = null;
    notifyListeners();
  }

  void initializeIFSCListener(BuildContext context) {
    ifscCodeController.addListener(() {
      final ifscCode = ifscCodeController.text.trim().toUpperCase();

      // Cancel previous timer
      _debounceTimer?.cancel();

      // If IFSC is cleared, clear bank name too
      if (ifscCode.isEmpty) {
        if (_isAutoFetching) {
          bankNameController.clear();
        }
        return;
      }

      // Check if IFSC code matches the pattern (11 characters)
      if (ifscCode.length == 11) {
        final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
        if (ifscRegex.hasMatch(ifscCode)) {
          // Valid IFSC - Start a new timer for auto-fetch
          _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
            // Only auto-fetch if the bank name is empty or was auto-fetched before
            if (bankNameController.text.isEmpty || _isAutoFetching) {
              _isAutoFetching = true;
              fetchIFSCDetails(context, silentMode: true);
            }
          });
        } else {
          // Invalid IFSC format - Show error after debounce
          _debounceTimer = Timer(const Duration(milliseconds: 800), () {
            if (_isAutoFetching) {
              bankNameController.clear();
            }
            showMessage(context, 'Invalid IFSC', MessageType.warning);
          });
        }
      }
    });
  }

  void clearForm() {
    _debounceTimer?.cancel();
    _isAutoFetching = false;
    bankNameController.clear();
    accountNumberController.clear();
    ifscCodeController.clear();
    accountHolderNameController.text =
        Constant.session.getData(SessionManager.name);
    clearDocument();
  }

  void populateForm(BankModel bank) {
    bankNameController.text = bank.bankName;
    accountNumberController.text = bank.accountNumber;
    ifscCodeController.text = bank.ifscCode;
    accountHolderNameController.text = bank.accountHolderName;
    _documentUrl = bank.documentUrl;
    _documentType = bank.documentType;
    notifyListeners();
  }

  String? validateForm() {
    if (bankNameController.text.trim().isEmpty) {
      return 'Please enter bank name';
    }
    if (accountNumberController.text.trim().isEmpty) {
      return 'Please enter account number';
    }
    if (ifscCodeController.text.trim().isEmpty) {
      return 'Please enter IFSC code';
    }
    // IFSC code validation: 11 characters, alphanumeric
    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    if (!ifscRegex.hasMatch(ifscCodeController.text.trim().toUpperCase())) {
      return 'Invalid IFSC code format';
    }
    if (accountHolderNameController.text.trim().isEmpty) {
      return 'Please enter account holder name';
    }
    return null;
  }

  Future<bool> fetchIFSCDetails(BuildContext context,
      {bool silentMode = false}) async {
    if (ifscCodeController.text.isEmpty) {
      if (!silentMode) {
        showMessage(context, 'Please enter IFSC code', MessageType.warning);
      }
      return false;
    }

    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    if (!ifscRegex.hasMatch(ifscCodeController.text.trim().toUpperCase())) {
      if (!silentMode) {
        showMessage(context, 'Invalid IFSC code format', MessageType.warning);
      }
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse(
                'https://ifsc.razorpay.com/${ifscCodeController.text.trim().toUpperCase()}'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['BANK'] != null) {
          bankNameController.text = data['BANK'];
          if (!silentMode) {
            showMessage(context, 'Bank details fetched successfully',
                MessageType.success);
          }
          return true;
        } else {
          if (!silentMode) {
            showMessage(context, 'Bank not found for this IFSC code',
                MessageType.error);
          }
          return false;
        }
      } else if (response.statusCode == 404) {
        if (!silentMode) {
          showMessage(context, 'IFSC code not found', MessageType.error);
        }
        return false;
      } else {
        if (!silentMode) {
          showMessage(
              context, 'Failed to fetch bank details', MessageType.error);
        }
        return false;
      }
    } catch (e) {
      if (!silentMode) {
        showMessage(context, 'Error: ${e.toString()}', MessageType.error);
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBankAccounts(String? storeId) async {
    if (storeId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> params = {};

      final res = await sendApiRequest(
        apiName: ApiAndParams.apiSellerBankAccounts,
        params: params,
        isPost: false,
      );

      final response = jsonDecode(res);

      if (response['status'] == 1 || response['status'] == '1') {
        List<dynamic> data = response['data'] ?? [];
        _bankAccounts = data.map((json) => BankModel.fromJson(json)).toList();
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch bank accounts';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBankAccount(BuildContext context, String? storeId) async {
    if (storeId == null) return false;

    final validationError = validateForm();
    if (validationError != null) {
      showMessage(context, validationError, MessageType.warning);
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      Map<String, dynamic> params = {
        'bank_name': bankNameController.text.trim(),
        'account_number': accountNumberController.text.trim(),
        'ifsc_code': ifscCodeController.text.trim().toUpperCase(),
        'account_holder_name': accountHolderNameController.text.trim(),
      };

      if (_documentType != null) {
        params['document_type'] = _documentType;
      }

      Map<String, dynamic> response;

      // If there's a document file, use multipart request
      if (_documentFile != null) {
        Map<String, File> filesMap = {
          'document': _documentFile!,
        };

        response = await sendApiMultiPartRequest(
          apiName: ApiAndParams.apiSellerBankAccounts,
          params: params,
          filesMap: filesMap,
        );
      } else {
        final res = await sendApiRequest(
          apiName: ApiAndParams.apiSellerBankAccounts,
          params: params,
          isPost: true,
        );
        response = jsonDecode(res);
      }

      if (response['status'] == 1 || response['status'] == '1') {
        showMessage(
            context, 'Bank account added successfully', MessageType.success);
        clearForm();
        await fetchBankAccounts(storeId);
        return true;
      } else {
        showMessage(
            context,
            response['message'] ?? 'Failed to add bank account',
            MessageType.error);
        return false;
      }
    } catch (e) {
      showMessage(context, 'Error: ${e.toString()}', MessageType.error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBankAccount(
      BuildContext context, String? storeId, String bankId) async {
    if (storeId == null) return false;

    final validationError = validateForm();
    if (validationError != null) {
      showMessage(context, validationError, MessageType.warning);
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      Map<String, dynamic> params = {
        'bank_name': bankNameController.text.trim(),
        'account_number': accountNumberController.text.trim(),
        'ifsc_code': ifscCodeController.text.trim().toUpperCase(),
        'account_holder_name': accountHolderNameController.text.trim(),
        '_method': 'POST', // Laravel POST method for update
      };

      if (_documentType != null) {
        params['document_type'] = _documentType;
      }

      Map<String, dynamic> response;

      // If there's a document file, use multipart request
      if (_documentFile != null) {
        Map<String, File> filesMap = {
          'document': _documentFile!,
        };

        response = await sendApiMultiPartRequest(
          apiName: '${ApiAndParams.apiSellerBankAccountUpdate}/$bankId',
          params: params,
          filesMap: filesMap,
        );
      } else {
        final res = await sendApiRequest(
          apiName: '${ApiAndParams.apiSellerBankAccountUpdate}/$bankId',
          params: params,
          isPost: true,
        );
        response = jsonDecode(res);
      }

      if (response['status'] == 1 || response['status'] == '1') {
        showMessage(
            context, 'Bank account updated successfully', MessageType.success);
        clearForm();
        await fetchBankAccounts(storeId);
        return true;
      } else {
        showMessage(
            context,
            response['message'] ?? 'Failed to update bank account',
            MessageType.error);
        return false;
      }
    } catch (e) {
      showMessage(context, 'Error: ${e.toString()}', MessageType.error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBankAccount(
      BuildContext context, String? storeId, String bankId) async {
    if (storeId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      Map<String, dynamic> params = {};

      final res = await sendApiRequest(
        apiName: '${ApiAndParams.apiSellerBankAccountDelete}/$bankId',
        params: params,
        isPost: false,
        isDelete: true,
      );

      final response = jsonDecode(res);

      if (response['status'] == 1 || response['status'] == '1') {
        showMessage(
            context, 'Bank account deleted successfully', MessageType.success);
        await fetchBankAccounts(storeId);
        return true;
      } else {
        showMessage(
            context,
            response['message'] ?? 'Failed to delete bank account',
            MessageType.error);
        return false;
      }
    } catch (e) {
      showMessage(context, 'Error: ${e.toString()}', MessageType.error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setDefaultBankAccount(
      BuildContext context, String? storeId, String bankId) async {
    if (storeId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      Map<String, dynamic> params = {};

      final res = await sendApiRequest(
        apiName:
            '${ApiAndParams.apiSellerBankAccountSetDefault}/$bankId/set-default',
        params: params,
        isPost: true,
      );

      final response = jsonDecode(res);

      if (response['status'] == 1 || response['status'] == '1') {
        showMessage(context, 'Default bank account set successfully',
            MessageType.success);
        await fetchBankAccounts(storeId);
        return true;
      } else {
        showMessage(
            context,
            response['message'] ?? 'Failed to set default bank account',
            MessageType.error);
        return false;
      }
    } catch (e) {
      showMessage(context, 'Error: ${e.toString()}', MessageType.error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    bankNameController.dispose();
    accountNumberController.dispose();
    ifscCodeController.dispose();
    accountHolderNameController.dispose();
    super.dispose();
  }
}
