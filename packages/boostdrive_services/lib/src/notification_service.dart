import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class NotificationService {
  final _supabase = Supabase.instance.client;

  /// Sends a notification to a specific user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'system',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      print('Error sending notification: $e');
      // Don't rethrow — a notification failure should never block the main action.
    }
  }

  /// Sends a document status notification, replacing any previous one for the same document.
  /// This prevents stale "Approved" notifications lingering after a "Rejected" status (or vice versa).
  Future<void> sendDocumentStatusNotification({
    required String userId,
    required String documentType,
    required String status, // 'approved' or 'rejected'
    String? rejectionReason,
    Map<String, dynamic>? metadata,
  }) async {
    final isApproved = status.toLowerCase() == 'approved';
    final title = isApproved ? 'Document Approved' : 'Document Rejected';
    final message = isApproved
        ? 'Your document "$documentType" has been approved.'
        : 'Your document "$documentType" was rejected. Reason: ${rejectionReason ?? "No reason provided"}';

    try {
      // Delete any existing notification for this exact document to avoid duplicates
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .ilike('message', '%"$documentType"%');
    } catch (e) {
      // RLS might prevent deleting notifications for other users, so we gracefully ignore
      print('Warning: could not delete old notification: $e');
    }

    try {
      // Insert the fresh (latest) notification
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': 'verification',
        'is_read': false,
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      print('Error sending document status notification: $e');
    }
  }

  /// Sends a general account verification notification (Approved/Rejected)
  Future<void> sendAccountVerificationNotification({
    required String userId,
    required String status, // 'approved' or 'rejected'
  }) async {
    final isApproved = status.toLowerCase() == 'approved';
    final title = isApproved ? 'Account Verified' : 'Account Verification Update';
    final message = isApproved
        ? 'Congratulations! Your BoostDrive account has been successfully verified. You now have full access to our dispatch and service features.'
        : 'There is an update regarding your account verification. Please check your document statuses for details.';

    await sendNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'account_verification',
    );
  }


  /// Fetches notifications for a specific user as a stream
  Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    final realtime = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return _withPollingFallback(userId, realtime);
  }

  /// Marks a specific notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Marks all notifications for a user as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> _withPollingFallback(
    String userId,
    Stream<List<Map<String, dynamic>>> realtime,
  ) async* {
    try {
      yield* realtime;
      return;
    } catch (e) {
      print('DEBUG: streamNotifications realtime failed, switching to polling: $e');
    }

    while (true) {
      try {
        yield await _fetchNotificationsSnapshot(userId);
      } catch (e) {
        print('DEBUG: streamNotifications polling fetch failed: $e');
        yield const <Map<String, dynamic>>[];
      }
      await Future<void>.delayed(const Duration(seconds: 8));
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNotificationsSnapshot(String userId) async {
    final rows = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List<dynamic>);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final userNotificationsStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  try {
    return ref.watch(notificationServiceProvider).streamNotifications(userId);
  } catch (e) {
    print('Failed to initialize notification stream: $e');
    return Stream.value([]); // Return empty list on immediate setup error
  }
});

final activeDashboardAlertsStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return ref.watch(userNotificationsStreamProvider(userId).stream).map((allNotifs) {
    return allNotifs.where((n) => n['type'] == 'dashboard_alert' && n['is_read'] == false).toList();
  });
});

/// Global provider to track which support ticket should be automatically opened
/// when navigating from a notification.
final pendingSupportTicketIdProvider = StateProvider<String?>((ref) => null);
