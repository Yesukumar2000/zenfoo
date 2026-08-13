import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/sellerOrderReturnRequestProvider.dart';
import 'package:project/provider/support_contact_provider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/screens/ordersScreen/admin_chat.dart';
import 'package:project/screens/mainHomeScreen/orderListScreen/widget/sellerReturnRequestContainer.dart';

class SellerOrderReturnRequestListScreen extends StatefulWidget {
  const SellerOrderReturnRequestListScreen({Key? key}) : super(key: key);

  @override
  State<SellerOrderReturnRequestListScreen> createState() =>
      _SellerOrderReturnRequestListScreenState();
}

class _SellerOrderReturnRequestListScreenState
    extends State<SellerOrderReturnRequestListScreen> {
  late ScrollController scrollController = ScrollController();
  List<String> tabNames = ["All", "Pending", "Completed"];
  int selectedTabIndex = 0;

  scrollListener() {
    var nextPageTrigger = 0.7 * scrollController.position.maxScrollExtent;
    if (scrollController.position.pixels > nextPageTrigger) {
      if (mounted) {
        if (context.read<SellerOrderReturnRequestProvider>().hasMoreData &&
            context.read<SellerOrderReturnRequestProvider>().requestState !=
                SellerOrderReturnRequestState.loadingMore) {
          callApi(reset: false);
        }
      }
    }
  }

  Future callApi({bool? reset, bool? isSilentLoading}) async {
    if (reset == true) {
      context.read<SupportContactProvider>().fetchSupportContacts();
      context.read<SellerOrderReturnRequestProvider>().offset = 0;
      context
          .read<SellerOrderReturnRequestProvider>()
          .returnRequestList
          .clear();
    }

    Map<String, String> params = {};

    // Add report_status filter based on selected tab
    if (selectedTabIndex == 1) {
      // Pending
      params[ApiAndParams.reportStatus] = "4";
    } else if (selectedTabIndex == 2) {
      // Completed
      params[ApiAndParams.reportStatus] = "2";
    }
    // All tab doesn't send report_status

    await context
        .read<SellerOrderReturnRequestProvider>()
        .getSellerOrderReturnRequests(
            context: context,
            params: params,
            silentLoading: isSilentLoading == true);
  }

  @override
  void initState() {
    Future.delayed(
      Duration.zero,
      () {
        callApi(reset: true);
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _showSupportDialog() {
    final provider = context.read<SupportContactProvider>();
    final contact = provider.supportContact;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF9AC444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.support_agent_rounded,
                  color: Color(0xFF9AC444), size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: provider.state == SupportContactState.loading
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF9AC444)),
                ),
              )
            : contact != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Need help? Reach out to our support team through any of the options below.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Phone tile
                      if (contact.phone.isNotEmpty)
                        _buildContactTile(
                          icon: Icons.phone_rounded,
                          label: 'Call Us',
                          value: contact.phone,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            launchUrl(Uri.parse('tel:${contact.phone}'));
                          },
                        ),
                      if (contact.phone.isNotEmpty && contact.email.isNotEmpty)
                        SizedBox(height: 12),
                      // Email tile
                      if (contact.email.isNotEmpty)
                        _buildContactTile(
                          icon: Icons.email_rounded,
                          label: 'Email Us',
                          value: contact.email,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            launchUrl(Uri.parse('mailto:${contact.email}'));
                          },
                        ),
                      SizedBox(height: 12),
                      // Chat tile
                      _buildContactTile(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chat with Us',
                        value: 'Start a live chat',
                        onTap: () {
                          Navigator.pop(dialogContext);
                          final sellerId = int.tryParse(Constant.session
                                  .getData(SessionManager.keyUserId)) ??
                              0;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SellerAdminChatScreen(sellerId: sellerId),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                : Text(
                    'Unable to load support contacts. Please try again later.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9AC444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF9AC444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Color(0xFF9AC444), size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF9CA3AF), size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: 'Return Management',
          title: 'Return Requests',
          showBackButton: true,
          actions: [
            InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: _showSupportDialog,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      getTranslatedValue(context, helpUsLabel),
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                    SizedBox(width: 7),
                    Icon(Icons.headset_mic_rounded,
                        size: 20, color: colorScheme.iconPrimary),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.border,
                width: 1,
              ),
            ),
            child: Row(
              children: List.generate(
                tabNames.length,
                (index) => Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTabIndex = index;
                      });
                      callApi(reset: true);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedTabIndex == index
                            ? Color(0xFF9AC444)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tabNames[index],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selectedTabIndex == index
                              ? Colors.white
                              : colorScheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          // List View
          Consumer<SellerOrderReturnRequestProvider>(
            builder: (context, provider, child) {
              if (provider.requestState ==
                      SellerOrderReturnRequestState.loaded ||
                  provider.requestState ==
                      SellerOrderReturnRequestState.loadingMore ||
                  provider.requestState ==
                      SellerOrderReturnRequestState.silentLoading) {
                return Expanded(
                  child: setRefreshIndicator(
                    context: context,
                    refreshCallback: () {
                      return callApi(reset: true);
                    },
                    child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.returnRequestList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == provider.returnRequestList.length) {
                          if (provider.requestState ==
                              SellerOrderReturnRequestState.loadingMore) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF9AC444),
                                  ),
                                ),
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SellerReturnRequestCard(
                            request: provider.returnRequestList[index],
                            refresh: () =>
                                callApi(reset: true, isSilentLoading: true),
                          ),
                        );
                      },
                    ),
                  ),
                );
              } else if (provider.requestState ==
                  SellerOrderReturnRequestState.loading) {
                return Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OrderContainerShimmer(context),
                      );
                    },
                  ),
                );
              } else if (provider.requestState ==
                  SellerOrderReturnRequestState.empty) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedDocumentCode,
                          color: colorScheme.textSecondary.withValues(
                            alpha: 0.5,
                          ),
                          size: 56,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Return Requests',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You have no return requests at the moment',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => callApi(reset: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF9AC444),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Refresh',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedAlertCircle,
                          color: colorScheme.textSecondary.withValues(
                            alpha: 0.5,
                          ),
                          size: 56,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please try again later',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => callApi(reset: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF9AC444),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Try Again',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
