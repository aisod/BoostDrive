import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';

class UserSupportView extends ConsumerStatefulWidget {
  final String userId;
  final String userType;
  final bool embedded;

  const UserSupportView({
    super.key,
    required this.userId,
    required this.userType,
    this.embedded = false,
  });

  @override
  ConsumerState<UserSupportView> createState() => _UserSupportViewState();
}

class _UserSupportViewState extends ConsumerState<UserSupportView> {
  String? _lastAutoOpenedId;

  static const _faqItems = [
    (Icons.payments_outlined, 'How do payouts work?', 'Learn about our weekly payout cycle and supported banking methods.'),
    (Icons.shield_outlined, 'Insurance & Protection', 'Understand coverage options for rentals and high-value listings.'),
    (Icons.verified_user_outlined, 'Verification delays', 'Why listings may stay pending and how to speed up approval.'),
    (Icons.chat_outlined, 'Messaging buyers', 'Best practices for responding to inquiries on BoostDrive.'),
  ];

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(userTicketsProvider(widget.userId));
    final pendingTicketId = ref.watch(pendingSupportTicketIdProvider);
    final palette = DashboardPalette.of(context);

    if (pendingTicketId != null && _lastAutoOpenedId != pendingTicketId && ticketsAsync.hasValue) {
      final tickets = ticketsAsync.value!;
      final ticket = tickets.cast<SupportTicket?>().firstWhere(
            (t) => t?.id == pendingTicketId,
            orElse: () => null,
          );

      if (ticket != null) {
        _lastAutoOpenedId = pendingTicketId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTicketDetails(context, ref, ticket);
          ref.read(pendingSupportTicketIdProvider.notifier).state = null;
        });
      }
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded) ...[
          const SizedBox(height: 8),
          DashboardHeroSearch(
            title: 'How can we help you today?',
            subtitle:
                'Search our knowledge base or check your existing tickets for updates on your vehicle listings and rentals.',
          ),
          const SizedBox(height: 32),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            final ticketsPanel = _buildTicketsPanel(context, ref, ticketsAsync, palette);
            final faqPanel = _buildFaqPanel(palette);
            if (!wide) {
              return Column(
                children: [
                  ticketsPanel,
                  const SizedBox(height: 32),
                  faqPanel,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: ticketsPanel),
                const SizedBox(width: 24),
                Expanded(flex: 5, child: faqPanel),
              ],
            );
          },
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return DashboardPageContainer(child: content);
  }

  Widget _buildTicketsPanel(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<SupportTicket>> ticketsAsync,
    DashboardPalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Active Tickets', style: DashboardTypography.headlineMd(palette)),
            ),
            DashboardPillButton(
              label: 'New Ticket',
              icon: Icons.confirmation_number_outlined,
              onPressed: () => _showCreateTicketDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ticketsAsync.when(
          data: (tickets) {
            if (tickets.isEmpty) {
              return DashboardCard(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.support_agent, size: 56, color: palette.muted.withValues(alpha: 0.6)),
                    const SizedBox(height: 16),
                    Text('No support tickets yet.', style: DashboardTypography.bodyMd(palette)),
                  ],
                ),
              );
            }
            return DashboardCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < tickets.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: palette.surfaceContainer),
                    _buildTicketRow(context, ref, tickets[i], palette),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (e, _) => Text('Error: $e', style: TextStyle(color: palette.error)),
        ),
      ],
    );
  }

  Widget _buildFaqPanel(DashboardPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Common Questions', style: DashboardTypography.headlineMd(palette)),
        const SizedBox(height: 6),
        Text('Find instant answers to common issues.', style: DashboardTypography.bodySm(palette)),
        const SizedBox(height: 16),
        ..._faqItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DashboardFaqTile(
              icon: item.$1,
              title: item.$2,
              description: item.$3,
              iconBackground: palette.primaryFixed.withValues(alpha: 0.35),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketRow(BuildContext context, WidgetRef ref, SupportTicket ticket, DashboardPalette palette) {
    final isOpen = ticket.status == 'open' || ticket.status == 'pending';
    final statusBg = isOpen ? palette.primaryContainer : palette.surfaceContainerHighest;
    final statusFg = isOpen ? Colors.white : palette.body;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTicketDetails(context, ref, ticket),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: DashboardTypography.labelLg(palette),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      ticket.status.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusFg,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.tag, size: 14, color: palette.muted),
                  const SizedBox(width: 4),
                  Text(
                    '#${ticket.id.substring(0, 8).toUpperCase()}',
                    style: DashboardTypography.labelMd(palette),
                  ),
                  const SizedBox(width: 12),
                  Text(ticket.issueType.toUpperCase(), style: DashboardTypography.labelMd(palette)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTicketDialog(BuildContext context, WidgetRef ref) {
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
    final palette = DashboardPalette.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: palette.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      Text('Create New Ticket', style: DashboardTypography.headlineMd(palette)),
                      IconButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: palette.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Issue Type', style: DashboardTypography.labelLg(palette)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: palette.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                      color: palette.surfaceContainerLow,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: palette.surfaceContainerLowest,
                        value: selectedType,
                        isExpanded: true,
                        style: DashboardTypography.bodyMd(palette).copyWith(color: palette.title),
                        items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Subject & Description', style: DashboardTypography.labelLg(palette)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: subjectController,
                    style: DashboardTypography.bodyMd(palette).copyWith(color: palette.title),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Please detail your issue...',
                      hintStyle: DashboardTypography.bodyMd(palette),
                      filled: true,
                      fillColor: palette.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: palette.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: palette.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: DashboardPillButton(
                      label: isSubmitting ? 'Submitting...' : 'Submit Ticket',
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
                                if (!context.mounted) return;
                                setState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            },
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
    final palette = DashboardPalette.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: palette.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      child: Text(
                        'Ticket #${ticket.id.substring(0, 8).toUpperCase()}',
                        style: DashboardTypography.headlineMd(palette),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: palette.muted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(ticket.subject, style: DashboardTypography.bodyMd(palette)),
                const SizedBox(height: 24),
                Divider(color: palette.surfaceContainer),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final msgsAsync = ref.watch(ticketMessagesProvider(ticket.id));
                      return msgsAsync.when(
                        data: (msgs) {
                          if (msgs.isEmpty) {
                            return Center(child: Text('No messages yet', style: DashboardTypography.bodyMd(palette)));
                          }
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
                                    color: isMe ? palette.primary : palette.surfaceContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.isAdmin ? 'Admin' : 'You',
                                        style: DashboardTypography.labelMd(palette).copyWith(
                                          color: isMe ? Colors.white70 : palette.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        m.message,
                                        style: DashboardTypography.bodySm(palette).copyWith(
                                          color: isMe ? Colors.white : palette.title,
                                        ),
                                      ),
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
                        minLines: 1,
                        maxLines: 6,
                        style: DashboardTypography.bodyMd(palette).copyWith(color: palette.title),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: DashboardTypography.bodyMd(palette),
                          filled: true,
                          fillColor: palette.surfaceContainerLow,
                          contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
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
                      icon: Icon(Icons.send, color: palette.primary),
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
