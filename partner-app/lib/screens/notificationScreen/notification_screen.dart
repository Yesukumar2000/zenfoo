import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/notification_response.dart';
import 'package:project/repositories/notificationApi.dart';
import 'package:project/screens/mainScreen/main_tab_scaffold.dart';
import 'package:project/screens/notificationScreen/order_loader_screen.dart';
import 'package:project/screens/ordersScreen/admin_chat.dart';
import 'package:project/screens/transactionScreen/transaction_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationItem> notifications = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int currentPage = 1;
  int totalNotifications = 0;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMoreData) {
      _loadMoreNotifications();
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await getNotificationsRepository(
        context: context,
        page: 1,
        perPage: 10,
      );

      if (response != null && response.status == 1) {
        setState(() {
          notifications = response.data?.data ?? [];
          totalNotifications = response.data?.total ?? 0;
          currentPage = 1;
          hasMoreData = notifications.length < totalNotifications;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = response?.message ?? 'Failed to load notifications';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Something went wrong';
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final response = await getNotificationsRepository(
        context: context,
        page: currentPage + 1,
        perPage: 10,
      );

      if (response != null && response.status == 1) {
        setState(() {
          notifications.addAll(response.data?.data ?? []);
          currentPage++;
          hasMoreData = notifications.length < totalNotifications;
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

  void _handleNotificationTap(NotificationItem notification) {
    final type = notification.type?.toLowerCase();
    final typeId = notification.typeId;
    debugPrint('++++++++type+++++++++++');
    print(type);
    debugPrint('------------type   = $typeId');

    switch (type) {
      case 'new_order':
      case 'order':
        // Navigate to order details screen for this particular order
        if (typeId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderLoaderScreen(orderId: typeId),
            ),
          );
        }
        break;

      case 'order_chat':
      case 'chat_message':
        // Navigate to order chat
        if (typeId != null) { 
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderLoaderScreen(orderId: typeId),
              ),
            ); 
        }
        break;  
      case 'admin_chat':
        // Navigate to admin support chat
        final sellerId =
            int.tryParse(Constant.session.getData(SessionManager.keyUserId)) ??
                0;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SellerAdminChatScreen(
              sellerId: sellerId,
            ),
          ),
        );
        break;

      case 'product':
        // Navigate to product detail/edit
        if (typeId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductAddScreen(
                productId: typeId.toString(),
                from: 'edit',
              ),
            ),
          );
        }
        break;

      case 'wallet':
        // Navigate to transactions screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TransactionScreen(),
          ),
        );
        break;

      case 'profile':
        // Navigate to profile screen
        Navigator.pop(context);
        break;

      case 'home':
      default:
        // Navigate to home tab (index 0)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainTabScaffold(),
          ),
          (route) => false,
        );
        break;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('dd MMM yyyy').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'new_order':
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'order_chat':
      case 'chat_message':
      case 'admin_chat':
        return Icons.chat_bubble_outline;
      case 'product':
        return Icons.inventory_2_outlined;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'profile':
        return Icons.person_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'new_order':
      case 'order':
        return const Color(0xff34C759);
      case 'order_chat':
      case 'chat_message':
      case 'admin_chat':
        return const Color(0xff007AFF);
      case 'product':
        return const Color(0xffFF9500);
      case 'wallet':
        return const Color(0xff5856D6);
      case 'profile':
        return const Color(0xffAF52DE);
      default:
        return const Color(0xff8E8E93);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F2F7),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingShimmer();
    }

    if (errorMessage != null) {
      return _buildErrorWidget();
    }

    if (notifications.isEmpty) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildNotificationCard(notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title ?? 'Notification',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xff1C1C1E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(notification.dateSent),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
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
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchNotifications,
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
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any notifications yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
