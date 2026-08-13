import 'package:flutter/material.dart';
import 'package:project/utils/order_number.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/services/admin_order_chat_service.dart';

// ── Local models ────────────────────────────────────────────────────────────

class _FAQItem {
  final String key;
  final String question;

  _FAQItem({required this.key, required this.question});

  factory _FAQItem.fromJson(Map<String, dynamic> json) => _FAQItem(
        key: json['key'] ?? '',
        question: json['question'] ?? '',
      );
}

class _LocalMessage {
  final String message;
  final bool isSeller;
  final DateTime timestamp;
  final bool isBot;

  _LocalMessage({
    required this.message,
    required this.isSeller,
    DateTime? timestamp,
    this.isBot = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class _CombinedMessage {
  final DateTime timestamp;
  final Widget widget;

  _CombinedMessage({required this.timestamp, required this.widget});
}

// ── Widget ───────────────────────────────────────────────────────────────────

class ChatWithAdminScreen extends StatefulWidget {
  final int orderId;
  final int sellerId;
  
  const ChatWithAdminScreen({
    super.key,
    required this.orderId,
    required this.sellerId
  });

  @override
  State<ChatWithAdminScreen> createState() => _ChatWithAdminScreenState();
}

class _ChatWithAdminScreenState extends State<ChatWithAdminScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  late FocusNode _focusNode;

  bool _isSending = false;
  bool _isLoadingFAQ = true;
  bool _isLoadingBotResponse = false;

  List<_FAQItem> _faqItems = [];
  final List<_LocalMessage> _localMessages = [];
  final List<AdminChatMessage> _firebaseMessages = [];
  late AdminChatService _chatService;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _chatService = AdminChatService();
    _loadFAQ();
    _listenFirebase();

    // Add welcome message
    _localMessages.add(_LocalMessage(
      message: "Hi! How can I help you with Order ${formatOrderNumber(widget.orderId)}? You can select a quick option below or type your message.",
      isSeller: false,
      isBot: true,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Load FAQ from API ─────────────────────────────────────────────────────

  Future<void> _loadFAQ() async {
    try {
      final response = await getFAQInChat(context: context);
      if (response['status'] == true &&
          response['data'] != null &&
          response['data'] is List) {
        setState(() {
          _faqItems = (response['data'] as List)
              .map((e) => _FAQItem.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('FAQ load error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFAQ = false);
    }
  }

  // ── Firebase listener ─────────────────────────────────────────────────────

  void _listenFirebase() {
    _chatService.getChatMessagesStream(widget.orderId, widget.sellerId).listen(
      (msgs) {
        if (mounted) {
          setState(() {
            _firebaseMessages
              ..clear()
              ..addAll(msgs);
          });
          _scrollToBottom();
        }
      },
      onError: (e) {
        debugPrint('Firebase chat error: $e');
      },
    );
  }

  // ── FAQ chip tapped ───────────────────────────────────────────────────────

  Future<void> _handleFAQ(_FAQItem faq) async {
    // Add question bubble locally
    setState(() {
      _localMessages.add(_LocalMessage(message: faq.question, isSeller: true));
      _isLoadingBotResponse = true;
    });
    _scrollToBottom();

    try {
      final response = await sendChatMessageToBot(
        orderId: widget.orderId.toString(),
        questionKey: faq.key,
      );

      if (response['status'] == true && response['answer'] != null) {
        final answer = response['answer'];
        String text = answer['text'] ?? '';

        if (answer['details'] != null &&
            (answer['details'] as List).isNotEmpty) {
          text += '\n';
          for (final detail in answer['details'] as List) {
            text += '\n${detail['label'] ?? ''}: ${detail['value'] ?? ''}';
          }
        }

        if (text.trim().isNotEmpty) {
          setState(() {
            _localMessages.add(_LocalMessage(
              message: text.trim(),
              isSeller: false,
              isBot: true,
            ));
          });
        }
      } else {
        setState(() {
          _localMessages.add(_LocalMessage(
            message: "I'll connect you with our support team. Please type your message below.",
            isSeller: false,
            isBot: true,
          ));
        });
      }
    } catch (e) {
      debugPrint('Bot answer error: $e');
      setState(() {
        _localMessages.add(_LocalMessage(
          message: "Sorry, I couldn't process that. Please type your question below.",
          isSeller: false,
          isBot: true,
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingBotResponse = false);
        _scrollToBottom();
      }
    }
  }

  // ── Send message via API + Firebase ───────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      // Send via API to notify admin
      final response = await sendChatMessageToAdminForOrder(
        orderId: widget.orderId,
        message: text,
      );

      if (response['status'] == 1) {
        debugPrint('Message sent to admin successfully');

        // Also add to Firebase so it appears in chat
        await _chatService.addMessage(
          sellerId: widget.sellerId,
          orderId: widget.orderId,
          message: text,
          senderType: 'seller',
        );
        _scrollToBottom();
      } else {
        throw Exception(response['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      debugPrint('Send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Scroll ────────────────────────────────────────────────────────────────

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

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  // ── Build combined messages sorted by timestamp ───────────────────────────
  List<Widget> _buildCombinedMessages(app_theme.AppColorScheme colorScheme) {
    // Create a unified list of message data with timestamps
    final List<_CombinedMessage> allMessages = [];

    // Add local messages
    for (final m in _localMessages) {
      allMessages.add(_CombinedMessage(
        timestamp: m.timestamp,
        widget: _buildBubble(
          m.message,
          m.isSeller,
          colorScheme,
          time: _formatTime(m.timestamp),
          isBot: m.isBot,
        ),
      ));
    }

    // Add Firebase messages
    for (final m in _firebaseMessages) {
      final isSeller = m.senderType == 'seller';
      allMessages.add(_CombinedMessage(
        timestamp: m.timestamp,
        widget: _buildBubble(
          m.message,
          isSeller,
          colorScheme,
          time: _formatTime(m.timestamp),
          senderName: m.senderName.isNotEmpty ? m.senderName : (isSeller ? 'You' : 'Admin'),
        ),
      ));
    }

    // Sort by timestamp
    allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return allMessages.map((m) => m.widget).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: PreferredSize(
          preferredSize: const Size(double.infinity, 64),
          child: AppHeader(
            label: 'Support',
            title: 'Order ${formatOrderNumber(widget.orderId)}',
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // ── Chat area ──────────────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Combined messages sorted by timestamp
                  ..._buildCombinedMessages(colorScheme),

                  // Loading indicator for bot response
                  if (_isLoadingBotResponse)
                    _buildTypingIndicator(colorScheme),
                ],
              ),
            ),

            // ── Quick reply options (above input) ──────────────────────────
            if (_faqItems.isNotEmpty && !_isLoadingFAQ)
              _buildQuickReplies(colorScheme),

            // ── Text input (always visible) ────────────────────────────────
            _buildInputArea(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(
    String message,
    bool isSeller,
    app_theme.AppColorScheme colorScheme, {
    String? time,
    bool isBot = false,
    String? senderName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isSeller ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender label
          if (!isSeller)
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
                          ? colorScheme.primary.withOpacity(0.1)
                          : const Color(0xff34C759).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBot ? Icons.smart_toy_outlined : Icons.support_agent,
                      size: 14,
                      color: isBot ? colorScheme.primary : const Color(0xff34C759),
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
            alignment: isSeller ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSeller
                    ? colorScheme.primary
                    : colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isSeller ? 18 : 4),
                  bottomRight: Radius.circular(isSeller ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                      color: isSeller ? Colors.white : colorScheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isSeller
                            ? Colors.white.withOpacity(0.7)
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

  Widget _buildTypingIndicator(app_theme.AppColorScheme colorScheme) {
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
                color: Colors.black.withOpacity(0.05),
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

  Widget _buildDot(int index, app_theme.AppColorScheme colorScheme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colorScheme.textSecondary.withOpacity(0.3 + (0.4 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickReplies(app_theme.AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  padding: EdgeInsets.only(right: index < _faqItems.length - 1 ? 8 : 0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoadingBotResponse ? null : () => _handleFAQ(faq),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
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

  IconData _getIconForFAQ(String key) {
    switch (key.toLowerCase()) {
      case 'order_status':
      case 'status':
        return Icons.local_shipping_outlined;
      case 'cancel':
      case 'cancellation':
        return Icons.cancel_outlined;
      case 'refund':
        return Icons.currency_exchange_outlined;
      case 'delivery':
        return Icons.delivery_dining_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'other':
        return Icons.chat_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildInputArea(app_theme.AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
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
              onTap: _isSending || _messageController.text.trim().isEmpty
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
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: _isSending
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
