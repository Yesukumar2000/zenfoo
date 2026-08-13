import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';

class PaymentMethodsWidget extends StatefulWidget {
  final bool isPaymentUnderProcessing;
  final double? totalAmount;

  const PaymentMethodsWidget({
    super.key,
    required this.isPaymentUnderProcessing,
    this.totalAmount,
  });

  @override
  State<PaymentMethodsWidget> createState() => _PaymentMethodsWidgetState();
}

class _PaymentMethodsWidgetState extends State<PaymentMethodsWidget> {
  // Open Paytm payment gateway
  Future<void> _openPaytmGateway() async {
    if (!mounted) return;
    final checkoutProvider = context.read<CheckoutProvider>();
    final paytmConfig = checkoutProvider.paytmConfig;
    // Must match the canonical 2-decimal form the backend used to sign the
    // checksum — otherwise the Paytm gateway aborts with "session expired".
    final num parsedAmount = num.tryParse(checkoutProvider.paytmAmount) ??
        checkoutProvider.totalAmount;
    final String sdkAmount = parsedAmount.toStringAsFixed(2);

    if (paytmConfig == null || paytmConfig.merchantId == null) {
      if (mounted) showMessage(context, 'Paytm configuration not loaded', MessageType.warning);
      checkoutProvider.setPaymentProcessState(false);
      return;
    }

    try {
      // Prefer the backend-issued callback URL (it's what the server used when
      // signing the checksum). Fall back to Paytm's current hosted callback on
      // the new paytmpayments.com domain — the legacy paytm.in host is no
      // longer accepted by the new SDK and causes immediate "session expired".
      final String callbackUrl = paytmConfig.callbackUrl?.isNotEmpty == true
          ? paytmConfig.callbackUrl!
          : (paytmConfig.isStaging
              ? "https://securestage.paytmpayments.com/theia/paytmCallback?ORDER_ID=${checkoutProvider.paytmOrderId}"
              : "https://secure.paytmpayments.com/theia/paytmCallback?ORDER_ID=${checkoutProvider.paytmOrderId}");

      debugPrint('💳 [Paytm] startTransaction → mid=${paytmConfig.merchantId}, '
          'orderId=${checkoutProvider.paytmOrderId}, amount=$sdkAmount, '
          'txnToken=${checkoutProvider.paytmTxnToken}, '
          'isStaging=${paytmConfig.isStaging}, callbackUrl=$callbackUrl');

      // When the Paytm consumer app is installed, the SDK delegates to it
      // unless we restrict the app-invoke. The consumer app rejects staging
      // tokens with "Your Session has expired" — so force the SDK's own UI
      // on staging. In production, allow handoff for the smoother UX.
      final bool restrictAppInvoke = paytmConfig.isStaging;

      // From here the gateway owns the screen. If it never calls us back (the
      // SDK stays silent when the user backs out), the checkout screen uses
      // this flag on app resume to recover instead of staying locked.
      checkoutProvider.setAwaitingPaytmResult(true);

      final response = PaytmPaymentsAllinonesdk().startTransaction(
        paytmConfig.merchantId!,
        checkoutProvider.paytmOrderId,
        sdkAmount,
        checkoutProvider.paytmTxnToken,
        callbackUrl,
        paytmConfig.isStaging,
        restrictAppInvoke,
      );

      response.then((value) async {
        debugPrint('💳 [Paytm] SDK response: $value');
        checkoutProvider.setAwaitingPaytmResult(false);
        if (!mounted) {
          // Screen is gone — at minimum don't leave the flag stuck on.
          if (value?['STATUS']?.toString() != 'TXN_SUCCESS') {
            checkoutProvider.setPaymentProcessState(false);
          }
          return;
        }
        if (value != null) {
          final String status = value['STATUS']?.toString() ?? '';
          final String txnId = value['TXNID']?.toString() ?? '';

          if (status == 'TXN_SUCCESS' && txnId.isNotEmpty) {
            final bool verified = await checkoutProvider.verifyPaytmPayment(
              context: context,
              paymentTransactionId: checkoutProvider.paytmOrderId,
            );
            if (!mounted) return;
            if (verified) {
              await checkoutProvider.placeOrderWithPaytm(
                context: context,
                paymentTransactionId: checkoutProvider.paytmOrderId,
              );
            } else {
              checkoutProvider.setPaymentProcessState(false);
            }
          } else {
            checkoutProvider.setPaymentProcessState(false);
            if (mounted) {
              showMessage(
                context,
                value['RESPMSG']?.toString() ?? 'Payment failed. Please try again.',
                MessageType.warning,
              );
            }
          }
        } else {
          checkoutProvider.setPaymentProcessState(false);
          if (mounted) showMessage(context, 'Payment cancelled or failed', MessageType.warning);
        }
      }).catchError((onError) {
        debugPrint('💳 [Paytm] SDK error: $onError');
        if (onError is PlatformException) {
          debugPrint('💳 [Paytm] PlatformException — code=${onError.code}, '
              'message=${onError.message}, details=${onError.details}');
        }
        checkoutProvider.setAwaitingPaytmResult(false);
        checkoutProvider.setPaymentProcessState(false);
        if (!mounted) return;
        String errorMessage = 'Payment failed. Please try again.';
        if (onError is PlatformException) {
          errorMessage = onError.message ?? errorMessage;
        }
        showMessage(context, errorMessage, MessageType.warning);
      });
    } catch (err, stack) {
      debugPrint('💳 [Paytm] startTransaction threw: $err\n$stack');
      checkoutProvider.setAwaitingPaytmResult(false);
      checkoutProvider.setPaymentProcessState(false);
      if (mounted) showMessage(context, 'Failed to open payment gateway', MessageType.warning);
    }
  }

