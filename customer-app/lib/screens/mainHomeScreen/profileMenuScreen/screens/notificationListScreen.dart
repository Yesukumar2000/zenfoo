import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({Key? key}) : super(key: key);

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final ScrollController scrollController = ScrollController();

  void scrollListener() {
    if (scrollController.position.maxScrollExtent == scrollController.offset) {
      if (!mounted) return;
      final provider = context.read<NotificationProvider>();
      if (provider.hasMoreData) {
        provider.getNotificationProvider(params: {}, context: context);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    scrollController.addListener(scrollListener);
    Future.delayed(Duration.zero, () {
      context
          .read<NotificationProvider>()
          .getNotificationProvider(params: {}, context: context);
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    Constant.resetTempFilters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: getTranslatedValue(context, 'all_notifications'),
          title: getTranslatedValue(context, 'notifications'),
          showBackButton: true,
          onBackPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: setRefreshIndicator(
        refreshCallback: () {
          final provider = context.read<NotificationProvider>();
          provider.notifications.clear();
          provider.offset = 0;
          return provider.getNotificationProvider(params: {}, context: context);
        },
        child: Consumer<NotificationProvider>(
          builder: (context, notificationProvider, _) {
            return CustomScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // _buildSliverAppBar(colorScheme),
                ..._buildNotificationSlivers(notificationProvider, colorScheme),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildNotificationSlivers(
      NotificationProvider notificationProvider, AppColorScheme colorScheme) {
    final state = notificationProvider.itemsState;
    final notifications = notificationProvider.notifications;

    if (state == NotificationState.initial ||
        state == NotificationState.loading) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildNotificationShimmer(colorScheme),
              childCount: 8,
            ),
          ),
        ),
      ];
    }

    if (state == NotificationState.error ||
        (state == NotificationState.loaded &&
            notificationProvider.notifications.isEmpty)) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(colorScheme),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index < notifications.length) {
                final notification = notifications[index];
                return _buildNotificationItem(
                    context, notification, colorScheme);
              }

              if (state == NotificationState.loadingMore &&
                  index == notifications.length) {
                return _buildNotificationShimmer(colorScheme);
              }

              return const SizedBox.shrink();
            },
            childCount: notifications.length +
                (state == NotificationState.loadingMore ? 1 : 0),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
    ];
  }

  Widget _buildNotificationItem(BuildContext context,
      NotificationListData notification, AppColorScheme colorScheme) {
    return GradientBorderCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 18,
      gradient: colorScheme.cardGradient,
      borderGradient: colorScheme.borderGradient,
      shadows: colorScheme.cardShadow,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (notification.type == "category") {
              Navigator.pushNamed(
                context,
                productListScreen,
                arguments: ["category", notification.typeId.toString(), ""],
              );
            } else if (notification.type == "product") {
              Navigator.pushNamed(
                context,
                productDetailScreen,
                arguments: [notification.typeId.toString(), "", null],
              );
            } else if (notification.type == "order") {
              Navigator.pushNamed(
                context,
                orderTrackingScreen,
                arguments: notification.typeId.toString(),
              );
            } else if (notification.type == "url") {
              if (await canLaunchUrl(Uri.parse(notification.linkUrl))) {
                await launchUrl(
                  Uri.parse(notification.linkUrl),
                  mode: LaunchMode.externalApplication,
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: notification.imageUrl.isNotEmpty
                        ? Colors.transparent
                        : colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: notification.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: setNetworkImg(
                            height: 56,
                            width: 56,
                            boxFit: BoxFit.cover,
                            image: notification.imageUrl,
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.notifications_outlined,
                            size: 28,
                            color: colorScheme.primary,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_buildCta(notification, colorScheme) != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildCta(notification, colorScheme)!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildCta(NotificationListData n, AppColorScheme colorScheme) {
    String? key;
    IconData? icon;

    if (n.type == "category") {
      key = goToCategoryLabel;
      icon = Icons.arrow_forward_rounded;
    } else if (n.type == "product") {
      key = goToProductLabel;
      icon = Icons.arrow_forward_rounded;
    } else if (n.type == "order") {
      key = viewOrderLabel;
      icon = Icons.arrow_forward_rounded;
    } else if (n.type == "url") {
      key = visitWebLinkLabel;
      icon = Icons.open_in_new_rounded;
    }

    if (key == null) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            getTranslatedValue(context, key),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            icon,
            size: 14,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationShimmer(AppColorScheme colorScheme) {
    return GradientBorderCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      gradient: colorScheme.cardGradient,
      borderGradient: colorScheme.borderGradient,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomShimmer(
            height: 56,
            width: 56,
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
                  height: 14,
                  width: double.infinity,
                  borderRadius: 8,
                ),
                const SizedBox(height: 6),
                CustomShimmer(
                  height: 14,
                  width: 200,
                  borderRadius: 8,
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
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  width: 8,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 72,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              getTranslatedValue(context, emptyNotificationListMessageLabel),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              getTranslatedValue(
                  context, emptyNotificationListDescriptionLabel),
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
