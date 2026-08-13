import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/styles/appColorScheme.dart';

class WalletHistoryListScreen extends StatefulWidget {
  const WalletHistoryListScreen({Key? key}) : super(key: key);

  @override
  State<WalletHistoryListScreen> createState() =>
      _WalletHistoryListScreenState();
}

class _WalletHistoryListScreenState extends State<WalletHistoryListScreen> {
  final ScrollController scrollController = ScrollController();
  String _selectedFilter = "all"; // all | added | used | cashback | refund

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      context.read<WalletHistoryProvider>().currentFilter = _selectedFilter;
      callApi(true);
    });
    scrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    Constant.resetTempFilters();
    super.dispose();
  }

  void scrollListener() {
    final nextPageTrigger = 0.7 * scrollController.position.maxScrollExtent;
    if (scrollController.position.pixels > nextPageTrigger) {
      if (!mounted) return;
      final p = context.read<WalletHistoryProvider>();
      if (p.hasMoreData) {
        callApi(false);
      }
    }
  }

  void _onFilterTap(String filterKey) {
    if (_selectedFilter == filterKey) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedFilter = filterKey);

    final provider = context.read<WalletHistoryProvider>();
    provider.resetForFilter(filterKey);
    callApi(false); // false because resetForFilter already clears data
  }

  Future callApi(bool resetLimitOffset) async {
    final provider = context.read<WalletHistoryProvider>();

    if (resetLimitOffset) {
      provider.offset = 0;
      provider.walletHistories.clear();
    }

    final value = await getUserDetail(context: context);
    if (value[ApiAndParams.status].toString() == "1") {
      context
          .read<UserProfileProvider>()
          .updateUserDataInSession(value, context);
    }

    await provider.getWalletHistoryProvider(
      params: {ApiAndParams.type: ApiAndParams.transactionId},
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;
        return Scaffold(
          backgroundColor: colorScheme.background,
          
          body: setRefreshIndicator(
            refreshCallback: () {
              context
                  .read<CartListProvider>()
                  .getAllCartItems(context: context);
              return callApi(true);
            },
            child: CustomScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeaderSliver(context, colorScheme),
                _buildFilterSliver(context, colorScheme),
                _buildTransactionsSliver(colorScheme),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= HEADER =================

  SliverAppBar _buildHeaderSliver(
      BuildContext context, AppColorScheme colorScheme) {
    const double expandedHeight = 285;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double collapsedExtent = kToolbarHeight + topPadding;

    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      automaticallyImplyLeading: false,
      expandedHeight: expandedHeight,
      backgroundColor: Colors.transparent,
      // The back button must live in `leading`, NOT inside flexibleSpace:
      // flexibleSpace shrinks to the collapsed height on scroll and clips its
      // children, which is what was cutting the arrow in half.
      leadingWidth: 72,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
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
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // 1.0 when fully expanded, 0.0 when collapsed onto the pinned toolbar.
          final double range = expandedHeight - collapsedExtent;
          final double expandRatio = range <= 0
              ? 0
              : ((constraints.maxHeight - collapsedExtent) / range)
                  .clamp(0.0, 1.0);

          return Container(
            decoration: BoxDecoration(
              gradient: colorScheme.surfaceGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                // Top inset clears the pinned toolbar band holding the back button.
                padding: const EdgeInsets.fromLTRB(16, kToolbarHeight, 16, 18),
                // Wrap in SingleChildScrollView to avoid overflow when height is tight
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Opacity(
                    // Fade out ahead of the collapse so nothing is left half-cut.
                    opacity: Curves.easeOut
                        .transform((expandRatio * 1.4).clamp(0.0, 1.0)),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        CustomTextLabel(
                          jsonKey: walletBalanceLabel,
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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
                                color: colorScheme.textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          getTranslatedValue(context, 'add_money_to_continue_more_payments'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: gradientBtnWidget(
                            context,
                            24,
                            height: 48,
                            callback: () {
                              Navigator.pushNamed(
                                context,
                                walletRechargeScreen,
                              ).then((value) {
                                if (value is bool && value == true) {
                                  callApi(true).then((_) => setState(() {}));
                                }
                              });
                            },
                            otherWidgets: Center(
                              child: CustomTextLabel(
                                jsonKey: walletRechargeLabel,
                                style: GoogleFonts.inter(
                                  color: colorScheme.buttonPrimaryText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= FILTER SECTION =================

  SliverToBoxAdapter _buildFilterSliver(
      BuildContext context, AppColorScheme colorScheme) {
    return SliverToBoxAdapter(
      child: Container(
        color: colorScheme.background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getTranslatedValue(context, 'transaction_history'),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("all", getTranslatedValue(context, 'all_filter'), colorScheme),
                  _buildFilterChip("added", getTranslatedValue(context, 'amount_added'), colorScheme),
                  _buildFilterChip("used", getTranslatedValue(context, 'amount_spent'), colorScheme),
                  _buildFilterChip("cashback", getTranslatedValue(context, 'cash_back_added'), colorScheme),
                  _buildFilterChip("refund", getTranslatedValue(context, 'amount_refunded'), colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String key, String label, AppColorScheme colorScheme) {
    final bool selected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _onFilterTap(key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.border,
              width: 1,
            ),
            boxShadow: selected
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
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : colorScheme.textSecondary,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }

  // ================= TRANSACTIONS LIST =================

  Widget _buildTransactionsSliver(AppColorScheme colorScheme) {
    return Consumer<WalletHistoryProvider>(
      builder: (context, walletHistoryProvider, _) {
        final state = walletHistoryProvider.walletHistoryState;
        final transactions = walletHistoryProvider.walletHistories;

        if (state == WalletHistoryState.initial ||
            state == WalletHistoryState.loading) {
          return SliverToBoxAdapter(
              child: getTransactionListShimmer(colorScheme));
        }

        if (state == WalletHistoryState.error ||
            (state == WalletHistoryState.empty && transactions.isEmpty)) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(colorScheme),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index < transactions.length) {
                return _walletTile(transactions[index], colorScheme);
              }
              // Loading more indicator
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
            childCount: transactions.length +
                (walletHistoryProvider.hasMoreData ? 1 : 0),
          ),
        );
      },
    );
  }

  // ================= TILE & SHIMMERS =================

  Widget _walletTile(
      WalletHistoryData walletHistory, AppColorScheme colorScheme) {
    final isCredit = walletHistory.type?.toLowerCase() == "credit";

    String message = "";
    if (walletHistory.orderId == "null" &&
        walletHistory.orderItemId == "null") {
      message = walletHistory.message.toString();
    } else if ((walletHistory.orderId != null ||
            walletHistory.orderId != "null") &&
        (walletHistory.orderItemId != null ||
            walletHistory.orderItemId != "null") &&
        walletHistory.type.toString().toLowerCase() == "debit") {
      final orderId = (walletHistory.orderId.toString() != "null")
          ? "-${getTranslatedValue(context, orderIdLabel)}:${walletHistory.orderId}"
          : "";
      message = "${getTranslatedValue(context, orderPlacedLabel)}$orderId";
    } else if ((walletHistory.orderId != null ||
            walletHistory.orderId != "null") &&
        (walletHistory.orderItemId != null ||
            walletHistory.orderItemId != "null") &&
        walletHistory.type.toString().toLowerCase() == "credit") {
      final orderDetail = (walletHistory.measurement.toString() != "null" &&
              walletHistory.measurementUnit.toString() != "null" &&
              walletHistory.productName.toString() != "null" &&
              walletHistory.orderId.toString() != "null")
          ? " [${getTranslatedValue(context, orderIdLabel)}:${walletHistory.orderId},${getTranslatedValue(context, itemLabel)}:${walletHistory.productName}(${walletHistory.measurement}${walletHistory.measurementUnit})]"
          : "";
      message = "${walletHistory.message}$orderDetail";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GradientBorderCard(
        gradient: colorScheme.cardGradient,
        borderGradient: colorScheme.borderGradient,
        borderRadius: 18,
        shadows: [
          BoxShadow(
            color: colorScheme.cardShadowColor,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCredit
                    ? colorScheme.statusDeliveredBg
                    : colorScheme.statusCancelledBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isCredit
                    ? colorScheme.statusDeliveredText
                    : colorScheme.statusCancelledText,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.isNotEmpty
                        ? message
                        : (isCredit
                            ? getTranslatedValue(context, 'amount_added_default')
                            : getTranslatedValue(context, 'amount_debited_default')),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    walletHistory.createdAt.toString().formatDate(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isCredit
                              ? colorScheme.statusDeliveredBg
                              : colorScheme.statusCancelledBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCredit
                              ? getTranslatedValue(context, 'credit_transaction')
                              : getTranslatedValue(context, 'debit_transaction'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCredit
                                ? colorScheme.statusDeliveredText
                                : colorScheme.statusCancelledText,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Text(
                        isCredit
                            ? "+ ${walletHistory.amount?.currency}"
                            : "- ${walletHistory.amount?.currency}",
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isCredit
                              ? colorScheme.statusDeliveredText
                              : colorScheme.statusCancelledText,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getTransactionListShimmer(AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(6, (_) => transactionItemShimmer(colorScheme)),
      ),
    );
  }

  Widget transactionItemShimmer(AppColorScheme colorScheme) {
    return GradientBorderCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      gradient: colorScheme.cardGradient,
      borderGradient: colorScheme.borderGradient,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomShimmer(
            height: 48,
            width: 48,
            borderRadius: 12,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomShimmer(
                  height: 16,
                  width: double.infinity,
                  borderRadius: 8,
                ),
                const SizedBox(height: 8),
                CustomShimmer(
                  height: 12,
                  width: 120,
                  borderRadius: 8,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomShimmer(
                      height: 24,
                      width: 60,
                      borderRadius: 8,
                    ),
                    CustomShimmer(
                      height: 20,
                      width: 80,
                      borderRadius: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  width: 8,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 72,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              getTranslatedValue(context, emptyWalletHistoryLabel),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              getTranslatedValue(context, emptyWalletTransactionHistoryLabel),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}