import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:intl/intl.dart';

class MessagesPage extends ConsumerStatefulWidget {
  final String? initialConversationId;
  
  const MessagesPage({super.key, this.initialConversationId});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  String? _selectedConversationId;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialConversationId != null) {
      _selectedConversationId = widget.initialConversationId;
      // Mark as read if an initial conversation is provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(messageServiceProvider).markConversationAsRead(widget.initialConversationId!);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedConversationId == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await ref.read(messageServiceProvider).sendMessage(
        conversationId: _selectedConversationId!,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
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
      return DateFormat('EEEE').format(date);
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view messages')),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return Scaffold(
        backgroundColor: BoostDriveTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: BoostDriveTheme.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            _selectedConversationId == null ? 'Messages' : 'Chat',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: _selectedConversationId != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => setState(() => _selectedConversationId = null),
                )
              : null,
        ),
        body: _selectedConversationId == null
            ? _buildConversationList(user.id)
            : _buildChatView(user.id),
      );
    }

    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      body: Row(
        children: [
          // Conversations List
          SizedBox(
            width: 350,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Messages',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: _buildConversationList(user.id)),
                ],
              ),
            ),
          ),
          // Chat View
          Expanded(
            child: _selectedConversationId == null
                ? _buildEmptyState()
                : _buildChatView(user.id),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(String conversationId, String productTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Conversation', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(messageServiceProvider).deleteConversation(conversationId);
        
        // If the deleted conversation was selected, clear selection
        if (_selectedConversationId == conversationId) {
          setState(() {
            _selectedConversationId = null;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete conversation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildConversationList(String userId) {
    return ref.watch(userConversationsProvider(userId)).when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return const Center(
            child: Text(
              'No conversations yet',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        // Sort conversations by created_at descending to show newest first
        final sortedConversations = List<Map<String, dynamic>>.from(conversations);
        sortedConversations.sort((a, b) {
          final aTime = a['created_at'] != null ? DateTime.parse(a['created_at']) : DateTime(2000);
          final bTime = b['created_at'] != null ? DateTime.parse(b['created_at']) : DateTime(2000);
          return bTime.compareTo(aTime);
        });

        return ListView.separated(
          itemCount: sortedConversations.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
          itemBuilder: (context, index) {
            final conv = sortedConversations[index];
            final isSelected = conv['id'] == _selectedConversationId;
            final otherUserId = conv['buyer_id'] == userId ? conv['seller_id'] : conv['buyer_id'];
            
            // Unread indicator logic for the conversation list
            final unreadConvs = ref.watch(unreadConversationsProvider(userId)).value ?? {};
            final isUnread = unreadConvs.contains(conv['id']);

            return ListTile(
              selected: isSelected,
              selectedTileColor: BoostDriveTheme.primaryColor.withOpacity(0.1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: ref.watch(userProfileProvider(otherUserId)).when(
                data: (profile) => Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: BoostDriveTheme.primaryColor,
                      child: Text(
                        profile != null && profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: BoostDriveTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                loading: () => const CircleAvatar(backgroundColor: Colors.white10, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white24)),
              ),
              title: ref.watch(userProfileProvider(otherUserId)).when(
                data: (profile) => Text(
                  profile?.fullName ?? 'User',
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: isUnread ? FontWeight.w900 : FontWeight.w600, 
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => const Text('Loading...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                error: (_, __) => const Text('User', style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    conv['product_title'] ?? 'Product',
                    style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conv['last_message'] ?? 'Start a conversation',
                    style: TextStyle(
                      color: isUnread ? Colors.white : Colors.white54, 
                      fontSize: 12,
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (conv['created_at'] != null)
                    Text(
                      _formatMessageDate(conv['created_at']),
                      style: TextStyle(
                        color: isUnread ? BoostDriveTheme.primaryColor : Colors.white24, 
                        fontSize: 10,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showDeleteConfirmation(conv['id'], conv['product_title'] ?? 'this conversation'),
                    child: Icon(
                      Icons.delete_outline,
                      color: isSelected ? BoostDriveTheme.primaryColor : Colors.red.withOpacity(0.5),
                      size: 18,
                    ),
                  ),
                ],
              ),
              onTap: () {
                setState(() {
                  _selectedConversationId = conv['id'];
                });
                // Mark as read when selected
                ref.read(messageServiceProvider).markConversationAsRead(conv['id']);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildChatView(String userId) {
    return Column(
      children: [
        // Chat Header
        FutureBuilder<Map<String, dynamic>>(
          future: ref.read(messageServiceProvider).getConversation(_selectedConversationId!),
          builder: (context, convSnapshot) {
            if (!convSnapshot.hasData) return const SizedBox();
            final conversation = convSnapshot.data!;
            final otherUserId = conversation['buyer_id'] == userId ? conversation['seller_id'] : conversation['buyer_id'];
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: BoostDriveTheme.primaryColor,
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  ref.watch(userProfileProvider(otherUserId)).when(
                    data: (profile) => CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        profile != null && profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    loading: () => const CircleAvatar(radius: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    error: (_, __) => const CircleAvatar(radius: 20, child: Icon(Icons.person, color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ref.watch(userProfileProvider(otherUserId)).when(
                              data: (profile) => Text(
                                profile?.fullName ?? 'User',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              loading: () => const Text('Loading...', style: TextStyle(color: Colors.white70)),
                              error: (_, __) => const Text('User', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                conversation['product_title'] != null ? 'INQUIRY' : 'REPAIR JOB',
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          conversation['product_title'] ?? 'Service Request',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // WhatsApp Bridge Logic
                      final phone = '264812345678'; // Placeholder
                      final url = 'https://wa.me/$phone';
                      // launchUrl(Uri.parse(url));
                    },
                    icon: const Icon(Icons.chat, color: Colors.white),
                    tooltip: 'WhatsApp Bridge',
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: ref.watch(conversationMessagesProvider(_selectedConversationId!)).when(
            data: (messages) {
              return FutureBuilder<Map<String, dynamic>>(
                future: ref.read(messageServiceProvider).getConversation(_selectedConversationId!),
                builder: (context, convSnapshot) {
                  if (!convSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final conversation = convSnapshot.data!;
                  final buyerId = conversation['buyer_id'] as String;
                  final sellerId = conversation['seller_id'] as String;
                  
                  final sortedMessages = messages.reversed.toList();
                  return _buildMessageList(sortedMessages, buyerId, sellerId, userId);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                mini: true,
                onPressed: _sendMessage,
                backgroundColor: BoostDriveTheme.primaryColor,
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList(List<Map<String, dynamic>> messages, String buyerId, String sellerId, String currentUserId) {
    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final senderId = msg['sender_id'] as String;
        
        // Buyer messages (senderId == buyerId) -> RIGHT
        // Seller messages (senderId == sellerId) -> LEFT
        final isBuyerMessage = senderId == buyerId;
        final isMe = senderId == currentUserId;
        
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Date header logic
              if (index == messages.length - 1 || _shouldShowDateHeader(messages[index], messages[index + 1]))
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
                        _formatMessageDate(msg['created_at']),
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (MediaQuery.of(context).size.width < 900 ? 0.75 : 0.45)),
                decoration: BoxDecoration(
                  // My messages: Orange gradient
                  gradient: isMe ? const LinearGradient(
                    colors: [BoostDriveTheme.primaryColor, Colors.orangeAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ) : null,
                  // Other messages: White/Glassmorphism
                  color: isMe ? null : Colors.white,
                  boxShadow: isMe ? [
                    BoxShadow(
                      color: BoostDriveTheme.primaryColor.withOpacity(0.3), 
                      blurRadius: 8, 
                      offset: const Offset(0, 4)
                    )
                  ] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                  border: isMe ? null : Border.all(color: Colors.black12),
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
                    // Label logic: only show label for the message that isn't from the viewer
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          isBuyerMessage ? 'Buyer' : 'Seller',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    Text(
                      msg['content'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMessageTime(msg['created_at']),
                      style: TextStyle(
                        color: isMe ? Colors.white.withOpacity(0.6) : Colors.black54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _shouldShowDateHeader(Map<String, dynamic> current, Map<String, dynamic> next) {
    if (current['created_at'] == null || next['created_at'] == null) return false;
    final date1 = DateTime.parse(current['created_at']);
    final date2 = DateTime.parse(next['created_at']);
    return date1.day != date2.day || date1.month != date2.month || date1.year != date2.year;
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'Select a conversation to start messaging',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
