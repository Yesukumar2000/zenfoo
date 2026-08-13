import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:project/provider/cartProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

/// Lets the customer choose how much of their wallet balance to spend on this
/// order. Closing it without a choice leaves the wallet as it was.
Future<void> showWalletAmountBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const WalletAmountBottomSheet(),
  );
}

class WalletAmountBottomSheet extends StatefulWidget {
  const WalletAmountBottomSheet({Key? key}) : super(key: key);

  @override
  State<WalletAmountBottomSheet> createState() =>
      _WalletAmountBottomSheetState();
}

class _WalletAmountBottomSheetState extends State<WalletAmountBottomSheet> {
  late final TextEditingController _amountController;
  late final double _maxAmount;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final cartProvider = context.read<CartProvider>();
    _maxAmount = cartProvider.maxUsableWalletAmount;

    final current = cartProvider.walletAmountToUse;
    _amountController = TextEditingController(
      text: current == null ? '' : _trimZeros(current),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  static String _trimZeros(double value) {
    final text = value.toStringAsFixed(2);
    return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
  }

  Future<void> _apply(double? amount) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    await context.read<CartProvider>().setWalletAmount(context, amount);

    if (mounted) Navigator.pop(context);
  }

  void _onApplyPressed() {
    final raw = _amountController.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Enter an amount');
      return;
    }

    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }

    if (amount > _maxAmount) {
      setState(() =>
          _error = 'You can use at most ₹${_maxAmount.toStringAsFixed(2)}');
      return;
    }

    _apply(amount);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final cartProvider = context.watch<CartProvider>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.border.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Use Wallet Balance',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Available ₹${cartProvider.userBalance.toStringAsFixed(2)} · '
                'up to ₹${_maxAmount.toStringAsFixed(2)} usable on this order',
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.2,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                enabled: !_isSaving,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: _trimZeros(_maxAmount),
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.textSecondary.withValues(alpha: 0.5),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  errorText: _error,
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: colorScheme.primary, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _isSaving ? null : _onApplyPressed(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _onApplyPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.buttonPrimaryText,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.buttonPrimaryText,
                          ),
                        )
                      : Text(
                          'Apply',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _isSaving ? null : () => _apply(null),
                  child: Text(
                    'Use maximum (₹${_maxAmount.toStringAsFixed(2)})',
                    style: GoogleFonts.inter(
                      color: colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
