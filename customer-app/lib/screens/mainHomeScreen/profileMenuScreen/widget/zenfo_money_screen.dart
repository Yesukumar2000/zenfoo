import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/styles/appColorScheme.dart';

class ZenfooMoneyScreen extends StatelessWidget {
  const ZenfooMoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: getTranslatedValue(context, 'wallet_management'),
          title: getTranslatedValue(context, 'zenfoo_money'),
          showBackButton: true,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                // decoration: BoxDecoration(
                //   gradient: LinearGradient(
                //     begin: Alignment.topCenter,
                //     end: Alignment.bottomCenter,
                //     colors: [
                //       colorScheme.primary.withValues(alpha: 0.15),
                //       colorScheme.background,
                //     ],
                //     stops: const [0.0, 0.3],
                //   ),
                // ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Image.asset(
                        'assets/images/zenfoo_money_wallet.png',
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        getTranslatedValue(context, 'zenfoo_money'),
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.textPrimary,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        getTranslatedValue(context, 'zenfoo_money_tagline'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: colorScheme.textSecondary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _MoneyFeatureTile(
                      iconPath: 'assets/images/zenfoo_money_add.png',
                      title: getTranslatedValue(context, 'add_money'),
                      description:
                          getTranslatedValue(context, 'add_money_description'),
                    ),
                    const SizedBox(height: 12),
                    _MoneyFeatureTile(
                      iconPath: 'assets/images/zenfoo_money_quick.png',
                      title: getTranslatedValue(context, 'quick_payments'),
                      description: getTranslatedValue(
                          context, 'quick_payments_description'),
                    ),
                    const SizedBox(height: 12),
                    _MoneyFeatureTile(
                      iconPath: 'assets/images/zenfoo_money_track.png',
                      title: getTranslatedValue(context, 'track_transactions'),
                      description: getTranslatedValue(
                          context, 'track_transactions_description'),
                    ),
                    const SizedBox(height: 12),
                    _MoneyFeatureTile(
                      iconPath: 'assets/images/zenfoo_money_zero.png',
                      title: getTranslatedValue(context, 'zero_failures'),
                      description: getTranslatedValue(
                          context, 'zero_failures_description'),
                    ),
                    const SizedBox(height: 12),
                    _MoneyFeatureTile(
                      iconPath: 'assets/images/zenfoo_money_refund.png',
                      title: getTranslatedValue(context, 'real_time_refunds'),
                      description: getTranslatedValue(
                          context, 'real_time_refunds_description'),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChangeNotifierProvider<WalletRechargeProvider>(
                          create: (_) => WalletRechargeProvider(),
                          child: const AddMoneyScreen(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    getTranslatedValue(context, 'add_money_to_wallet'),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.buttonPrimaryText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        colorScheme.buttonPrimaryText.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          colorScheme.buttonPrimaryText.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colorScheme.buttonPrimaryText,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                getTranslatedValue(context, 'zenfoo_money'),
                style: GoogleFonts.inter(
                  color: colorScheme.buttonPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneyFeatureTile extends StatelessWidget {
  final String iconPath;
  final String title;
  final String description;

  const _MoneyFeatureTile({
    required this.iconPath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.border, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: colorScheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              iconPath,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: colorScheme.textSecondary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: "1000");
  final FocusNode _amountFocusNode = FocusNode();
  final List<int> _presets = [500, 1000, 2000, 5000];
  int? _selectedPreset = 1000;

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  int get _amount =>
      int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

  void _onPresetTap(int value) {
    setState(() {
      _selectedPreset = value;
      _amountController.text = value.toString();
      _amountFocusNode.unfocus();
    });
  }

  void _onCustomAmountChanged(String value) {
    setState(() {
      _selectedPreset = null; // Deselect presets when typing custom amount
    });
  }

  bool _isProcessing = false;

  void _onAddPaymentMethod() async {
    if (_amount <= 0) return;
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final walletProvider = context.read<WalletRechargeProvider>();
    await walletProvider.setWalletPaymentProcessState(true);

    bool initiated = await walletProvider.initiateWalletPaytmTransactionNew(
      context: context,
      rechargeAmount: _amount.toString(),
    );

    if (initiated) {
      _openWalletPaytmPaymentGateway();
    } else {
      setState(() => _isProcessing = false);
    }
  }

  void _openWalletPaytmPaymentGateway() async {
    final walletProvider = context.read<WalletRechargeProvider>();
    final paytmConfig = walletProvider.paytmConfig;
    final String sdkAmount = walletProvider.paytmAmount.isNotEmpty
        ? walletProvider.paytmAmount
        : _amount.toString();

    if (paytmConfig == null || paytmConfig.merchantId == null) {
      showMessage(
          context, 'Paytm configuration not loaded', MessageType.warning);
      walletProvider.setWalletPaymentProcessState(false);
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final String callbackUrl = paytmConfig.isStaging
          ? "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=${walletProvider.paytmOrderId}"
          : (paytmConfig.callbackUrl ??
              "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=${walletProvider.paytmOrderId}");

      var response = PaytmPaymentsAllinonesdk().startTransaction(
        paytmConfig.merchantId!,
        walletProvider.paytmOrderId,
        sdkAmount,
        walletProvider.paytmTxnToken,
        callbackUrl,
        paytmConfig.isStaging,
        true,
      );

      response.then((value) async {
        if (value != null) {
          String status = value['STATUS']?.toString() ?? '';
          String txnId = value['TXNID']?.toString() ?? '';

          if (status == 'TXN_SUCCESS' && txnId.isNotEmpty) {
            bool verified = await walletProvider.verifyWalletPaytmPayment(
              context: context,
              paymentTransactionId: walletProvider.paytmOrderId,
            );

            if (verified) {
              bool credited = await walletProvider.creditWalletBalance(
                context: context,
                amount: sdkAmount,
                paymentTransactionId: walletProvider.paytmOrderId,
              );

              if (credited) {
                showMessage(
                  context,
                  'Wallet recharged successfully!',
                  MessageType.success,
                );
                Navigator.pop(context, true);
                return;
              }
            }
          } else {
            showMessage(
              context,
              value['RESPMSG']?.toString() ??
                  'Payment failed. Please try again.',
              MessageType.warning,
            );
          }
        } else {
          showMessage(
              context, 'Payment cancelled or failed', MessageType.warning);
        }
        walletProvider.setWalletPaymentProcessState(false);
        setState(() => _isProcessing = false);
      }).catchError((onError) {
        walletProvider.setWalletPaymentProcessState(false);
        setState(() => _isProcessing = false);
        String errorMessage = 'Payment failed. Please try again.';
        if (onError is PlatformException) {
          errorMessage = onError.message ?? errorMessage;
        }
        showMessage(context, errorMessage, MessageType.warning);
      });
    } catch (err) {
      walletProvider.setWalletPaymentProcessState(false);
      setState(() => _isProcessing = false);
      showMessage(
          context, 'Failed to open payment gateway', MessageType.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: getTranslatedValue(context, 'wallet_management'),
          title: getTranslatedValue(context, 'zenfoo_money'),
          showBackButton: true,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // Balance card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: ShapeDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            colorScheme.primaryDark,
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        shadows: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getTranslatedValue(context, 'current_balance'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Consumer<SessionManager>(
                            builder: (_, sessionManager, __) {
                              final bal =
                                  "${sessionManager.getData(SessionManager.keyWalletBalance)}"
                                      .currency;
                              return Text(
                                bal,
                                style: GoogleFonts.inter(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        getTranslatedValue(context, 'quick_add'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _presets.map((value) {
                        final isSelected = _selectedPreset == value;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _onPresetTap(value);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.borderStrong,
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              "₹$value",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? colorScheme.buttonPrimaryText
                                    : colorScheme.textSecondary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        getTranslatedValue(context, 'or_enter_custom_amount'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.inputBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _amountFocusNode.hasFocus
                              ? colorScheme.inputBorderFocused
                              : colorScheme.inputBorder,
                          width: _amountFocusNode.hasFocus ? 2 : 1,
                        ),
                        boxShadow: [
                          if (_amountFocusNode.hasFocus)
                            BoxShadow(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: TextField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: _onCustomAmountChanged,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                        decoration: InputDecoration(
                          hintText: "₹1000",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.inputPlaceholder,
                            letterSpacing: -0.5,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(
                              left: 24,
                            ),
                            child: Text(
                              "₹",
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFFF9E6),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                              color: Color(0xFFFFE082), width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Color(0xFFF57C00),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                getTranslatedValue(context, 'important'),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF57C00),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _bulletText(
                            getTranslatedValue(context, 'money_expiry_note'),
                            const Color(0xFF795548),
                          ),
                          _bulletText(
                            getTranslatedValue(context, 'money_usage_note'),
                            const Color(0xFF795548),
                          ),
                          _bulletText(
                            getTranslatedValue(context, 'money_transfer_note'),
                            const Color(0xFF795548),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "•  ",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF795548),
                                  height: 1.4,
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    // open T&C
                                  },
                                  child: Text(
                                    getTranslatedValue(
                                        context, 'terms_and_conditions'),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1565C0),
                                      decoration: TextDecoration.underline,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: (_amount > 0 && !_isProcessing)
                      ? () {
                          HapticFeedback.lightImpact();
                          _onAddPaymentMethod();
                        }
                      : null,
                  icon: _isProcessing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: colorScheme.buttonPrimaryText,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(Icons.add_circle_outline,
                          color: colorScheme.buttonPrimaryText, size: 20),
                  label: Text(
                    _isProcessing
                        ? getTranslatedValue(context, 'processing')
                        : getTranslatedValue(context, 'add_payment_method'),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.buttonPrimaryText,
                      letterSpacing: -0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    disabledBackgroundColor:
                        colorScheme.buttonDisabledBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.borderStrong,
                  width: 1,
                ),
                boxShadow: colorScheme.cardShadow,
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: colorScheme.iconPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            getTranslatedValue(context, 'zenfoo_money'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.textPrimary,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletText(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "•  ",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: color,
              height: 1.4,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
