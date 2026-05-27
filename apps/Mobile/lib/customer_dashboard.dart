import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'emergency_hub_page.dart';
import 'job_card_tool_page.dart';
import 'messages_page.dart';

class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final palette = DashboardPalette.of(context);
    if (user == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(child: Text('Please log in', style: DashboardTypography.bodyMd(palette))),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: MobileCustomerUi.topAppBar(
        context: context,
        title: 'BOOSTDRIVE',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotificationsOverlay(context, ref, user.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          MobileCustomerUi.marginMobile,
          16,
          MobileCustomerUi.marginMobile,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(ref, user.id, palette),
            const SizedBox(height: 20),
            _buildJobCardUpdatesSection(ref, user.id, palette),
            const SizedBox(height: 20),
            _buildSOSSection(palette),
            const SizedBox(height: 20),
            _buildJobCardSection(palette),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, String uid, DashboardPalette palette) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return MobileCustomerUi.greetingCard(
          palette: palette,
          fullName: profile.fullName,
          profileImageUrl: profile.profileImg,
          messagesButton: ref.watch(unreadConversationsProvider(uid)).when(
            data: (ids) => MobileCustomerUi.iconActionButton(
              palette: palette,
              icon: Icons.chat_bubble_outline,
              badgeCount: ids.length,
              onTap: () => _openMessages(context),
            ),
            loading: () => MobileCustomerUi.iconActionButton(
              palette: palette,
              icon: Icons.chat_bubble_outline,
              onTap: () => _openMessages(context),
            ),
            error: (_, _) => MobileCustomerUi.iconActionButton(
              palette: palette,
              icon: Icons.chat_bubble_outline,
              onTap: () => _openMessages(context),
            ),
          ),
          notificationsButton: ref.watch(userNotificationsStreamProvider(uid)).when(
            data: (list) {
              final unread = list.where((n) => n['is_read'] == false).length;
              return MobileCustomerUi.iconActionButton(
                palette: palette,
                icon: Icons.notifications_none_rounded,
                badgeCount: unread,
                onTap: () => _showNotificationsOverlay(context, ref, uid),
              );
            },
            loading: () => MobileCustomerUi.iconActionButton(
              palette: palette,
              icon: Icons.notifications_none_rounded,
              onTap: () => _showNotificationsOverlay(context, ref, uid),
            ),
            error: (_, _) => MobileCustomerUi.iconActionButton(
              palette: palette,
              icon: Icons.notifications_off_outlined,
              onTap: () => _showNotificationsOverlay(context, ref, uid),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text('Error loading header', style: DashboardTypography.bodySm(palette)),
    );
  }

  void _openMessages(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MessagesPage()),
    );
  }

  void _showNotificationsOverlay(BuildContext context, WidgetRef ref, String uid) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => NotificationsOverlay(
        onNotificationTap: (type, id) {
          if (type == 'support') {
            ref.read(pendingSupportTicketIdProvider.notifier).state = id;
            return;
          }
          if (type == 'job_card_quote' ||
              type == 'job_card_status' ||
              type == 'job_card_completed' ||
              type == 'job_card_decision' ||
              type == 'job_card_cancelled' ||
              type == 'job_card_request') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => JobCardToolPage(initialJobCardId: id)),
            );
            return;
          }
          if (type == 'job_card_review_request') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const EmergencyHubPage()),
            );
            return;
          }
          if (type == 'sos') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const EmergencyHubPage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildSOSSection(DashboardPalette palette) {
    return MobileCustomerUi.sosPromoCard(
      palette: palette,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const EmergencyHubPage()),
        );
      },
    );
  }

  Widget _buildJobCardSection(DashboardPalette palette) {
    return MobileCustomerUi.jobCardPromoCard(
      palette: palette,
      onOpen: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const JobCardToolPage()),
        );
      },
    );
  }

  Widget _buildJobCardUpdatesSection(WidgetRef ref, String uid, DashboardPalette palette) {
    final updatesAsync = ref.watch(_requesterJobCardsDashboardFamily(uid));
    return updatesAsync.when(
      data: (rows) {
        final actionable = rows.where((r) {
          final s = (r['status']?.toString() ?? '').toLowerCase();
          return s == 'quoted';
        }).toList();
        if (actionable.isEmpty) return const SizedBox.shrink();
        final first = actionable.first;
        final labor = (first['labor_amount'] as num?)?.toDouble() ?? 0;
        return MobileCustomerUi.quoteAlertCard(
          palette: palette,
          laborAmount: 'N\$${labor.toStringAsFixed(2)}',
          pendingCount: actionable.length,
          onReview: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const JobCardToolPage()),
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

final _requesterJobCardsDashboardFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(jobCardServiceProvider).listJobCardsForRequester(uid);
});
