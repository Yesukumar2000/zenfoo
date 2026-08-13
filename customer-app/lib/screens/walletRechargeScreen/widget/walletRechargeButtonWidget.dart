import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class WalletRechargeButtonWidget extends StatefulWidget {
  final BuildContext context;
  final TextEditingController rechargeAmount;

  const WalletRechargeButtonWidget(
      {Key? key, required this.context, required this.rechargeAmount})
      : super(key: key);

  @override
  State<WalletRechargeButtonWidget> createState() =>
      WalletRechargeButtonWidgetState();
}

class WalletRechargeButtonWidgetState
    extends State<WalletRechargeButtonWidget> {
  late double amount = 0.00;

  @override
  void initState() {
    super.initState();
  }

  /// Opens Paytm payment gateway using the SDK
  openWalletPaytmPaymentGateway() async {
    final walletProvider = context.read<WalletRechargeProvider>();
    final paytmConfig = walletProvider.paytmConfig;

    final String sdkAmount = walletProvider.paytmAmount.isNotEmpty
        ? walletProvider.paytmAmount
        : widget.rechargeAmount.text.toString();

    debugPrint('💳 [Wallet-Paytm] openWalletPaytmPaymentGateway() called');
    debugPrint('💳 [Wallet-Paytm] merchantId: ${paytmConfig?.merchantId}');
    debugPrint('💳 [Wallet-Paytm] orderId: ${walletProvider.paytmOrderId}');
    debugPrint('💳 [Wallet-Paytm] amount: $sdkAmount');
    debugPrint('💳 [Wallet-Paytm] isStaging: ${paytmConfig?.isStaging}');

    if (paytmConfig == null || paytmConfig.merchantId == null) {
      debugPrint('❌ [Wallet-Paytm] Config not loaded!');
      showMessage(
          context, 'Paytm configuration not loaded', MessageType.warning);
      walletProvider.setWalletPaymentProcessState(false);
      return;
    }

    try {
      final String callbackUrl = paytmConfig.isStaging
          ? "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=${walletProvider.paytmOrderId}"
          : (paytmConfig.callbackUrl ??
              "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=${walletProvider.paytmOrderId}");

      debugPrint('💳 [Wallet-Paytm] Launching Paytm SDK...');

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
        debugPrint('💳 [Wallet-Paytm] SDK Response: $value');

        if (value != null) {
          value.forEach((key, val) {
            debugPrint('💳 [Wallet-Paytm] $key: $val');
          });

          String status = value['STATUS']?.toString() ?? '';
          String txnId = value['TXNID']?.toString() ?? '';

          if (status == 'TXN_SUCCESS' && txnId.isNotEmpty) {
            debugPrint(
                '💳 [Wallet-Paytm] Payment SUCCESS - Verifying...');

            // Step 3: Verify payment
            bool verified = await walletProvider.verifyWalletPaytmPayment(
              context: context,
              paymentTransactionId: walletProvider.paytmOrderId,
            );

            if (verified) {
              debugPrint(
                  '💳 [Wallet-Paytm] Verified - Crediting wallet...');

              // Step 4: Credit wallet balance
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
              }
            } else {
              walletProvider.setWalletPaymentProcessState(false);
            }
          } else {
            debugPrint(
                '❌ [Wallet-Paytm] Payment failed - STATUS: $status');
            walletProvider.setWalletPaymentProcessState(false);
            showMessage(
              context,
              value['RESPMSG']?.toString() ??
                  'Payment failed. Please try again.',
              MessageType.warning,
            );
          }
        } else {
          debugPrint('❌ [Wallet-Paytm] SDK returned null');
          walletProvider.setWalletPaymentProcessState(false);
          showMessage(
              context, 'Payment cancelled or failed', MessageType.warning);
        }
      }).catchError((onError) {
        debugPrint('❌ [Wallet-Paytm] SDK error: $onError');
        walletProvider.setWalletPaymentProcessState(false);
        String errorMessage = 'Payment failed. Please try again.';
        if (onError is PlatformException) {
          errorMessage = onError.message ?? errorMessage;
        }
        showMessage(context, errorMessage, MessageType.warning);
      });
    } catch (err) {
      debugPrint('❌ [Wallet-Paytm] Exception: $err');
      walletProvider.setWalletPaymentProcessState(false);
      showMessage(
          context, 'Failed to open payment gateway', MessageType.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<WalletRechargeProvider>(
      builder: (context, walletRechargeProvider, child) {
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: walletRechargeProvider.isPaymentUnderProcessing
                ? null
                : () async {
                    HapticFeedback.lightImpact();

                    if (widget.rechargeAmount.text.toString().toDouble >
                        Constant.maximumWalletRechargeAmount) {
                      showMessage(
                          context,
                          "Maximum recharge amount is ${Constant.maximumWalletRechargeAmount.toStringAsFixed(0).currency}",
                          MessageType.warning);
                      return;
                    }

                    if (widget.rechargeAmount.text.isNotEmpty &&
                        amountValidation(widget.rechargeAmount.text) ==
                            null &&
                        !walletRechargeProvider.isPaymentUnderProcessing) {
                      walletRechargeProvider
                          .setWalletPaymentProcessState(true)
                          .then(
                        (value) async {
                          amount = widget.rechargeAmount.text
                              .toString()
                              .toDouble;

                          // Paytm Payment Flow
                          bool initiated = await walletRechargeProvider
                              .initiateWalletPaytmTransactionNew(
                            context: context,
                            rechargeAmount:
                                widget.rechargeAmount.text.toString(),
                          );

                          if (initiated) {
                            openWalletPaytmPaymentGateway();
                          }
                        },
                      );
                    } else {
                      showMessage(
                          context,
                          getTranslatedValue(context, enterValidAmountLabel)
                              .toString(),
                          MessageType.warning);
                    }
                  },
            style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.buttonPrimaryText,
                disabledBackgroundColor:
                    colorScheme.primary.withValues(alpha: 0.5),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: walletRechargeProvider.isPaymentUnderProcessing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: colorScheme.buttonPrimaryText,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        getTranslatedValue(context, rechargeLabel)
                            .toUpperCase(),
                        style: GoogleFonts.inter(
                          color: colorScheme.buttonPrimaryText,
                          fontSize: 17,
                          letterSpacing: -0.3,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: colorScheme.buttonPrimaryText,
                        size: 22,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
