import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'emergency_hub_page.dart';
import 'messages_page.dart';

// Notifications use the same stream + overlay as the web customer dashboard.

class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return PremiumPageLayout(
      showBackground: true,
      appBar: AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Customer Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(ref, user.id),
              const SizedBox(height: 24),
              _buildSOSSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, String uid) {
    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: BoostDriveTheme.surfaceDark,
              backgroundImage: profile.profileImg.isNotEmpty ? NetworkImage(profile.profileImg) : null,
              child: profile.profileImg.isEmpty ? const Icon(Icons.person, color: BoostDriveTheme.primaryColor) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13),
                ),
                Text(
                  profile.fullName,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ref.watch(userNotificationsStreamProvider(uid)).when(
              data: (list) {
                final unreadCount = list.where((n) => n['is_read'] == false).length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => _showNotificationsOverlay(context, ref, uid),
                      child: _buildHeaderIcon(Icons.notifications_none_rounded),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => GestureDetector(
                onTap: () => _showNotificationsOverlay(context, ref, uid),
                child: _buildHeaderIcon(Icons.notifications_none_rounded),
              ),
              error: (_, _) => GestureDetector(
                onTap: () => _showNotificationsOverlay(context, ref, uid),
                child: _buildHeaderIcon(Icons.notifications_off_outlined),
              ),
            ),
            const SizedBox(width: 12),
            ref.watch(unreadConversationsProvider(uid)).when(
              data: (unreadConversationIds) {
                final unreadCount = unreadConversationIds.length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => _openMessages(context),
                      child: _buildHeaderIcon(Icons.message_outlined),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => GestureDetector(
                onTap: () => _openMessages(context),
                child: _buildHeaderIcon(Icons.message_outlined),
              ),
              error: (_, _) => GestureDetector(
                onTap: () => _openMessages(context),
                child: _buildHeaderIcon(Icons.message_outlined),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProfileSettingsPage()),
                );
              },
              child: _buildHeaderIcon(Icons.settings_outlined),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const Text('Error loading header'),
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
          }
        },
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  /// SOS / Emergency card: one-tap access to request towing or mobile mechanic.
  Widget _buildSOSSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const EmergencyHubPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.sos, color: BoostDriveTheme.primaryColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emergency & SOS',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Request towing or a mobile mechanic when you need help.',
                    style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: BoostDriveTheme.primaryColor, size: 28),
          ],
        ),
      ),
    );
  }

}
