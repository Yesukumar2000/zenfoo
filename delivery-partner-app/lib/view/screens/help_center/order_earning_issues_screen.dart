import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/order_history_model.dart';
import 'package:zenfoo_partner/providers/order_earning_issue_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/request_sent.dart';
import 'package:zenfoo_partner/view/screens/help_center/driver_issues_screen.dart';

import '../../../providers/language_provider.dart';

class OrderEarningIssuesScreen extends StatefulWidget {
  const OrderEarningIssuesScreen({super.key});

  @override
  State<OrderEarningIssuesScreen> createState() =>
      _OrderEarningIssuesScreenState();
}

class _OrderEarningIssuesScreenState extends State<OrderEarningIssuesScreen> {
  int? _expandedIndex;
  final Set<int> _submittedOrderIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<OrderEarningIssueProvider>()
          .getOrderEarningIssue(page: 1, perPage: 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();
    final provider = context.watch<OrderEarningIssueProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: languageProvider.getTranslatedText('help_center'),
            title: languageProvider.getTranslatedText('order_earning_issues'),
            showBackButton: true,
            trailing: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DriverIssuesScreen(fixedIssueType: 'order_earning'),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.watch<ThemeProvider>().isDarkMode
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.watch<ThemeProvider>().isDarkMode
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.history,
                    color: context.watch<ThemeProvider>().isDarkMode
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildBody(provider, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(OrderEarningIssueProvider provider, colorScheme) {
    final languageProvider = context.watch<LanguageProvider>();
    if (provider.getOrderEarningIssueState.status == ApiStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.getOrderEarningIssueState.status == ApiStatus.error) {
      return Center(
          child: Text(provider.getOrderEarningIssueState.message ?? 'Error'));
    }

    final data = provider.getOrderEarningIssueState.data;
    if (data == null ||
        data.ordersByDate == null ||
        data.ordersByDate!.isEmpty) {
      return Center(
          child: Text(languageProvider.getTranslatedText('no_data_found')));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: data.ordersByDate!.length,
      itemBuilder: (context, index) {
        final dateGroup = data.ordersByDate![index];
        final isExpanded = _expandedIndex == index;

        return _buildDateGroup(index, dateGroup, isExpanded, colorScheme);
      },
    );
  }

  Widget _buildDateGroup(
      int index, OrdersByDate dateGroup, bool isExpanded, colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border),
      ),
      child: Column(
        children: [
          /// HEADER
          InkWell(
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateGroup.dateHeader ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textPrimary,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: colorScheme.textPrimary,
                  ),
                ],
              ),
            ),
          ),

          /// EXPANDED CONTENT
          if (isExpanded) ...[
            if (dateGroup.orders == null || dateGroup.orders!.isEmpty)
              _buildEmptyState(colorScheme)
            else
              ...dateGroup.orders!
                  .map((order) => _buildOrderDetails(order, colorScheme)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(colorScheme) {
    final languageProvider = context.watch<LanguageProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            languageProvider.getTranslatedText('no_orders_delivered'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFEF4444), // Red color as in screenshot
            ),
          ),
          Image.asset(
            'assets/images/no_orders.png',
            width: 80,
            height: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(Order order, colorScheme) {
    final languageProvider = context.watch<LanguageProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${languageProvider.getTranslatedText('order_id')} : # ${order.orderId}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textSecondary,
                ),
              ),
              Text(
                order.deliveryTime ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${order.itemCount} ${languageProvider.getTranslatedText('items')}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          /// ITEMS LIST
          ...order.items!.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.quantity}X  ${item.itemName}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.measurement ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              )),

          /// DASHED DIVIDER
          _buildDashedDivider(colorScheme),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languageProvider.getTranslatedText('total_bill'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textSecondary,
                ),
              ),
              Text(
                '₹${order.totalAmountPaid}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languageProvider.getTranslatedText('deliver_charges'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textPrimary,
                ),
              ),
              Text(
                '₹${order.deliveryCharges}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          /// SEND ENQUIRY BUTTON
          if (!_submittedOrderIds.contains(order.orderId)) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () async {
                  final provider = context.read<OrderEarningIssueProvider>();

                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  await provider.orderEarningIssueDetails(
                      orderId: order.orderId!);

                  // Hide loading
                  if (context.mounted) {
                    Navigator.pop(context);

                    if (provider.orderEarningIssueDetailsState.status ==
                        ApiStatus.success) {
                      setState(() {
                        _submittedOrderIds.add(order.orderId!);
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RequestSent(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              provider.orderEarningIssueDetailsState.message ??
                                  'Failed to send enquiry'),
                        ),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: colorScheme.primary.withAlpha(0x7F), width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: colorScheme.primary.withAlpha(0x0A),
                ),
                child: Text(
                  languageProvider.getTranslatedText('send_an_enquiry'),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDashedDivider(colorScheme) {
    return Row(
      children: List.generate(
        800 ~/ 10,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : colorScheme.border,
            height: 1,
          ),
        ),
      ),
    );
  }
}
