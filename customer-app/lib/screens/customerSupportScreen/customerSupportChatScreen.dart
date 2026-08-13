import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/chatProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/generalWidgets/appHeader.dart';

class ChatFAQItem {
  final String key;
  final String question;

  ChatFAQItem({
    required this.key,
    required this.question,
  });

  factory ChatFAQItem.fromJson(Map<String, dynamic> json) {
    return ChatFAQItem(
      key: json['key'] ?? '',
      question: json['question'] ?? '',
    );
  }
}

class LocalMessage {
  final String message;
  final bool isCustomer;
  final DateTime timestamp;

  LocalMessage({
    required this.message,
    required this.isCustomer,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Unified message for display — merges local bot messages + Firebase messages
class _DisplayMessage {
  final String message;
  final bool isCustomer;
  final DateTime timestamp;

  _DisplayMessage({
    required this.message,
    required this.isCustomer,
    required this.timestamp,
  });
}

class CustomerSupportChatScreen extends StatefulWidget {
  final String orderId;

  const CustomerSupportChatScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<CustomerSupportChatScreen> createState() =>
      _CustomerSupportChatScreenState();
}

class _CustomerSupportChatScreenState
    extends State<CustomerSupportChatScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;

  String _customerId = '';
  String _customerName = '';

  List<ChatFAQItem> _faqItems = [];
  List<LocalMessage> _localMessages = [];
  bool _isBotTyping = false;
  bool _showFAQSuggestions = true;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _messageController.addListener(() => setState(() {}));

    final sessionManager = context.read<SessionManager>();
    _customerId = sessionManager.getData(SessionManager.keyPhone);
    _customerName = sessionManager.getData(SessionManager.keyUserName);
    if (_customerName.isEmpty) {
      _customerName = 'Customer';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.listenToMessages(widget.orderId, chatType: 'customer');
      chatProvider.markAllMessagesAsRead(widget.orderId, chatType: 'customer');

      await _loadFAQ();

      // Add welcome message
      if (_localMessages.isEmpty) {
        setState(() {
          _localMessages.add(
            LocalMessage(
              message:
                  "Hi ${_customerName}! I'm your Zenfoo assistant. How can I help you today?",
              isCustomer: false,
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFAQ() async {
    final response =
        await getChatFAQApi(context: context, orderId: widget.orderId);

    if (response['status'] == true &&
        response['data'] != null &&
        response['data'] is List) {
      setState(() {
        _faqItems = (response['data'] as List)
            .map((e) => ChatFAQItem.fromJson(e))
            .toList();
      });
    }
  }

  /// FAQ CLICK → show as chat conversation
  Future<void> _handleFAQQuestion(ChatFAQItem faqItem) async {
    // Add user question bubble
    setState(() {
      _showFAQSuggestions = false;
      _localMessages.add(
        LocalMessage(
          message: faqItem.question,
          isCustomer: true,
        ),
      );
      _isBotTyping = true;
    });
    _scrollToBottom();

    if (faqItem.key == 'other') {
      // Bot responds that user can type freely
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _isBotTyping = false;
        _localMessages.add(
          LocalMessage(
            message: "Sure! Type your message below and I'll help you out.",
            isCustomer: false,
          ),
        );
      });
      _scrollToBottom();
      return;
    }

    final response = await ChatFAQSentAPI(
      context: context,
      orderId: widget.orderId,
      questionKey: faqItem.key,
    );

    if (response['status'] == true) {
      final answer = response['answer'];
      String answerText = answer['text'] ?? '';

      if (answer['details'] != null && answer['details'].isNotEmpty) {
        answerText += '\n\n';
        for (var detail in answer['details']) {
          answerText +=
              '${detail['label'] ?? ''}: ${detail['value'] ?? ''}\n';
        }
      }

      setState(() {
        _isBotTyping = false;
        _localMessages.add(
          LocalMessage(
            message: answerText.trim(),
            isCustomer: false,
          ),
        );
      });
    } else {
      setState(() {
        _isBotTyping = false;
        _localMessages.add(
          LocalMessage(
            message: "Sorry, I couldn't get that information right now.",
            isCustomer: false,
          ),
        );
      });
    }

    _scrollToBottom();
  }

  /// Text field send → send via Firebase (message appears via listener)
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    // Send via Firebase — message will appear through the listener
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.sendMessage(
      orderId: widget.orderId,
      customerId: _customerId,
      customerName: _customerName,
      message: message,
      chatType: 'customer',
      context: context,
    );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        context.watch<app_theme.ThemeProvider>().colorScheme;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: PreferredSize(
          preferredSize: const Size(double.infinity, 64),
          child: AppHeader(
            label: 'Support',
            title: 'I am zenfoo Chat bot',
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            /// CHAT AREA — merges local bot messages + Firebase messages
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  // Build merged display list
                  final List<_DisplayMessage> allMessages = [];

                  // Add local bot/FAQ messages
                  for (final local in _localMessages) {
                    allMessages.add(_DisplayMessage(
                      message: local.message,
                      isCustomer: local.isCustomer,
                      timestamp: local.timestamp,
                    ));
                  }

                  // Add Firebase messages (both sent & received)
                  for (final fbMsg in chatProvider.messages) {
                    allMessages.add(_DisplayMessage(
                      message: fbMsg.message,
                      isCustomer: fbMsg.senderType == 'customer',
                      timestamp: fbMsg.timestamp,
                    ));
                  }

                  // Sort by timestamp
                  allMessages
                      .sort((a, b) => a.timestamp.compareTo(b.timestamp));

                  // Auto-scroll when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  final bool showSuggestions =
                      _showFAQSuggestions && _faqItems.isNotEmpty;
                  final int headerCount = showSuggestions ? 1 : 0;

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: headerCount +
                        allMessages.length +
                        (_isBotTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Vertical FAQ suggestions block at the very top
                      if (showSuggestions && index == 0) {
                        return _buildFAQSuggestions(colorScheme);
                      }

                      final adjustedIndex = index - headerCount;

                      // Typing indicator
                      if (_isBotTyping &&
                          adjustedIndex == allMessages.length) {
                        return _buildTypingIndicator(colorScheme);
                      }

                      final msg = allMessages[adjustedIndex];
                      return _buildBubble(
                        msg.message,
                        msg.isCustomer,
                        msg.timestamp,
                        colorScheme,
                      );
                    },
                  );
                },
              ),
            ),

            /// TEXT INPUT — always visible
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.border.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: colorScheme.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: colorScheme.border,
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
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: colorScheme.cardBackground,
                        ),
                        maxLines: null,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _messageController.text.trim().isEmpty
                          ? null
                          : _sendMessage,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _messageController.text.trim().isEmpty
                              ? colorScheme.border
                              : colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
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

  Widget _buildBubble(
      String text, bool isCustomer, DateTime timestamp, dynamic colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment:
            isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isCustomer ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isCustomer) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isCustomer
                        ? colorScheme.primary
                        : colorScheme.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isCustomer ? 16 : 4),
                      bottomRight: Radius.circular(isCustomer ? 4 : 16),
                    ),
                    border: isCustomer
                        ? null
                        : Border.all(
                            color: colorScheme.border.withValues(alpha: 0.5),
                          ),
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
                      color: isCustomer
                          ? Colors.white
                          : colorScheme.textPrimary,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 3,
              bottom: 8,
              left: isCustomer ? 0 : 36,
              right: isCustomer ? 4 : 0,
            ),
            child: Text(
              _formatTime(timestamp),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: colorScheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSuggestions(dynamic colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, right: 8, bottom: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Text(
              'Suggested questions',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.textSecondary,
              ),
            ),
          ),
          ..._faqItems.map((faq) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _handleFAQQuestion(faq),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          faq.question,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(dynamic colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: colorScheme.border.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration: Duration(milliseconds: 600 + (i * 200)),
                  builder: (context, value, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colorScheme.textSecondary
                            .withValues(alpha: value * 0.6),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
