import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boost_drive_web/dashboard_router.dart';
import 'package:boost_drive_web/provider_hub_page.dart';

/// Notification bell with unread badge for signed-in users on public pages.
class PublicNavNotificationBell extends ConsumerWidget {
  final String userId;
  final bool compact;

  const PublicNavNotificationBell({
    super.key,
    required this.userId,
    this.compact = false,
  });

  void _showOverlay(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => NotificationsOverlay(
        onNotificationTap: (type, id) {
          if (type == 'support') {
            ref.read(pendingSupportTicketIdProvider.notifier).state = id;
            final profile = ref.read(userProfileProvider(userId)).value;
            if (profile != null && context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => dashboardWidgetForProfile(profile)),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconSize = compact ? 24.0 : 28.0;
    final notificationsAsync = ref.watch(userNotificationsStreamProvider(userId));

    return notificationsAsync.when(
      data: (list) {
        final unreadCount = list.where((n) => n['is_read'] == false).length;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.white, size: iconSize),
              tooltip: 'Notifications',
              onPressed: () => _showOverlay(context, ref),
            ),
            if (unreadCount > 0)
              Positioned(
                right: compact ? 6 : 8,
                top: compact ? 6 : 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => IconButton(
        icon: SizedBox(
          width: iconSize,
          height: iconSize,
          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        onPressed: () => _showOverlay(context, ref),
      ),
      error: (_, __) => IconButton(
        icon: Icon(Icons.notifications_off, color: Colors.white.withValues(alpha: 0.7), size: iconSize),
        tooltip: 'Notifications',
        onPressed: () => _showOverlay(context, ref),
      ),
    );
  }
}

/// Profile avatar — opens dashboard or profile settings depending on role.
class PublicNavProfileAvatar extends ConsumerWidget {
  final String userId;
  final bool compact;

  const PublicNavProfileAvatar({
    super.key,
    required this.userId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = compact ? 16.0 : 18.0;

    return ref.watch(userProfileProvider(userId)).when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(right: compact ? 4 : 0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                if (isWebProviderRole(profile.role)) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => dashboardWidgetForProfile(profile)),
                  );
                }
              },
              child: CircleAvatar(
                radius: radius,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                backgroundImage: profile.profileImg.isNotEmpty ? NetworkImage(profile.profileImg) : null,
                child: profile.profileImg.isEmpty
                    ? Icon(Icons.person, color: Colors.white, size: radius)
                    : null,
              ),
            ),
          ),
        );
      },
      loading: () => SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      error: (_, __) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white24,
        child: Icon(Icons.person, color: Colors.white, size: radius),
      ),
    );
  }
}

/// Opens Find a Provider or provider hub depending on role.
void openFindProviderOrHub(BuildContext context, WidgetRef ref, UserProfile profile) {
  if (isWebProviderRole(profile.role)) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProviderHubPage()));
    return;
  }
  if (ModalRoute.of(context)?.settings.name == '/find-provider') return;
  Navigator.of(context).pushNamed('/find-provider');
}

/// True when the user is a marketplace seller (not a service-provider role).
bool isMarketplaceSeller(UserProfile profile) {
  return profile.isSeller && !isWebProviderRole(profile.role);
}
