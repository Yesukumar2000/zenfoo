import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/custom_text_form_field.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/models/wallet_transaction.dart';
import 'package:project/repositories/walletApi.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({Key? key}) : super(key: key);

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<WalletTransaction> _transactions = [];
  List<WalletTransaction> _filteredTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchWalletHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletHistory({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _transactions = [];
        _errorMessage = null;
      });
    }

    try {
      final response = await getWalletTransactions(
        context: context,
        page: _currentPage,
        perPage: 20,
      );

      if (response != null && response['data'] != null) {
        final List<dynamic> transactionsData = response['data'];
        final newTransactions =
            transactionsData.map((t) => WalletTransaction.fromJson(t)).toList();

        setState(() {
          if (refresh || _currentPage == 1) {
            _transactions = newTransactions;
          } else {
            _transactions.addAll(newTransactions);
          }
          _filteredTransactions = _transactions;
          _totalPages = response['last_page'] ?? 1;
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = 'No transaction data available';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'Failed to load transactions: ${e.toString()}';
      });
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _fetchWalletHistory();
  }

  void _filterTransactions(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredTransactions = _transactions;
      });
    } else {
      setState(() {
        _filteredTransactions = _transactions.where((transaction) {
          return transaction.id
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (transaction.message
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false);
        }).toList();
      });
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return DateFormat('dd MMMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: AppHeader(
                label: "Wallet",
                title: "Transaction History",
                showBackButton: true,
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: () => _fetchWalletHistory(refresh: true),
          color: ColorsRes.appColor,
          backgroundColor: colorScheme.cardBackground,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _ShimmerTransactionCard(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          CustomTextFormField(
            title: "",
            controller: _searchController,
            hintText: "Search by ID or message",
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 22,
              color: colorScheme.iconSecondary,
            ),
            onChanged: _filterTransactions,
          ),
          const SizedBox(height: 20),
          // Transaction list
          if (_filteredTransactions.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredTransactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildTransactionCard(_filteredTransactions[index]);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction transaction) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final isCredit = transaction.isCredit;
    final statusColor =
        isCredit ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    final statusBgColor =
        isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID and Type row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Transaction #${transaction.id}',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: statusColor,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isCredit ? 'Credit' : 'Debit',
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        height: 1.02,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Container(
            height: 1,
            color: colorScheme.border,
          ),
          const SizedBox(height: 16),
          // Amount with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCredit
                      ? Icons.add_circle_outline
                      : Icons.remove_circle_outline,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.3,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.55,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Date & Time with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Date',
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.3,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDateTime(transaction.dateTime),
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Message section (if available)
          if (transaction.message != null &&
              transaction.message!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.iconSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Details',
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    transaction.message!,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.3,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 56,
                color: colorScheme.iconSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Transactions',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your wallet history will appear here',
              style: GoogleFonts.inter(
                fontSize: 14,
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

  Widget _buildErrorState() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load History',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Something went wrong. Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            InkWell(
              onTap: () => _fetchWalletHistory(refresh: true),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: ColorsRes.appColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: ColorsRes.appColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerTransactionCard extends StatefulWidget {
  const _ShimmerTransactionCard({Key? key}) : super(key: key);

  @override
  State<_ShimmerTransactionCard> createState() =>
      _ShimmerTransactionCardState();
}

class _ShimmerTransactionCardState extends State<_ShimmerTransactionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.border, width: 1),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 18,
                    width: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          colorScheme.surfaceVariant,
                          colorScheme.surface,
                          colorScheme.surfaceVariant,
                        ],
                        stops: [
                          _animation.value - 0.3,
                          _animation.value,
                          _animation.value + 0.3,
                        ].map((e) => e.clamp(0.0, 1.0)).toList(),
                      ),
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          colorScheme.surfaceVariant,
                          colorScheme.surface,
                          colorScheme.surfaceVariant,
                        ],
                        stops: [
                          _animation.value - 0.3,
                          _animation.value,
                          _animation.value + 0.3,
                        ].map((e) => e.clamp(0.0, 1.0)).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: colorScheme.border),
              const SizedBox(height: 16),
              // Amount row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          colorScheme.surfaceVariant,
                          colorScheme.surface,
                          colorScheme.surfaceVariant,
                        ],
                        stops: [
                          _animation.value - 0.3,
                          _animation.value,
                          _animation.value + 0.3,
                        ].map((e) => e.clamp(0.0, 1.0)).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                colorScheme.surfaceVariant,
                                colorScheme.surface,
                                colorScheme.surfaceVariant,
                              ],
                              stops: [
                                _animation.value - 0.3,
                                _animation.value,
                                _animation.value + 0.3,
                              ].map((e) => e.clamp(0.0, 1.0)).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 20,
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                colorScheme.surfaceVariant,
                                colorScheme.surface,
                                colorScheme.surfaceVariant,
                              ],
                              stops: [
                                _animation.value - 0.3,
                                _animation.value,
                                _animation.value + 0.3,
                              ].map((e) => e.clamp(0.0, 1.0)).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Date row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          colorScheme.surfaceVariant,
                          colorScheme.surface,
                          colorScheme.surfaceVariant,
                        ],
                        stops: [
                          _animation.value - 0.3,
                          _animation.value,
                          _animation.value + 0.3,
                        ].map((e) => e.clamp(0.0, 1.0)).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                colorScheme.surfaceVariant,
                                colorScheme.surface,
                                colorScheme.surfaceVariant,
                              ],
                              stops: [
                                _animation.value - 0.3,
                                _animation.value,
                                _animation.value + 0.3,
                              ].map((e) => e.clamp(0.0, 1.0)).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 14,
                          width: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                colorScheme.surfaceVariant,
                                colorScheme.surface,
                                colorScheme.surfaceVariant,
                              ],
                              stops: [
                                _animation.value - 0.3,
                                _animation.value,
                                _animation.value + 0.3,
                              ].map((e) => e.clamp(0.0, 1.0)).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
