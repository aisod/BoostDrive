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
  bool _isMarkingAllAsRead = false;

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

  /// Derives a descriptive notification title from the product attached to a conversation.
  String _conversationTitle(Map<String, dynamic> conv) {
    final productId = conv['product_id'] as String?;
    if (productId == null || productId.isEmpty) return 'New Message';

    final productAsync = ref.watch(productByIdProvider(productId));
    final product = productAsync.valueOrNull;
    if (product == null) return 'New Message';

    final typeLabel = _listingTypeLabel(product.category);
    final name = product.title.isNotEmpty ? product.title : 'a listing';
    return '$typeLabel – $name';
  }

  /// Human-readable listing type from the product category.
  String _listingTypeLabel(String? category) {
    if (category == null || category.isEmpty) return 'Message';
    switch (category.toLowerCase()) {
      case 'car':
        return 'Vehicle for sale';
      case 'part':
        return 'Spare part for sale';
      case 'rental':
        return 'Car for rent';
      default:
        return 'Message';
    }
  }

  /// Build a subtitle for the notification using the sender's name when available.
  String _conversationSubtitle(Map<String, dynamic> conv, String currentUserId) {
    final isBuyer = conv['buyer_id'] == currentUserId;
    final otherUserId = isBuyer ? conv['seller_id'] : conv['buyer_id'];
    final otherProfileAsync = ref.watch(userProfileProvider(otherUserId ?? ''));
    final otherName = otherProfileAsync.valueOrNull?.fullName;

    final lastMsg = conv['last_message'] as String?;
    if (lastMsg != null && lastMsg.isNotEmpty) {
      if (otherName != null && otherName.isNotEmpty) return '$otherName: $lastMsg';
      return lastMsg;
    }
    if (otherName != null && otherName.isNotEmpty) return 'Conversation with $otherName';
    return 'You have an active conversation regarding a product.';
  }

  List<Map<String, dynamic>> _processNotifications(
    String currentUserId,
    List<Map<String, dynamic>> conversations,
    Set<String> unreadConversationIds,
    List<DeliveryOrder> deliveries,
    List<SosRequest> sosRequests,
  ) {
    final List<Map<String, dynamic>> all = [];

    for (var conv in conversations) {
      if (conv['buyer_id'] != currentUserId && conv['seller_id'] != currentUserId) continue;

      final isBuyer = conv['buyer_id'] == currentUserId;
      final otherPartyId = isBuyer ? conv['seller_id'] : conv['buyer_id'];
      
      final convId = conv['id']?.toString() ?? '';
      final isRead = !unreadConversationIds.contains(convId);
      
      all.add({
        'id': 'msg_$convId',
        'title': _conversationTitle(conv),
        'message': _conversationSubtitle(conv, currentUserId),
        'time': _formatTime(conv['created_at']),
        'isRead': isRead,
        'icon': Icons.message,
        'type': 'message',
        'userId': otherPartyId,
        'timestamp': conv['created_at'] != null ? DateTime.parse(conv['created_at']) : DateTime.now(),
      });
    }

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

    const bool isWeb = bool.fromEnvironment('dart.library.js_util'); 
    if (!isWeb) {
      for (var sos in sosRequests) {
        all.add({
          'id': 'sos_${sos.id}',
          'title': 'SOS ${sos.status.toUpperCase()}',
          'message': 'Your emergency request for ${sos.type} is ${sos.status}.',
          'time': _formatTime(sos.createdAt),
          'isRead': true,
          'icon': Icons.warning_amber_rounded,
          'type': 'sos',
          'timestamp': sos.createdAt,
        });
      }
    }

    all.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    final currentIndex = _tabController.index;
    var filtered = all;
    if (currentIndex == 1) {
      filtered = all.where((n) => !n['isRead']).toList();
    } else if (currentIndex == 2) {
      filtered = all.where((n) => n['isRead']).toList();
    }

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
              color: Colors.black.withValues(alpha: 0.1),
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
                    onPressed: _isMarkingAllAsRead ? null : () => _handleMarkAllAsRead(user.id),
                    icon: _isMarkingAllAsRead
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: BoostDriveTheme.primaryColor,
                            ),
                          )
                        : const Icon(Icons.done_all, size: 18, color: BoostDriveTheme.primaryColor),
                    label: Text(
                      _isMarkingAllAsRead ? 'Marking...' : 'Mark all as read',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: BoostDriveTheme.primaryColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.05),
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
                    : BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
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

    final user = ref.read(currentUserProvider);

    try {
      if (type == 'message') {
        await ref.read(messageServiceProvider).markConversationAsRead(realId);
        if (user != null) {
          ref.invalidate(unreadConversationsProvider(user.id));
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }

    if (!mounted) return;
    Navigator.pop(context);
    if (widget.onNotificationTap != null) {
      widget.onNotificationTap!(type ?? '', realId);
    }
  }

  Future<void> _handleMarkAllAsRead(String userId) async {
    if (userId.isEmpty) return;
    if (_isMarkingAllAsRead) return;

    setState(() => _isMarkingAllAsRead = true);
    try {
      await ref.read(messageServiceProvider).markAllAsRead(userId);
      if (!mounted) return;
      ref.invalidate(unreadConversationsProvider(userId));
      if (!mounted) return;
      setState(() => _isMarkingAllAsRead = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            'All notifications marked as read',
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: BoostDriveTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      if (mounted) {
        setState(() => _isMarkingAllAsRead = false);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('Could not mark all as read: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingAllAsRead = false);
    }
  }
}
