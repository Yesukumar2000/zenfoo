import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/order_chat_service.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/ist_time.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';

class OrderChatScreen extends StatefulWidget {
  final int orderId;
  final int sellerId;
  final String sellerName;
  final String sellerType; // 'seller' or 'driver'

  const OrderChatScreen({
    super.key,
    required this.orderId,
    required this.sellerId,
    required this.sellerName,
    this.sellerType = 'seller',
  });

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  bool _isSending = false;
  final List<ChatMessage> _messages = [];
  late OrderChatService _chatService;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _chatService = OrderChatService();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    /// Listen to real-time messages from Firebase Firestore
    /// Collection path: /chatting/{orderId}/{customer_to_driver or driver_to_seller}/
    _chatService.getChatMessagesStream(
      widget.orderId,
      senderType: widget.sellerType,
      receiverType: 'driver',
    ).listen(
      (firebaseMessages) {
        if (mounted) {
          setState(() {
            _messages.clear();
            // Convert OrderChatService ChatMessage to local ChatMessage
            for (var msg in firebaseMessages) {
              _messages.add(
                ChatMessage(
                  id: msg.id,
                  orderId: msg.orderId,
                  senderType: msg.senderType,
                  receiverType: msg.receiverType,
                  message: msg.message,
                  timestamp: msg.timestamp,
                  read: msg.read,
                ),
              );
            }
          });
          // Scroll to bottom when messages load
          _scrollToBottom();
        }
      },
      onError: (error) {
        debugPrint('❌ Error loading messages: $error');
        if (mounted) {
          _showError('Failed to load messages');
        }
      },
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final apiService = ApiService();

      // First, save to Firebase immediately (don't wait for API)
      try {
        await _chatService.addMessage(
          orderId: widget.orderId,
          message: message.trim(),
          senderType: 'driver',
          receiverType: widget.sellerType == 'customer' ? 'customer' : 'seller',
          senderId: null, // Driver ID not needed for this implementation
          receiverId: widget.sellerId,
        );
        debugPrint('✅ Message saved to Firebase');
      } catch (e) {
        debugPrint('⚠️ Warning: Failed to write to Firebase: $e');
      }

      // Clear message input immediately
      _messageController.clear();

      // Add message to local list (real message will come from Firebase listener)
      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        orderId: widget.orderId,
        senderType: 'driver',
        receiverType: widget.sellerType == 'customer' ? 'customer' : 'seller',
        message: message.trim(),
        timestamp: DateTime.now(),
        read: false,
      );

      setState(() {
        _messages.add(newMessage);
      });

      // Scroll to bottom
      _scrollToBottom();

      // Now send to API (fire and forget - don't block on this)
      try {
        final response = await apiService.post(
          AppUrl.sendChatMessage,
          data: {
            "order_id": widget.orderId,
            "message": message.trim(),
            "sender_type": "driver",
            "receiver_type": widget.sellerType == 'customer' ? 'customer' : 'seller',
            "seller_id": widget.sellerId,
          },
          isToast: false,
          isErrorToast: false,
        );

        if (isStatusSuccess(response.status)) {
          debugPrint('✅ Message sent to API successfully');
        } else {
          debugPrint('⚠️ API response not successful: ${response.message}');
          // Message already saved to Firebase, so no need to show error
        }
      } catch (e) {
        debugPrint('⚠️ API call failed (but Firebase has message): $e');
        // Message already saved to Firebase, don't show error to user
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      _showError('Error sending message');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _sendQuickMessage(String message) {
    _sendMessage(message);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      extendBody: false,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          /// Header
          AppHeader(
            label: 'CHAT',
            title: widget.sellerName,
            showBackButton: true,
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
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isDriver = message.senderType == 'driver';

                      return Align(
                        alignment: isDriver
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: 12,
                            left: isDriver ? 48 : 8,
                            right: isDriver ? 8 : 48,
                          ),
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Column(
                            crossAxisAlignment: isDriver
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDriver
                                      ? colorScheme.primary
                                      : colorScheme.cardBackground,
                                  borderRadius: isDriver
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
                                  border: !isDriver
                                      ? Border.all(
                                          color: colorScheme.cardBorder,
                                          width: 1,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
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
                                    color: isDriver
                                        ? Colors.white
                                        : colorScheme.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDriver ? 0 : 8,
                                ),
                                child: Text(
                                  _formatTime(message.timestamp),
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

          /// Quick Messages Bar (visible always)
          _buildQuickMessagesBar(colorScheme),

          /// Message Input Container (stays fixed)
          Container(
            color: colorScheme.background,
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).viewInsets.bottom,
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
                        color: colorScheme.cardBorder,
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
                    color: colorScheme.primary,
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
        ],
      ),
    );
  }

  Widget _buildQuickMessagesBar(AppColorScheme colorScheme) {
    final quickMessages = [
      'I have arrived',
      'Order is ready',
      'Package damaged',
      'On the way',
      'Waiting for you',
    ];

    return Container(
      color: colorScheme.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            quickMessages.length,
            (index) => Padding(
              padding: EdgeInsets.only(
                  right: index < quickMessages.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () => _sendQuickMessage(quickMessages[index]),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    quickMessages[index],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (messageDate == today) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

/// Chat Message Model
class ChatMessage {
  final String id;
  final int orderId;
  final String senderType; // 'driver' or 'seller'
  final String receiverType; // 'seller' or 'driver'
  final String message;
  final DateTime timestamp;
  final bool read;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderType,
    required this.receiverType,
    required this.message,
    required this.timestamp,
    required this.read,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? 0,
      senderType: json['sender_type'] ?? 'driver',
      receiverType: json['receiver_type'] ?? 'seller',
      message: json['message'] ?? '',
      timestamp: toIst(
        DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      ),
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'sender_type': senderType,
      'receiver_type': receiverType,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
    };
  }
}
