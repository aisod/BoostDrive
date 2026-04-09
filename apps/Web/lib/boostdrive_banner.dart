import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';

class BoostDriveBanner extends ConsumerWidget {
  final Map<String, dynamic> alert;
  final ValueChanged<String?>? onAction;

  const BoostDriveBanner({
    super.key,
    required this.alert,
    this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = alert['title'] ?? 'Alert';
    final message = alert['message'] ?? '';
    final id = alert['id'].toString();
    final metadata = alert['metadata'] as Map<String, dynamic>?;
    final ticketId = metadata?['ticket_id'] as String?;

    final isSupport = title.toLowerCase().contains('support') || 
                      message.toLowerCase().contains('help') ||
                      message.toLowerCase().contains('support') ||
                      title.toLowerCase().contains('ticket');

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
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
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                
                if (isSupport && onAction != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TextButton.icon(
                      onPressed: () => onAction!(ticketId),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18, color: BoostDriveTheme.primaryColor),
                      label: const Text(
                        'SEE CONVERSATION',
                        style: TextStyle(
                          color: BoostDriveTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                TextButton.icon(
                  onPressed: () async {
                    await ref.read(notificationServiceProvider).markAsRead(id);
                    final user = ref.read(currentUserProvider);
                    if (user != null) {
                      ref.invalidate(activeDashboardAlertsStreamProvider(user.id));
                      ref.invalidate(userNotificationsStreamProvider(user.id));
                    }
                  },
                  icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                  label: const Text(
                    'DISMISS',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
