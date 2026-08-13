import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/transaction_response.dart';
import 'package:project/models/new_order.dart' show SettlementItem;
import 'package:project/repositories/transactionApi.dart';
import 'package:project/services/transaction_pdf_service.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<TransactionItem> transactions = [];
  TransactionSummary? summary;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  bool isExporting = false;
  int currentPage = 1;
  int totalRecords = 0;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Filters
  String? selectedType;
  String? selectedPaymentStatus;
  DateTime? fromDate;
  DateTime? toDate;
  String? selectedQuickRange; // 'today' | 'week' | 'month' | 'year'
  String sortBy = 'created_at';
  String sortOrder = 'desc';

  // Quick date-range presets shown as chips above the summary.
  final List<Map<String, String>> quickRanges = [
    {'value': '', 'label': 'Overall'},
    {'value': 'today', 'label': 'Today'},
    {'value': 'week', 'label': 'This Week'},
    {'value': 'month', 'label': 'This Month'},
    {'value': 'year', 'label': 'This Year'},
  ];

  final List<Map<String, String>> typeFilters = [
    {'value': '', 'label': 'All Types'},
    {'value': 'order_commission', 'label': 'Order Earnings'},
    {'value': 'withdrawal', 'label': 'Withdrawals'},
    {'value': 'credit', 'label': 'Credits'},
    {'value': 'debit', 'label': 'Debits'},
    {'value': 'refund', 'label': 'Refunds'},
  ];

  final List<Map<String, String>> paymentStatusFilters = [
    {'value': '', 'label': 'All Status'},
    {'value': 'paid', 'label': 'Paid'},
    {'value': 'unpaid', 'label': 'Unpaid'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMoreData) {
      _loadMoreTransactions();
    }
  }

  Future<void> _fetchTransactions({bool reset = true}) async {
    if (reset) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        currentPage = 1;
        transactions.clear();
      });
    }

    try {
      final response = await getTransactionsRepository(
        context: context,
        page: 1,
        perPage: 15,
        type: selectedType,
        paymentStatus: selectedPaymentStatus,
        fromDate: fromDate != null
            ? DateFormat('yyyy-MM-dd').format(fromDate!)
            : null,
        toDate:
            toDate != null ? DateFormat('yyyy-MM-dd').format(toDate!) : null,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      if (response != null && response.status == 1) {
        setState(() {
          transactions = response.data?.transactions ?? [];
          summary = response.data?.summary;
          currentPage = 1;
          totalRecords =
              response.data?.pagination?.total ?? transactions.length;
          hasMoreData = response.data?.pagination?.hasMore ?? false;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = response?.message ?? 'Failed to load transactions';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Something went wrong';
      });
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final response = await getTransactionsRepository(
        context: context,
        page: currentPage + 1,
        perPage: 15,
        type: selectedType,
        paymentStatus: selectedPaymentStatus,
        fromDate: fromDate != null
            ? DateFormat('yyyy-MM-dd').format(fromDate!)
            : null,
        toDate:
            toDate != null ? DateFormat('yyyy-MM-dd').format(toDate!) : null,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      if (response != null && response.status == 1) {
        setState(() {
          transactions.addAll(response.data?.transactions ?? []);
          currentPage++;
          totalRecords =
              response.data?.pagination?.total ?? transactions.length;
          hasMoreData = response.data?.pagination?.hasMore ?? false;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    String? tempType = selectedType;
    String? tempPaymentStatus = selectedPaymentStatus;
    DateTime? tempFromDate = fromDate;
    DateTime? tempToDate = toDate;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          tempType = null;
                          tempPaymentStatus = null;
                          tempFromDate = null;
                          tempToDate = null;
                        });
                      },
                      child: Text(
                        'Clear All',
                        style: TextStyle(color: ColorsRes.appColor),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Filter content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction Type
                      const Text(
                        'Transaction Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: typeFilters.map((filter) {
                          final isSelected = tempType == filter['value'] ||
                              (tempType == null && filter['value'] == '');
                          return FilterChip(
                            label: Text(filter['label']!),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                tempType = filter['value']!.isEmpty
                                    ? null
                                    : filter['value'];
                              });
                            },
                            selectedColor: ColorsRes.appColor.withOpacity(0.2),
                            checkmarkColor: ColorsRes.appColor,
                            labelStyle: TextStyle(
                              color:
                                  isSelected ? ColorsRes.appColor : Colors.black87,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Payment Status
                      const Text(
                        'Payment Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: paymentStatusFilters.map((filter) {
                          final isSelected =
                              tempPaymentStatus == filter['value'] ||
                                  (tempPaymentStatus == null &&
                                      filter['value'] == '');
                          return FilterChip(
                            label: Text(filter['label']!),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                tempPaymentStatus = filter['value']!.isEmpty
                                    ? null
                                    : filter['value'];
                              });
                            },
                            selectedColor: ColorsRes.appColor.withOpacity(0.2),
                            checkmarkColor: ColorsRes.appColor,
                            labelStyle: TextStyle(
                              color:
                                  isSelected ? ColorsRes.appColor : Colors.black87,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Date Range
                      const Text(
                        'Date Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: tempFromDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setModalState(() {
                                    tempFromDate = date;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 18, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Text(
                                      tempFromDate != null
                                          ? DateFormat('dd MMM yyyy')
                                              .format(tempFromDate!)
                                          : 'From Date',
                                      style: TextStyle(
                                        color: tempFromDate != null
                                            ? Colors.black87
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: tempToDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setModalState(() {
                                    tempToDate = date;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 18, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Text(
                                      tempToDate != null
                                          ? DateFormat('dd MMM yyyy')
                                              .format(tempToDate!)
                                          : 'To Date',
                                      style: TextStyle(
                                        color: tempToDate != null
                                            ? Colors.black87
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Apply button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedType = tempType;
                          selectedPaymentStatus = tempPaymentStatus;
                          fromDate = tempFromDate;
                          toDate = tempToDate;
                          // Picking dates manually means it's a custom range,
                          // so no quick-range chip stays highlighted.
                          selectedQuickRange = null;
                        });
                        Navigator.pop(context);
                        _fetchTransactions();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsRes.appColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  IconData _getTransactionIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'order_commission':
        return Icons.shopping_bag_outlined;
      case 'withdrawal':
        return Icons.account_balance_wallet_outlined;
      case 'credit':
        return Icons.add_circle_outline;
      case 'debit':
        return Icons.remove_circle_outline;
      case 'refund':
        return Icons.replay_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color _getTransactionColor(String? type, bool? isCredit) {
    if (isCredit == true) {
      return const Color(0xff34C759);
    } else {
      return const Color(0xffFF3B30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F2F7),
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showFilterBottomSheet,
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_hasActiveFilters())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ColorsRes.appColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          // Quick date-range presets
          _buildQuickDateFilters(),
          // Summary Card
          if (summary != null && !isLoading) _buildSummaryCard(),
          // Active Filters
          if (_hasActiveFilters()) _buildActiveFilters(),
          // Record count + PDF export
          if (!isLoading && errorMessage == null) _buildResultHeader(),
          // Transactions List
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return selectedType != null ||
        selectedPaymentStatus != null ||
        fromDate != null ||
        toDate != null;
  }

  // Tapping a summary tile filters the list to the matching records.
  void _applySummaryFilter({String? type, String? paymentStatus}) {
    setState(() {
      selectedType = type;
      selectedPaymentStatus = paymentStatus;
    });
    _fetchTransactions();
  }

  // Maps a quick-range key to a [from, to] date pair and reloads the list.
  void _applyQuickRange(String key) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? from;
    DateTime? to = today;

    switch (key) {
      case 'today':
        from = today;
        break;
      case 'week':
        // Start of the current week (Monday) through today.
        from = today.subtract(Duration(days: today.weekday - 1));
        break;
      case 'month':
        from = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        from = DateTime(now.year, 1, 1);
        break;
      default: // 'Overall' clears the range.
        from = null;
        to = null;
        break;
    }

    setState(() {
      selectedQuickRange = key.isEmpty ? null : key;
      fromDate = from;
      toDate = to;
    });
    _fetchTransactions();
  }

  // Quick date-range preset chips (Overall / Today / This Week / ...).
  Widget _buildQuickDateFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: quickRanges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final range = quickRanges[index];
          final value = range['value']!;
          final isSelected = value.isEmpty
              ? (selectedQuickRange == null && fromDate == null && toDate == null)
              : selectedQuickRange == value;
          return ChoiceChip(
            label: Text(range['label']!),
            selected: isSelected,
            onSelected: (_) => _applyQuickRange(value),
            backgroundColor: Colors.white,
            selectedColor: ColorsRes.appColor.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: isSelected ? ColorsRes.appColor : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? ColorsRes.appColor
                    : Colors.grey.shade300,
              ),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  // Record-count header with a "Download PDF" action for the current view.
  Widget _buildResultHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            totalRecords == 1 ? '1 record' : '$totalRecords records',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton.icon(
            onPressed: (isExporting || totalRecords == 0) ? null : _exportToPdf,
            icon: isExporting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorsRes.appColor,
                    ),
                  )
                : Icon(Icons.picture_as_pdf_outlined,
                    size: 18, color: ColorsRes.appColor),
            label: Text(
              isExporting ? 'Preparing...' : 'Download PDF',
              style: TextStyle(
                color: ColorsRes.appColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fetches every record for the active filters and exports it as a PDF.
  Future<void> _exportToPdf() async {
    setState(() => isExporting = true);
    try {
      final response = await getTransactionsRepository(
        context: context,
        page: 1,
        // Large page size so the report covers all matching records, not
        // just the page currently scrolled into view.
        perPage: totalRecords > 0 ? totalRecords : 1000,
        type: selectedType,
        paymentStatus: selectedPaymentStatus,
        fromDate:
            fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate!) : null,
        toDate:
            toDate != null ? DateFormat('yyyy-MM-dd').format(toDate!) : null,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      final items = response?.data?.transactions ?? transactions;
      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No records to export')),
          );
        }
        return;
      }

      await TransactionPdfService.generateAndOpenReport(
        items: items,
        summary: response?.data?.summary ?? summary,
        currency: Constant.currency,
        rangeLabel: _currentRangeLabel(),
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate PDF')),
        );
      }
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }

  String _currentRangeLabel() {
    if (selectedQuickRange != null) {
      return quickRanges.firstWhere(
        (r) => r['value'] == selectedQuickRange,
        orElse: () => {'label': 'Custom'},
      )['label']!;
    }
    if (fromDate != null || toDate != null) return 'Custom';
    return 'Overall';
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Total Earnings (Overall)',
                '${Constant.currency}${summary!.totalEarnings?.toStringAsFixed(2) ?? '0.00'}',
                Icons.trending_up,
                onTap: () =>
                    _applySummaryFilter(type: 'order_commission'),
              ),
              _buildSummaryItem(
                'Available to Withdraw',
                '${Constant.currency}${summary!.adminDueAmount?.toStringAsFixed(2) ?? '0.00'}',
                Icons.account_balance_wallet,
                onTap: () => _applySummaryFilter(paymentStatus: 'unpaid'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Settled / Paid Out',
                '${Constant.currency}${summary!.paidAmount?.toStringAsFixed(2) ?? '0.00'}',
                Icons.check_circle_outline,
                onTap: () => _applySummaryFilter(paymentStatus: 'paid'),
              ),
              _buildSummaryItem(
                'Pending Payout from Zenfoo',
                '${Constant.currency}${summary!.pendingAmount?.toStringAsFixed(2) ?? '0.00'}',
                Icons.hourglass_empty,
                onTap: () => _applySummaryFilter(paymentStatus: 'unpaid'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon,
      {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorsRes.appColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ColorsRes.appColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _fetchTransactions();
                  },
                  icon: Icon(Icons.close, color: Colors.grey.shade500),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (_) => _fetchTransactions(),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (selectedType != null)
            _buildFilterChip(
              typeFilters.firstWhere(
                  (f) => f['value'] == selectedType,
                  orElse: () => {'label': selectedType!})['label']!,
              () {
                setState(() => selectedType = null);
                _fetchTransactions();
              },
            ),
          if (selectedPaymentStatus != null)
            _buildFilterChip(
              selectedPaymentStatus == 'paid' ? 'Paid' : 'Unpaid',
              () {
                setState(() => selectedPaymentStatus = null);
                _fetchTransactions();
              },
            ),
          if (fromDate != null || toDate != null)
            _buildFilterChip(
              '${fromDate != null ? DateFormat('dd/MM').format(fromDate!) : ''} - ${toDate != null ? DateFormat('dd/MM').format(toDate!) : ''}',
              () {
                setState(() {
                  fromDate = null;
                  toDate = null;
                  selectedQuickRange = null;
                });
                _fetchTransactions();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ColorsRes.appColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorsRes.appColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: ColorsRes.appColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: ColorsRes.appColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingShimmer();
    }

    if (errorMessage != null) {
      return _buildErrorWidget();
    }

    if (transactions.isEmpty) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: () => _fetchTransactions(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == transactions.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildTransactionCard(transactions[index]);
        },
      ),
    );
  }

  Widget _buildTransactionCard(TransactionItem transaction) {
    final color = _getTransactionColor(transaction.type, transaction.isCredit);
    final icon = _getTransactionIcon(transaction.type);
    final isRefunded = transaction.isRefundedToCustomer == true;
    final displayAmount = transaction.formattedPayableAmount ?? transaction.formattedAmount ?? '';

    return GestureDetector(
      onTap: () => _showTransactionDetail(transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.typeLabel ?? transaction.type ?? 'Transaction',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Color(0xff1C1C1E),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (isRefunded) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffFF3B30).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xffFF3B30).withOpacity(0.3),
                                        ),
                                      ),
                                      child: const Text(
                                        'Refunded to Customer',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xffFF3B30),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  displayAmount,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                if (transaction.formattedPayableAmount != null &&
                                    transaction.formattedAmount != null &&
                                    transaction.formattedPayableAmount != transaction.formattedAmount) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    transaction.formattedAmount!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (transaction.itemName != null &&
                            transaction.itemName!.isNotEmpty)
                          Text(
                            transaction.itemName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.message ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(transaction.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: transaction.paymentStatus == 'paid'
                          ? const Color(0xff34C759).withOpacity(0.1)
                          : const Color(0xffFF9500).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.paymentStatus == 'paid' ? 'Paid' : 'Unpaid',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: transaction.paymentStatus == 'paid'
                            ? const Color(0xff34C759)
                            : const Color(0xffFF9500),
                      ),
                    ),
                  ),
                ],
              ),
              if (transaction.adminCommission != null &&
                  transaction.adminCommission! > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Commission: ${Constant.currency}${transaction.adminCommission?.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
              if (transaction.vendorWaitCharge != null &&
                  transaction.vendorWaitCharge! > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Wait Charge: -${Constant.currency}${transaction.vendorWaitCharge?.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xffFF3B30),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetail(TransactionItem transaction) {
    // TEMP DEBUG: confirm whether the breakdown reached the parsed model.
    debugPrint(
        '>>> SETTLEMENT DEBUG: order #${transaction.orderId} settlementInfo='
        '${transaction.settlementInfo == null ? 'NULL' : '${transaction.settlementInfo!.length} items'}');
    final color = _getTransactionColor(transaction.type, transaction.isCredit);
    final icon = _getTransactionIcon(transaction.type);
    final isRefunded = transaction.isRefundedToCustomer == true;
    final displayAmount = transaction.formattedPayableAmount ?? transaction.formattedAmount ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.typeLabel ?? transaction.type ?? 'Transaction',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1C1C1E),
                          ),
                        ),
                        if (transaction.itemName != null && transaction.itemName!.isNotEmpty)
                          Text(
                            transaction.itemName!,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isRefunded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xffFF3B30).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffFF3B30).withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.replay_outlined, color: Color(0xffFF3B30), size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'This order was refunded to the customer. The payable amount reflects the deduction.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xffFF3B30),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildDetailRow('Payable Amount', displayAmount, valueColor: color, bold: true),
              if (transaction.formattedPayableAmount != null &&
                  transaction.formattedAmount != null &&
                  transaction.formattedPayableAmount != transaction.formattedAmount)
                _buildDetailRow('Original Amount', transaction.formattedAmount ?? ''),
              if (transaction.settlementInfo != null &&
                  transaction.settlementInfo!.isNotEmpty)
                _buildSettlementBreakdown(transaction.settlementInfo!)
              else if (transaction.adminCommission != null &&
                  transaction.adminCommission! > 0)
                _buildDetailRow('Commission', '${Constant.currency}${transaction.adminCommission?.toStringAsFixed(2)}'),
              _buildDetailRow('Status', transaction.paymentStatus == 'paid' ? 'Paid' : 'Unpaid'),
              if (transaction.orderId != null)
                _buildDetailRow('Order ID', '#${transaction.orderId}'),
              if (transaction.paidAt != null && transaction.paidAt!.isNotEmpty)
                _buildDetailRow('Paid At', _formatDate(transaction.paidAt)),
              _buildDetailRow('Date', _formatDate(transaction.createdAt)),
              if (transaction.paymentTransactionId != null && transaction.paymentTransactionId!.isNotEmpty)
                _buildDetailRow('Transaction ID', transaction.paymentTransactionId!),
              if (transaction.message != null && transaction.message!.isNotEmpty)
                _buildDetailRow('Note', transaction.message!),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? const Color(0xff1C1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementBreakdown(List<SettlementItem> items) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settlement Details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            final isNumeric = item.value is num;
            String displayValue;
            if (isNumeric) {
              displayValue =
                  '${Constant.currency}${(item.value as num).toStringAsFixed(2)}';
            } else {
              final raw = '${item.value}';
              // Format date-like values (e.g. "Settled At") to match the
              // rest of the screen; leave plain text (Paid/Pending) as-is.
              final parsed = DateTime.tryParse(raw);
              displayValue = parsed != null ? _formatDate(raw) : raw;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    displayValue,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1C1C1E),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchTransactions(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsRes.appColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            'No Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters()
                ? 'No transactions match your filters'
                : 'You don\'t have any transactions yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedType = null;
                  selectedPaymentStatus = null;
                  fromDate = null;
                  toDate = null;
                });
                _fetchTransactions();
              },
              child: Text(
                'Clear Filters',
                style: TextStyle(color: ColorsRes.appColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
