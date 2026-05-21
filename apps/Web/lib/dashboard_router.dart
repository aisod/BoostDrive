import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boost_drive_web/customer_dashboard_page.dart';
import 'package:boost_drive_web/provider_hub_page.dart';
import 'package:boost_drive_web/seller_dashboard_page.dart';
import 'package:boost_drive_web/super_admin_dashboard_page.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

/// Whether [role] maps to a marketplace service-provider dashboard.
bool isWebProviderRole(String role) {
  final cleaned = role.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), ' ');
  if (cleaned.isEmpty) return false;
  if (cleaned == 'service_provider') return true;

  return cleaned.contains('service provider') ||
      cleaned.contains('service pro') ||
      cleaned.contains('mechanic') ||
      cleaned.contains('towing') ||
      cleaned.contains('logistics') ||
      cleaned.contains('rental');
}

/// Resolves the dashboard widget for a stored profile role string.
Widget dashboardWidgetForRole(String role) {
  final cleaned = role.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), ' ');

  if (cleaned == 'admin' || cleaned == 'super admin') {
    return const SuperAdminDashboardPage();
  }

  if (cleaned == 'seller' || cleaned.contains('seller')) {
    return const SellerDashboardPage();
  }

  if (isWebProviderRole(role)) {
    return const ProviderHubPage();
  }

  return const CustomerDashboardPage();
}

/// Uses role plus buyer/seller flags from the profile record.
Widget dashboardWidgetForProfile(UserProfile profile) {
  if (profile.isAdmin ||
      profile.role == 'admin' ||
      profile.role == 'super_admin') {
    return const SuperAdminDashboardPage();
  }

  if (profile.isSeller && !isWebProviderRole(profile.role)) {
    return const SellerDashboardPage();
  }

  return dashboardWidgetForRole(profile.role);
}

/// After authentication, send the user to the dashboard that matches their profile.
Future<void> navigateToUserDashboard(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onBeforeNavigate,
}) async {
  onBeforeNavigate?.call();

  final user = ref.read(currentUserProvider);
  if (user == null || !context.mounted) return;

  final profile = await ref.read(userProfileProvider(user.id).future);
  if (!context.mounted || profile == null) return;

  if (profile.isAdmin ||
      profile.role == 'admin' ||
      profile.role == 'super_admin') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SuperAdminDashboardPage()),
      (_) => false,
    );
    return;
  }

  final role = profile.role.trim().toLowerCase();
  final isCustomerOrSeller = role == 'customer' || role == 'seller';
  if (!profile.isBuyer &&
      !profile.isSeller &&
      !isCustomerOrSeller &&
      !isWebProviderRole(profile.role)) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      (_) => false,
    );
    return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => dashboardWidgetForProfile(profile)),
    (_) => false,
  );
}

/// Closes any login drawer/sheet, then routes to the role dashboard.
Future<void> handleWebLoginSuccess(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? closeDrawer,
}) {
  return navigateToUserDashboard(
    context,
    ref,
    onBeforeNavigate: closeDrawer,
  );
}
