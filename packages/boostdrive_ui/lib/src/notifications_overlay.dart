import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'theme.dart';
import 'package:intl/intl.dart';

class NotificationsOverlay extends ConsumerStatefulWidget {
  final Function(String type, String id)? onNotificationTap;
  const NotificationsOverlay({super.key, this.onNotificationTap});

  @override
  ConsumerState<NotificationsOverlay> createState() => _NotificationsOverlayState();
}

class _NotificationsOverlayState extends ConsumerState<NotificationsOverlay> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _optimisticReadIds = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _processNotifications(
    String currentUserId,
    List<Map<String, dynamic>> conversations,
    Set<String> unreadConversationIds,
    List<DeliveryOrder> deliveries,
    List<Map<String, dynamic>> sosRequests,
  ) {
    final List<Map<String, dynamic>> all = [];

    // 1. Messages from Conversations
    for (var conv in conversations) {
      // Filter conversations where the user is a participant
      if (conv['buyer_id'] != currentUserId && conv['seller_id'] != currentUserId) continue;

      final isBuyer = conv['buyer_id'] == currentUserId;
      final otherPartyId = isBuyer ? conv['seller_id'] : conv['buyer_id'];
      
      // The orange dot should only appear if:
      // 1. There are unread messages in the conversation (checked via unreadConversationIds)
      // 2. OR it's optimistically marked as read
      final convId = conv['id']?.toString() ?? '';
      final hasUnreadMessages = unreadConversationIds.contains(convId);
      final isRead = !hasUnreadMessages || _optimisticReadIds.contains('msg_$convId');
      
      debugPrint('DEBUG: Notification msg_$convId - hasUnread: $hasUnreadMessages, optimistic: ${_optimisticReadIds.contains('msg_$convId')}, final isRead: $isRead');
      
      all.add({
        'id': 'msg_$convId',
        'title': 'New Message',
        'message': conv['last_message'] ?? 'You have an active conversation regarding a product.',
        'time': _formatTime(conv['created_at']),
        'isRead': isRead,
        'icon': Icons.message,
        'type': 'message',
        'userId': otherPartyId,
        'timestamp': conv['created_at'] != null ? DateTime.parse(conv['created_at']) : DateTime.now(),
      });
    }

    // 2. Delivery Updates
    for (var order in deliveries) {
      all.add({
        'id': 'del_${order.id}',
        'title': 'Order ${order.status.replaceAll('_', ' ').toUpperCase()}',
        'message': 'Your order #${order.id.substring(0, 8)} is currently ${order.status.replaceAll('_', ' ')}.',
        'time': 'Update',
        'isRead': order.status == 'delivered',
        'icon': Icons.local_shipping,
        'type': 'delivery',
        'timestamp': order.createdAt,
      });
    }

    // 3. SOS Requests (Mobile Only)
    // We check if we are on web by checking the platform. 
    // However, since this is a UI package, we'll use a simple check or just rely on the fact that 
    // SOS data won't be passed from the web app if we remove the providers there.
    // To be safe, we'll check for kIsWeb.
    const bool isWeb = bool.fromEnvironment('dart.library.js_util'); 
    if (!isWeb) {
      for (var sos in sosRequests) {
        all.add({
          'id': 'sos_${sos['id']}',
          'title': 'SOS ${sos['status'].toUpperCase()}',
          'message': 'Your emergency request for ${sos['type']} is ${sos['status']}.',
          'time': _formatTime(sos['created_at']),
          'isRead': true, // Default SOS to read for now since we don't have is_read column
          'icon': Icons.warning_amber_rounded,
          'type': 'sos',
          'timestamp': DateTime.parse(sos['created_at']),
        });
      }
    }

    // Sort by timestamp descending
    all.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    // Filter by tab
    final currentIndex = _tabController.index;
    var filtered = all;
    if (currentIndex == 1) {
      filtered = all.where((n) => !n['isRead']).toList();
    } else if (currentIndex == 2) {
      filtered = all.where((n) => n['isRead']).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((n) {
        final title = (n['title'] as String).toLowerCase();
        final message = (n['message'] as String).toLowerCase();
        return title.contains(_searchQuery) || message.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final dt = timestamp is String ? DateTime.parse(timestamp) : timestamp as DateTime;
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d').format(dt);
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Dialog(child: Padding(padding: EdgeInsets.all(20), child: Text('Please log in to see notifications')));
    }

    final conversationsAsync = ref.watch(userConversationsProvider(user.id));
    final unreadConvsAsync = ref.watch(unreadConversationsProvider(user.id));
    final deliveriesAsync = ref.watch(activeDeliveriesProvider(user.id));
    final sosAsync = ref.watch(userActiveSosRequestsProvider(user.id));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1D2939),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF667085)),
                  ),
                ],
              ),
            ),

            // Mark All as Read Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _handleMarkAllAsRead(user.id, conversationsAsync.value),
                    icon: const Icon(Icons.done_all, size: 18, color: BoostDriveTheme.primaryColor),
                    label: Text(
                      'Mark all as read',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: BoostDriveTheme.primaryColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: BoostDriveTheme.primaryColor.withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: BoostDriveTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF667085),
                labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14),
                dividerColor: Colors.transparent,
                onTap: (_) => setState(() {}),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Unread'),
                  Tab(text: 'Read'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search notifications...',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 14,
                      color: const Color(0xFF98A2B3),
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF667085)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.black, // Visible text color
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notifications List
            Expanded(
              child: conversationsAsync.when(
                data: (convs) => unreadConvsAsync.when(
                  data: (unreadIds) => deliveriesAsync.when(
                    data: (dels) => sosAsync.when(
                      data: (sos) {
                        final filtered = _processNotifications(user.id, convs, unreadIds, dels, sos);
                        if (filtered.isEmpty) {
                          return _buildEmptyState();
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) => _buildNotificationItem(filtered[index]),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error loading SOS: $e')),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error loading deliveries: $e')),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading unread info: $e')),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading messages: $e')),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: const Color(0xFF98A2B3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: notification['isRead'] 
                    ? const Color(0xFFF9FAFB) 
                    : BoostDriveTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification['icon'],
                size: 20,
                color: notification['isRead'] 
                    ? const Color(0xFF667085) 
                    : BoostDriveTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: notification['isRead'] ? FontWeight.w600 : FontWeight.w800,
                            color: const Color(0xFF1D2939),
                          ),
                        ),
                      ),
                      if (!notification['isRead'])
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: BoostDriveTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'],
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: const Color(0xFF667085),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['time'],
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    final type = notification['type'] as String?;
    final id = notification['id'] as String;
    final realId = id.split('_').last;

    debugPrint('DEBUG: Notification tapped: $type - $realId');

    // Mark as read in backend
    try {
      if (type == 'message') {
        debugPrint('DEBUG: Marking conversation $realId as read');
        await ref.read(messageServiceProvider).markConversationAsRead(realId);
      } else if (type == 'delivery') {
        // For deliveries, we might just track if the user viewed it
        // await ref.read(deliveryServiceProvider).markAsRead(realId);
      }
    } catch (e) {
      debugPrint('DEBUG: Error marking notification as read: $e');
    }

    // Force a local state update to hide the dot immediately
    if (mounted) {
      setState(() {
        _optimisticReadIds.add('msg_$realId');
      });
      
      // Small delay to ensure the UI updates before the dialog closes
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (mounted) {
        Navigator.pop(context);
        if (widget.onNotificationTap != null) {
          widget.onNotificationTap!(type ?? '', realId);
        }
      }
    }
  }

  void _handleMarkAllAsRead(String userId, List<Map<String, dynamic>>? conversations) async {
    if (userId.isEmpty) return;
    
    try {
      // Optimistically update local state
      if (conversations != null) {
        setState(() {
          for (var conv in conversations) {
            final id = conv['id'] as String? ?? '';
            if (id.isNotEmpty) _optimisticReadIds.add('msg_$id');
          }
        });
      }
      
      await ref.read(messageServiceProvider).markAllAsRead(userId);
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }
}
