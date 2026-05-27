import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boost_drive_web/dashboard_shell.dart';
import 'package:boost_drive_web/logistics_dashboard_page.dart';
import 'package:boost_drive_web/seller_dashboard_page.dart';
import 'package:boost_drive_web/service_pro_dashboard_page.dart';

class ProviderHubPage extends ConsumerStatefulWidget {
  const ProviderHubPage({super.key});

  @override
  ConsumerState<ProviderHubPage> createState() => _ProviderHubPageState();
}

class _ProviderHubPageState extends ConsumerState<ProviderHubPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ProviderHubTab _activeTab = ProviderHubTab.services;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final profile = ref.watch(userProfileProvider(user.id)).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isSeller = profile.role.toLowerCase().contains('seller');
    if (isSeller) {
      return const SellerDashboardPage();
    }

    final hubBody = isSeller
        ? const SellerDashboardPage()
        : _activeTab == ProviderHubTab.logistics
            ? const LogisticsDashboardPage()
            : const ServiceProDashboardPage(embedded: true);

    return ProviderProfileSetupReminderScope(
      profile: profile,
      child: DashboardAppShell(
        scaffoldKey: _scaffoldKey,
        activeTab: DashboardNavTab.dashboard,
        sidebar: ProviderDashboardSidebar(
          activeTab: _activeTab,
          portalSubtitle: profile.verificationStatus.toLowerCase() == 'approved'
              ? 'Verified Expert'
              : 'Manage services & logistics',
          earningsDisplay: '\$${profile.totalEarnings.toStringAsFixed(2)}',
          onTabSelected: (tab) {
            setState(() => _activeTab = tab);
            _scaffoldKey.currentState?.closeDrawer();
          },
          onSettings: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
          ),
        ),
        child: hubBody,
      ),
    );
  }
}
