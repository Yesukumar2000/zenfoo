import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class PromoCodeListScreen extends StatefulWidget {
  final double amount;

  const PromoCodeListScreen({Key? key, required this.amount}) : super(key: key);

  @override
  State<PromoCodeListScreen> createState() => _PromoCodeListScreenState();
}

class _PromoCodeListScreenState extends State<PromoCodeListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _couponController = TextEditingController();
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    Future.delayed(Duration.zero).then((value) async {
      await context.read<PromoCodeProvider>().getPromoCodeProvider(
        params: {ApiAndParams.amount: widget.amount.toString()},
        context: context,
      );
    });
  }

  @override
  dispose() {
    _couponController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            // Coupon Input
            _buildCouponInputField(),

            // Content
            Expanded(
              child: setRefreshIndicator(
                refreshCallback: () async {
                  context
                      .read<CartListProvider>()
                      .getAllCartItems(context: context);
                  await context.read<PromoCodeProvider>().getPromoCodeProvider(
                    params: {ApiAndParams.amount: widget.amount.toString()},
                    context: context,
                  );
                },
                child: Consumer<PromoCodeProvider>(
                  builder: (context, promoCodeProvider, _) {
                    if (promoCodeProvider.promoCodeState ==
                        PromoCodeState.loading) {
                      return _PromoCodeShimmer(
                          shimmerController: _shimmerController);
                    }

                    if (promoCodeProvider.promoCodeState ==
                            PromoCodeState.loaded &&
                        promoCodeProvider.promoCode.data.isNotEmpty) {
                      return SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20),
                            Text(
                              getTranslatedValue(context, 'more_offers'),
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 14),
                            ...List.generate(
                              promoCodeProvider.promoCode.data.length,
                              (index) => promoCodeItemWidget(
                                promoCodeProvider.promoCode.data[index],
                                index,
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      );
                    }

                    return _EmptyPromoCodeState();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.textPrimary,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Text(
            getTranslatedValue(context, 'apply_coupon'),
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          Spacer(),
          Text(
            '${getTranslatedValue(context, 'your_cart')} : ${Constant.currency}${widget.amount.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponInputField() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.textTertiary.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: getTranslatedValue(context, 'enter_coupon_code'),
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.textTertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            GestureDetector(
              onTap: () async {
                if (_couponController.text.isNotEmpty) {
                  final promoCodeProvider = context.read<PromoCodeProvider>();
                  if (promoCodeProvider.promoCodeState == PromoCodeState.loaded) {
                    final matchedPromo = promoCodeProvider.promoCode.data
                        .where((p) => p.promoCode.toLowerCase() == _couponController.text.trim().toLowerCase())
                        .toList();
                    if (matchedPromo.isNotEmpty) {
                      final promo = matchedPromo.first;
                      if (promo.isApplicable == "1") {
                        promoCodeProvider.applyPromoCode(promo);
                        await context.read<CartProvider>().saveCartMetadata(
                              context: context,
                              promoCode: promo.promoCode,
                              promoCodeId: promo.id,
                            );
                        Navigator.pop(context, true);
                      } else {
                        showMessage(context, promo.applicableMessage.isNotEmpty ? promo.applicableMessage : promo.message, MessageType.warning);
                      }
                    } else {
                      showMessage(context, getTranslatedValue(context, 'invalid_coupon_code'), MessageType.warning);
                    }
                  }
                }
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  getTranslatedValue(context, 'apply_button'),
                  style: GoogleFonts.inter(
                    color: _couponController.text.isEmpty
                        ? colorScheme.textTertiary
                        : colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget promoCodeItemWidget(PromoCodeData promoCode, int index) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final isApplicable = promoCode.isApplicable == "1";
    final isExpanded =
        context.watch<PromoCodeProvider>().expandedIndex == index;
    final isApplied = Constant.selectedCoupon == promoCode.promoCode;

    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  promoCode.promoCodeMessage,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Apply Text
              GestureDetector(
                onTap: () async {
                  if (isApplied) {
                    context.read<PromoCodeProvider>().removePromoCode();
                    await removePromocodeApi(context: context);
                    if (!mounted) return;
                    Navigator.pop(context, false);
                  } else if (isApplicable) {
                    context.read<PromoCodeProvider>().applyPromoCode(promoCode);
                    await context.read<CartProvider>().saveCartMetadata(
                          context: context,
                          promoCode: promoCode.promoCode,
                          promoCodeId: promoCode.id,
                        );
                    Navigator.pop(context, true);
                  }
                },
                child: Text(
                  isApplied
                      ? getTranslatedValue(context, 'applied_button')
                      : getTranslatedValue(context, 'apply_button'),
                  style: GoogleFonts.inter(
                    color: isApplied
                        ? colorScheme.primary
                        : isApplicable
                            ? colorScheme.primary
                            : colorScheme.textTertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          // Subtitle
          Text(
            '${getTranslatedValue(context, 'save_up_to')}${promoCode.discount}',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
          // // Red error text (commented out)
          // if (!isApplicable)
          //   Text(
          //     promoCode.message,
          //     style: GoogleFonts.inter(
          //       color: colorScheme.error,
          //       fontSize: 13,
          //       fontWeight: FontWeight.w400,
          //       height: 1.3,
          //     ),
          //   ),
          SizedBox(height: 8),
          // Promo code chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF1F5BF9).withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              promoCode.promoCode,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F5BF9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(height: 8),
          // Applicable message
          if (promoCode.applicableMessage.isNotEmpty)
            Text(
              promoCode.applicableMessage,
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
          SizedBox(height: 10),
          // More / Terms and conditions
          GestureDetector(
            onTap: () {
              context.read<PromoCodeProvider>().toggleExpanded(index);
            },
            child: Text(
              isExpanded
                  ? 'Terms and conditions apply'
                  : 'More',
              style: GoogleFonts.inter(
                color: isExpanded
                    ? colorScheme.textPrimary
                    : const Color(0xFF1F5BF9),
                fontSize: isExpanded ? 12 : 14,
                fontWeight: isExpanded
                    ? FontWeight.w500
                    : FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          // Expanded Terms
          if (isExpanded && promoCode.seeMore.isNotEmpty) ...[
            SizedBox(height: 14),
            ...promoCode.seeMore.map((term) {
              return Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 6, left: 4),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colorScheme.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        term,
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}

// Modern Shimmer Widget
class _PromoCodeShimmer extends StatelessWidget {
  final AnimationController shimmerController;

  const _PromoCodeShimmer({required this.shimmerController});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final isDark = colorScheme.isDark;

    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) {
        final animationValue = shimmerController.value * 4 - 2;

        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              // "More Offers" title shimmer
              Container(
                height: 18,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment(animationValue - 1, 0),
                    end: Alignment(animationValue + 1, 0),
                    colors: isDark
                        ? [
                            Color(0xFF2C2C2C),
                            Color(0xFF3C3C3C),
                            Color(0xFF2C2C2C),
                          ]
                        : [
                            Color(0xFFF0F0F0),
                            Color(0xFFFAFAFA),
                            Color(0xFFF0F0F0),
                          ],
                  ),
                ),
              ),
              SizedBox(height: 14),
              // Promo code cards shimmer
              ...List.generate(5, (index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 14),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 16,
                                  width: 160,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: LinearGradient(
                                      begin: Alignment(animationValue - 1, 0),
                                      end: Alignment(animationValue + 1, 0),
                                      colors: isDark
                                          ? [
                                              Color(0xFF2C2C2C),
                                              Color(0xFF3C3C3C),
                                              Color(0xFF2C2C2C),
                                            ]
                                          : [
                                              Color(0xFFF0F0F0),
                                              Color(0xFFFAFAFA),
                                              Color(0xFFF0F0F0),
                                            ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  height: 13,
                                  width: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: LinearGradient(
                                      begin: Alignment(animationValue - 1, 0),
                                      end: Alignment(animationValue + 1, 0),
                                      colors: isDark
                                          ? [
                                              Color(0xFF2C2C2C),
                                              Color(0xFF3C3C3C),
                                              Color(0xFF2C2C2C),
                                            ]
                                          : [
                                              Color(0xFFF0F0F0),
                                              Color(0xFFFAFAFA),
                                              Color(0xFFF0F0F0),
                                            ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            height: 16,
                            width: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin: Alignment(animationValue - 1, 0),
                                end: Alignment(animationValue + 1, 0),
                                colors: isDark
                                    ? [
                                        Color(0xFF2C2C2C),
                                        Color(0xFF3C3C3C),
                                        Color(0xFF2C2C2C),
                                      ]
                                    : [
                                        Color(0xFFF0F0F0),
                                        Color(0xFFFAFAFA),
                                        Color(0xFFF0F0F0),
                                      ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 13,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            begin: Alignment(animationValue - 1, 0),
                            end: Alignment(animationValue + 1, 0),
                            colors: isDark
                                ? [
                                    Color(0xFF2C2C2C),
                                    Color(0xFF3C3C3C),
                                    Color(0xFF2C2C2C),
                                  ]
                                : [
                                    Color(0xFFF0F0F0),
                                    Color(0xFFFAFAFA),
                                    Color(0xFFF0F0F0),
                                  ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 14,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            begin: Alignment(animationValue - 1, 0),
                            end: Alignment(animationValue + 1, 0),
                            colors: isDark
                                ? [
                                    Color(0xFF2C2C2C),
                                    Color(0xFF3C3C3C),
                                    Color(0xFF2C2C2C),
                                  ]
                                : [
                                    Color(0xFFF0F0F0),
                                    Color(0xFFFAFAFA),
                                    Color(0xFFF0F0F0),
                                  ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// Empty State Widget
class _EmptyPromoCodeState extends StatelessWidget {
  const _EmptyPromoCodeState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.local_offer_outlined,
                  size: 60,
                  color: colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              getTranslatedValue(context, 'no_coupons_available'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              getTranslatedValue(context, 'no_coupons_message'),
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
