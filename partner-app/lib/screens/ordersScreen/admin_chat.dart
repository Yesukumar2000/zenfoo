import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/widgets/app_header.dart';
import '../../services/admin_chat_service.dart';

class SellerAdminChatScreen extends StatefulWidget {

  final int sellerId;
  const SellerAdminChatScreen({
    super.key,
   required this.sellerId,
  });

  @override
  State<SellerAdminChatScreen> createState() => _SellerAdminChatScreenState();
}

class _SellerAdminChatScreenState extends State<SellerAdminChatScreen> {

  StreamSubscription<List<AdminChatMessage>>? _chatSubscription;
   final TextEditingController _messageController = TextEditingController();
final ScrollController _scrollController = ScrollController();
final AdminChat _chatService = AdminChat();
  bool _isSending = false;
  final List<AdminChatMessage> _messages = [];
 
  @override
  void initState() {
    super.initState();
  
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

 void _loadMessages() {
  _chatService
      .getChatMessagesStreams(widget.sellerId)
      .listen((firebaseMessage) {
    if (!mounted) return;

    setState(() {
      _messages
        ..clear()
        ..addAll(firebaseMessage)
        ..sort((a, b) => (a.time ?? DateTime.now()).compareTo(b.time ?? DateTime.now()));
    });

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }, onError: (e) {
    debugPrint('Stream error: $e');
    _showError('Failed to load messages');
  });
}

 Future<void> _sendMessage(String message) async {
  if (message.trim().isEmpty) return;

  setState(() => _isSending = true);

  try {
    final text = message.trim();
    _messageController.clear();

    await _chatService.addMessages(
      sellerId: widget.sellerId,
      orderId: 0,
      message: text,
      senderType: 'seller',
    );

  } catch (e) {
    _showError('Send failed');
    _messageController.text = message;
  } finally {
    if (mounted) setState(() => _isSending = false);
  }
}

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          // If animation fails, try jumpTo as fallback
          try {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          } catch (e) {
            debugPrint('❌ Error scrolling to bottom: $e');
          }
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// Header
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return AppHeader(
                label: getTranslatedValue(context, chatLabel),
                // label: getTranslatedValue(context, chatLabel),
                title: 'Support',
                // title: widget.sellerId.toString(),
                showBackButton: true,
              );
            },
          ),

          /// Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: colorScheme.textSecondary,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.textSecondary
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      // For seller app: seller messages on right, driver messages on left
                     final isSeller = message.sender == 'seller';

                      return Align(
                        alignment: isSeller
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: 12,
                            left: isSeller ? 48 : 8,
                            right: isSeller ? 8 : 48,
                          ),
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Column(
                            crossAxisAlignment: isSeller
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSeller
                                      ? Color(0xFF059669)
                                      : colorScheme.cardBackground,
                                  borderRadius: isSeller
                                      ? const BorderRadius.only(
                                          topLeft: Radius.circular(18),
                                          topRight: Radius.circular(18),
                                          bottomLeft: Radius.circular(18),
                                          bottomRight: Radius.circular(4),
                                        )
                                      : const BorderRadius.only(
                                          topLeft: Radius.circular(18),
                                          topRight: Radius.circular(18),
                                          bottomLeft: Radius.circular(4),
                                          bottomRight: Radius.circular(18),
                                        ),
                                  border: !isSeller
                                      ? Border.all(
                                          color: colorScheme.border,
                                          width: 1,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  message.message,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isSeller
                                        ? Colors.white
                                        : colorScheme.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSeller ? 0 : 8,
                                ),
                                child: Text(
                                 _formatTime(message.time ?? DateTime.now()),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: colorScheme.textSecondary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          /// Message Input Container
          SafeArea(
            top: false,
            child: Container(
              color: colorScheme.background,
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 ,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: colorScheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.border,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: colorScheme.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.textPrimary,
                        ),
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF059669),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSending
                            ? null
                            : () => _sendMessage(_messageController.text),
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: _isSending
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    // Convert UTC to local time
    final localDateTime = dateTime.toLocal();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      localDateTime.year,
      localDateTime.month,
      localDateTime.day,
    );

    if (messageDate == today) {
      // 12-hour format with AM/PM
      final hour = localDateTime.hour;
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final amPm = hour < 12 ? 'AM' : 'PM';
      return '$hour12:${localDateTime.minute.toString().padLeft(2, '0')} $amPm';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${localDateTime.day}/${localDateTime.month}';
    }
  }
}
