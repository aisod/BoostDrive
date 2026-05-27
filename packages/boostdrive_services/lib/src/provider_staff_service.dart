import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// CRUD for [provider_staff] roster rows (Staff & Fleet Management).
/// Schema: `database/provider_staff_migration.sql`
class ProviderStaffService {
  ProviderStaffService([SupabaseClient? client])
      : _c = client ?? Supabase.instance.client;

  final SupabaseClient _c;

  Future<List<Map<String, dynamic>>> listForProvider(String providerId) async {
    final rows = await _c
        .from('provider_staff')
        .select()
        .eq('provider_id', providerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>> addStaff({
    required String providerId,
    required String fullName,
    required String staffRole,
    String? staffInternalId,
    String? phoneNumber,
    String? email,
    bool canViewFleet = false,
    bool canAcceptSos = false,
    bool canViewFinance = false,
    String? staffUserId,
  }) async {
    final payload = <String, dynamic>{
      'provider_id': providerId,
      'full_name': fullName.trim(),
      'staff_role': staffRole,
      'staff_internal_id': _emptyToNull(staffInternalId),
      'phone_number': _emptyToNull(phoneNumber),
      'email': _emptyToNull(email?.trim().toLowerCase()),
      'can_view_fleet': canViewFleet,
      'can_accept_sos': canAcceptSos,
      'can_view_finance': canViewFinance,
      if (staffUserId != null) 'staff_user_id': staffUserId,
    };

    final row = await _c.from('provider_staff').insert(payload).select().single();
    return Map<String, dynamic>.from(row as Map);
  }

  Future<void> updateStaff({
    required String staffRowId,
    required String fullName,
    required String staffRole,
    String? staffInternalId,
    String? phoneNumber,
    bool? canViewFleet,
    bool? canAcceptSos,
    bool? canViewFinance,
    bool? isActive,
  }) async {
    await _c.from('provider_staff').update({
      'full_name': fullName.trim(),
      'staff_role': staffRole,
      'staff_internal_id': _emptyToNull(staffInternalId),
      'phone_number': _emptyToNull(phoneNumber),
      if (canViewFleet != null) 'can_view_fleet': canViewFleet,
      if (canAcceptSos != null) 'can_accept_sos': canAcceptSos,
      if (canViewFinance != null) 'can_view_finance': canViewFinance,
      if (isActive != null) 'is_active': isActive,
    }).eq('id', staffRowId);
  }

  Future<void> deleteStaff(String staffRowId) async {
    await _c.from('provider_staff').delete().eq('id', staffRowId);
  }

  /// If [email] already has a profile, link the roster row to that user.
  Future<String?> lookupUserIdByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final rows = await _c
        .from('profiles')
        .select('id')
        .eq('email', normalized)
        .limit(1);
    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) return null;
    return list.first['id'] as String?;
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
}

final providerStaffServiceProvider = Provider<ProviderStaffService>((ref) {
  return ProviderStaffService();
});

final providerStaffProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, providerId) {
  return ref.watch(providerStaffServiceProvider).listForProvider(providerId);
});
