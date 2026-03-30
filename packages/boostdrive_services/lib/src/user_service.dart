import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'notification_service.dart';

class UserService {
  final _supabase = Supabase.instance.client;
  final NotificationService _notificationService;

  UserService([NotificationService? notificationService])
      : _notificationService = notificationService ?? NotificationService();

  /// Checks if an account with the same email or phone and role already exists
  Future<String?> checkDuplicateAccount({
    required String email,
    required String phone,
  }) async {
    try {
      final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
      String formattedPhone = digits;
      if (formattedPhone.startsWith('08')) {
        formattedPhone = '264${formattedPhone.substring(1)}';
      } else if (formattedPhone.isNotEmpty && !formattedPhone.startsWith('264')) {
        formattedPhone = '264$formattedPhone';
      }
      formattedPhone = '+$formattedPhone';
      
      final response = await _supabase
          .from('profiles')
          .select()
          .or('email.eq.${email.trim()},phone_number.eq.$formattedPhone')
          .maybeSingle();

      if (response != null) {
        if (response['email'] == email.trim()) return 'An account with this email already exists.';
        if (response['phone_number'] == formattedPhone) return 'An account with this phone number already exists.';
      }
      return null;
    } catch (e) {
      print('Error checking duplicate account: $e');
      return null; // Assume not duplicate if error, but log it
    }
  }


  /// Gets the profile for the current user
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromMap(response);
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  /// Updates or creates a user profile
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _supabase.from('profiles').upsert(profile.toMap()..['id'] = profile.uid);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  /// Updates the provider's verification status and logs the action
  Future<void> updateVerificationStatus({
    required String uid,
    required String status,
    required String adminUid,
  }) async {
    try {
      print('DEBUG: Attempting to update verification_status of $uid to $status...');
      
      final response = await _supabase
          .from('profiles')
          .update({'verification_status': status})
          .eq('id', uid)
          .select();

      if (response == null || (response as List).isEmpty) {
        throw Exception('No profile found to update or update rejected by RLS.');
      }

      print('DEBUG: Verification status update successful for $uid');

      // Soft-fail audit logging in case table isn't set up yet
      try {
        await _supabase.from('admin_audit_logs').insert({
          'admin_id': adminUid,
          'target_id': uid,
          'action_type': status == 'approved' ? 'APPROVE_PROVIDER' : 'REJECT_PROVIDER',
          'notes': 'Verification status changed to $status'
        });
      } catch (e) {
        print('Warning: Failed to insert audit log (table might be missing): $e');
      }

      // Trigger the account-level notification for the provider
      try {
        final notificationService = NotificationService();
        await notificationService.sendAccountVerificationNotification(
          userId: uid,
          status: status,
        );
      } catch (e) {
        print('Warning: Could not send verification notification: $e');
      }
    } catch (e) {
      print('DEBUG: Error updating verification status: $e');
      rethrow;
    }
  }

  /// Updates status of a specific document for a provider
  Future<void> updateDocumentStatus({
    required String providerId,
    required String documentType,
    required String status,
    required String adminUid,
    String? reason,
  }) async {
    try {
      final data = {
        'provider_id': providerId,
        'document_type': documentType,
        'status': status,
        'rejection_reason': reason,
        'reviewer_id': adminUid,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _supabase
          .from('provider_document_status')
          .upsert(data, onConflict: 'provider_id,document_type');
          
      // Send notification — replaces any existing one for this document
      await _notificationService.sendDocumentStatusNotification(
        userId: providerId,
        documentType: documentType,
        status: status,
        rejectionReason: reason,
      );
          
    } catch (e) {
      print('DEBUG: updateDocumentStatus ERROR: $e');
      rethrow;
    }
  }

  /// Removes a document verification status record
  Future<void> deleteDocumentStatus({
    required String providerId,
    required String documentType,
  }) async {
    try {
      await _supabase
          .from('provider_document_status')
          .delete()
          .eq('provider_id', providerId)
          .eq('document_type', documentType);
    } catch (e) {
      print('Error deleting document status: $e');
      rethrow;
    }
  }

  /// Fetches all document statuses for a provider
  Future<List<Map<String, dynamic>>> getProviderDocuments(String providerId) async {
    try {
      final response = await _supabase
          .from('provider_document_status')
          .select()
          .eq('provider_id', providerId)
          .order('updated_at', ascending: true);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching provider documents: $e');
      return [];
    }
  }

  /// Updates the user's account status (active, banned, frozen) and logs it.
  Future<void> updateUserStatus({
    required String uid,
    required String status,
    required String adminUid,
    String? notes,
  }) async {
    try {
      await _supabase.from('profiles').update({'status': status}).eq('id', uid);
      try {
        await _supabase.from('admin_audit_logs').insert({
          'admin_id': adminUid,
          'target_id': uid,
          'action_type': 'UPDATE_USER_STATUS',
          'notes': 'Account status changed to ${status.toUpperCase()}. Notes: ${notes ?? "No notes provided"}'
        });
      } catch (e) {
        print('Warning: Failed to insert audit log for status change: $e');
      }
    } catch (e) {
      print('Error updating user status: $e');
      rethrow;
    }
  }


  /// Specifically updates the roles for a user
  Future<void> updateRoles({
    required String uid,
    required bool isBuyer,
    required bool isSeller,
    String? role,
  }) async {
    try {
      final updates = <String, dynamic>{
        'is_buyer': isBuyer,
        'is_seller': isSeller,
      };
      if (role != null) updates['role'] = role;
      
      await _supabase.from('profiles').update(updates).eq('id', uid);
    } catch (e) {
      print('Error updating roles: $e');
      rethrow;
    }
  }

  /// Streams the current user's profile
  Stream<UserProfile?> streamProfile(String uid) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .map((data) => data.isNotEmpty ? UserProfile.fromMap(data.first) : null);
  }

