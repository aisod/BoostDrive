import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';

class UserSupportView extends ConsumerStatefulWidget {
  final String userId;
  final String userType;

  const UserSupportView({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  ConsumerState<UserSupportView> createState() => _UserSupportViewState();
}

class _UserSupportViewState extends ConsumerState<UserSupportView> {
  String? _lastAutoOpenedId;

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(userTicketsProvider(widget.userId));
    final pendingTicketId = ref.watch(pendingSupportTicketIdProvider);

    // Auto-open logic when tickets are loaded and pending ID is present
    if (pendingTicketId != null && _lastAutoOpenedId != pendingTicketId && ticketsAsync.hasValue) {
      final tickets = ticketsAsync.value!;
      final ticket = tickets.cast<SupportTicket?>().firstWhere(
        (t) => t?.id == pendingTicketId, 
        orElse: () => null
      );
      
      if (ticket != null) {
        _lastAutoOpenedId = pendingTicketId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTicketDetails(context, ref, ticket);
          // Clear it in state but we already have _lastAutoOpenedId to prevent loops
          ref.read(pendingSupportTicketIdProvider.notifier).state = null;
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Help & Support',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'View your previous tickets or submit a new request.',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 14),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showCreateTicketDialog(context, ref),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('NEW TICKET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: BoostDriveTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        ticketsAsync.when(
          data: (tickets) {
            if (tickets.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.support_agent, size: 64, color: BoostDriveTheme.textDim.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    const Text('No support tickets yet.', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16)),
                  ],
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final t = tickets[index];
                return _buildTicketCard(context, ref, t);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
        ),
      ],
    );
  }

  Widget _buildTicketCard(BuildContext context, WidgetRef ref, SupportTicket ticket) {
    Color statusColor = Colors.orange;
    if (ticket.status == 'resolved') statusColor = Colors.green;
    if (ticket.status == 'closed') statusColor = BoostDriveTheme.primaryColor.withValues(alpha: 0.1);

    return InkWell(
      onTap: () => _showTicketDetails(context, ref, ticket),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: BoostDriveTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.assignment, color: BoostDriveTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.subject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Ticket #${ticket.id.substring(0, 8).toUpperCase()}', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13)),
                      const SizedBox(width: 12),
                      const Text('•', style: TextStyle(color: Color(0x22FF6600))),
                      const SizedBox(width: 12),
                      Text(ticket.issueType.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                ticket.status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.chevron_right, color: Color(0x22FF6600)),
          ],
        ),
      ),
    );
  }

  void _showCreateTicketDialog(BuildContext context, WidgetRef ref) {
    // Map display labels -> exact DB values that pass the issue_type CHECK constraint
    const typeMap = {
      'General Inquiry': 'general',
      'Billing Issue': 'billing',
      'Technical Problem': 'technical',
      'Dispute': 'dispute',
    };
    String selectedType = 'General Inquiry';
    final subjectController = TextEditingController();
    final types = typeMap.keys.toList();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: BoostDriveTheme.surfaceDark,
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Create New Ticket', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Issue Type', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: BoostDriveTheme.surfaceDark,
                        value: selectedType,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Subject & Description', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: subjectController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Please detail your issue...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: BoostDriveTheme.backgroundDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BoostDriveTheme.primaryColor)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final text = subjectController.text.trim();
                              if (text.isEmpty) return;
                              setState(() => isSubmitting = true);
                              try {
                                await ref.read(supportServiceProvider).createTicket(
                                  userId: widget.userId,
                                  userType: widget.userType,
                                  issueType: typeMap[selectedType] ?? 'general',
                                  subject: text,
                                );
                                ref.invalidate(userTicketsProvider(widget.userId));
                                if (context.mounted) Navigator.pop(context);
                              } catch (e) {
                                setState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BoostDriveTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('SUBMIT TICKET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTicketDetails(BuildContext context, WidgetRef ref, SupportTicket ticket) {
    final msgController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: BoostDriveTheme.surfaceDark,
          child: Container(
            width: 600,
            height: 700,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Ticket #${ticket.id.substring(0, 8).toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(ticket.subject, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16)),
                const SizedBox(height: 24),
                const Divider(color: Color(0x22FF6600)),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final msgsAsync = ref.watch(ticketMessagesProvider(ticket.id));
                      return msgsAsync.when(
                        data: (msgs) {
                          if (msgs.isEmpty) return Center(child: Text('No messages yet', style: TextStyle(color: BoostDriveTheme.textDim)));
                          return ListView.builder(
                            itemCount: msgs.length,
                            itemBuilder: (context, index) {
                              final m = msgs[index];
                              final isMe = m.senderId == widget.userId;
                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  constraints: const BoxConstraints(maxWidth: 400),
                                  decoration: BoxDecoration(
                                    color: isMe ? BoostDriveTheme.primaryColor : Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.isAdmin ? 'Admin' : 'You',
                                        style: TextStyle(color: isMe ? Colors.white70 : BoostDriveTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(m.message, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: msgController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                          filled: true,
                          fillColor: BoostDriveTheme.backgroundDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final text = msgController.text.trim();
                        if (text.isEmpty) return;
                        msgController.clear();
                        try {
                          await ref.read(supportServiceProvider).addMessage(
                            ticketId: ticket.id,
                            senderId: widget.userId,
                            message: text,
                            isAdmin: false,
                          );
                          ref.invalidate(ticketMessagesProvider(ticket.id));
                          ref.invalidate(userTicketsProvider(widget.userId));
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
                          }
                        }
                      },
                      icon: const Icon(Icons.send, color: BoostDriveTheme.primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
