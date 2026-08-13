import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/orderChatProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/generalWidgets/appHeader.dart';

class OrderChatScreen extends StatefulWidget {
  final String orderId;
  final String driverName;
  final int? driverId;
  final String? driverPhone;

  const OrderChatScreen({
    super.key,
    required this.orderId,
    required this.driverName,
    this.driverId,
    this.driverPhone,
  });

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  String _customerId = '';
  String _customerName = '';

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();

    // Get customer info from session
    final sessionManager = context.read<SessionManager>();
    _customerId = sessionManager.getData(SessionManager.keyPhone);
    _customerName = sessionManager.getData(SessionManager.keyUserName);
    if (_customerName.isEmpty) {
      _customerName = 'Customer';
    }

    // Start listening to messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<OrderChatProvider>();
      chatProvider.listenToDriverChat(widget.orderId);
      chatProvider.listenToUnreadCount(widget.orderId);
      chatProvider.markAllMessagesAsRead(widget.orderId);
    });
  }

  @override
  void didUpdateWidget(OrderChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text;
    if (message.trim().isEmpty) return;

    _messageController.clear();

    final chatProvider = context.read<OrderChatProvider>();
    await chatProvider.sendMessageToDriver(
      orderId: widget.orderId,
      customerId: _customerId,
      customerName: _customerName,
      message: message,
      driverId: widget.driverId,
      context: context,
    );

    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: Consumer<OrderChatProvider>(
          builder: (context, chatProvider, _) {
            return AppHeader(
              label: 'Driver Chat',
              title: widget.driverName,
              showBackButton: true,
              onBackPressed: chatProvider.isSending
                  ? null
                  : () => Navigator.pop(context),
            );
          },
        ),
      ),
      body: Consumer<OrderChatProvider>(
        builder: (context, chatProvider, _) {
          final messages = chatProvider.messages;

          return Column(
            children: [
              // Messages list
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet\nStart chatting with your driver',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMyMessage = message.senderType == 'customer';

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: 12,
                              left: isMyMessage ? 50 : 16,
                              right: isMyMessage ? 16 : 50,
                            ),
                            child: Align(
                              alignment: isMyMessage
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                decoration: BoxDecoration(
                                  color: isMyMessage
                                      ? colorScheme.primary
                                      : const Color(0xFFE8E8E8),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(14),
                                    topRight: Radius.circular(14),
                                    bottomLeft: isMyMessage
                                        ? Radius.circular(14)
                                        : Radius.circular(4),
                                    bottomRight: isMyMessage
                                        ? Radius.circular(4)
                                        : Radius.circular(14),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: isMyMessage
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      message.message,
                                      style: TextStyle(
                                        color: isMyMessage
                                            ? colorScheme.surface
                                            : const Color(0xFF1F1F1F),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatTime(message.timestamp),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isMyMessage
                                                ? colorScheme.surface
                                                    .withValues(alpha: 0.6)
                                                : Colors.grey[700],
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        if (isMyMessage) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            message.read
                                                ? Icons.done_all
                                                : Icons.done,
                                            size: 12,
                                            color: colorScheme.surface
                                                .withValues(alpha: 0.6),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Input field
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(
                              color: colorScheme.textSecondary,
                              fontSize: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          minLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: context.watch<OrderChatProvider>().isSending
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.surface,
                                    ),
                                  ),
                                )
                              : Icon(Icons.send_rounded),
                          color: colorScheme.surface,
                          onPressed:
                              context.watch<OrderChatProvider>().isSending
                                  ? null
                                  : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