  Stream<int> getUserCount() {
    return _supabase.from('profiles').stream(primaryKey: ['id']).map((data) => data.length);
  }
  Stream<List<UserProfile>> getPendingVerifications() {
    // We stream profiles and filter client-side because the Supabase stream builder
    // does not support `.or(...)` on the stream query.
    return _supabase.from('profiles').stream(primaryKey: ['id']).map((data) {
      final profiles = data.map((json) => UserProfile.fromMap(json)).toList();

      return profiles.where((p) {
        // Verification status values used across the app:
        // 'pending' | 'approved' | 'rejected' | 'unverified'
        final status = p.verificationStatus.trim().toLowerCase();
        final isNotApproved =
            status == 'pending' || status == 'unverified';
        if (!isNotApproved) return false;

        final r = p.role.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), ' ');
        if (r.isEmpty) return false;

        // provider accounts are stored as "service_provider"
        if (r == 'service_provider') return true;

        return r.contains('service provider') ||
            r.contains('service pro') ||
            r.contains('mechanic') ||
            r.contains('towing') ||
            r.contains('logistics') ||
            r.contains('rental');
      }).toList();
    });
  }

  Stream<List<UserProfile>> getAllProfiles() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => UserProfile.fromMap(json)).toList());
  }

  /// Returns service providers for the Find a Provider directory.
  /// Types: mechanic, towing, parts (seller), rental, or null for all.
  /// Tries verified first; if none, returns providers by role so the page is never empty.
  Future<List<UserProfile>> getVerifiedProviders({String? serviceType}) async {
    try {
      // 1) Try verified providers first (verification_status = 'approved')
      var list = await _fetchProviders(serviceType: serviceType, verifiedOnly: true);
      // 2) If none, show any provider with that role so the directory isn't blank
      if (list.isEmpty) {
        list = await _fetchProviders(serviceType: serviceType, verifiedOnly: false);
      }
      return list;
    } catch (e) {
      print('Error fetching verified providers: $e');
      return [];
    }
  }

  Future<List<UserProfile>> _fetchProviders({String? serviceType, required bool verifiedOnly}) async {
    var query = _supabase.from('profiles').select();
    if (verifiedOnly) {
      query = query.eq('verification_status', 'approved');
    }

    // Explicitly exclude non-provider roles
    query = query.neq('role', 'customer').neq('role', 'admin').neq('role', 'seller');
    
    if (serviceType != null && serviceType.isNotEmpty) {
      final t = serviceType.toLowerCase();
      if (t == 'mechanic') {
        query = query.or('role.eq.mechanic,primary_service_category.eq.mechanic');
      } else if (t == 'towing') {
        query = query.or('role.eq.towing,primary_service_category.eq.towing');
      } else if (t == 'parts' || t == 'seller') {
        query = query.or('role.eq.parts_supplier,primary_service_category.eq.parts'); // Removed broad seller/is_seller
      } else if (t == 'rental') {
        query = query.or('role.eq.rental,primary_service_category.eq.rental');
      } else {
        query = query.or('role.eq.$t,primary_service_category.eq.$t');
      }
    } else {
      query = query.or('role.in.(mechanic,towing,service_provider,service_pro,provider,rental)');
    }
    
    final response = await query;
    final List<dynamic> rawList = response is List ? response : [];
    print('-----------------------------------------');
    print('DEBUG: _fetchProviders (serviceType=$serviceType, verifiedOnly=$verifiedOnly) returned ${rawList.length} rows.');
    for (var row in rawList) {
      final name = row['full_name'] ?? 'NO NAME';
      final role = row['role'] ?? 'NO ROLE';
      final category = row['primary_service_category'] ?? 'NO CATEGORY';
      print('DEBUG: ROW -> NAME: $name, ROLE: $role, CATEGORY: $category');
    }
    print('-----------------------------------------');
    final result = <UserProfile>[];
    for (final item in rawList) {
      try {
        final map = item is Map ? Map<String, dynamic>.from(item) : null;
        if (map != null) {
          result.add(UserProfile.fromMap(map));
        }
      } catch (e) {
        print('Skip invalid profile row: $e');
      }
    }
    return result;
  }
}

final userServiceProvider = Provider<UserService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return UserService(notificationService);
});

final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, uid) {
  return ref.watch(userServiceProvider).getProfile(uid);
});

final userCountProvider = StreamProvider<int>((ref) {
  return ref.watch(userServiceProvider).getUserCount();
});

final pendingVerificationsProvider = StreamProvider<List<UserProfile>>((ref) {
  return ref.watch(userServiceProvider).getPendingVerifications();
});

/// Verified service providers for customer/seller discovery (mechanic, towing, service_provider).
/// Pass [serviceType] 'mechanic' or 'towing' to filter, or null for all.
final verifiedProvidersProvider = FutureProvider.family<List<UserProfile>, String?>((ref, serviceType) {
  return ref.watch(userServiceProvider).getVerifiedProviders(serviceType: serviceType);
});

final allProfilesProvider = StreamProvider<List<UserProfile>>((ref) {
  return ref.watch(userServiceProvider).getAllProfiles();
});
