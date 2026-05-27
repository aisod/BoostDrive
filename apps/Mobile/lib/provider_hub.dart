import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'batlorrih_logistics_dashboard.dart';
import 'service_pro_dashboard.dart';
import 'seller_dashboard.dart';
class ProviderHub extends ConsumerStatefulWidget {
  const ProviderHub({super.key});

  @override
  ConsumerState<ProviderHub> createState() => _ProviderHubState();
}

class _ProviderHubState extends ConsumerState<ProviderHub> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please log in')));

    final profile = ref.watch(userProfileProvider(user.id)).value;
    if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isSeller = profile.role.toLowerCase().contains('seller');

    final palette = DashboardPalette.of(context);

    return ProviderProfileSetupReminderScopeMobile(
      profile: profile,
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: MobileProviderUi.glassAppBar(
          context: context,
          palette: palette,
          title: 'BoostDrive',
          avatar: MobileProviderUi.profileAvatar(
            palette: palette,
            imageUrl: profile.profileImg,
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MobileProviderUi.hubTabBar(
              palette: palette,
              controller: _tabController,
              tabs: [
                Tab(text: isSeller ? 'MY STORE' : 'MY SERVICES'),
                const Tab(text: 'BATLORRIH'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  isSeller ? const SellerDashboard() : const ServiceProDashboard(),
                  const BaTLorriHLogisticsDashboard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
