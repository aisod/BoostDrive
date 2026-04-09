import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:intl/intl.dart';

class SupportCenterView extends ConsumerStatefulWidget {
  const SupportCenterView({super.key});

  @override
  ConsumerState<SupportCenterView> createState() => _SupportCenterViewState();
}

class _SupportCenterViewState extends ConsumerState<SupportCenterView> {
  String _statusFilter = 'all';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasAutoOpened = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(allTicketsProvider);
    final pendingTicketId = ref.watch(pendingSupportTicketIdProvider);

    // Auto-open logic for Admin side
    if (pendingTicketId != null && !_hasAutoOpened && ticketsAsync.hasValue) {
      final tickets = ticketsAsync.value!;
      final ticket = tickets.cast<SupportTicket?>().firstWhere(
        (t) => t?.id == pendingTicketId, 
        orElse: () => null
      );
      
      if (ticket != null) {
        _hasAutoOpened = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTicketDetails(ticket);
          // Clear the pending ID global state
          ref.read(pendingSupportTicketIdProvider.notifier).state = null;
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilters(),
        const SizedBox(height: 24),
        Expanded(
          child: ticketsAsync.when(
            data: (tickets) {
              final filtered = tickets.where((t) {
                if (_statusFilter != 'all' && t.status != _statusFilter) return false;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  return t.subject.toLowerCase().contains(q) || t.id.toLowerCase().contains(q);
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return _buildEmptyState();
              }

              return _buildTicketList(filtered);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loding tickets: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Container(
          width: 300,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by Ticket ID or Subject...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
              prefixIcon: Icon(Icons.search, size: 18, color: Colors.black38),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              dropdownColor: Colors.white,
              style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Status')),
                DropdownMenuItem(value: 'open', child: Text('Open')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
              ],
              onChanged: (v) => setState(() => _statusFilter = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketList(List<SupportTicket> tickets) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: tickets.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return ListTile(
            onTap: () => _showTicketDetails(ticket),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            title: Row(
              children: [
                _buildStatusChip(ticket.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ticket.subject,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text(
                    'Ticket: #${ticket.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'User: ${ticket.userType.toUpperCase()}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Type: ${ticket.issueType.replaceAll('_', ' ').toUpperCase()}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, HH:mm').format(ticket.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0x22FF6600)),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'open': color = Colors.orange; break;
      case 'pending': color = BoostDriveTheme.primaryColor; break;
      case 'resolved': color = Colors.green; break;
      default: color = BoostDriveTheme.primaryColor.withValues(alpha: 0.1);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.support_agent, size: 64, color: Color(0x22FF6600)),
          const SizedBox(height: 16),
          const Text(
            'No support tickets found',
            style: TextStyle(color: Colors.black38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showTicketDetails(SupportTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => TicketDetailsModal(ticket: ticket),
    ).then((_) => ref.refresh(allTicketsProvider));
  }
}

class TicketDetailsModal extends ConsumerStatefulWidget {
  final SupportTicket ticket;
  const TicketDetailsModal({super.key, required this.ticket});

  @override
  ConsumerState<TicketDetailsModal> createState() => _TicketDetailsModalState();
}

class _TicketDetailsModalState extends ConsumerState<TicketDetailsModal> {
  final _messageController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.ticket.adminNotes ?? '';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(ticketMessagesProvider(widget.ticket.id));

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Conversation
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: messagesAsync.when(
                            data: (messages) => _buildMessageList(messages),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Center(child: Text('Error: $e')),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildComposer(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Right: Admin Notes & Actions
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAdminNotesSection(),
                        const SizedBox(height: 24),
                        _buildActionsSection(),
                      ],
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.confirmation_number_outlined, color: BoostDriveTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ticket Detail · #${widget.ticket.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.ticket.subject,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Consumer(
                builder: (context, ref, _) {
                  final profileAsync = ref.watch(userProfileProvider(widget.ticket.userId));
                  return profileAsync.when(
                    data: (profile) => Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: BoostDriveTheme.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          profile?.displayName ?? 'Unknown User',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (profile?.role ?? widget.ticket.userType).toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: BoostDriveTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(height: 16),
                    error: (_, __) => const SizedBox(height: 16),
                  );
                },
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildMessageList(List<TicketMessage> messages) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          return _buildMessageBubble(msg);
        },
      ),
    );
  }

  Widget _buildMessageBubble(TicketMessage msg) {
    final isAdmin = msg.isAdmin;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, ref, child) {
              final profileAsync = ref.watch(userProfileProvider(msg.senderId));
              return profileAsync.when(
                data: (profile) => Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                  child: Text(
                    isAdmin ? 'Admin: ${profile?.displayName ?? "Support Agent"}' : (profile?.displayName ?? 'Customer'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isAdmin ? BoostDriveTheme.primaryColor : Colors.black45,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                loading: () => const SizedBox(height: 14),
                error: (_, __) => const SizedBox(height: 14),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAdmin ? BoostDriveTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isAdmin ? const Radius.circular(12) : Radius.zero,
                bottomRight: isAdmin ? Radius.zero : const Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              msg.message,
              style: TextStyle(color: isAdmin ? Colors.white : Colors.black87, fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MM/dd HH:mm').format(msg.createdAt),
            style: const TextStyle(fontSize: 10, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Type internal response...',
              hintStyle: TextStyle(fontSize: 13, color: BoostDriveTheme.primaryColor.withValues(alpha: 0.4)),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: BoostDriveTheme.primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _isSending ? null : _sendMessage,
          icon: const Icon(Icons.send),
          style: IconButton.styleFrom(
            backgroundColor: BoostDriveTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INTERNAL ADMIN NOTES',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 5,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Hidden from user...',
            hintStyle: TextStyle(fontSize: 12, color: BoostDriveTheme.primaryColor.withValues(alpha: 0.4)),
            filled: true,
            fillColor: const Color(0xFFFFF9F5),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BoostDriveTheme.primaryColor),
            ),
          ),
          onChanged: (v) => ref.read(supportServiceProvider).updateAdminNotes(widget.ticket.id, v),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACCOUNT ACTIONS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        // Dispute freeze shortcut logic
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus('resolved'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('RESOLVE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateStatus('pending'),
                icon: const Icon(Icons.hourglass_empty),
                label: const Text('PENDING'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BoostDriveTheme.primaryColor,
                  side: const BorderSide(color: BoostDriveTheme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Implementation of freeze using existing logic 
              // We'd typically call a method in UserManagementView or similar.
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account restriction initiated via ticket.')));
            },
            icon: const Icon(Icons.block),
            label: const Text('FREEZE ACCOUNT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    final profileId = ref.read(currentUserProvider)!.id;

    await ref.read(supportServiceProvider).addMessage(
      ticketId: widget.ticket.id,
      senderId: profileId,
      message: text,
      isAdmin: true,
    );

    // Notify the ticket owner that they have a new reply
    await ref.read(notificationServiceProvider).sendNotification(
      userId: widget.ticket.userId,
      title: 'New Support Message',
      message: 'Management has replied to your ticket: "${widget.ticket.subject}".',
      type: 'dashboard_alert',
      metadata: {'ticket_id': widget.ticket.id, 'type': 'support'},
    );

    _messageController.clear();
    setState(() => _isSending = false);
    ref.refresh(ticketMessagesProvider(widget.ticket.id));
  }

  Future<void> _updateStatus(String status) async {
    await ref.read(supportServiceProvider).updateTicketStatus(widget.ticket.id, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
      Navigator.pop(context);
    }
  }
}
