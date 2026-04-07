import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a single notification record returned from the DB.
class NotificationRecord {
  final String id;
  final String adminId;
  final String targetGroup; // 'all' | 'providers' | 'customers'
  final String title;
  final String message;
  final String? actionLink;
  final List<String> deliveryMethods; // ['in_app', 'dashboard']
  final int estimatedReach;
  final DateTime createdAt;

  NotificationRecord({
    required this.id,
    required this.adminId,
    required this.targetGroup,
    required this.title,
    required this.message,
    this.actionLink,
    required this.deliveryMethods,
    required this.estimatedReach,
    required this.createdAt,
  });

  factory NotificationRecord.fromMap(Map<String, dynamic> m) {
    return NotificationRecord(
      id: m['id'] as String,
      adminId: m['admin_id'] as String,
      targetGroup: m['target_group'] as String,
      title: m['subject'] as String? ?? m['title'] as String? ?? '',
      message: m['body'] as String? ?? m['message'] as String? ?? '',
      actionLink: m['action_link'] as String?,
      deliveryMethods: List<String>.from(m['delivery_methods'] as List? ?? []),
      estimatedReach: m['estimated_reach'] as int? ?? 0,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}

/// Represents a marketing promotion for the BoostDrive platform.
class NotificationPromotion {
  final String id;
  final String adminId;
  final String type;
  final String title;
  final String description;
  final double discountPercentage;
  final String? targetCategory;
  final DateTime expiryDate;
  final bool isActive;
  final DateTime createdAt;

  NotificationPromotion({
    required this.id,
    required this.adminId,
    required this.type,
    required this.title,
    required this.description,
    required this.discountPercentage,
    this.targetCategory,
    required this.expiryDate,
    required this.isActive,
    required this.createdAt,
  });

  factory NotificationPromotion.fromMap(Map<String, dynamic> m) {
    return NotificationPromotion(
      id: m['id'] as String,
      adminId: m['admin_id'] as String,
      type: m['promotion_type'] as String? ?? 'Seasonal',
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      discountPercentage: (m['discount_percentage'] as num? ?? 0).toDouble(),
      targetCategory: m['target_category'] as String?,
      expiryDate: DateTime.parse(m['expiry_date'] as String),
      isActive: m['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}

class NotificationHubService {
  final _supabase = Supabase.instance.client;

  /// Counts how many profiles would receive this notification.
  Future<int> getEstimatedReach(String targetGroup) async {
    try {
      final query = _supabase
          .from('profiles')
          .select('id');

      late final List result;
      if (targetGroup == 'providers' || targetGroup == 'service_providers') {
        result = await query.eq('role', 'service_provider') as List;
      } else if (targetGroup == 'customers') {
        result = await query.inFilter('role', ['customer', 'seller']) as List;
      } else {
        // Includes 'all', 'all_users', etc.
        result = await query as List;
      }
      return result.length;
    } catch (_) {
      return 0;
    }
  }

  /// Sends a notification: writes to `notifications_broadcast` and fans out
  /// in-app notifications to all matching user profiles.
  Future<void> sendNotification({
    required String adminId,
    required String targetGroup,
    required String title,
    required String message,
    String? actionLink,
    required List<String> deliveryMethods,
  }) async {
    // 1. Fetch target profiles
    final query = _supabase.from('profiles').select('id, role, status');
    late final List<dynamic> rawProfiles;

    if (targetGroup == 'providers' || targetGroup == 'service_providers') {
      rawProfiles = await query.eq('role', 'service_provider') as List;
    } else if (targetGroup == 'customers') {
      rawProfiles = await query.inFilter('role', ['customer', 'seller']) as List;
    } else {
      rawProfiles = await query as List;
    }

    final profiles = rawProfiles
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((p) => (p['status'] as String?)?.toLowerCase() == 'active')
        .toList();

    final estimatedReach = profiles.length;

    // 2. Record the notification in the audit table
    final notificationRow = await _supabase
        .from('notifications_broadcast')
        .insert({
          'admin_id': adminId,
          'target_group': targetGroup,
          'subject': title,
          'body': message,
          'action_link': actionLink?.isNotEmpty == true ? actionLink : null,
          'delivery_methods': deliveryMethods,
          'estimated_reach': estimatedReach,
        })
        .select()
        .single();

    final notificationId = notificationRow['id'] as String;

    // 3. Fan out in-app notifications if 'in_app' or 'dashboard' is selected
    // Note: 'email' delivery is typically handled by a database trigger/edge function
    // picking up the record from 'notifications_broadcast'.
    if (deliveryMethods.contains('in_app') || deliveryMethods.contains('dashboard')) {
      final notifType = deliveryMethods.contains('dashboard') ? 'dashboard_alert' : 'notification';
      final rows = profiles.map((p) => {
        'user_id': p['id'],
        'title': title,
        'message': message,
        'type': notifType,
        'is_read': false,
        'metadata': {
          'notification_id': notificationId,
          if (actionLink?.isNotEmpty == true) 'action_link': actionLink,
        },
      }).toList();

      // Insert in chunks of 100 to avoid request size limits
      for (var i = 0; i < rows.length; i += 100) {
        final chunk = rows.sublist(i, i + 100 > rows.length ? rows.length : i + 100);
        await _supabase.from('notifications').insert(chunk);
      }
    }
  }

  /// Returns recent notification history (last 50), newest first.
  Future<List<NotificationRecord>> getNotificationHistory() async {
    final res = await _supabase
        .from('notifications_broadcast')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return (res as List)
        .map((e) => NotificationRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// ── PROMOTIONS ─────────────────────────────────────────────────────────────

  /// Creates a new promotion and optionally broadcasts it as a notification.
  Future<void> createPromotion({
    required String adminId,
    required String type,
    required String title,
    required String description,
    required double discountPercentage,
    String? targetCategory,
    required DateTime expiryDate,
    bool broadcastAsNotification = true,
  }) async {
    // 1. Create the promotion record
    final promoRow = await _supabase
        .from('promotions')
        .insert({
          'admin_id': adminId,
          'promotion_type': type,
          'title': title,
          'description': description,
          'discount_percentage': discountPercentage,
          'target_category': targetCategory,
          'expiry_date': expiryDate.toIso8601String(),
          'is_active': true,
        })
        .select()
        .single();

    // 2. Broadcast if requested
    if (broadcastAsNotification) {
      // Determine target audience based on category
      String targetGroup = 'all';
      if (targetCategory != null && targetCategory!.isNotEmpty) {
        // More sophisticated targeting could be added here
        targetGroup = 'all'; 
      }

      await sendNotification(
        adminId: adminId,
        targetGroup: targetGroup,
        title: 'Promotion: $title',
        message: description,
        deliveryMethods: ['in_app', 'dashboard'],
        actionLink: 'boostdrive://promotions/${promoRow['id']}',
      );
    }
  }

  /// Returns list of promotions for the admin management view.
  Future<List<NotificationPromotion>> getPromotionsHistory() async {
    final res = await _supabase
        .from('promotions')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return (res as List)
        .map((e) => NotificationPromotion.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Returns active promotions for a specific category (used in directory).
  Future<List<NotificationPromotion>> getActivePromotions({String? category}) async {
    var query = _supabase
        .from('promotions')
        .select()
        .eq('is_active', true)
        .gt('expiry_date', DateTime.now().toIso8601String());
    
    if (category != null && category.isNotEmpty) {
      query = query.eq('target_category', category);
    }

    final res = await query;
    return (res as List)
        .map((e) => NotificationPromotion.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

final notificationHubServiceProvider = Provider<NotificationHubService>((ref) {
  return NotificationHubService();
});

final activePromotionsProvider = FutureProvider.family<List<NotificationPromotion>, String?>((ref, category) {
  return ref.watch(notificationHubServiceProvider).getActivePromotions(category: category);
});
