import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;

class HelpChatScreen extends StatefulWidget {
  const HelpChatScreen({super.key});

  @override
  State<HelpChatScreen> createState() => _HelpChatScreenState();
}

class _HelpChatScreenState extends State<HelpChatScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();

    // Get user ID from session
    final sessionManager = context.read<SessionManager>();
    _userId = sessionManager.getData(SessionManager.keyUserId);
  }

  @override
  void didUpdateWidget(HelpChatScreen oldWidget) {
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

    try {
      // Send to API. The server writes the message into the same Firestore
      // subcollection this screen streams from and notifies the admin panel,
      // so the client must not write the message itself — that would duplicate it.
      final res = await sendApiRequest(
        apiName: '${Constant.hostUrl}customer/support-chat/send',
        isPost: true,
        context: context,
        params: {
          'message': message.trim(),
        },
      );

      if (res != null) {
        debugPrint('Message sent successfully to support');
      } else {
        debugPrint('Error sending message to API');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }

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
        child: AppHeader(
          label: 'Help & Support',
          title: 'Chat with Admin',
          showBackButton: true,
          onBackPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('admin_customer_chatting')
                  .doc(_userId)
                  .collection('messages')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet\nStart a conversation',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final isCustomerMessage = messageData['sender'] == 'customer';
                    final messageText = messageData['message'] ?? '';
                    final timeDisplay = messageData['time_display'] ?? '';

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: 12,
                        left: isCustomerMessage ? 50 : 16,
                        right: isCustomerMessage ? 16 : 50,
                      ),
                      child: Align(
                        alignment: isCustomerMessage
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isCustomerMessage
                                ? colorScheme.primary
                                : const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(14),
                              topRight: Radius.circular(14),
                              bottomLeft: isCustomerMessage
                                  ? Radius.circular(14)
                                  : Radius.circular(4),
                              bottomRight: isCustomerMessage
                                  ? Radius.circular(4)
                                  : Radius.circular(14),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: isCustomerMessage
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                messageText,
                                style: TextStyle(
                                  color: isCustomerMessage
                                      ? colorScheme.surface
                                      : const Color(0xFF1F1F1F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeDisplay,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isCustomerMessage
                                      ? colorScheme.surface.withValues(alpha: 0.6)
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                      icon: Icon(Icons.send_rounded),
                      color: colorScheme.surface,
                      onPressed: _sendMessage,
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
}
