import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class ReferAndEarn extends StatefulWidget {
  const ReferAndEarn({Key? key}) : super(key: key);

  @override
  State<ReferAndEarn> createState() => _ReferAndEarnState();
}

class _ReferAndEarnState extends State<ReferAndEarn> {
  bool isCreatingLink = false;
  List workflowlist = [];

  // Referral earnings summary (fetched from the backend).
  Map<String, dynamic>? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    addList();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final result = await getReferralStatsApi(context: context);
      if (!mounted) return;
      setState(() {
        _stats =
            result['status'].toString() == '1' ? (result['data'] ?? {}) : {};
        _loadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStats = false);
    }
  }

  num _statNum(String key) {
    final v = _stats?[key];
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? 0;
  }

  void addList() {
    Future.delayed(Duration.zero, () {
      workflowlist = [
        {
          "icon": AppAssets.referStep1Icon,
          "title": getTranslatedValue(context, inviteFriendsLabel),
          "subtitle": getTranslatedValue(context, inviteFriendsToSignupLabel),
        },
        {
          "icon": AppAssets.referStep2Icon,
          "title": getTranslatedValue(context, friendSignsUpLabel),
          "subtitle": getTranslatedValue(context, friendsDownloadAppLabel),
        },
        {
          "icon": AppAssets.referStep3Icon,
          "title": getTranslatedValue(context, friendFirstOrderLabel),
          "subtitle": getTranslatedValue(context, friendsPlaceFirstOrderLabel),
        },
      ];
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final referralCode =
        Constant.session.getData(SessionManager.keyReferralCode).toString();

    // Bonus the referrer earns once the invited friend completes their first
    // qualifying order. Sourced from the same settings the payout job uses.
    final referralCredit =
        double.tryParse(Constant.referralCreditFirstOrder) ?? 0;
    final referralMinOrder =
        double.tryParse(Constant.referralMinOrderAmount) ?? 0;
    final showBonus = referralCredit > 0;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              AppHeader(
                label: 'Rewards',
                title: getTranslatedValue(context, referAndEarnLabel),
                showBackButton: true,
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        getTranslatedValue(context, referralEarningsLabel),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      // Illustration
                      Container(
                        height: 240,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Image.asset(
                          'assets/images/refer_and_earn.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Main headline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          getTranslatedValue(context, referMainHeadlineLabel),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                            height: 1.3,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),

                      // Earnings summary (what the user has earned so far)
                      _earningsCard(colorScheme),

                      // Bonus highlight (only when a credit is configured)
                      if (showBonus) ...[
                        const SizedBox(height: 20),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  referralCredit.toStringAsFixed(0).currency,
                                  style: GoogleFonts.inter(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.primary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  referralMinOrder > 0
                                      ? "Earn this when your friend places their first order of ${referralMinOrder.toStringAsFixed(0).currency} or more"
                                      : "Earn this when your friend places their first order",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Referral Benefits Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getTranslatedValue(
                                  context, referralBenefitsLabel),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...workflowlist
                                .map((step) => _benefitRow(step, colorScheme))
                                .toList(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Invite Code Box
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GradientBorderCard(
                          padding: const EdgeInsets.all(20),
                          borderRadius: 18,
                          gradient: colorScheme.heroGradient,
                          borderGradient: colorScheme.borderGradientStrong,
                          shadows: colorScheme.cardShadow,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${getTranslatedValue(context, inviteCodeLabel)} :',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: colorScheme.border,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        referralCode,
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme.textPrimary,
                                          letterSpacing: 2,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Clipboard.setData(
                                        ClipboardData(text: referralCode),
                                      );
                                      showMessage(
                                        context,
                                        getTranslatedValue(
                                            context, referCodeCopiedLabel),
                                        MessageType.success,
                                      );
                                    },
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: colorScheme.border,
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.copy_rounded,
                                        size: 20,
                                        color: colorScheme.iconPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom spacing for fixed button
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Fixed Bottom Navigation Bar with Invite Button
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
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: !isCreatingLink
                        ? () {
                            HapticFeedback.lightImpact();
                            setState(() => isCreatingLink = true);
                            shareCode();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      disabledBackgroundColor:
                          colorScheme.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          getTranslatedValue(context, inviteNowLabel)
                              .toUpperCase(),
                          style: GoogleFonts.inter(
                            color: colorScheme.buttonPrimaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (isCreatingLink)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _earningsCard(dynamic colorScheme) {
    // While loading, reserve space with a slim placeholder.
    if (_loadingStats) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GradientBorderCard(
          height: 96,
          borderRadius: 18,
          gradient: colorScheme.cardGradient,
          borderGradient: colorScheme.borderGradient,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ),
        ),
      );
    }

    final totalEarned = _statNum('total_earned');
    final friendsJoined = _statNum('friends_joined');
    final rewarded = _statNum('successful_referrals');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(
              getTranslatedValue(context, referralEarningsLabel),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              totalEarned.toStringAsFixed(0).currency,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _statColumn(
                      friendsJoined.toStringAsFixed(0), 'Friends joined',
                      colorScheme),
                ),
                Container(
                    width: 1, height: 32, color: colorScheme.border),
                Expanded(
                  child: _statColumn(
                      rewarded.toStringAsFixed(0), 'Rewarded', colorScheme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String value, String label, dynamic colorScheme) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _benefitRow(Map item, dynamic colorScheme) {
    return GradientBorderCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      gradient: colorScheme.cardGradient,
      borderGradient: colorScheme.borderGradient,
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: defaultImg(
                image: item["icon"],
                height: 24,
                width: 24,
                iconColor: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"] ?? "",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item["subtitle"] ?? "",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void shareCode() async {
    final prefixMessage =
        getTranslatedValue(context, referAndEarnSharePrefixMessageLabel);
    final referralCode =
        Constant.session.getData(SessionManager.keyReferralCode);
    final configuredUrl =
        Platform.isAndroid ? Constant.playStoreUrl : Constant.appStoreUrl;

    // Use the configured store URL when present; otherwise fall back to a
    // placeholder Play Store link until the app is actually published.
    const fallbackUrl =
        "https://play.google.com/store/apps/details?id=com.zenfoo.customer";
    final storeUrl =
        configuredUrl.trim().isEmpty ? fallbackUrl : configuredUrl;

    await SharePlus.instance.share(
      ShareParams(
        text: "$prefixMessage $referralCode\n$storeUrl",
        subject: "Refer and earn app",
      ),
    );

    setState(() => isCreatingLink = false);
  }
}
