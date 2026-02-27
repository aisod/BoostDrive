import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'logistics_dashboard_page.dart';
import 'service_pro_dashboard_page.dart';
import 'seller_dashboard_page.dart';

class ProviderHubPage extends ConsumerStatefulWidget {
  const ProviderHubPage({super.key});

  @override
  ConsumerState<ProviderHubPage> createState() => _ProviderHubPageState();
}

class _ProviderHubPageState extends ConsumerState<ProviderHubPage> with SingleTickerProviderStateMixin {
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

    return PremiumPageLayout(
      showBackground: true,
      appBar: AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        elevation: 0,
        title: const Text(
          'Provider Hub',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
          tabs: [
            Tab(text: isSeller ? 'MY STORE' : 'MY SERVICES'),
            const Tab(text: 'LOGISTICS (BATLORRIH)'),
          ],
        ),
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 120, // Adjust for AppBar and TabBar
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Trade-specific Dashboard
            isSeller ? const SellerDashboardPage() : const ServiceProDashboardPage(),
            
            // Tab 2: BaTLorriH Dashboard
            const LogisticsDashboardPage(),
          ],
        ),
      ),
    );
  }
}
