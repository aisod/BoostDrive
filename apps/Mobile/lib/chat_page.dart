import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';

import 'package:intl/intl.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String productTitle;
  final String buyerId;
  final String sellerId;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.productTitle,
    required this.buyerId,
    required this.sellerId,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark conversation as read when entering the chat page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageServiceProvider).markConversationAsRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await ref.read(messageServiceProvider).sendMessage(
        conversationId: widget.conversationId,
        senderId: user.id,
        content: _messageController.text.trim(),
      );
      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatMessageDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final DateTime date = timestamp is String ? DateTime.parse(timestamp) : timestamp as DateTime;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day of the week
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';
    final DateTime date = timestamp is String ? DateTime.parse(timestamp) : timestamp as DateTime;
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ref.watch(messageServiceProvider).streamMessages(widget.conversationId),
      builder: (context, snapshot) {
        // We need to know who the buyer and seller are to show the correct title
        // If they aren't passed in (like from notifications), we can fetch them
        return FutureBuilder<Map<String, dynamic>>(
          future: ref.read(messageServiceProvider).getConversation(widget.conversationId),
          builder: (context, convSnapshot) {
            final conversation = convSnapshot.data;
            final buyerId = widget.buyerId.isNotEmpty ? widget.buyerId : (conversation?['buyer_id'] ?? '');
            final sellerId = widget.sellerId.isNotEmpty ? widget.sellerId : (conversation?['seller_id'] ?? '');
            final productTitle = widget.productTitle != 'Chat' ? widget.productTitle : (conversation?['product_title'] ?? 'Chat');

            return Scaffold(
              backgroundColor: BoostDriveTheme.backgroundDark,
              appBar: AppBar(
                title: buyerId.isNotEmpty && sellerId.isNotEmpty 
                  ? ref.watch(userProfileProvider(user.id == buyerId ? sellerId : buyerId)).when(
                      data: (otherProfile) => Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(otherProfile?.fullName ?? productTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text(otherProfile != null ? productTitle : 'Seller Chat', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              conversation?['product_title'] != null ? 'INQUIRY' : 'REPAIR JOB',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // WhatsApp Bridge
                            },
                            icon: const Icon(Icons.chat, size: 20),
                          ),
                        ],
                      ),
                      loading: () => Text(productTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      error: (_, __) => Text(productTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    )
                  : Text(productTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                backgroundColor: BoostDriveTheme.primaryColor,
                iconTheme: const IconThemeData(color: Colors.white),
                elevation: 1,
              ),
              body: Column(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        
                        final messages = snapshot.data!.reversed.toList();

                        return ListView.builder(
                          reverse: true,
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final rawContent = msg['content'] as String;
                            final senderId = msg['sender_id'] as String;
                            final timestamp = msg['created_at'];

                            final isMe = senderId == user.id;

                            // Date header logic
                            bool showDateHeader = false;
                            if (index == messages.length - 1) {
                              showDateHeader = true;
                            } else {
                              final prevMsg = messages[index + 1];
                              if (timestamp != null && prevMsg['created_at'] != null) {
                                final date = DateTime.parse(timestamp);
                                final prevDate = DateTime.parse(prevMsg['created_at']);
                                if (date.day != prevDate.day || date.month != prevDate.month || date.year != prevDate.year) {
                                  showDateHeader = true;
                                }
                              }
                            }

                            return Column(
                              children: [
                                if (showDateHeader)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _formatMessageDate(timestamp),
                                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                _MessageBubble(
                                  content: rawContent,
                                  isMe: isMe, 
                                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  color: isMe ? BoostDriveTheme.primaryColor : Colors.white.withOpacity(0.05),
                                  time: _formatMessageTime(timestamp),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  _buildInput(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: BoostDriveTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final Alignment alignment;
  final Color color;
  final String time;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    required this.alignment,
    required this.color,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white.withOpacity(0.6) : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
