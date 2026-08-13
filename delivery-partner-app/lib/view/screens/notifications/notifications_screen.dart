import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/notification_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/router/app_router_name.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/notifications/notification_settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final notificationProvider = context.read<NotificationProvider>();
    await notificationProvider.fetchNotifications();
  }

  Future<void> _refreshData() async {
    final notificationProvider = context.read<NotificationProvider>();
    await notificationProvider.refreshNotifications();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final notificationProvider = context.read<NotificationProvider>();
      if (notificationProvider.hasMoreData &&
          notificationProvider.notificationState !=
              NotificationState.loadingMore) {
        notificationProvider.fetchNotifications(loadMore: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final notificationProvider = context.watch<NotificationProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: context.watch<LanguageProvider>().getTranslatedText('updates'),
            title: context.watch<LanguageProvider>().getTranslatedText('notifications'),
            showBackButton: true,
            trailing: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
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
                    Icons.settings_outlined,
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
            child: _buildContent(colorScheme, notificationProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(colorScheme, NotificationProvider provider) {
    if (provider.notificationState == NotificationState.loading) {
      return _buildLoadingState(colorScheme);
    }

    if (provider.notificationState == NotificationState.error &&
        provider.notifications.isEmpty) {
      return _buildErrorState(colorScheme, provider.message);
    }

    if (provider.notifications.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: provider.notifications.length +
            (provider.notificationState == NotificationState.loadingMore
                ? 1
                : 0),
        itemBuilder: (context, index) {
          if (index == provider.notifications.length) {
            return _buildLoadingMoreIndicator(colorScheme);
          }

          final notification = provider.notifications[index];
          return _buildNotificationCard(colorScheme, notification, index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(colorScheme, notification, int index) {
    final bool isNavigable = _isNavigableNotification(notification.type);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _handleNotificationTap(notification);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: index == 0 ? 12 : 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.border.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type, colorScheme)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: HugeIcon(
                icon: _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type, colorScheme),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.name,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.subtitle,
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow indicator for navigable notifications
            if (isNavigable)
              Icon(
                Icons.chevron_right,
                color: colorScheme.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// Check if notification type is navigable
  bool _isNavigableNotification(String type) {
    final navigableTypes = [
      'order',
      'order_chat',
      'chat_message',
      'admin_chat',
      'hand_cash_limit',
      'payout',
      'issue_update',
    ];
    return navigableTypes.contains(type.toLowerCase());
  }

  /// Handle notification tap based on type
  void _handleNotificationTap(notification) {
    // Prevent multiple taps while navigating
    if (_isNavigating) return;
    _isNavigating = true;

    final notificationType = notification.type.toLowerCase();
    final notificationTypeId = notification.typeId;

    // Perform navigation using go_router
    _performNavigation(notificationType, notificationTypeId);

    // Reset navigation flag after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _isNavigating = false;
      }
    });
  }

  /// Perform the actual navigation based on notification type
  void _performNavigation(String notificationType, int? notificationTypeId) {
    switch (notificationType) {
      case 'order':
        // Navigate to order detail/delivery progress
        // For now, navigate to home where order details can be accessed
        context.go(AppRouterName.bottomNavScreen);
        break;

      case 'order_chat':
      case 'chat_message':
        // Navigate to order chat with admin
        if (notificationTypeId != null) {
          context.push(
            AppRouterName.chatWithAdmin,
            extra: {'orderId': notificationTypeId},
          );
        }
        break;

      case 'admin_chat':
        // Navigate to admin support chat
        context.push(AppRouterName.supportChat);
        break;

      case 'hand_cash_limit':
      case 'payout':
        // Navigate to earnings/wallet
        context.push(AppRouterName.earnings);
        break;

      case 'document_status':
        // No navigation for document verification notifications
        break;

      case 'issue_update':
        // Navigate to help center/issues screen
        context.push(AppRouterName.helpCenter);
        break;

      case 'general':
      default:
        // Navigate to home
        context.go(AppRouterName.bottomNavScreen);
        break;
    }
  }

  dynamic _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return HugeIcons.strokeRoundedDeliveryBox01;
      case 'order_chat':
      case 'chat_message':
      case 'admin_chat':
        return HugeIcons.strokeRoundedMessage01;
      case 'hand_cash_limit':
      case 'payout':
        return HugeIcons.strokeRoundedMoney02;
      case 'document_status':
        return HugeIcons.strokeRoundedFile02;
      case 'issue_update':
        return HugeIcons.strokeRoundedCustomerSupport;
      case 'gig':
      case 'booking':
        return HugeIcons.strokeRoundedCalendar03;
      case 'offer':
      case 'incentive':
        return HugeIcons.strokeRoundedGift;
      case 'session':
        return HugeIcons.strokeRoundedClock01;
      case 'earning':
      case 'payment':
        return HugeIcons.strokeRoundedMoney02;
      case 'alert':
      case 'warning':
        return HugeIcons.strokeRoundedAlert02;
      case 'success':
        return HugeIcons.strokeRoundedCheckmarkCircle02;
      default:
        return HugeIcons.strokeRoundedNotification02;
    }
  }

  Color _getNotificationColor(String type, colorScheme) {
    switch (type.toLowerCase()) {
      case 'order':
        return colorScheme.primary;
      case 'order_chat':
      case 'chat_message':
      case 'admin_chat':
        return const Color(0xFF3B82F6); // Blue
      case 'hand_cash_limit':
      case 'payout':
        return colorScheme.success;
      case 'document_status':
        return const Color(0xFFFB923C); // Orange
      case 'issue_update':
        return const Color(0xFF8B5CF6); // Purple
      case 'gig':
      case 'booking':
        return colorScheme.primary;
      case 'offer':
      case 'incentive':
        return const Color(0xFFFB923C); // Orange
      case 'session':
        return const Color(0xFF3B82F6); // Blue
      case 'earning':
      case 'payment':
        return colorScheme.success;
      case 'alert':
      case 'warning':
        return colorScheme.error;
      case 'success':
        return colorScheme.success;
      default:
        return colorScheme.textSecondary;
    }
  }

  Widget _buildLoadingState(colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.border.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon skeleton
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),

              // Content skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 14,
                      width: 150,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
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

  Widget _buildEmptyState(colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedNotification02,
            color: colorScheme.textSecondary.withValues(alpha: 0.5),
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!\nWe\'ll notify you when something new arrives.',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(colorScheme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            color: colorScheme.error,
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              message.isNotEmpty
                  ? message
                  : 'Failed to load notifications. Please try again.',
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator(colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
