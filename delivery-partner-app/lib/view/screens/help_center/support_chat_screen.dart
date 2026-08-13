import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/support_chat_model.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/personal_details_provider.dart';
import 'package:zenfoo_partner/providers/support_chat_provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/help_center/widgets/quick_chat_suggestions.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Cached so rebuilds (e.g. quick message taps) don't re-subscribe.
  Stream<List<SupportChatMessage>>? _messagesStream;
  int _streamDeliveryBoyId = 0;

  /// Drives the quick message bar: it only sits above the input once the
  /// conversation has started — before that the whole empty state is suggestions.
  bool _hasMessages = false;

  Stream<List<SupportChatMessage>> _messagesStreamFor(int deliveryBoyId) {
    if (_messagesStream == null || _streamDeliveryBoyId != deliveryBoyId) {
      _streamDeliveryBoyId = deliveryBoyId;
      _messagesStream = context
          .read<SupportChatProvider>()
          .getSupportMessagesStream(deliveryBoyId);
    }
    return _messagesStream!;
  }

  void _syncHasMessages(bool hasMessages) {
    if (_hasMessages == hasMessages) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _hasMessages != hasMessages) {
        setState(() => _hasMessages = hasMessages);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Mark all messages as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final personalDetails =
          context.read<PersonalDetailsProvider>().personalDetails;
      if (personalDetails?.id != null) {
        context
            .read<SupportChatProvider>()
            .markAllMessagesAsRead(personalDetails!.id);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSending = false;

  Future<void> _sendMessage() => _sendText(_messageController.text);

  /// Sends [text] as a support message. Used both by the input field and by the
  /// one-tap quick messages.
  Future<void> _sendText(String text) async {
    final message = text.trim();
    if (message.isEmpty || _isSending) return;

    final personalDetails =
        context.read<PersonalDetailsProvider>().personalDetails;
    if (personalDetails?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await context
          .read<SupportChatProvider>()
          .sendSupportMessage(personalDetails!.id, message);

      _messageController.clear();
      // Auto scroll to latest message
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final personalDetails =
        context.watch<PersonalDetailsProvider>().personalDetails;
    final deliveryBoyId = personalDetails?.id ?? 0;

    return CustomScaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: context
                .watch<LanguageProvider>()
                .getTranslatedText('help_support'),
            title: context
                .watch<LanguageProvider>()
                .getTranslatedText('chat_with_us'),
            showBackButton: true,
            showExitButton: false,
          ),

          /// CHAT MESSAGES
          Expanded(
            child: deliveryBoyId == 0
                ? Center(
                    child: Text(
                      'User information not available',
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                : StreamBuilder<List<SupportChatMessage>>(
                    stream: _messagesStreamFor(deliveryBoyId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading messages',
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      final messages = snapshot.data ?? [];
                      _syncHasMessages(messages.isNotEmpty);

                      if (messages.isEmpty) {
                        // No conversation yet — offer ready-made messages so the
                        // partner can start with one tap.
                        return QuickChatEmptyState(onSelect: _sendText);
                      }

                      // Sort messages by time (newest first for display)
                      final sortedMessages = messages.toList()
                        ..sort((a, b) => a.time.compareTo(b.time));

                      // Auto scroll to bottom
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 12,
                        ),
                        itemCount: sortedMessages.length,
                        itemBuilder: (context, index) {
                          final message = sortedMessages[index];
                          final isDeliveryBoy =
                              message.sender == 'delivery_boy';

                          // Mark admin messages as read when displayed
                          if (!isDeliveryBoy && !message.read) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              context
                                  .read<SupportChatProvider>()
                                  .markMessageAsRead(
                                      deliveryBoyId, message.messageId);
                            });
                          }

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: 12,
                              left: isDeliveryBoy ? 50 : 16,
                              right: isDeliveryBoy ? 16 : 50,
                            ),
                            child: Align(
                              alignment: isDeliveryBoy
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                decoration: BoxDecoration(
                                  color: isDeliveryBoy
                                      ? colorScheme.primary
                                      : const Color(0xFFE8E8E8),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(14),
                                    topRight: const Radius.circular(14),
                                    bottomLeft: isDeliveryBoy
                                        ? const Radius.circular(14)
                                        : const Radius.circular(4),
                                    bottomRight: isDeliveryBoy
                                        ? const Radius.circular(4)
                                        : const Radius.circular(14),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: isDeliveryBoy
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      message.message,
                                      style: GoogleFonts.inter(
                                        color: isDeliveryBoy
                                            ? Colors.white
                                            : const Color(0xFF1F1F1F),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message.timeDisplay,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isDeliveryBoy
                                            ? Colors.white.withValues(
                                                alpha: 0.6,
                                              )
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

          /// QUICK MESSAGES — one-tap suggestions above the input.
          /// Hidden on the empty state, which already lists every suggestion.
          if (_hasMessages)
            Consumer<SupportChatProvider>(
              builder: (context, chatProvider, _) => Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.border.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(top: 10, bottom: 2),
                child: QuickChatBar(
                  onSelect: _sendText,
                  enabled: !chatProvider.isSending && !_isSending,
                ),
              ),
            ),

          /// MESSAGE INPUT AREA
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              // The quick message bar above already draws this divider.
              border: _hasMessages
                  ? null
                  : Border(
                      top: BorderSide(
                        color: colorScheme.border.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Consumer<SupportChatProvider>(
              builder: (context, chatProvider, _) {
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !chatProvider.isSending && !_isSending,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: context
                              .watch<LanguageProvider>()
                              .getTranslatedText('type_message'),
                          hintStyle: GoogleFonts.inter(
                            color: colorScheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: colorScheme.border.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: colorScheme.border.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: (chatProvider.isSending || _isSending)
                          ? null
                          : _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (chatProvider.isSending || _isSending)
                              ? colorScheme.primary.withValues(alpha: 0.5)
                              : colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: (chatProvider.isSending || _isSending)
                              ? []
                              : [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: (chatProvider.isSending || _isSending)
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
                  ],
                );
              },
            ),
          ),

          /// ERROR MESSAGE
          if (context.watch<SupportChatProvider>().errorMessage.isNotEmpty)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.watch<SupportChatProvider>().errorMessage,
                      style: GoogleFonts.inter(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.read<SupportChatProvider>().clearError();
                    },
                    child: Icon(
                      Icons.close,
                      color: Colors.red.shade700,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
