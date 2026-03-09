import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';

class UserService {
  final _supabase = Supabase.instance.client;

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
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('verification_status', 'pending')
        .map((data) => data.map((json) => UserProfile.fromMap(json)).toList());
  }

  /// Returns service providers for the Find a Provider directory.
  /// Types: mechanic, towing, parts (seller), rental, or null for all.
  /// Tries verified first; if none, returns providers by role so the page is never empty.
  Future<List<UserProfile>> getVerifiedProviders({String? serviceType}) async {
    String? roleFilter;
    if (serviceType != null && serviceType.isNotEmpty) {
      switch (serviceType.toLowerCase()) {
        case 'mechanic':
          roleFilter = 'mechanic';
          break;
        case 'towing':
          roleFilter = 'towing';
          break;
        case 'parts':
          roleFilter = 'seller';
          break;
        case 'rental':
          roleFilter = 'rental';
          break;
        default:
          break;
      }
    }

    try {
      // 1) Try verified providers first (verification_status = 'approved')
      var list = await _fetchProvidersByRole(roleFilter: roleFilter, verifiedOnly: true);
      // 2) If none, show any provider with that role so the directory isn't blank
      if (list.isEmpty) {
        list = await _fetchProvidersByRole(roleFilter: roleFilter, verifiedOnly: false);
      }
      return list;
    } catch (e) {
      print('Error fetching verified providers: $e');
      return [];
    }
  }

  Future<List<UserProfile>> _fetchProvidersByRole({String? roleFilter, required bool verifiedOnly}) async {
    var query = _supabase.from('profiles').select();
    if (verifiedOnly) {
      query = query.eq('verification_status', 'approved');
    }
    if (roleFilter != null && roleFilter.isNotEmpty) {
      query = query.eq('role', roleFilter);
    } else {
      query = query.or(
        'role.eq.mechanic,role.eq.towing,role.eq.service_provider,role.eq.seller,role.eq.rental',
      );
    }
    final response = await query;
    final rawList = response is List ? response as List : [response];
    final result = <UserProfile>[];
    for (final item in rawList) {
      try {
        final map = item is Map ? Map<String, dynamic>.from(item as Map) : null;
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
  return UserService();
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
