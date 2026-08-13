import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/custom_text_form_field.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/models/withdrawal_request.dart';
import 'package:project/repositories/walletApi.dart';
import 'package:project/screens/walletScreen/create_withdrawal_request_screen.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class WithdrawalRequestsScreen extends StatefulWidget {
  const WithdrawalRequestsScreen({Key? key}) : super(key: key);

  @override
  State<WithdrawalRequestsScreen> createState() =>
      _WithdrawalRequestsScreenState();
}

class _WithdrawalRequestsScreenState extends State<WithdrawalRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<WithdrawalRequest> _requests = [];
  List<WithdrawalRequest> _filteredRequests = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
    _fetchWithdrawalRequests();
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final response = await getWalletOverview(context: context);
      if (response != null && response.data != null) {
        setState(() {
          _walletBalance = response.data!.currentBalance;
        });
      }
    } catch (e) {
      debugPrint('Error fetching wallet balance: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWithdrawalRequests({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _requests = [];
        _errorMessage = null;
      });
    }

    try {
      final response = await getWithdrawalRequests(
        context: context,
        page: _currentPage,
        perPage: 20,
      );

      if (response != null && response['data'] != null) {
        final List<dynamic> requestsData = response['data'];
        final newRequests =
            requestsData.map((r) => WithdrawalRequest.fromJson(r)).toList();

        setState(() {
          if (refresh || _currentPage == 1) {
            _requests = newRequests;
          } else {
            _requests.addAll(newRequests);
          }
          _filteredRequests = _requests;
          _totalPages = response['last_page'] ?? 1;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No withdrawal requests available';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load withdrawal requests: ${e.toString()}';
      });
    }
  }

  void _filterRequests(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredRequests = _requests;
      });
    } else {
      setState(() {
        _filteredRequests = _requests.where((request) {
          return request.id
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (request.sellerNote
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false) ||
              (request.adminNote?.toLowerCase().contains(query.toLowerCase()) ??
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

  Future<void> _showWithdrawalDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateWithdrawalRequestScreen(
          walletBalance: _walletBalance,
        ),
      ),
    );

    if (result == true) {
      await _fetchWalletBalance();
      await _fetchWithdrawalRequests(refresh: true);
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
                title: "Withdrawal Requests",
                showBackButton: true,
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: () async {
            await _fetchWalletBalance();
            await _fetchWithdrawalRequests(refresh: true);
          },
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
        itemBuilder: (context, index) => _ShimmerRequestCard(),
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
          // Wallet Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.border, width: 1),
              boxShadow: colorScheme.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallet Balance',
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${_walletBalance.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.55,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _showWithdrawalDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
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
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Withdraw',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
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
          const SizedBox(height: 20),
          // Search field
          CustomTextFormField(
            title: "Search",
            controller: _searchController,
            hintText: "Search by ID or notes",
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 22,
              color: colorScheme.iconSecondary,
            ),
            onChanged: _filterRequests,
          ),
          const SizedBox(height: 20),
          // Requests list
          if (_filteredRequests.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredRequests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildRequestCard(_filteredRequests[index]);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRequestCard(WithdrawalRequest request) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    Color statusColor;
    Color statusBgColor;

    if (request.isPending) {
      statusColor = const Color(0xFFF59E0B);
      statusBgColor = const Color(0xFFFEF3C7);
    } else if (request.isApproved) {
      statusColor = const Color(0xFF16A34A);
      statusBgColor = const Color(0xFFDCFCE7);
    } else {
      statusColor = const Color(0xFFEF4444);
      statusBgColor = const Color(0xFFFEE2E2);
    }

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
          // ID and Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Request #${request.id}',
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
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      request.statusLabel,
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
                  color: ColorsRes.appColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: ColorsRes.appColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdrawal Amount',
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
                      '₹${request.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
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
                      'Request Date',
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
                      _formatDateTime(request.createdAt),
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
          if (request.status.isNotEmpty &&
              request.status != request.statusLabel) ...[
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
                        'Note',
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
                    request.sellerNote ?? 'No note added',
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
                Icons.receipt_long_outlined,
                size: 56,
                color: colorScheme.iconSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Withdrawal Requests',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your withdrawal requests will appear here',
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
              'Unable to Load Requests',
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
              onTap: _fetchWithdrawalRequests,
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

class _ShimmerRequestCard extends StatefulWidget {
  const _ShimmerRequestCard({Key? key}) : super(key: key);

  @override
  State<_ShimmerRequestCard> createState() => _ShimmerRequestCardState();
}

class _ShimmerRequestCardState extends State<_ShimmerRequestCard>
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
                  Container(
                    height: 28,
                    width: 90,
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
                          height: 20,
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
                          width: 80,
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
