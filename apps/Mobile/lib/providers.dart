import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';

/// Maps [UserProfile] from Supabase `profiles` to the shell used by [MainShell].
/// Uses text `role` and boolean `is_admin` only — no client-side security; RLS remains authoritative.
String resolveMobileShellRole(UserProfile p) {
  final r = p.role.toLowerCase().trim();
  if (p.isAdmin || r == 'admin' || r == 'super_admin') return 'super_admin';
  if (r.contains('seller') && !r.contains('customer')) return 'seller';
  if (r == 'logistics' || r.contains('logistics')) return 'logistics';
  if (r.contains('mechanic') ||
      r.contains('towing') ||
      r.contains('provider') ||
      r == 'service_pro' ||
      r == 'service_provider' ||
      r == 'rental') {
    return 'service_pro';
  }
  return 'customer';
}

/// Effective navigation shell after login, driven by server profile (not hard-coded).
final mobileShellRoleProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 'customer';
  final profileAsync = ref.watch(userProfileProvider(user.id));
  return profileAsync.maybeWhen(
    data: (p) => p == null ? 'customer' : resolveMobileShellRole(p),
    orElse: () => 'customer',
  );
});
