import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'chat_page.dart';

class ConversationsPage extends ConsumerWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        backgroundColor: BoostDriveTheme.backgroundDark,
        body: Center(child: Text('Please log in to view messages')),
      );
    }

    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: BoostDriveTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.watch(messageServiceProvider).streamConversations(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final conversations = snapshot.data!;
          final unreadConvs = ref.watch(unreadConversationsProvider(user.id)).value ?? {};

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final isUnread = unreadConvs.contains(conv['id']);

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Stack(
                  children: [
                    const CircleAvatar(
                      backgroundColor: BoostDriveTheme.primaryColor,
                      child: Icon(Icons.person, color: Colors.white),
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
                            border: Border.all(color: BoostDriveTheme.backgroundDark, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  conv['product_title'] ?? 'Product Inquiry',
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  conv['last_message'] ?? 'No messages yet',
                  style: TextStyle(
                    color: isUnread ? Colors.white : BoostDriveTheme.textDim,
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                onTap: () {
                  // Mark as read
                  ref.read(messageServiceProvider).markConversationAsRead(conv['id']);
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        conversationId: conv['id'],
                        productTitle: conv['product_title'] ?? 'Inquiry',
                        buyerId: conv['buyer_id'],
                        sellerId: conv['seller_id'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 24),
          const Text(
            'No conversations yet',
            style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Inquire about a listing to start a chat!',
            style: TextStyle(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
