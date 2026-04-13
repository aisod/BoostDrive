import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:convert';
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

  /// Specialized check for Admin Invite system
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email.trim())
          .maybeSingle();
          
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Creates a new admin account using a secure RPC call
  Future<Map<String, dynamic>> createAdminAccount({
    required String fullName,
    required String email,
    required String password,
    required String adminUid,
  }) async {
    try {
      // Direct call to Secure RPC
      final response = await _supabase.rpc('create_admin_user', params: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
        'admin_id': adminUid,
      });
      
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error calling create_admin_user RPC: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Finalizes an admin account after email verification
  Future<Map<String, dynamic>> finalizeAdminAccount({
    required String targetUid,
    required String adminUid,
    required String email,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.rpc('finalize_admin_account', params: {
        'target_uid': targetUid,
        'admin_id': adminUid,
        'target_email': email.trim(),
        'target_full_name': fullName.trim(),
      });
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Requests a 6-digit verification code for a new admin invitation
  Future<Map<String, dynamic>> requestAdminInviteOtp(String email) async {
    try {
      final response = await _supabase.rpc(
        'request_admin_invite_otp',
        params: {'target_email': email.toLowerCase().trim()},
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verifies the 6-digit invitation code
  Future<bool> verifyAdminInviteOtp(String email, String code) async {
    try {
      final response = await _supabase.rpc(
        'verify_admin_invite_otp',
        params: {
          'target_email': email.toLowerCase().trim(),
          'input_otp': code.trim(),
        },
      );
      return response as bool;
    } catch (e) {
      print('OTP Verification Error: $e');
      return false;
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

  /// Updates or creates a user profile.
  ///
  /// Returns `true` when `emergency_contacts` was included in the upsert (column exists).
  /// Returns `false` when that column is missing on the server: upsert retries without it
  /// so legacy `emergency_contact_name` / `emergency_contact_phone` still store the first contact.
  /// Apply `supabase/migrations/20260410210000_profiles_emergency_contacts_jsonb.sql` for full multi-contact storage.
  Future<bool> updateProfile(UserProfile profile) async {
    final map = profile.toMap()..['id'] = profile.uid;
    try {
      await _supabase.from('profiles').upsert(map);
      return true;
    } catch (e) {
      if (_isMissingEmergencyContactsColumn(e)) {
        print(
          'Warning: profiles.emergency_contacts column missing (PGRST204). '
          'Upserting without it; only the first emergency contact is stored until the migration is applied.',
        );
        final fallback = Map<String, dynamic>.from(map)..remove('emergency_contacts');
        await _supabase.from('profiles').upsert(fallback);
        return false;
      }
      print('Error updating profile: $e');
      rethrow;
    }
  }

  static bool _isMissingEmergencyContactsColumn(Object e) {
    if (e is! PostgrestException) return false;
    final code = e.code;
    final msg = e.message;
    return (code == 'PGRST204' || msg.contains('PGRST204')) &&
        msg.contains('emergency_contacts');
  }

  /// Updates the provider's verification status and logs the action
  Future<void> updateVerificationStatus({
    required String uid,
    required String status,
    required String adminUid,
  }) async {
    try {
      print('DEBUG: Attempting to update verification_status of $uid to $status...');
      
      final Map<String, dynamic> updates = {'verification_status': status};
      if (status == 'approved') {
        updates['status'] = 'active';
      }
      
      final response = await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', uid)
          .select();

      if (response == null || (response as List).isEmpty) {
        throw Exception('No profile found to update or update rejected by RLS.');
      }

      print('DEBUG: Verification status update successful for $uid');

      // Granular Audit Logging
      final context = await _getAuditContext();
      await logAuditAction(
        adminId: adminUid,
        targetId: uid,
        actionType: status == 'approved' ? 'APPROVE_PROVIDER' : 'REJECT_PROVIDER',
        notes: 'Verification status changed to ${status.toUpperCase()}',
        metadata: {
          'old_status': 'pending', // Usually pending if we are in this flow
          'new_status': status,
          'category': 'VERIFICATION'
        },
        context: context,
      );

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

  /// New professional audit helper
  Future<void> logAuditAction({
    required String adminId,
    required String targetId,
    required String actionType,
    required String notes,
    Map<String, dynamic>? metadata,
    Map<String, String>? context,
  }) async {
    try {
      await _supabase.from('audit_logs').insert({
        'admin_id': adminId,
        'target_id': targetId,
        'action_type': actionType,
        'notes': notes,
        'metadata': metadata ?? {},
        'ip_address': context?['ip'],
        'device_info': context?['device'],
        'location': context?['location'],
      });
    } catch (e) {
      print('Warning: Failed to insert professional audit log: $e');
    }
  }

  /// Returns the last 10 audit logs for administrative overview
  Stream<List<Map<String, dynamic>>> getRecentAuditLogs() {
    return _supabase
        .from('audit_logs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(10);
  }

  /// Captures IP and Device Info for Security Trail
  Future<Map<String, String>> _getAuditContext() async {
    String ip = 'Unknown';
    String device = kIsWeb ? 'ASUS Web Dashboard' : 'Mobile App'; // Default label
    if (!kIsWeb) {
      if (Platform.isIOS) device = 'iPhone';
      if (Platform.isAndroid) device = 'Android Device';
    }

    try {
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = (Uri.parse('?${response.body}').queryParameters); 
        ip = jsonDecode(response.body)['ip'] ?? 'Unknown';
      }
    } catch (_) {}

    return {
      'ip': ip,
      'device': device,
      'location': 'Namibia (Estimate)', // Placeholder for location services
    };
  }

  /// Logs when an admin views sensitive documents
  Future<void> logDocumentReview({
    required String adminId,
    required String targetId,
    required String documentType,
    required String fileName,
  }) async {
    final context = await _getAuditContext();
    await logAuditAction(
      adminId: adminId,
      targetId: targetId,
      actionType: 'DOC_VIEW',
      notes: 'Admin reviewed $documentType ($fileName)',
      metadata: {
        'document_type': documentType,
        'file_name': fileName,
        'access_time': DateTime.now().toIso8601String(),
      },
      context: context,
    );
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

  /// Updates the user's account status (active, suspended, frozen) and logs it.
  Future<void> updateUserStatus({
    required String uid,
    required String status,
    required String adminUid,
    String? reason,
  }) async {
    try {
      final Map<String, dynamic> updates = {'status': status};
      if (status == 'active') {
        updates['suspension_reason'] = null;
        updates['suspended_at'] = null;
        updates['suspended_by'] = null;
      } else {
        updates['suspension_reason'] = reason;
        updates['suspended_at'] = DateTime.now().toIso8601String();
        updates['suspended_by'] = adminUid;
      }
      await _supabase.from('profiles').update(updates).eq('id', uid);
      
      // Granular Audit Logging
      final context = await _getAuditContext();
      final actionLabel = status == 'active' ? 'UNSUSPENDED' : 'SUSPENDED';
      await logAuditAction(
        adminId: adminUid,
        targetId: uid,
        actionType: 'UPDATE_USER_STATUS',
        notes: 'Account $actionLabel. Reason: ${reason ?? "No reason provided"}',
        metadata: {
          'new_status': status,
          'reason': reason,
          'category': 'ACCOUNT_SECURITY'
        },
        context: context,
      );
    } catch (e) {
      print('Error updating user status: $e');
      rethrow;
    }
  }

  /// Fetches audit logs for a specific user
  Future<List<Map<String, dynamic>>> getAuditLogs(String targetId) async {
    try {
      final response = await _supabase
          .from('audit_logs')
          .select()
          .eq('target_id', targetId)
          .order('created_at', ascending: false);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching audit logs: $e');
      return [];
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
      // Temporarily relaxed for development: show ALL providers regardless of verification status
      return await _fetchProviders(serviceType: serviceType, verifiedOnly: false);
    } catch (e) {
      print('Error fetching verified providers: $e');
      return [];
    }
  }

  /// Providers with workshop coordinates within [maxKm] of the SOS point (for customer waiting map).
  Future<List<UserProfile>> getNearbyVerifiedProviders({
    required double customerLat,
    required double customerLng,
    String? serviceType,
    double maxKm = 150,
  }) async {
    final all = await getVerifiedProviders(serviceType: serviceType);
    return all.where((p) {
      final lat = p.workshopLat;
      final lng = p.workshopLng;
      if (lat == null || lng == null) return false;
      return GeoEta.haversineKm(customerLat, customerLng, lat, lng) <= maxKm;
    }).toList()
      ..sort((a, b) {
        final da = GeoEta.haversineKm(customerLat, customerLng, a.workshopLat!, a.workshopLng!);
        final db = GeoEta.haversineKm(customerLat, customerLng, b.workshopLat!, b.workshopLng!);
        return da.compareTo(db);
      });
  }

  Future<List<UserProfile>> _fetchProviders({String? serviceType, required bool verifiedOnly}) async {
    var query = _supabase.from('profiles').select();
    if (verifiedOnly) {
      query = query.eq('verification_status', 'approved');
    }

    // Visibility Blackout: Exclude suspended/banned/frozen providers from the directory
    query = query.neq('status', 'suspended').neq('status', 'banned').neq('status', 'frozen');

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

final providerStaffProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, providerId) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('provider_staff')
      .stream(primaryKey: ['id'])
      .eq('provider_id', providerId)
      .order('created_at', ascending: false);
});

final recentAuditLogsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(userServiceProvider).getRecentAuditLogs();
});

