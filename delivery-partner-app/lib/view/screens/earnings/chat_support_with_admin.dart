import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenfoo_partner/utils/order_number.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/order_earnings_chat_model.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/order_earnings_chat_provider.dart';

import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class ChatFAQItem {
  final String key;
  final String question;

  ChatFAQItem({
    required this.key,
    required this.question,
  });

  factory ChatFAQItem.fromJson(Map<String, dynamic> json) {
    return ChatFAQItem(
      key: json['key']?.toString() ?? '',
      question: json['question'] ?? '',
    );
  }
}

class LocalMessage {
  final String message;
  final bool isDriver;

  LocalMessage({
    required this.message,
    required this.isDriver,
  });
}

class ChatSupportWithAdmin extends StatefulWidget {
  final int orderId;

  const ChatSupportWithAdmin({
    super.key,
    required this.orderId,
  });

  @override
  State<ChatSupportWithAdmin> createState() => _ChatSupportWithAdminState();
}

class _ChatSupportWithAdminState extends State<ChatSupportWithAdmin> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;

  List<ChatFAQItem> _faqItems = [];
  List<LocalMessage> _localMessages = [];
  bool _showFAQ = true;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = context.read<OrderEarningsChatProvider>();
      // Real-time listener handled by StreamBuilder in build, but we can mark read here
      chatProvider.markAllMessagesAsRead(widget.orderId);
      await _loadFAQ();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFAQ() async {
    final response = await context
        .read<OrderEarningsChatProvider>()
        .fetchFAQ(widget.orderId);

    // Using reference-style loose status check
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

          // Ensure "Other" is available for manual chat transition
          if (!_faqItems.any((item) => item.key == 'other')) {
            _faqItems.add(
                ChatFAQItem(key: 'other', question: 'Other (Talk to Support)'));
          }
        });
      }
    } else {
      // Fallback
      if (mounted) {
        setState(() {
          _faqItems = [
            ChatFAQItem(key: 'other', question: 'Other (Talk to Support)')
          ];
        });
      }
    }
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

  Future<void> _handleFAQQuestion(ChatFAQItem faqItem) async {
    if (faqItem.key == 'other') {
      setState(() {
        _showFAQ = false;
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _localMessages.add(
        LocalMessage(
          message: faqItem.question,
          isDriver: true,
        ),
      );
    });

    final response = await context
        .read<OrderEarningsChatProvider>()
        .submitFAQ(widget.orderId, faqItem.key);

    if (response.data != null &&
        (response.data['status'] == true ||
            response.data['status'] == 1 ||
            response.data['status'] == "1")) {
      final answer = response.data['answer'];
      if (answer != null) {
        String answerText = answer['text'] ?? '';

        if (answer['details'] != null &&
            answer['details'] is List &&
            (answer['details'] as List).isNotEmpty) {
          answerText += '\n\n';
          for (var detail in (answer['details'] as List)) {
            answerText +=
                '${detail['label'] ?? ''}: ${detail['value'] ?? ''}\n';
          }
        }

        if (answerText.isNotEmpty) {
          setState(() {
            _localMessages.add(
              LocalMessage(
                message: answerText.trim(),
                isDriver: false,
              ),
            );
          });
          _scrollToBottom();
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    setState(() {});

    final provider = context.read<OrderEarningsChatProvider>();
    await provider.sendMessage(widget.orderId, message);

    if (mounted && provider.errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();
    final chatProvider = context.watch<OrderEarningsChatProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          AppHeader(
            label: languageProvider.getTranslatedText('support'),
            title: 'Order ${formatOrderNumber(widget.orderId)} Support',
            showBackButton: true,
          ),

          if (chatProvider.errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorScheme.error.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatProvider.errorMessage,
                      style: GoogleFonts.inter(
                          color: colorScheme.error, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.error, size: 20),
                    onPressed: () =>
                        context.read<OrderEarningsChatProvider>().clearError(),
                  )
                ],
              ),
            ),

          /// FAQ SECTION
          if (_showFAQ && _faqItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _faqItems.map((faq) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _handleFAQQuestion(faq);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.border),
                      ),
                      child: Text(
                        faq.question,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          /// CHAT AREA
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                /// 1. LOCAL FAQ MESSAGES
                ..._localMessages.map((msg) =>
                    _buildBubble(msg.message, msg.isDriver, colorScheme)),

                /// 2. FIREBASE MESSAGES
                StreamBuilder<List<OrderEarningsChatMessage>>(
                  stream: chatProvider.getMessagesStream(widget.orderId),
                  builder: (context, snapshot) {
                    final firebaseMessages = snapshot.data ?? [];

                    return Column(
                      children: firebaseMessages.map((message) {
                        final isDriver = message.sender == 'driver';
                        if (!isDriver && !message.read) {
                          context
                              .read<OrderEarningsChatProvider>()
                              .markMessageAsRead(
                                  widget.orderId, message.messageId);
                        }
                        return _buildBubble(
                            message.message, isDriver, colorScheme);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          /// INPUT AREA (Visible after "Other")
          if (!_showFAQ)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.border)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.inter(
                            color: colorScheme.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                              color: colorScheme.textSecondary, fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: colorScheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: colorScheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        maxLines: null,
                        minLines: 1,
                        onChanged: (text) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: _messageController.text.trim().isEmpty
                          ? Colors.grey
                          : colorScheme.primary,
                      onPressed: (_messageController.text.trim().isEmpty ||
                              chatProvider.isSending)
                          ? null
                          : _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isDriver, dynamic colorScheme) {
    return Align(
      alignment: isDriver ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isDriver ? colorScheme.primary : colorScheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: isDriver ? null : Border.all(color: colorScheme.border),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isDriver ? Colors.white : colorScheme.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