  Future<void> _handleOnlinePayNow() async {
    if (!mounted) return;
    final checkoutProvider = context.read<CheckoutProvider>();

    if (checkoutProvider.isPaymentUnderProcessing) return;

    if (checkoutProvider.selectedAddress == null) {
      showMessage(context, getTranslatedValue(context, addAddressFirstLabel), MessageType.warning);
      return;
    }

    checkoutProvider.setOrderType("0");
    checkoutProvider.selectedOrderType = "0";

    await checkoutProvider.setPaymentProcessState(true);
    if (!mounted) return;

    bool success = false;
    try {
      success =
          await checkoutProvider.initiatePaytmTransaction(context: context);
    } catch (e) {
      debugPrint('💳 [Paytm] initiatePaytmTransaction threw: $e');
    }

    if (!mounted || success != true) {
      // Never leave the overlay up when the gateway was never reached.
      await checkoutProvider.setPaymentProcessState(false);
      return;
    }

    await _openPaytmGateway();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    return Consumer<PaymentMethodsProvider>(
      builder: (context, provider, child) {
        if (provider.paymentMethodsState == PaymentMethodsState.loaded) {
          final bool hasOnlinePayment =
              provider.paymentMethodsData?.paytmPaymentMethod == "1" ||
              provider.paymentMethodsData?.phonePePaymentMethod == "1";
          final bool hasCod =
              provider.paymentMethodsData?.codPaymentMethod == "1" &&
              provider.isCodAllowed == "1";

          if (!hasOnlinePayment && !hasCod) return SizedBox.shrink();

          return Consumer<CheckoutProvider>(
            builder: (context, checkoutProvider, _) {
              final billingSummary =
                  checkoutProvider.deliveryChargeData?.billingSummary;
              final double gatewayFees =
                  (billingSummary?.paymentGatewayFees as num?)?.toDouble() ?? 0;
              final double gatewayFeesPercent =
                  (billingSummary?.paymentGatewayFeesPercent as num?)
                          ?.toDouble() ??
                      0;
              final String currencySymbol = billingSummary?.currency ?? '₹';
              final bool showGatewayFeeNote = gatewayFeesPercent > 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Online Payment option
                      if (hasOnlinePayment)
                        _buildPaymentOption(
                          icon: Icons.payment_outlined,
                          iconColor: const Color(0xFF1A73E8),
                          title: 'Online Payment',
                          subtitle: 'UPI, Cards, Net Banking',
                          isSelected: provider.selectedPaymentMethod == "Paytm",
                          isProcessing: checkoutProvider.isPaymentUnderProcessing,
                          amount: widget.totalAmount,
                          onTap: () async {
                            await provider.setSelectedPaymentMethod('Paytm');
                            if (context.mounted) {
                              await context
                                  .read<CheckoutProvider>()
                                  .refreshChargesForPaymentMethod(
                                      context, 'Paytm');
                            }
                          },
                          onPayNow: _handleOnlinePayNow,
                          colorScheme: colorScheme,
                        ),

                      // Payment Gateway Fee notice (shown only when online is the
                      // selected method and a fee is configured)
                      if (hasOnlinePayment &&
                          showGatewayFeeNote &&
                          provider.selectedPaymentMethod == "Paytm")
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: colorScheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'A payment gateway fee of ${gatewayFeesPercent.toStringAsFixed(gatewayFeesPercent % 1 == 0 ? 0 : 2)}% '
                                  '($currencySymbol${gatewayFees.toStringAsFixed(2)}) '
                                  'is included for online payments. Choose Cash on Delivery to avoid this charge.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: colorScheme.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Divider between options
                      if (hasOnlinePayment && hasCod)
                        const SizedBox(height: 10),

                      // Cash on Delivery option
                      if (hasCod)
                        _buildPaymentOption(
                          icon: Icons.local_atm_outlined,
                          iconColor: const Color(0xFF4CAF50),
                          title: 'Cash on Delivery',
                          subtitle: 'Pay when you receive',
                          isSelected: provider.selectedPaymentMethod == "COD",
                          isProcessing: false,
                          amount: null,
                          onTap: () async {
                            await provider.setSelectedPaymentMethod('COD');
                            if (context.mounted) {
                              await context
                                  .read<CheckoutProvider>()
                                  .refreshChargesForPaymentMethod(
                                      context, 'COD');
                            }
                          },
                          onPayNow: null,
                          colorScheme: colorScheme,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        } else if (provider.paymentMethodsState == PaymentMethodsState.loading) {
          return Container(
            margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.border, width: 1),
              boxShadow: colorScheme.cardShadow,
            ),
            child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool isSelected,
    required bool isProcessing,
    required double? amount,
    required VoidCallback onTap,
    required VoidCallback? onPayNow,
    required AppColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Radio button
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : colorScheme.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Title & subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pay button — shown only when selected and amount provided
          if (isSelected && amount != null && onPayNow != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: isProcessing ? null : onPayNow,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: isProcessing
                      ? colorScheme.primary.withValues(alpha: 0.5)
                      : colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isProcessing
                    ? Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.buttonPrimaryText),
                          ),
                        ),
                      )
                    : Text(
                        'Pay ₹${amount.toStringAsFixed(0)}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.buttonPrimaryText,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
