import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/custom_text_form_field.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/repositories/walletApi.dart';
import 'package:project/models/bank_model.dart';
import 'package:project/provider/bank_details_provider.dart';
import 'package:project/screens/profileScreen/add_edit_bank_screen.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class CreateWithdrawalRequestScreen extends StatefulWidget {
  final double walletBalance;

  const CreateWithdrawalRequestScreen({
    Key? key,
    required this.walletBalance,
  }) : super(key: key);

  @override
  State<CreateWithdrawalRequestScreen> createState() =>
      _CreateWithdrawalRequestScreenState();
}

class _CreateWithdrawalRequestScreenState
    extends State<CreateWithdrawalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingBanks = true;
  List<BankModel> _bankAccounts = [];
  BankModel? _selectedBank;
  bool _hasShownNoBankDialog = false;

  @override
  void initState() {
    super.initState();
    _fetchBankAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchBankAccounts() async {
    setState(() {
      _isLoadingBanks = true;
    });

    try {
      final response = await sendApiRequest(
        apiName: ApiAndParams.apiSellerBankAccounts,
        params: {},
        isPost: false,
      );

      final data = json.decode(response);

      if (data['status'] == 1) {
        List<dynamic> bankList = data['data'] ?? [];
        setState(() {
          _bankAccounts =
              bankList.map((json) => BankModel.fromJson(json)).toList();
          if (_bankAccounts.isNotEmpty) {
            _selectedBank = _bankAccounts.firstWhere(
              (bank) => bank.isDefault,
              orElse: () => _bankAccounts.first,
            );
          }
          _isLoadingBanks = false;
        });
      } else {
        setState(() {
          _isLoadingBanks = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bank accounts: $e');
      setState(() {
        _isLoadingBanks = false;
      });
    }
  }

  Future<void> _submitWithdrawalRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBank == null) {
      showMessage(
        context,
        'Please select a bank account',
        MessageType.warning,
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      showMessage(
        context,
        'Please enter a valid amount',
        MessageType.warning,
      );
      return;
    }

    if (amount > widget.walletBalance) {
      showMessage(
        context,
        'Insufficient balance. Available: ₹${widget.walletBalance.toStringAsFixed(2)}',
        MessageType.error,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await createWithdrawalRequest(
        context: context,
        amount: amount,
        accountNumber: _selectedBank!.accountNumber,
        bankIfscCode: _selectedBank!.ifscCode,
        accountName: _selectedBank!.accountHolderName,
        bankName: _selectedBank!.bankName,
        sellerNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (result != null) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _navigateToAddBank() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => BankDetailsProvider(),
          child: const AddEditBankScreen(bank: null),
        ),
      ),
    );

    if (result == true) {
      await _fetchBankAccounts();
    }
  }

  void _showNoBankAccountBottomSheet() {
    if (_hasShownNoBankDialog) return;
    _hasShownNoBankDialog = true;

    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: ColorsRes.appColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_rounded,
                      color: ColorsRes.appColor,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'No Bank Account',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Message
                  Text(
                    'You need to add a bank account before creating a withdrawal request.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: colorScheme.border,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _navigateToAddBank();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsRes.appColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Add Account',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    if (_isLoadingBanks) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Column(
          children: [
            AppHeader(
              label: "Wallet",
              title: "Withdrawal Request",
              showBackButton: true,
            ),
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: ColorsRes.appColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_bankAccounts.isEmpty && !_hasShownNoBankDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNoBankAccountBottomSheet();
      });
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: "Wallet",
            title: "Withdrawal Request",
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wallet Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ColorsRes.appColor.withValues(alpha: 0.1),
                            const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ColorsRes.appColor.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: ColorsRes.appColor
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: ColorsRes.appColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Available Balance',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.textSecondary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '₹${widget.walletBalance.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: ColorsRes.appColor,
                              letterSpacing: -0.8,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bank Account Selection
                    Text(
                      'Bank Account *',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.border,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ..._bankAccounts.map((bank) {
                            final isSelected = _selectedBank?.id == bank.id;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedBank = bank;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? ColorsRes.appColor
                                          .withValues(alpha: 0.05)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? ColorsRes.appColor
                                              : colorScheme.border,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? ColorsRes.appColor
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  bank.bankName,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        colorScheme.textPrimary,
                                                    letterSpacing: -0.2,
                                                  ),
                                                ),
                                              ),
                                              if (bank.isDefault)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: ColorsRes.appColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    'DEFAULT',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${bank.accountHolderName} • XXXX${bank.accountNumber.substring(bank.accountNumber.length - 4)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.textSecondary,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          // Add Bank Account Button
                          InkWell(
                            onTap: _navigateToAddBank,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: colorScheme.border,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color: ColorsRes.appColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Add New Bank Account',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: ColorsRes.appColor,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Withdrawal Amount
                    CustomTextFormField(
                      title: "Withdrawal Amount *",
                      controller: _amountController,
                      hintText: "Enter amount to withdraw",
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(
                        Icons.currency_rupee,
                        size: 22,
                        color: colorScheme.iconSecondary,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        if (amount > widget.walletBalance) {
                          return 'Amount exceeds available balance';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Note (Optional)
                    CustomTextFormField(
                      title: "Note (Optional)",
                      controller: _noteController,
                      hintText: "Add a note for this withdrawal",
                      maxLines: 3,
                      prefixIcon: Icon(
                        Icons.note_outlined,
                        size: 22,
                        color: colorScheme.iconSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: colorScheme.cardShadow,
        ),
        child: SafeArea(
          child: _isSubmitting
              ? Container(
                  height: 56,
                  decoration: ShapeDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorsRes.gradient1,
                        ColorsRes.gradient2,
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : gradientBtnWidget(
                  context,
                  MediaQuery.of(context).size.width,
                  title: "Submit Request",
                  callback: () => _submitWithdrawalRequest(),
                ),
        ),
      ),
    );
  }
}
