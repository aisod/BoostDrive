import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';

class DashboardAlertBanner extends ConsumerWidget {
  final Map<String, dynamic> alert;

  const DashboardAlertBanner({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = alert['title'] ?? 'Alert';
    final message = alert['message'] ?? '';
    final id = alert['id'].toString();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: BoostDriveTheme.primaryColor, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded, color: BoostDriveTheme.primaryColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          color: BoostDriveTheme.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // DISMISS BUTTON
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(notificationServiceProvider).markAsRead(id);
                    // Invalidate the provider to refresh UI
                    final user = ref.read(currentUserProvider);
                    if (user != null) {
                      ref.invalidate(activeDashboardAlertsProvider(user.id));
                      ref.invalidate(userNotificationsProvider(user.id));
                    }
                  },
                  icon: const Icon(Icons.close, size: 18, color: Colors.white38),
                  label: const Text(
                    'DISMISS',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.white12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Subtle progress-line-styled separator
          const LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(BoostDriveTheme.primaryColor),
            minHeight: 1,
          ),
        ],
      ),
    );
  }
}
