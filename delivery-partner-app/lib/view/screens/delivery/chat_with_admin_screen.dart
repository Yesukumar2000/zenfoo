import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenfoo_partner/utils/order_number.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/admin_order_chat_provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/services/admin_order_chat_service.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

/// Combined message for sorting by timestamp
class _CombinedMessage {
  final DateTime timestamp;
  final Widget widget;

  _CombinedMessage({required this.timestamp, required this.widget});
}

class ChatWithAdminScreen extends StatefulWidget {
  final int orderId;
  const ChatWithAdminScreen({
    super.key,
    required this.orderId,
  });
  @override
  State<ChatWithAdminScreen> createState() => _ChatWithAdminScreenState();
}

class _ChatWithAdminScreenState extends State<ChatWithAdminScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  late FocusNode _focusNode;

  List<ChatFAQItem> _faqItems = [];
  final List<LocalChatMessage> _localMessages = [];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _focusNode = FocusNode();

    // Add welcome message
    _localMessages.add(LocalChatMessage(
      message:
          "Hi! How can I help you with Order ${formatOrderNumber(widget.orderId)}? You can select a quick option below or type your message.",
      isDriver: false,
      isBot: true,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = context.read<AdminOrderChatProvider>();
      chatProvider.markAllMessagesAsRead(widget.orderId);
      await _loadFAQ();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFAQ() async {
    final chatProvider = context.read<AdminOrderChatProvider>();
    final response = await chatProvider.fetchFAQ();

    if (response.data != null &&
        (response.data['status'] == true ||
            response.data['status'] == 1 ||
            response.data['status'] == "1") &&
        response.data['data'] != null &&
        response.data['data'] is List) {
      if (mounted) {
        setState(() {
          _faqItems = (response.data['data'] as List)
              .map((e) => ChatFAQItem.fromJson(e))
              .toList();
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleFAQ(ChatFAQItem faq) async {
    HapticFeedback.lightImpact();

    // Add question bubble locally
    setState(() {
      _localMessages.add(LocalChatMessage(
        message: faq.question,
        isDriver: true,
      ));
    });
    _scrollToBottom();

    // If "other" is selected, show support message
    if (faq.key == 'other') {
      setState(() {
        _localMessages.add(LocalChatMessage(
          message:
              "I'll connect you with our support team. Please type your message below.",
          isDriver: false,
          isBot: true,
        ));
      });
      _scrollToBottom();
      return;
    }

    // Get answer from API
    final chatProvider = context.read<AdminOrderChatProvider>();
    final response = await chatProvider.getFAQAnswer(widget.orderId, faq.key);

    if (response.data != null &&
        (response.data['status'] == true ||
            response.data['status'] == 1 ||
            response.data['status'] == "1") &&
        response.data['answer'] != null) {
      final answer = response.data['answer'];
      String text = answer['text'] ?? '';

      // Append details if available
      if (answer['details'] != null && (answer['details'] as List).isNotEmpty) {
        text += '\n';
        for (final detail in answer['details'] as List) {
          final isTotal = detail['is_total'] == true;
          if (isTotal) {
            text += '\n${detail['label'] ?? ''}: ${detail['value'] ?? ''}';
          } else {
            text += '\n${detail['label'] ?? ''}: ${detail['value'] ?? ''}';
          }
        }
      }

      if (text.trim().isNotEmpty) {
        setState(() {
          _localMessages.add(LocalChatMessage(
            message: text.trim(),
            isDriver: false,
            isBot: true,
          ));
        });
      }
    } else {
      setState(() {
        _localMessages.add(LocalChatMessage(
          message:
              "Sorry, I couldn't process that. Please tap 'Need to talk with Support Team?' to chat with our team.",
          isDriver: false,
          isBot: true,
        ));
      });
    }
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final driverId = authProvider.currentDeliveryBoy?.id?.toString() ?? '';
    final driverName = authProvider.currentUser?.name ?? 'Driver';

    _messageController.clear();
    setState(() {});

    final chatProvider = context.read<AdminOrderChatProvider>();
    await chatProvider.sendMessage(
      orderId: widget.orderId,
      message: text,
      driverId: driverId,
      driverName: driverName,
    );

    if (mounted && chatProvider.errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatProvider.errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
    _scrollToBottom();
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  IconData _getIconForFAQ(String key) {
    switch (key.toLowerCase()) {
      case 'my_earning':
        return Icons.currency_rupee_outlined;
      case 'customer_details':
        return Icons.person_outline;
      case 'delivery_address':
        return Icons.location_on_outlined;
      case 'order_items':
        return Icons.shopping_bag_outlined;
      case 'order_total':
        return Icons.receipt_long_outlined;
      case 'payment_method':
        return Icons.payment_outlined;
      case 'seller_details':
        return Icons.storefront_outlined;
      case 'other':
        return Icons.support_agent_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final chatProvider = context.watch<AdminOrderChatProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          /// App Header
          AppHeader(
            label: 'Support',
            title: 'Order ${formatOrderNumber(widget.orderId)}',
            showBackButton: true,
          ),

          /// Error Banner
          if (chatProvider.errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorScheme.error.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatProvider.errorMessage,
                      style: GoogleFonts.inter(
                        color: colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.error, size: 20),
                    onPressed: () =>
                        context.read<AdminOrderChatProvider>().clearError(),
                  ),
                ],
              ),
            ),

          /// Chat Area with StreamBuilder for real-time Firebase messages
          Expanded(
            child: StreamBuilder<List<AdminChatMessage>>(
              stream: chatProvider.getMessagesStream(widget.orderId),
              builder: (context, snapshot) {
                final firebaseMessages = snapshot.data ?? [];

                // Mark admin messages as read
                for (final m in firebaseMessages) {
                  if (m.senderType != 'driver' && !m.read) {
                    chatProvider.markMessageAsRead(widget.orderId, m.id);
                  }
                }

                return ListView(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    /// Combined messages sorted by timestamp
                    ..._buildCombinedMessages(colorScheme, firebaseMessages),

                    /// Typing indicator
                    if (chatProvider.isLoadingBotResponse)
                      _buildTypingIndicator(colorScheme),
                  ],
                );
              },
            ),
          ),

          /// Quick Reply Options (above input)
          if (_faqItems.isNotEmpty && !chatProvider.isLoadingFAQ)
            _buildQuickReplies(colorScheme, chatProvider),

          /// Text Input Area (always visible)
          _buildInputArea(colorScheme, chatProvider),
        ],
      ),
    );
  }

  List<Widget> _buildCombinedMessages(
    dynamic colorScheme,
    List<AdminChatMessage> firebaseMessages,
  ) {
    final List<_CombinedMessage> allMessages = [];

    // Add local messages (FAQ Q&A with bot)
    for (final m in _localMessages) {
      allMessages.add(_CombinedMessage(
        timestamp: m.timestamp,
        widget: _buildBubble(
          m.message,
          m.isDriver,
          colorScheme,
          time: _formatTime(m.timestamp),
          isBot: m.isBot,
        ),
      ));
    }

    // Add Firebase messages (driver-admin chat)
    for (final m in firebaseMessages) {
      final isDriver = m.senderType == 'driver';
      allMessages.add(_CombinedMessage(
        timestamp: m.timestamp,
        widget: _buildBubble(
          m.message,
          isDriver,
          colorScheme,
          time: _formatTime(m.timestamp),
          senderName: m.senderName.isNotEmpty
              ? m.senderName
              : (isDriver ? 'You' : 'Admin'),
        ),
      ));
    }

    // Sort all messages by timestamp
    allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return allMessages.map((m) => m.widget).toList();
  }

  Widget _buildBubble(
    String message,
    bool isDriver,
    dynamic colorScheme, {
    String? time,
    bool isBot = false,
    String? senderName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isDriver ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender label
          if (!isDriver)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isBot
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : const Color(0xff34C759).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBot ? Icons.smart_toy_outlined : Icons.support_agent,
                      size: 14,
                      color:
                          isBot ? colorScheme.primary : const Color(0xff34C759),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    senderName ?? (isBot ? 'Bot' : 'Admin'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          // Message bubble
          Align(
            alignment: isDriver ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDriver ? colorScheme.primary : colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isDriver ? 18 : 4),
                  bottomRight: Radius.circular(isDriver ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDriver ? Colors.white : colorScheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isDriver
                            ? Colors.white.withValues(alpha: 0.7)
                            : colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(dynamic colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(0, colorScheme),
              const SizedBox(width: 4),
              _buildDot(1, colorScheme),
              const SizedBox(width: 4),
              _buildDot(2, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index, dynamic colorScheme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colorScheme.textSecondary
                .withValues(alpha: 0.3 + (0.4 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickReplies(
    dynamic colorScheme,
    AdminOrderChatProvider chatProvider,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Quick Options',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.textSecondary,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _faqItems.asMap().entries.map((entry) {
                final index = entry.key;
                final faq = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                      right: index < _faqItems.length - 1 ? 8 : 0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: chatProvider.isLoadingBotResponse
                          ? null
                          : () => _handleFAQ(faq),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIconForFAQ(faq.key),
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              faq.question,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: colorScheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(
      dynamic colorScheme, AdminOrderChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: _faqItems.isEmpty
            ? Border(top: BorderSide(color: colorScheme.border, width: 0.5))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: colorScheme.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.border),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  maxLines: null,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorScheme.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send button
            GestureDetector(
              onTap: chatProvider.isSending ||
                      _messageController.text.trim().isEmpty
                  ? null
                  : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _messageController.text.trim().isEmpty
                      ? colorScheme.border
                      : colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: _messageController.text.trim().isNotEmpty
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: chatProvider.isSending
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.surface,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        size: 22,
                        color: _messageController.text.trim().isEmpty
                            ? colorScheme.textSecondary
                            : Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
