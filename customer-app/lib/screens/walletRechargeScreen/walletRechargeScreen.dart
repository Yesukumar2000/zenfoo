import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/keyboardOverlay.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/styles/appColorScheme.dart';

class WalletRechargeScreen extends StatefulWidget {
  const WalletRechargeScreen({super.key});

  @override
  State<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

/// Blocks any input that is not a valid amount or that exceeds [maxAmount].
class _MaxAmountInputFormatter extends TextInputFormatter {
  final double maxAmount;

  const _MaxAmountInputFormatter(this.maxAmount);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final String text = newValue.text;
    if (text.isEmpty) return newValue;

    // Digits with at most one decimal point and two decimals
    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text)) return oldValue;

    // Allow a trailing "." while the user is still typing
    final String normalized = text.endsWith('.')
        ? text.substring(0, text.length - 1)
        : text;
    if (normalized.isEmpty) return newValue;

    final double? value = double.tryParse(normalized);
    if (value == null || value > maxAmount) return oldValue;

    return newValue;
  }
}

class _WalletRechargeScreenState extends State<WalletRechargeScreen> {
  final TextEditingController rechargeAmount = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final List<int> _presets = [100, 200, 500, 1000, 2000, 5000];
  int? _selectedPreset;

  @override
  void initState() {
    focusNode.addListener(() {
      bool hasFocus = focusNode.hasFocus;
      if (hasFocus) {
        KeyboardOverlay.showOverlay(context);
      } else {
        KeyboardOverlay.removeOverlay();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    rechargeAmount.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _onPresetTap(int value) {
    setState(() {
      _selectedPreset = value;
      rechargeAmount.text = value.toString();
      focusNode.unfocus();
    });
  }

  void _onCustomAmountChanged(String value) {
    setState(() {
      _selectedPreset = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Consumer<WalletRechargeProvider>(
        builder: (context, walletRechargeProvider, _) {
          return Stack(
            children: [
              NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: AppHeader(
                        label: 'Wallet',
                        title: getTranslatedValue(
                            context, walletRechargeLabel),
                        showBackButton: true,
                      ),
                    ),
                  ];
                },
                body: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Balance Card
                      _buildBalanceCard(colorScheme),
                      const SizedBox(height: 32),

                      // Quick Add Section
                      Text(
                        getTranslatedValue(context, 'quick_add'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPresetChips(colorScheme),
                      const SizedBox(height: 32),

                      // Custom Amount Section
                      Text(
                        getTranslatedValue(context, 'or_enter_custom_amount'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAmountInput(colorScheme),
                      const SizedBox(height: 10),
                      _buildMaxAmountHint(colorScheme),
                      const SizedBox(height: 24),

                      // Terms and Conditions
                      _buildTermsText(colorScheme),

                      // Bottom spacing for fixed button
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Fixed Bottom Navigation Bar with Recharge Button
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.border,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: WalletRechargeButtonWidget(
                      context: context,
                      rechargeAmount: rechargeAmount,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(AppColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
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
            getTranslatedValue(context, 'current_wallet_balance'),
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
    );
  }

  Widget _buildPresetChips(AppColorScheme colorScheme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _presets
          .where((value) => value <= Constant.maximumWalletRechargeAmount)
          .map((value) {
        final isSelected = _selectedPreset == value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _onPresetTap(value);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color:
                  isSelected ? colorScheme.primary : colorScheme.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.border,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              "\u20B9$value",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : colorScheme.textSecondary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMaxAmountHint(AppColorScheme colorScheme) {
    return Center(
      child: Text(
        "Maximum ${Constant.maximumWalletRechargeAmount.toStringAsFixed(0).currency} per recharge",
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTermsText(AppColorScheme colorScheme) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: 'By recharging, you agree to our ',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colorScheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: 'Terms & Conditions',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  HapticFeedback.lightImpact();
                  launchUrl(
                    Uri.parse(
                        '${Constant.hostUrl}customer/terms-conditions'),
                    mode: LaunchMode.externalApplication,
                  );
                },
            ),
            TextSpan(
              text: ' and ',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colorScheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: 'Privacy Policy',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  HapticFeedback.lightImpact();
                  launchUrl(
                    Uri.parse(
                        '${Constant.hostUrl}customer/privacy-policy'),
                    mode: LaunchMode.externalApplication,
                  );
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput(AppColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focusNode.hasFocus ? colorScheme.primary : colorScheme.border,
          width: focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: [
          if (focusNode.hasFocus)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: TextField(
        controller: rechargeAmount,
        focusNode: Platform.isIOS ? focusNode : FocusNode(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        onChanged: _onCustomAmountChanged,
        inputFormatters: [
          _MaxAmountInputFormatter(Constant.maximumWalletRechargeAmount),
        ],
        style: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: colorScheme.textPrimary,
          letterSpacing: -0.5,
        ),
        decoration: InputDecoration(
          hintText: getTranslatedValue(context, 'wallet_recharge_hint'),
          hintStyle: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: colorScheme.border,
            letterSpacing: -0.5,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              "\u20B9",
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
      ),
    );
  }
}
